# CLAUDE.md — インテリア専門商社 AS/400 基幹システム ポートフォリオ

## プロジェクト概要

IBM i（AS/400）上で稼働するインテリア専門商社向け基幹システムのポートフォリオ。
受発注・物流在庫・会計の3モジュールをRPG IV（Free-format）で実装し、Node.jsシミュレータで動作デモを提供する。

## ディレクトリ構成

```
portfolio-rpg/
├── src/
│   ├── order/          受発注モジュール
│   ├── inventory/      在庫管理モジュール
│   ├── accounting/     会計モジュール
│   └── common/         共通サービスプログラム
├── simulator/          Node.jsシミュレータ
│   └── public/         Web UI
├── docs/               設計書・仕様書
├── README.md
└── CLAUDE.md
```

## 各ファイルの役割

### src/order/
| ファイル | 種別 | 説明 |
|---|---|---|
| ORDPF.DDS | 物理ファイル | 受注データ格納（主キー：受注番号） |
| ORDLF.DDS | 論理ファイル | 得意先コード・日付順アクセスパス |
| ORDDSPF.DDS | ディスプレイファイル | 受注メニュー・明細画面定義 |
| ORDMGR.RPGLE | RPGプログラム | 受注CRUD・在庫引当・受注残照会 |

### src/inventory/
| ファイル | 種別 | 説明 |
|---|---|---|
| ITMPF.DDS | 物理ファイル | 商品マスタ（主キー：商品コード） |
| INVPF.DDS | 物理ファイル | 在庫データ（主キー：商品コード+ロケーション） |
| INVLF.DDS | 論理ファイル | ロケーション順アクセスパス |
| INVDSPF.DDS | ディスプレイファイル | 在庫照会・入出庫画面定義 |
| INVMGR.RPGLE | RPGプログラム | 商品マスタ管理・入出庫処理・在庫調整 |

### src/accounting/
| ファイル | 種別 | 説明 |
|---|---|---|
| ARPF.DDS | 物理ファイル | 売掛金データ（主キー：請求番号） |
| APPF.DDS | 物理ファイル | 買掛金データ（主キー：仕入番号） |
| ACCDSPF.DDS | ディスプレイファイル | 売掛・買掛照会・入金消込画面 |
| ACCMGR.RPGLE | RPGプログラム | 売掛金管理・買掛金管理・残高照会 |

### src/common/
| ファイル | 種別 | 説明 |
|---|---|---|
| UTILSRV.RPGLE | サービスプログラム | 日付変換・数値フォーマット・コード検証共通処理 |
| ERRSRV.RPGLE | サービスプログラム | エラーメッセージ管理・ログ出力共通処理 |

### simulator/
| ファイル | 説明 |
|---|---|
| server.js | Express Webサーバー（REST API + 静的ファイル配信） |
| rpg-interpreter.js | RPGビジネスロジックのJS移植版 |
| public/index.html | 5250端末風ポートフォリオUI |

## 開発・テスト手順

### シミュレータ起動
```bash
cd simulator
npm install
node server.js
# ブラウザで http://localhost:3000 を開く
```

### IBM i 実環境ビルド順序
```
1. 物理ファイル作成    CRTPF
2. 論理ファイル作成    CRTLF
3. ディスプレイファイル CRTDSPF
4. 共通SRVPGM作成     CRTSRVPGM (UTILSRV, ERRSRV)
5. RPGコンパイル       CRTRPGMOD → CRTPGM
```

### コンパイルコマンド例
```
CRTRPGMOD MODULE(MYLIB/ORDMGR) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(ORDMGR)
CRTPGM PGM(MYLIB/ORDMGR) MODULE(MYLIB/ORDMGR) BNDSRVPGM(MYLIB/UTILSRV MYLIB/ERRSRV)
```

## コーディング規約

- **FREE（完全自由形式）を使用
- 変数名：キャメルケース（Wrkプレフィックスで作業変数を識別）
- プロシージャ名：動詞+目的語（例：GetOrderRec、ValidateInput）
- エラー処理：%Error/%Found/%Eof を使用し *IN99 は使用しない
- 日本語コメントを // で記述
