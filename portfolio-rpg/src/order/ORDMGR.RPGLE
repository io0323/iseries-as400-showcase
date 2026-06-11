**FREE
// =======================================================================
// プログラム名：ORDMGR
// 機　　　能：受注管理（CRUD・在庫引当・受注残照会）
// 使用ファイル：ORDPF（受注物理）ORDLF（受注論理）ORDDSPF（画面）
// バインドSRVPGM：UTILSRV ERRSRV
// =======================================================================
Ctl-Opt DftActGrp(*No) ActGrp('ORDMGR') BndDir('QC2LE')
        Option(*SrcStmt : *NoDebugIO) DatFmt(*ISO) TimFmt(*ISO);

// ファイル定義
DCL-F ORDPF    Keyed Usage(*Update : *Delete : *Output : *Input);
DCL-F ORDLF    Keyed Usage(*Input);
DCL-F ORDDSPF  WorkStn SFile(ORDSFL : WrkRRN);

// 受注ステータス定数
DCL-C STS_OPEN   '1';
DCL-C STS_ALLOC  '2';
DCL-C STS_SHIP   '3';
DCL-C STS_CANCEL '9';

// 作業変数
DCL-S WrkMode    Char(1);
DCL-S WrkRRN     Int(10);
DCL-S WrkMsg     Char(79);
DCL-S WrkOrdNo   Char(10);
DCL-S WrkFound   Ind;
DCL-S WrkErr     Ind;
DCL-S WrkToday   Char(8);
DCL-S WrkTime    Char(6);

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
  Clear ORDMNU;
  WrkMsg = *Blanks;
EndSr;

// =======================================================================
// メインループ
// =======================================================================
BegSr SrMain;
  DoU *In03;
    ExSr SrLoadList;
    ExFmt ORDMNU;
    Select;
      When *In03;
        Leave;
      When *In06;
        // F6=新規登録
        WrkMode = 'A';
        ExSr SrAddOrder;
      When *In05;
        // F5=再表示
        WrkMsg = *Blanks;
      Other;
        // Enter=検索・選択
        If SRORDNO <> *Blanks Or SRCUSTCD <> *Blanks;
          ExSr SrSearchOrder;
        EndIf;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 一覧データ読込（サブファイルロード）
// =======================================================================
BegSr SrLoadList;
  WrkRRN = 0;
  Write ORDCTL;
  // ステータス1〜3（未完了受注）を検索
  SetLL *LVal ORDLF;
  Read  ORDREC ORDLF;
  DoW Not %Eof(ORDLF) And WrkRRN < 9999;
    If ORDSTS <> STS_CANCEL;
      WrkRRN += 1;
      // サブファイルへの書込（ORDSFLフォーマット）
      Write ORDSFL;
    EndIf;
    Read ORDREC ORDLF;
  EndDo;
  If WrkRRN = 0;
    WrkMsg = '受注データがありません';
  EndIf;
EndSr;

// =======================================================================
// 受注検索（受注番号 or 得意先CDで検索）
// =======================================================================
BegSr SrSearchOrder;
  WrkFound = *Off;
  If SRORDNO <> *Blanks;
    Chain SRORDNO ORDREC;
    WrkFound = %Found(ORDPF);
  ElseIf SRCUSTCD <> *Blanks;
    // 論理ファイルで得意先コード順に読込
    SetLL SRCUSTCD ORDLF;
    Read  ORDREC ORDLF;
    WrkFound = Not %Eof(ORDLF) And CUSTCD = SRCUSTCD;
  EndIf;

  If WrkFound;
    WrkMode = 'U';
    ExSr SrDetScreen;
  Else;
    MSGLST = '検索条件に一致する受注が見つかりません';
  EndIf;
EndSr;

// =======================================================================
// 受注登録（新規追加）
// =======================================================================
BegSr SrAddOrder;
  Clear ORDDET;
  Clear ORDREC;
  ORDSTS = STS_OPEN;
  ORDDT  = WrkToday;
  MSGLST = '新規受注を入力してください  F4=確定  F3=取消';
  ExSr SrDetScreen;
