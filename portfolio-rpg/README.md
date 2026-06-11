# インテリア専門商社 AS/400 基幹システム ポートフォリオ

IBM i（AS/400）とRPG IV（Free-format）を用いた社内SEポートフォリオ。  
受発注・物流在庫・会計の3モジュールで構成された基幹システムのデモ実装。

---

## システム概要

| 項目 | 内容 |
|---|---|
| 想定企業 | インテリア専門商社 |
| 対象システム | 受発注・物流在庫・会計 基幹システム |
| 言語 | RPG IV（Free-format / **FREE） |
| プラットフォーム | IBM i 7.4 / AS/400 |
| ファイル形式 | DDS物理ファイル・論理ファイル・ディスプレイファイル |
| バインディング | サービスプログラム（SRVPGM） |
| デモ環境 | Node.js + Express（5250端末風WebUI） |

---

## 技術スタック

- **RPG IV Free-format**（**FREE〜）：メイン業務ロジック
- **DDS**（Data Description Specifications）：ファイル・画面定義
- **CL**（Control Language）：ジョブ制御・バッチ処理
- **SRVPGM**：共通処理のモジュール化・バインディング
- **Node.js / Express**：ローカル動作確認用シミュレータ

---

## モジュール構成

### 1. 受発注管理（ORDMGR）

| 機能 | 処理内容 |
|---|---|
| 受注登録 | 得意先・商品・数量・単価を入力し受注レコードを作成 |
| 受注照会 | 受注番号・得意先コードで検索、明細表示 |
| 受注更新 | ステータス変更（受注→引当→出荷→完了）・数量修正 |
| 受注削除 | キャンセル処理（論理削除） |
| 発注登録 | 在庫不足時に発注レコードを自動生成 |
| 在庫引当 | 受注確定時に在庫ファイルを更新 |
| 受注残照会 | 未出荷受注の一覧表示 |

### 2. 物流在庫管理（INVMGR）

| 機能 | 処理内容 |
|---|---|
| 商品マスタ管理 | 商品コード・名称・単価・安全在庫数のCRUD |
| 入庫処理 | 入庫数量を在庫ファイルに加算 |
| 出庫処理 | 出庫数量を在庫ファイルから減算・引当との照合 |
| 在庫照会 | 商品・ロケーション別在庫量の表示 |
| 在庫調整 | 棚卸差異の修正処理 |
| ロケーション管理 | 倉庫内ロケーション（棚番号）の割当・変更 |

### 3. 会計管理（ACCMGR）

| 機能 | 処理内容 |
|---|---|
| 売掛金管理 | 出荷確定時に売掛金レコード生成（請求書発行） |
| 入金消込 | 入金データと売掛金の照合・消込処理 |
| 買掛金管理 | 仕入確定時に買掛金レコード生成 |
| 支払処理 | 支払確定・買掛金の消込 |
| 残高照会 | 得意先別売掛残高・仕入先別買掛残高の表示 |

---

## シミュレータ起動方法

```bash
cd simulator
npm install
node server.js
```

ブラウザで `http://localhost:3000` を開く。

### 動作確認項目
- [x] 受注一覧・受注登録・受注更新・受注削除
- [x] 商品マスタ照会・在庫照会・入出庫処理
- [x] 売掛金照会・入金消込・買掛金照会

---

## IBM i 実環境へのデプロイ手順（概要）

```
1. ソースファイル転送
   FTPまたはIBM i Access for Windowsでソースをアップロード

2. ファイル作成
   CRTPF   FILE(MYLIB/ORDPF)   SRCFILE(MYLIB/QDDSSRC)  SRCMBR(ORDPF)
   CRTLF   FILE(MYLIB/ORDLF)   SRCFILE(MYLIB/QDDSSRC)  SRCMBR(ORDLF)
   CRTDSPF FILE(MYLIB/ORDDSPF) SRCFILE(MYLIB/QDDSSRC)  SRCMBR(ORDDSPF)

3. 共通サービスプログラム作成
   CRTRPGMOD MODULE(MYLIB/UTILSRV) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(UTILSRV)
   CRTRPGMOD MODULE(MYLIB/ERRSRV)  SRCFILE(MYLIB/QRPGLESRC) SRCMBR(ERRSRV)
   CRTSRVPGM SRVPGM(MYLIB/UTILSRV) MODULE(MYLIB/UTILSRV) EXPORT(*ALL)
   CRTSRVPGM SRVPGM(MYLIB/ERRSRV)  MODULE(MYLIB/ERRSRV)  EXPORT(*ALL)

4. 業務プログラム作成
   CRTRPGMOD MODULE(MYLIB/ORDMGR) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(ORDMGR)
   CRTPGM PGM(MYLIB/ORDMGR) MODULE(MYLIB/ORDMGR) +
          BNDSRVPGM(MYLIB/UTILSRV MYLIB/ERRSRV)
```

---

## RPGプログラム設計思想

### Free-format採用理由
- 列制限なしで可読性の高いコードを記述可能
- 現代的な構造化プログラミングに対応
- 保守性・拡張性を重視した設計

### モジュール分離方針
- 業務ロジック（ORDMGR/INVMGR/ACCMGR）と共通処理（UTILSRV/ERRSRV）を分離
- SRVPGM によるバインディングで再利用性を確保
- プロシージャ（DCL-PROC）単位で機能を分割し単体テスト可能な構造

### エラーハンドリング
- `%Error` / `%Found` / `%Eof` によるファイル操作後の状態確認
- エラーメッセージはERRSRVサービスプログラムで一元管理
- *INLR オン前に必ずファイルクローズ処理を実施

---

## 採用担当者へのアピールポイント

1. **RPG IV Free-format の実践的記述能力**：DCL-F / DCL-DS / DCL-PROC を用いた現代的なRPG開発
2. **DDS精通**：物理ファイル・論理ファイル・ディスプレイファイルの設計・実装経験
3. **システム全体像の把握**：受発注→在庫→会計の業務フローに沿った設計
4. **SRVPGM活用**：共通処理のモジュール化でコードの再利用性・保守性を向上
5. **ローカル動作デモ**：実機なしでも5250端末UIで業務ロジックを体感可能
