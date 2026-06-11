# プログラム仕様書 — RPG IV ソースコード解説

## ORDMGR.RPGLE — 受注管理プログラム

### 概要
受注の登録・照会・更新・取消（CRUD）および在庫引当を行うメインプログラム。

### 制御オプション
```rpgle
Ctl-Opt DftActGrp(*No) ActGrp('ORDMGR') BndDir('QC2LE')
        Option(*SrcStmt : *NoDebugIO) DatFmt(*ISO) TimFmt(*ISO);
```
- `DftActGrp(*No)` — デフォルト活動化グループを使用しない（モジュール化対応）
- `ActGrp('ORDMGR')` — 名前付き活動化グループで状態管理
- `BndDir('QC2LE')` — C言語ランタイムバインドディレクトリ

### サブルーティン一覧

| サブルーティン | 機能 |
|---|---|
| SrInit | 初期化（日付・時刻取得、画面クリア） |
| SrMain | メインループ（F3終了まで画面表示・キー判定） |
| SrLoadList | サブファイルへの受注一覧ロード |
| SrSearchOrder | 受注番号または得意先CDで検索 |
| SrAddOrder | 新規受注登録（画面クリア・初期値セット） |
| SrDetScreen | 明細画面表示・F4確定/F3取消/F9削除処理 |
| SrCancelOrder | 受注取消（ステータスを'9'に更新） |
| SrAllocInv | 在庫引当（INVMGR経由でINVPF更新） |
| SrValidate | 入力チェック（必須・正数・日付） |

### プロシージャ一覧

| プロシージャ | 戻り値 | 説明 |
|---|---|---|
| GenOrderNo | Char(10) | 最終受注番号+1で採番（例: ORD0000011） |

### キーオペレーション
| キー | インジケーター | 処理 |
|---|---|---|
| F3 | *In03 | プログラム終了 |
| F4 | *In04 | 入力内容確定・DB書込 |
| F5 | *In05 | 画面再表示 |
| F6 | *In06 | 新規受注登録モードへ |
| F9 | *In09 | 受注取消処理 |

---

## INVMGR.RPGLE — 在庫管理プログラム

### サブルーティン一覧

| サブルーティン | 機能 |
|---|---|
| SrInit | 初期化 |
| SrMain | メインループ |
| SrInqInv | 在庫照会（商品CD/ロケーション/全件） |
| SrAddItem | 商品マスタ登録・更新 |
| SrInitInvRec | 商品新規登録時の在庫レコード初期化 |
| SrDiscItem | 廃番処理（在庫残あり時はエラー） |
| SrReceive | 入庫処理（STKQTY加算・AVLQTY再計算） |
| SrShip | 出庫処理（STKQTY減算・有効在庫チェック） |
| SrValidItem | 商品マスタ入力チェック |

### プロシージャ一覧（SRVPGM公開）

| プロシージャ | 説明 |
|---|---|
| AllocateStock(ITMCD, LOCCD, QTY) | 在庫引当：ALCQTY+=QTY、AVLQTY再計算。戻り値: Ind（成功/失敗） |
| AdjustStock(ITMCD, LOCCD, QTY, REASON) | 棚卸調整：STKQTY=新数量。戻り値: Ind |

### 在庫計算ロジック
```
入庫：STKQTY += 入庫数
      RCVQTY += 入庫数
      AVLQTY = STKQTY - ALCQTY

出庫：STKQTY -= 出庫数  ← 有効在庫(AVLQTY)チェック後
      SHPQTY += 出庫数
      AVLQTY = STKQTY - ALCQTY

引当：ALCQTY += 引当数  ← 有効在庫チェック後
      AVLQTY = STKQTY - ALCQTY
```

---

## ACCMGR.RPGLE — 会計管理プログラム

### 消費税計算
```rpgle
DCL-C TAXRATE 0.10;
LclTax = %Int(LclAmt * TAXRATE);  // 切り捨て
```