EndSr;

// =======================================================================
// 明細画面表示・入力処理
// =======================================================================
BegSr SrDetScreen;
  DoU *In03 Or *In04;
    ExFmt ORDDET;
    Select;
      When *In03;
        // F3=取消
        MSGLST = '受注登録を取り消しました';
        Leave;
      When *In04;
        // F4=確定
        ExSr SrValidate;
        If Not WrkErr;
          AMT = QTY * UNTPRC;
          UPDDT  = WrkToday;
          UPDTM  = WrkTime;
          UPDUID = 'WEBUSER';
          If WrkMode = 'A';
            // 新規書込
            WrkOrdNo = ORDNO;
            Chain WrkOrdNo ORDREC;
            If %Found(ORDPF);
              MSGDET = '受注番号 ' + %TrimR(ORDNO) + ' は既に存在します';
            Else;
              Write ORDREC;
              If Not %Error;
                MSGLST = '受注を登録しました: ' + %TrimR(ORDNO);
                ExSr SrAllocInv;
                Leave;
              EndIf;
            EndIf;
          Else;
            // 既存更新
            Update ORDREC;
            If Not %Error;
              MSGLST = '受注を更新しました: ' + %TrimR(ORDNO);
              Leave;
            EndIf;
          EndIf;
        EndIf;
      When *In09;
        // F9=削除（取消）
        If WrkMode = 'U';
          ExSr SrCancelOrder;
          Leave;
        EndIf;
    EndSl;
  EndDo;
EndSr;

// =======================================================================
// 受注取消（論理削除：ステータスを9に変更）
// =======================================================================
BegSr SrCancelOrder;
  ORDSTS = STS_CANCEL;
  UPDDT  = WrkToday;
  UPDTM  = WrkTime;
  Update ORDREC;
  If Not %Error;
    MSGLST = '受注を取り消しました: ' + %TrimR(ORDNO);
  Else;
    MSGLST = '受注取消に失敗しました';
  EndIf;
EndSr;

// =======================================================================
// 在庫引当処理（受注確定時に在庫ファイルを更新）
// =======================================================================
BegSr SrAllocInv;
  // 在庫ファイル（INVPF）への引当処理
  // ※実装はINVMGRサービスプログラム経由で行う
  // ここでは受注ステータスを引当済に更新
  Chain ORDNO ORDREC;
  If %Found(ORDPF);
    ORDSTS = STS_ALLOC;
    UPDDT  = WrkToday;
    Update ORDREC;
  EndIf;
EndSr;

// =======================================================================
// 入力チェック
// =======================================================================
BegSr SrValidate;
  WrkErr  = *Off;
  MSGDET  = *Blanks;

  If %TrimR(ORDNO) = *Blanks;
    MSGDET = '受注番号を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If %TrimR(CUSTCD) = *Blanks;
    MSGDET = '得意先コードを入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If %TrimR(ITMCD) = *Blanks;
    MSGDET = '商品コードを入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If QTY <= 0;
    MSGDET = '数量は1以上を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If UNTPRC <= 0;
    MSGDET = '単価は0より大きい値を入力してください';
    WrkErr = *On;
    Return;
  EndIf;

  If %TrimR(ORDDT) = *Blanks;
    ORDDT = WrkToday;
  EndIf;
EndSr;

// =======================================================================
// プロシージャ：受注番号採番（10桁連番）
// =======================================================================
DCL-PROC GenOrderNo;
  DCL-PI *N Char(10);
  DCL-PR *N;
  END-PR;

  DCL-S LclSeq  Packed(7 : 0);
  DCL-S LclNo   Char(10);

  // 最終受注番号を読込んで+1（実環境ではデータエリアを使用）
  LclSeq = 1;
  SetLL *HVal ORDPF;
  ReadP ORDREC;
  If %Found(ORDPF);
    LclSeq = %Dec(%SubSt(ORDNO : 4 : 7) : 7 : 0) + 1;
  EndIf;
  LclNo = 'ORD' + %EditC(LclSeq : 'Z');
  Return LclNo;
END-PROC;
