**FREE
// =======================================================================
// プログラム名：ERRSRV
// 機　　　能：エラーハンドリング共通サービスプログラム
// 提供機能：エラーメッセージ管理・ジョブログ出力・メッセージキュー送信
// 利用方法：BNDSRVPGM(ERRSRV) を指定してバインド
// =======================================================================
Ctl-Opt NoMain DftActGrp(*No) ActGrp('ERRSRV')
        Option(*SrcStmt) BndDir('QC2LE');

// エラーコード定数
DCL-C ERR_NOTFOUND 'E001';  // レコードが見つからない
DCL-C ERR_DUPKEY   'E002';  // 重複キー
DCL-C ERR_INVDATA  'E003';  // 入力値不正
DCL-C ERR_STKLACK  'E004';  // 在庫不足
DCL-C ERR_SYSTEM   'E999';  // システムエラー

// メッセージテキストデータ構造
DCL-DS ErrMsgDs;
  ErrCode  Char(4);
  ErrText  Char(75);
End-DS;

// =======================================================================
// プロシージャ：GetErrMsg — エラーコードからメッセージを取得
// =======================================================================
DCL-PROC GetErrMsg Export;
  DCL-PI *N Char(79);
    PiErrCode Char(4) Const;
    PiDetail  Char(40) Const Options(*NoPass);
  END-PI;

  DCL-S LclMsg    Char(79);
  DCL-S LclDetail Char(40);

  If %Parms >= 2;
    LclDetail = PiDetail;
  Else;
    LclDetail = *Blanks;
  EndIf;

  Select;
    When PiErrCode = ERR_NOTFOUND;
      LclMsg = 'レコードが見つかりません';
    When PiErrCode = ERR_DUPKEY;
      LclMsg = '既に同じキーのレコードが存在します';
    When PiErrCode = ERR_INVDATA;
      LclMsg = '入力値が正しくありません';
    When PiErrCode = ERR_STKLACK;
      LclMsg = '在庫が不足しています';
    When PiErrCode = ERR_SYSTEM;
      LclMsg = 'システムエラーが発生しました';
    Other;
      LclMsg = '不明なエラーが発生しました';
  EndSl;

  If %TrimR(LclDetail) <> *Blanks;
    LclMsg = %TrimR(LclMsg) + ': ' + %TrimR(LclDetail);
  EndIf;

  Return LclMsg;
END-PROC;

// =======================================================================
// プロシージャ：WriteJobLog — ジョブログにメッセージを出力
// =======================================================================
DCL-PROC WriteJobLog Export;
  DCL-PI *N;
    PiPgmName Char(10) Const;
    PiMsgType Char(4)  Const;
    PiMsg     Char(79) Const;
  END-PI;

  DCL-S LclLogMsg Char(132);

  // ジョブログ用メッセージの組み立て
  LclLogMsg = '[' + PiMsgType + '] ' +
              %TrimR(PiPgmName) + ': ' +
              %TrimR(PiMsg);

  // DSPMSGコマンド相当の処理（QSYS2ログ出力）
  // 実環境ではSNDPGMMSGを使用
  // SNDPGMMSG MSG(LclLogMsg) MSGTYPE(*INFO)
END-PROC;

// =======================================================================
// プロシージャ：HandleFileErr — ファイル操作エラー処理
// =======================================================================
DCL-PROC HandleFileErr Export;
  DCL-PI *N Char(79);
    PiOperation Char(10) Const;
    PiFileName  Char(10) Const;
    PiKey       Char(20) Const Options(*NoPass);
  END-PI;

  DCL-S LclMsg Char(79);
  DCL-S LclKey Char(20);

  If %Parms >= 3;
    LclKey = PiKey;
  Else;
    LclKey = *Blanks;
  EndIf;

  LclMsg = %TrimR(PiOperation) + 'エラー [' +
           %TrimR(PiFileName) + ']';

  If %TrimR(LclKey) <> *Blanks;
    LclMsg = %TrimR(LclMsg) + ' キー=' + %TrimR(LclKey);
  EndIf;

  ExSr SrInternalLog;

  Return LclMsg;

  BegSr SrInternalLog;
    // ジョブログへの出力処理
    // 実環境ではSNDPGMMSGコマンドをQCMDEXCで実行
  EndSr;
END-PROC;

// =======================================================================
// プロシージャ：ValidateRequired — 必須項目チェック
// =======================================================================
DCL-PROC ValidateRequired Export;
  DCL-PI *N Ind;
    PiValue   Char(200) Const;
    PiFldName Char(20)  Const;
    PiMsg     Char(79);
  END-PI;

  If %TrimR(PiValue) = *Blanks;
    PiMsg = %TrimR(PiFldName) + 'を入力してください';
    Return *Off;
  EndIf;

  Return *On;
END-PROC;

// =======================================================================
// プロシージャ：ValidatePositive — 正数チェック
// =======================================================================
DCL-PROC ValidatePositive Export;
  DCL-PI *N Ind;
    PiValue   Packed(15 : 2) Const;
    PiFldName Char(20) Const;
    PiMsg     Char(79);
  END-PI;

  If PiValue <= 0;
    PiMsg = %TrimR(PiFldName) + 'は0より大きい値を入力してください';
    Return *Off;
  EndIf;

  Return *On;
END-PROC;

// =======================================================================
// プロシージャ：ValidateRange — 範囲チェック
// =======================================================================
DCL-PROC ValidateRange Export;
  DCL-PI *N Ind;
    PiValue   Packed(15 : 2) Const;
    PiMin     Packed(15 : 2) Const;
    PiMax     Packed(15 : 2) Const;
    PiFldName Char(20) Const;
    PiMsg     Char(79);
  END-PI;

  If PiValue < PiMin Or PiValue > PiMax;
    PiMsg = %TrimR(PiFldName) + 'の入力範囲が正しくありません' +
            '（' + %EditC(PiMin : '1') + '〜' +
            %EditC(PiMax : '1') + '）';
    Return *Off;
  EndIf;

  Return *On;
END-PROC;
