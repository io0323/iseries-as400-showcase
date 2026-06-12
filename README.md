# iSeries AS/400 Showcase

> IBM i / AS/400（RPG IV）による社内基幹システム開発ポートフォリオ  
> インテリア専門商社の受発注・物流在庫管理・会計システムを題材に、実務レベルのRPGプログラミングを実証します。

---

## 概要

本リポジトリは、**IBM i（AS/400）環境・RPG IV言語**による業務システム開発能力を示すポートフォリオです。  
インテリア専門商社の自社基幹システムを想定し、以下3モジュールを実装しています。

| モジュール | 対象業務 | プログラム |
|-----------|---------|-----------|
| 受発注管理 | 受注登録・発注・在庫引当 | `ORDMGR.RPGLE` |
| 物流在庫管理 | 入出庫・在庫照会・ロケーション管理 | `INVMGR.RPGLE` |
| 会計 | 売掛・買掛・入金消込 | `ACCMGR.RPGLE` |

AS/400実機がなくてもデモ確認できるよう、**Node.jsベースのシミュレータ**（5250端末風UI）を同梱しています。

---

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| 言語 | RPG IV（Free-format `/FREE`）|
| 環境 | IBM i / AS/400（OS/400・IBM i 7.x想定）|
| ファイル定義 | DDS（物理ファイル・論理ファイル）|
| 画面定義 | DDS（ディスプレイファイル / 5250端末）|
| バインディング | サービスプログラム（SRVPGM）|
| シミュレータ | Node.js / Express |
| デモUI | HTML + CSS（5250端末風グリーンスクリーン）|

---

## ディレクトリ構成

```
iseries-as400-showcase/
├── src/
│   ├── order/               # 受発注管理モジュール
│   │   ├── ORDPF.DDS        # 受注物理ファイル定義
│   │   ├── ORDLF.DDS        # 受注論理ファイル定義（キー順アクセス）
│   │   ├── ORDDSPF.DDS      # 受注画面ファイル定義（5250）
│   │   └── ORDMGR.RPGLE     # 受注管理プログラム（Free-format RPG）
│   ├── inventory/           # 物流在庫管理モジュール
│   │   ├── ITMPF.DDS        # 商品マスタ物理ファイル定義
│   │   ├── INVPF.DDS        # 在庫物理ファイル定義
│   │   ├── INVLF.DDS        # 在庫論理ファイル定義
│   │   ├── INVDSPF.DDS      # 在庫画面ファイル定義（5250）
│   │   └── INVMGR.RPGLE     # 在庫管理プログラム（Free-format RPG）
│   ├── accounting/          # 会計モジュール
│   │   ├── ARPF.DDS         # 売掛物理ファイル定義
│   │   ├── APPF.DDS         # 買掛物理ファイル定義
│   │   ├── ACCDSPF.DDS      # 会計画面ファイル定義（5250）
│   │   └── ACCMGR.RPGLE     # 会計管理プログラム（Free-format RPG）
│   └── common/              # 共通サービスプログラム
│       ├── UTILSRV.RPGLE    # 共通ユーティリティ（日付変換・文字列処理）
│       └── ERRSRV.RPGLE     # エラーハンドリング共通処理
├── simulator/               # ローカル動作確認用シミュレータ
│   ├── server.js            # Expressサーバー
│   ├── rpg-interpreter.js   # RPGビジネスロジック移植（JavaScript）
│   └── public/
│       └── index.html       # 5250端末風デモUI
├── docs/
│   ├── system-design.md     # システム設計書
│   └── program-spec.md      # プログラム仕様書
└── README.md
```

---

## 実装詳細

### RPGプログラム設計方針

```rpgle
**FREE
// -------------------------------------------------------
// ORDMGR - 受注管理プログラム
// 機能: 受注登録・照会・更新・削除（CRUD）
// -------------------------------------------------------

DCL-F ORDPF  USAGE(*UPDATE) KEYED;
DCL-F ORDDSPF WORKSTN;

DCL-DS OrderDS LIKEREC(ORDREC);
DCL-S errMsg  CHAR(80);

// メイン処理
DOW NOT *IN03;
  EXFMT MAINSCR;
  SELECT;
    WHEN *IN04; LEAVE;                 // F4: 終了
    WHEN *IN06; EXSR srRegist;        // F6: 新規登録
    WHEN *IN09; EXSR srDelete;        // F9: 削除
  ENDSL;
ENDDO;

*INLR = *ON;
```

