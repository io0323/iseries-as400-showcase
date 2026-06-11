**FREE
// =======================================================================
// プログラム名：ACCMGR
// 機　　　能：会計管理（売掛金・買掛金・入金消込・支払処理・残高照会）
// 使用ファイル：ARPF（売掛）APPF（買掛）ACCDSPF（画面）
// バインドSRVPGM：UTILSRV ERRSRV
// =======================================================================
Ctl-Opt DftActGrp(*No) ActGrp('ACCMGR') BndDir('QC2LE')
        Option(*SrcStmt : *NoDebugIO) DatFmt(*ISO) TimFmt(*ISO);

// ファイル定義
DCL-F ARPF     Keyed Usage(*Update : *Output : *Input);
DCL-F APPF     Keyed Usage(*Update : *Output : *Input);
DCL-F ACCDSPF  WorkStn;

// 消費税率定数
DCL-C TAXRATE 0.10;

// 売掛ステータス定数
DCL-C AR_OPEN  '1';
DCL-C AR_PART  '2';
DCL-C AR_DONE  '3';
DCL-C AR_CNCL  '9';

// 買掛ステータス定数
DCL-C AP_OPEN  '1';
DCL-C AP_PART  '2';
DCL-C AP_DONE  '3';
DCL-C AP_CNCL  '9';

// 作業変数
DCL-S WrkMsg     Char(79);
DCL-S WrkToday   Char(8);
DCL-S WrkErr     Ind;
DCL-S WrkFound   Ind;

// サマリー集計用
DCL-S WrkTotInv  Packed(13 : 2);
DCL-S WrkTotRcv  Packed(13 : 2);
DCL-S WrkTotARBal Packed(13 : 2);
DCL-S WrkTotPO   Packed(13 : 2);
DCL-S WrkTotPay  Packed(13 : 2);
DCL-S WrkTotAPBal Packed(13 : 2);

// =======================================================================
// メイン処理
// =======================================================================
ExSr SrInit;
ExSr SrMain;
*InLR = *On;
Return;

// =======================================================================
// 初期化
// =======================================================================
BegSr SrInit;
  WrkToday = %Char(%Date() : *ISO0);
  Clear ACCMNU;
  WrkMsg = *Blanks;
  ExSr SrCalcSummary;
EndSr;

// =======================================================================
// サマリー集計（画面表示用）
// =======================================================================
BegSr SrCalcSummary;
  WrkTotInv   = 0;
  WrkTotRcv   = 0;
  WrkTotARBal = 0;
  WrkTotPO    = 0;
  WrkTotPay   = 0;
  WrkTotAPBal = 0;

  // 売掛金合計
  SetLL *LVal ARREC;
  Read  ARREC;
  DoW Not %Eof(ARPF);
    If ARSTS <> AR_CNCL;
      WrkTotInv   += INVAMT;
      WrkTotRcv   += RCVAMT;
      WrkTotARBal += BALAMT;
    EndIf;
    Read ARREC;
  EndDo;

  // 買掛金合計
  SetLL *LVal APREC;
  Read  APREC;
  DoW Not %Eof(APPF);
    If APSTS <> AP_CNCL;
      WrkTotPO    += POAMT;
      WrkTotPay   += PAYAMT;
      WrkTotAPBal += BALAMT;
    EndIf;
    Read APREC;
  EndDo;

  TOTINV   = WrkTotInv;
  TOTRCV   = WrkTotRcv;
  TOTARBAL = WrkTotARBal;
  TOTPO    = WrkTotPO;
  TOTPAY   = WrkTotPay;
  TOTAPBAL = WrkTotAPBal;
EndSr;

// =======================================================================
// メインループ
// =======================================================================
BegSr SrMain;
  DoU *In03;
    ExFmt ACCMNU;
    Select;
      When *In03;
        Leave;
      When *In06;
        // F6=売掛照会
        ExSr SrArInquiry;
      When *In07;
        // F7=入金消込
        ExSr SrReceive;
      When *In08;
        // F8=買掛照会
        ExSr SrApInquiry;
      When *In09;
        // F9=支払処理
        ExSr SrPayment;
      Other;
        ExSr SrCalcSummary;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 売掛金照会