### 売掛ステータス遷移
```
AR_OPEN('1') → 部分入金 → AR_PART('2') → 完済 → AR_DONE('3')
             → 取消 → AR_CNCL('9')
```

### プロシージャ一覧（SRVPGM公開）

| プロシージャ | 説明 |
|---|---|
| CreateArRecord(...) | 売掛金レコード生成（出荷確定時にORDMGRから呼出し）。支払期日=請求日+30日 |

---

## UTILSRV.RPGLE — 共通ユーティリティ SRVPGM

### プロシージャ一覧

| プロシージャ | PI/PO | 説明 |
|---|---|---|
| ToYMD(Date) | →Char(8) | Date型→YYYYMMDD変換 |
| FromYMD(Char(8)) | →Date | YYYYMMDD→Date型変換 |
| AddDays(Char(8), Int(10)) | →Char(8) | 日付に日数加算 |
| Today() | →Char(8) | 本日日付取得 |
| NowTime() | →Char(6) | 現在時刻取得 |
| FmtNum(Packed(15,2)) | →Char(20) | 数値→カンマ区切り文字列 |
| GenSeqNo(Char(3), Char(10)) | →Char(10) | 連番採番（プレフィックス+7桁） |
| CalcTax(amt, rate) | →Packed(11,2) | 消費税計算（切り捨て） |
| CalcNetAmt(qty, prc, rate) | →Packed(13,2) | 税込金額計算 |
| PadLeft(str, len, pad) | →Char(20) | 左埋め（ゼロパディング等） |
| IsValidDate(Char(8)) | →Ind | 日付妥当性チェック（Monitor構文） |
| IsBlank(Char(200)) | →Ind | 空白チェック |

---

## ERRSRV.RPGLE — エラーハンドリング SRVPGM

### エラーコード定義

| コード | 定数名 | 意味 |
|---|---|---|
| E001 | ERR_NOTFOUND | レコードが見つからない |
| E002 | ERR_DUPKEY | 重複キー |
| E003 | ERR_INVDATA | 入力値不正 |
| E004 | ERR_STKLACK | 在庫不足 |
| E999 | ERR_SYSTEM | システムエラー |

### プロシージャ一覧

| プロシージャ | 説明 |
|---|---|
| GetErrMsg(code, [detail]) | エラーコードからメッセージ文字列を取得 |
| WriteJobLog(pgm, type, msg) | ジョブログへのメッセージ書込み |
| HandleFileErr(op, file, [key]) | ファイルエラー処理（メッセージ生成+ログ） |
| ValidateRequired(value, fldname, msg) | 必須項目チェック |
| ValidatePositive(value, fldname, msg) | 正数チェック |
| ValidateRange(val, min, max, fld, msg) | 範囲チェック |

---

## RPG IV Free-format 記述例

### ファイル定義（DCL-F）
```rpgle
DCL-F ORDPF    Keyed Usage(*Update : *Delete : *Output : *Input);
DCL-F ORDDSPF  WorkStn SFile(ORDSFL : WrkRRN);
```

### データ構造（DCL-DS）
```rpgle
DCL-DS OrdDs;
  OrdNo   Char(10);
  OrdDt   Char(8);
  CustCd  Char(10);
End-DS;
```

### キーリスト操作（%KList相当）
```rpgle
// 複合キー検索
Chain %KList(PiItmCd : PiLocCd) INVREC;
```

### モニター（エラートラップ）
```rpgle
Monitor;
  LclDate = %Date(PiDateStr : *ISO0);
  LclOk   = *On;
On-Error;
  LclOk = *Off;
EndMon;
```

### プロシージャ定義
```rpgle
DCL-PROC AllocateStock;
  DCL-PI *N Ind;
    PiItmCd  Char(10) Const;
    PiLocCd  Char(10) Const;
    PiQty    Packed(9 : 0) Const;
  END-PI;
  // 処理本体
  Return Not %Error;
END-PROC;
```
