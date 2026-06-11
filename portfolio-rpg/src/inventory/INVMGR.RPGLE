**FREE
// =======================================================================
// プログラム名：INVMGR
// 機　　　能：物流在庫管理（商品マスタ・入出庫・在庫照会・在庫調整）
// 使用ファイル：ITMPF（商品マスタ）INVPF（在庫）INVLF（在庫論理）INVDSPF（画面）
// バインドSRVPGM：UTILSRV ERRSRV
// =======================================================================
Ctl-Opt DftActGrp(*No) ActGrp('INVMGR') BndDir('QC2LE')
        Option(*SrcStmt : *NoDebugIO) DatFmt(*ISO) TimFmt(*ISO);

// ファイル定義
DCL-F ITMPF    Keyed Usage(*Update : *Delete : *Output : *Input);
DCL-F INVPF    Keyed Usage(*Update : *Output : *Input);
DCL-F INVLF    Keyed Usage(*Input);
DCL-F INVDSPF  WorkStn;

// 商品ステータス定数
DCL-C ITM_ACTIVE '1';
DCL-C ITM_DISC   '9';

// 作業変数
DCL-S WrkMode    Char(1);
DCL-S WrkMsg     Char(79);
DCL-S WrkToday   Char(8);
DCL-S WrkTime    Char(6);
DCL-S WrkErr     Ind;
DCL-S WrkFound   Ind;

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
  WrkTime  = %Char(%Time() : *HMS0);
  Clear INVMNU;
  WrkMsg = *Blanks;
EndSr;

// =======================================================================
// メインループ
// =======================================================================
BegSr SrMain;
  DoU *In03;
    ExFmt INVMNU;
    Select;
      When *In03;
        Leave;
      When *In06;
        // F6=商品登録（新規）
        WrkMode = 'A';
        ExSr SrAddItem;
      When *In07;
        // F7=入庫処理
        ExSr SrReceive;
      When *In08;
        // F8=出庫処理
        ExSr SrShip;
      Other;
        // Enter=在庫照会
        ExSr SrInqInv;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 在庫照会（商品コード・カテゴリ・ロケーション指定）
// =======================================================================
BegSr SrInqInv;
  WrkFound = *Off;

  If SRITMCD <> *Blanks;
    // 商品コード指定：INVPF直接キーアクセス
    Chain SRITMCD INVREC;
    WrkFound = %Found(INVPF);
  ElseIf SRLOCCD <> *Blanks;
    // ロケーション指定：論理ファイルで検索
    SetLL SRLOCCD INVLF;
    Read  INVREC INVLF;
    WrkFound = Not %Eof(INVLF) And LOCCD = SRLOCCD;
  Else;
    // 全件照会
    SetLL *LVal INVLF;
    Read  INVREC INVLF;
    WrkFound = Not %Eof(INVLF);
  EndIf;

  If Not WrkFound;
    MSGINV = '該当する在庫データがありません';
  EndIf;
EndSr;

// =======================================================================
// 商品登録（新規・更新）
// =======================================================================
BegSr SrAddItem;
  Clear ITMDET;
  Clear ITMREC;
  ITMSTS = ITM_ACTIVE;
  UPDDT  = WrkToday;
  MSGITM = '商品情報を入力してください  F4=確定  F3=取消';

  DoU *In03 Or *In04;
    ExFmt ITMDET;
    Select;
      When *In03;
        MSGINV = '商品登録を取り消しました';
        Leave;
      When *In04;
        ExSr SrValidItem;
        If Not WrkErr;
          UPDDT  = WrkToday;
          UPDUID = 'WEBUSER';
          Chain ITMCD ITMREC;
          If %Found(ITMPF) And WrkMode = 'A';
            MSGITM = '商品コード ' + %TrimR(ITMCD) + ' は既に登録されています';
          ElseIf %Found(ITMPF);
            Update ITMREC;
            MSGINV = '商品を更新しました: ' + %TrimR(ITMCD);
            Leave;
          Else;
            Write ITMREC;
            ExSr SrInitInvRec;
            MSGINV = '商品を登録しました: ' + %TrimR(ITMCD);
            Leave;
          EndIf;
        EndIf;
      When *In09;
        // F9=廃番処理
        ExSr SrDiscItem;
        Leave;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 在庫レコード初期化（商品新規登録時）
// =======================================================================
BegSr SrInitInvRec;
  Clear INVREC;
  ITMCD   = ITMREC.ITMCD;
  LOCCD   = 'WH-A-001';   // デフォルトロケーション
  ITMNM   = ITMREC.ITMNM;
  STKQTY  = 0;
  ALCQTY  = 0;
  AVLQTY  = 0;
  RCVQTY  = 0;
  SHPQTY  = 0;
  UPDDT   = WrkToday;
  UPDTM   = WrkTime;
  UPDUID  = 'WEBUSER';
  Write INVREC;
EndSr;

// =======================================================================
// 廃番処理（商品ステータスを廃番に変更）
// =======================================================================
BegSr SrDiscItem;
  If STKQTY > 0 Or ALCQTY > 0;
    MSGITM = '在庫・引当残のある商品は廃番にできません';
    Return;
  EndIf;
  ITMSTS = ITM_DISC;
  UPDDT  = WrkToday;
  Update ITMREC;
  MSGINV = '商品を廃番にしました: ' + %TrimR(ITMCD);