- **Free-format RPG**（`**FREE` 〜 `ENDSR`）で全プログラムを記述
- `DCL-F`（ファイル定義）、`DCL-DS`（データ構造）、`DCL-S`（スカラー変数）を明示的に宣言
- サブルーチン（`BEGSR`）ではなく**プロシージャ**（`DCL-PROC`）を積極採用
- エラーハンドリングは `%ERROR`・`%STATUS` ビルトイン関数で統一処理

### DDSファイル設計

```dds
     A* -------------------------------------------------------
     A* ORDPF - 受注物理ファイル
     A* -------------------------------------------------------
     A          R ORDREC
     A            ORDNO       8  0         TEXT('受注番号')
     A            ORDDTE      8  0         TEXT('受注日')
     A            CUSCD      10            TEXT('得意先コード')
     A            ITMCD      10            TEXT('商品コード')
     A            QTY         5  0         TEXT('受注数量')
     A            UNIPRC      9  2         TEXT('単価')
     A            AMNT       11  2         TEXT('金額')
     A            STCD        1            TEXT('ステータス')
     A          K ORDNO
```

- 物理ファイル（PF）・論理ファイル（LF）の両方をDDSで定義
- キー構成・結合論理ファイル（JOIN LF）を適切に設計
- 5250ディスプレイファイルはサブファイル（SFL/SFLCTL）構成で一覧表示を実装

### 会計モジュール：入金消込処理フロー

```
売掛照会 → 入金データ入力 → 消込対象選択 → 消込確定 → 仕訳計上
    ↓                                              ↓
ARPF照会                                    ARPF更新（消込フラグ）
                                            +
                                       仕訳ファイル書込（JRNPF）
```

---

## シミュレータ起動手順

AS/400実機不要で、ブラウザ上で全機能をデモ確認できます。

### 前提条件

- Node.js 18以上

### 起動

```bash
git clone https://github.com/io0323/iseries-as400-showcase.git
cd iseries-as400-showcase/simulator
npm install
node server.js
```

ブラウザで `http://localhost:3000` を開くと、5250端末風UIでデモが起動します。

### デモで確認できる操作

| 操作 | 内容 |
|------|------|
| 受注登録 | ソファ・テーブル等の商品を選択し受注データを登録 |
| 在庫照会 | 商品コード・ロケーション別の在庫数量を照会 |
| 入出庫処理 | 入庫・出庫を登録し在庫数を即時更新 |
| 売掛照会 | 得意先別の売掛残高・請求一覧を表示 |
| 入金消込 | 入金データを入力し売掛を消込処理 |

---

## AS/400実環境へのデプロイ

### コンパイル手順（概要）

```cl
/* 1. ライブラリ作成 */
CRTLIB LIB(INTERIORDB)

/* 2. 物理ファイルのコンパイル */
CRTPF FILE(INTERIORDB/ORDPF) SRCFILE(SRCLIB/QDDSSRC)

/* 3. 論理ファイルのコンパイル */
CRTLF FILE(INTERIORDB/ORDLF) SRCFILE(SRCLIB/QDDSSRC)

/* 4. ディスプレイファイルのコンパイル */
CRTDSPF FILE(INTERIORDB/ORDDSPF) SRCFILE(SRCLIB/QDDSSRC)

/* 5. RPGプログラムのコンパイル */
CRTRPGMOD MODULE(INTERIORLIB/ORDMGR) SRCFILE(SRCLIB/QRPGLESRC)
CRTPGM PGM(INTERIORLIB/ORDMGR)
```

### 推奨IBM i バージョン

- IBM i 7.3以上
- RPG IV Free-format 完全サポート環境

---

## アピールポイント

### 1. Free-format RPGの実践

固定形式（カラム依存）ではなくFree-format RPGで記述し、保守性・可読性を向上させた実装を提示しています。モダンなRPG開発のベストプラクティスに準拠しています。

### 2. 上流設計からの一貫開発

DDSによるファイル設計 → 画面設計 → プログラム実装まで、基幹システム開発の全工程を一人で完結できることを示しています。

### 3. サービスプログラム（SRVPGM）構成

共通処理を`UTILSRV`・`ERRSRV`としてサービスプログラム化し、再利用性・保守性を重視した設計を採用しています。

### 4. 業務ドメインへの理解

受発注・物流在庫・会計の3ドメインを連携させた業務フロー（受注 → 在庫引当 → 出荷 → 売掛計上 → 入金消込）を設計・実装しています。

---

## 開発者

**Io** — Android / Kotlin Engineer  
IBM i（AS/400）・RPG IVによる業務システム開発への参入を目指し本ポートフォリオを作成。

[![GitHub](https://img.shields.io/badge/GitHub-io0323-181717?logo=github)](https://github.com/io0323)

---

## ライセンス

MIT License