// =======================================================================
BegSr SrArInquiry;
  WrkFound = *Off;

  If SRNO <> *Blanks;
    Chain SRNO ARREC;
    WrkFound = %Found(ARPF);
  ElseIf SRCD <> *Blanks;
    SetLL SRCD ARREC;
    Read  ARREC;
    WrkFound = Not %Eof(ARPF) And CUSTCD = SRCD;
  EndIf;

  If WrkFound;
    ExSr SrArDetail;
  Else;
    MSGACC = '該当する売掛金データが見つかりません';
  EndIf;
  ExSr SrCalcSummary;
EndSr;

// =======================================================================
// 売掛金明細表示・入金消込
// =======================================================================
BegSr SrArDetail;
  // 画面フィールドに値をセット
  ARCUSTCD = CUSTCD;
  ARCUSTNM = CUSTNM;
  ARITMNM  = ITMNM;
  ARQTY    = QTY;
  RCVDT    = WrkToday;

  DoU *In03 Or *In04;
    ExFmt ARDET;
    Select;
      When *In03;
        MSGACC = '入金消込を取り消しました';
        Leave;
      When *In04;
        // F4=入金消込確定
        ExSr SrValidRcv;
        If Not WrkErr;
          ExSr SrDoReceive;
          If Not WrkErr;
            ExSr SrCalcSummary;
            Leave;
          EndIf;
        EndIf;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 入金消込実行
// =======================================================================
BegSr SrDoReceive;
  WrkErr = *Off;

  If NOWRCV > BALAMT;
    MSGAR  = '入金額が残高を超えています';
    WrkErr = *On;
    Return;
  EndIf;

  RCVAMT += NOWRCV;
  BALAMT  = INVAMT - RCVAMT;

  Select;
    When BALAMT = 0;
      ARSTS = AR_DONE;
    When RCVAMT > 0;
      ARSTS = AR_PART;
    Other;
      ARSTS = AR_OPEN;
  EndSl;

  UPDDT   = WrkToday;
  UPDUID  = 'WEBUSER';
  Update ARREC;

  If Not %Error;
    MSGACC = '入金消込が完了しました。残高=' +
             %EditC(BALAMT : '1');
  Else;
    MSGAR  = '入金消込の更新に失敗しました';
    WrkErr = *On;
  EndIf;
EndSr;

// =======================================================================
// 入金消込 入力チェック
// =======================================================================
BegSr SrValidRcv;
  WrkErr = *Off;
  MSGAR  = *Blanks;

  If %TrimR(RCVDT) = *Blanks;
    MSGAR  = '入金日付を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If NOWRCV <= 0;
    MSGAR  = '入金額は0より大きい値を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If %TrimR(RCVMTD) = *Blanks;
    MSGAR  = '入金方法を入力してください（01=振込 02=手形 03=現金）';
    WrkErr = *On;
    Return;
  EndIf;
EndSr;

// =======================================================================
// 買掛金照会
// =======================================================================
BegSr SrApInquiry;
  WrkFound = *Off;

  If SRNO <> *Blanks;
    Chain SRNO APREC;
    WrkFound = %Found(APPF);
  ElseIf SRCD <> *Blanks;
    SetLL SRCD APREC;
    Read  APREC;
    WrkFound = Not %Eof(APPF) And SUPCD = SRCD;
  EndIf;

  If WrkFound;
    ExSr SrApDetail;
  Else;
    MSGACC = '該当する買掛金データが見つかりません';
  EndIf;
  ExSr SrCalcSummary;
EndSr;

// =======================================================================
// 買掛金明細・支払処理
// =======================================================================
BegSr SrApDetail;
  APSUPCD  = SUPCD;
  APSUPNM  = SUPNM;
  APITMNM  = ITMNM;
  APQTY    = QTY;
  APTAXAMT = TAXAMT;
  APBALAMT = BALAMT;
  ACTPAYDT = WrkToday;

  DoU *In03 Or *In04;
    ExFmt APDET;
    Select;
      When *In03;
        MSGACC = '支払処理を取り消しました';
        Leave;
      When *In04;
        ExSr SrValidPay;
        If Not WrkErr;
          ExSr SrDoPayment;
          If Not WrkErr;
            ExSr SrCalcSummary;
            Leave;
          EndIf;
        EndIf;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 支払処理実行