EndSr;

// =======================================================================
// 入庫処理
// =======================================================================
BegSr SrReceive;
  Clear NYUKO;
  MSGNYU = '入庫する商品コードとロケーションを入力してください';

  DoU *In03 Or *In04;
    ExFmt NYUKO;
    Select;
      When *In03;
        MSGINV = '入庫処理を取り消しました';
        Leave;
      When *In04;
        // 在庫レコード取得
        Chain %KList(NITMCD : NLOCCD) INVREC;
        If Not %Found(INVPF);
          MSGNYU = '在庫レコードが見つかりません';
        ElseIf NRCVQTY <= 0;
          MSGNYU = '入庫数量は1以上を入力してください';
        Else;
          // 在庫数量を加算
          STKQTY  += NRCVQTY;
          AVLQTY   = STKQTY - ALCQTY;
          RCVQTY  += NRCVQTY;
          LSTRCVDT = WrkToday;
          UPDDT    = WrkToday;
          UPDTM    = WrkTime;
          UPDUID   = 'WEBUSER';
          Update INVREC;
          If Not %Error;
            MSGINV = '入庫処理が完了しました: ' + %TrimR(NITMCD) +
                     ' 入庫数量=' + %Char(NRCVQTY);
            Leave;
          Else;
            MSGNYU = '在庫更新に失敗しました';
          EndIf;
        EndIf;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 出庫処理
// =======================================================================
BegSr SrShip;
  Clear NYUKO;
  MSGNYU = '出庫する商品コードとロケーションを入力してください';

  DoU *In03 Or *In04;
    ExFmt NYUKO;
    Select;
      When *In03;
        MSGINV = '出庫処理を取り消しました';
        Leave;
      When *In04;
        Chain %KList(NITMCD : NLOCCD) INVREC;
        If Not %Found(INVPF);
          MSGNYU = '在庫レコードが見つかりません';
        ElseIf NRCVQTY <= 0;
          MSGNYU = '出庫数量は1以上を入力してください';
        ElseIf AVLQTY < NRCVQTY;
          MSGNYU = '有効在庫不足: 有効在庫=' + %Char(AVLQTY);
        Else;
          // 在庫数量を減算
          STKQTY  -= NRCVQTY;
          AVLQTY   = STKQTY - ALCQTY;
          SHPQTY  += NRCVQTY;
          LSTSHPDT = WrkToday;
          UPDDT    = WrkToday;
          UPDTM    = WrkTime;
          UPDUID   = 'WEBUSER';
          Update INVREC;
          If Not %Error;
            MSGINV = '出庫処理が完了しました: ' + %TrimR(NITMCD) +
                     ' 出庫数量=' + %Char(NRCVQTY);
            Leave;
          Else;
            MSGNYU = '在庫更新に失敗しました';
          EndIf;
        EndIf;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 商品入力チェック
// =======================================================================
BegSr SrValidItem;
  WrkErr  = *Off;
  MSGITM  = *Blanks;

  If %TrimR(ITMCD) = *Blanks;
    MSGITM = '商品コードを入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If %TrimR(ITMNM) = *Blanks;
    MSGITM = '商品名を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If UNTPRC <= 0;
    MSGITM = '販売単価は0より大きい値を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If CPRC <= 0;
    MSGITM = '仕入単価は0より大きい値を入力してください';
    WrkErr = *On;
    Return;
  EndIf;
EndSr;

// =======================================================================
// プロシージャ：在庫引当（受注確定時にORDMGRから呼び出し）
// =======================================================================
DCL-PROC AllocateStock;
  DCL-PI *N Ind;
    PiItmCd  Char(10) Const;
    PiLocCd  Char(10) Const;
    PiQty    Packed(9 : 0) Const;
  END-PI;

  Chain %KList(PiItmCd : PiLocCd) INVREC;
  If Not %Found(INVPF);
    Return *Off;
  EndIf;

  If AVLQTY < PiQty;
    Return *Off;
  EndIf;

  ALCQTY += PiQty;
  AVLQTY  = STKQTY - ALCQTY;
  UPDDT   = %Char(%Date() : *ISO0);
  UPDTM   = %Char(%Time() : *HMS0);
  UPDUID  = 'ORDMGR';
  Update INVREC;

  Return Not %Error;
END-PROC;

// =======================================================================
// プロシージャ：在庫調整（棚卸差異修正）
// =======================================================================
DCL-PROC AdjustStock;
  DCL-PI *N Ind;
    PiItmCd    Char(10) Const;
    PiLocCd    Char(10) Const;
    PiAdjQty   Packed(9 : 0) Const;
    PiReason   Char(40) Const;
  END-PI;

  DCL-S LclToday Char(8);

  LclToday = %Char(%Date() : *ISO0);

  Chain %KList(PiItmCd : PiLocCd) INVREC;
  If Not %Found(INVPF);
    Return *Off;
  EndIf;

  STKQTY = PiAdjQty;
  AVLQTY = STKQTY - ALCQTY;
  UPDDT  = LclToday;
  UPDUID = 'ADJUST';
  Update INVREC;

  Return Not %Error;
END-PROC;
