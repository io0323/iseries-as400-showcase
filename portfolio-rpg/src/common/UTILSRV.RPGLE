**FREE
// =======================================================================
// プログラム名：UTILSRV
// 機　　　能：共通ユーティリティサービスプログラム
// 提供機能：日付変換・数値フォーマット・コード検証・連番採番
// 利用方法：BNDSRVPGM(UTILSRV) を指定してバインド
// =======================================================================
Ctl-Opt NoMain DftActGrp(*No) ActGrp('UTILSRV')
        Option(*SrcStmt) BndDir('QC2LE');

// =======================================================================
// プロシージャ：ToYMD — 日付をYYYYMMDD形式文字列に変換
// =======================================================================
DCL-PROC ToYMD Export;
  DCL-PI *N Char(8);
    PiDate Date Const;
  END-PI;

  Return %Char(PiDate : *ISO0);
END-PROC;

// =======================================================================
// プロシージャ：FromYMD — YYYYMMDD文字列をDate型に変換
// =======================================================================
DCL-PROC FromYMD Export;
  DCL-PI *N Date;
    PiStr Char(8) Const;
  END-PI;

  Return %Date(PiStr : *ISO0);
END-PROC;

// =======================================================================
// プロシージャ：AddDays — 日付に日数を加算
// =======================================================================
DCL-PROC AddDays Export;
  DCL-PI *N Char(8);
    PiDate  Char(8) Const;
    PiDays  Int(10) Const;
  END-PI;

  DCL-S LclDate Date;

  LclDate = %Date(PiDate : *ISO0);
  LclDate += %Days(PiDays);
  Return %Char(LclDate : *ISO0);
END-PROC;

// =======================================================================
// プロシージャ：Today — 本日日付をYYYYMMDD文字列で返す
// =======================================================================
DCL-PROC Today Export;
  DCL-PI *N Char(8);
  END-PI;

  Return %Char(%Date() : *ISO0);
END-PROC;

// =======================================================================
// プロシージャ：NowTime — 現在時刻をHHMMSS文字列で返す
// =======================================================================
DCL-PROC NowTime Export;
  DCL-PI *N Char(6);
  END-PI;

  Return %Char(%Time() : *HMS0);
END-PROC;

// =======================================================================
// プロシージャ：FmtNum — 数値を3桁カンマ区切り文字列に変換
// =======================================================================
DCL-PROC FmtNum Export;
  DCL-PI *N Char(20);
    PiNum Packed(15 : 2) Const;
  END-PI;

  Return %EditC(PiNum : '1');
END-PROC;

// =======================================================================
// プロシージャ：GenSeqNo — 連番採番（プレフィックス + 7桁連番）
// =======================================================================
DCL-PROC GenSeqNo Export;
  DCL-PI *N Char(10);
    PiPrefix Char(3) Const;
    PiCurMax Char(10) Const;
  END-PI;

  DCL-S LclSeq  Packed(7 : 0);
  DCL-S LclNo   Char(10);

  If %TrimR(PiCurMax) = *Blanks;
    LclSeq = 1;
  Else;
    LclSeq = %Dec(%SubSt(PiCurMax : 4 : 7) : 7 : 0) + 1;
  EndIf;

  LclNo = PiPrefix + %EditC(LclSeq : 'Z');
  Return %TrimR(LclNo);
END-PROC;

// =======================================================================
// プロシージャ：CalcTax — 消費税額計算（切り捨て）
// =======================================================================
DCL-PROC CalcTax Export;
  DCL-PI *N Packed(11 : 2);
    PiAmt  Packed(11 : 2) Const;
    PiRate Packed(3 : 2) Const;
  END-PI;

  Return %Int(PiAmt * PiRate);
END-PROC;

// =======================================================================
// プロシージャ：CalcNetAmt — 税込金額計算（数量×単価＋消費税）
// =======================================================================
DCL-PROC CalcNetAmt Export;
  DCL-PI *N Packed(13 : 2);
    PiQty  Packed(9 : 0) Const;
    PiPrc  Packed(9 : 2) Const;
    PiRate Packed(3 : 2) Const;
  END-PI;

  DCL-S LclAmt Packed(11 : 2);
  DCL-S LclTax Packed(9 : 2);

  LclAmt = PiQty * PiPrc;
  LclTax = %Int(LclAmt * PiRate);
  Return LclAmt + LclTax;
END-PROC;

// =======================================================================
// プロシージャ：PadLeft — 文字列を左ゼロ埋め（数値コード用）
// =======================================================================
DCL-PROC PadLeft Export;
  DCL-PI *N Char(20);
    PiStr  Char(20) Const;
    PiLen  Int(10) Const;
    PiPad  Char(1) Const;
  END-PI;

  DCL-S LclResult Char(20);
  DCL-S LclLen    Int(10);

  LclLen    = %Len(%TrimR(PiStr));
  If LclLen >= PiLen;
    Return %SubSt(%TrimR(PiStr) : 1 : PiLen);
  EndIf;
  LclResult = %Rep(PiPad : 1 : PiLen - LclLen) + %TrimR(PiStr);
  Return LclResult;
END-PROC;

// =======================================================================
// プロシージャ：IsValidDate — 日付文字列の妥当性チェック
// =======================================================================
DCL-PROC IsValidDate Export;
  DCL-PI *N Ind;
    PiDateStr Char(8) Const;
  END-PI;

  DCL-S LclDate Date;
  DCL-S LclOk   Ind;

  Monitor;
    LclDate = %Date(PiDateStr : *ISO0);
    LclOk   = *On;
  On-Error;
    LclOk = *Off;
  EndMon;

  Return LclOk;
END-PROC;

// =======================================================================
// プロシージャ：IsBlank — 文字列が空白かチェック
// =======================================================================
DCL-PROC IsBlank Export;
  DCL-PI *N Ind;
    PiStr Char(200) Const;
  END-PI;

  Return %TrimR(PiStr) = *Blanks;
END-PROC;