// =======================================================================
BegSr SrDoPayment;
  WrkErr = *Off;

  If NOWPAY > BALAMT;
    MSGAP  = '支払額が残高を超えています';
    WrkErr = *On;
    Return;
  EndIf;

  PAYAMT += NOWPAY;
  BALAMT  = POAMT - PAYAMT;

  Select;
    When BALAMT = 0;
      APSTS = AP_DONE;
    When PAYAMT > 0;
      APSTS = AP_PART;
    Other;
      APSTS = AP_OPEN;
  EndSl;

  UPDDT  = WrkToday;
  UPDUID = 'WEBUSER';
  Update APREC;

  If Not %Error;
    MSGACC = '支払処理が完了しました。残高=' +
             %EditC(BALAMT : '1');
  Else;
    MSGAP  = '支払処理の更新に失敗しました';
    WrkErr = *On;
  EndIf;
EndSr;

// =======================================================================
// 支払処理 入力チェック
// =======================================================================
BegSr SrValidPay;
  WrkErr = *Off;
  MSGAP  = *Blanks;

  If %TrimR(ACTPAYDT) = *Blanks;
    MSGAP  = '支払日付を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If NOWPAY <= 0;
    MSGAP  = '支払額は0より大きい値を入力してください';
    WrkErr = *On;
    Return;
  EndIf;
EndSr;

// =======================================================================
// 入金消込画面遷移（メニューから直接）
// =======================================================================
BegSr SrReceive;
  If SRNO <> *Blanks;
    Chain SRNO ARREC;
    If %Found(ARPF);
      ExSr SrArDetail;
    Else;
      MSGACC = '請求番号が見つかりません: ' + %TrimR(SRNO);
    EndIf;
  Else;
    MSGACC = '入金消込する請求番号を入力してください';
  EndIf;
EndSr;

// =======================================================================
// 支払処理画面遷移（メニューから直接）
// =======================================================================
BegSr SrPayment;
  If SRNO <> *Blanks;
    Chain SRNO APREC;
    If %Found(APPF);
      ExSr SrApDetail;
    Else;
      MSGACC = '仕入番号が見つかりません: ' + %TrimR(SRNO);
    EndIf;
  Else;
    MSGACC = '支払処理する仕入番号を入力してください';
  EndIf;
EndSr;

// =======================================================================
// プロシージャ：売掛金レコード生成（出荷確定時にORDMGRから呼び出し）
// =======================================================================
DCL-PROC CreateArRecord;
  DCL-PI *N Ind;
    PiInvNo   Char(10) Const;
    PiOrdNo   Char(10) Const;
    PiCustCd  Char(10) Const;
    PiCustNm  Char(40) Const;
    PiItmCd   Char(10) Const;
    PiItmNm   Char(40) Const;
    PiQty     Packed(7 : 0) Const;
    PiUntPrc  Packed(9 : 2) Const;
  END-PI;

  DCL-S LclAmt   Packed(11 : 2);
  DCL-S LclTax   Packed(9 : 2);
  DCL-S LclToday Char(8);

  LclToday = %Char(%Date() : *ISO0);
  LclAmt   = PiQty * PiUntPrc;
  LclTax   = %Int(LclAmt * TAXRATE);

  Clear ARREC;
  INVNO   = PiInvNo;
  INVDT   = LclToday;
  DUEDT   = %Char(%Date() + %Days(30) : *ISO0);  // 30日後を支払期日に設定
  CUSTCD  = PiCustCd;
  CUSTNM  = PiCustNm;
  ORDNO   = PiOrdNo;
  ITMCD   = PiItmCd;
  ITMNM   = PiItmNm;
  QTY     = PiQty;
  UNTPRC  = PiUntPrc;
  INVAMT  = LclAmt + LclTax;
  TAXAMT  = LclTax;
  RCVAMT  = 0;
  BALAMT  = INVAMT;
  ARSTS   = AR_OPEN;
  UPDDT   = LclToday;
  UPDUID  = 'ORDMGR';
  Write ARREC;

  Return Not %Error;
END-PROC;
