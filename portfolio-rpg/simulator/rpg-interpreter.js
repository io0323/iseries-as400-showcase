'use strict';

// =======================================================================
// RPGビジネスロジック移植版（Node.js）
// ORDMGR / INVMGR / ACCMGR のコアロジックをJSで再現
// =======================================================================

const TAX_RATE = 0.10;

// =======================================================================
// インメモリデータストア（インテリア商社サンプルデータ）
// =======================================================================

let orders = [
  { ORDNO:'ORD0000001', ORDDT:'20260501', CUSTCD:'C001', CUSTNM:'株式会社山田インテリア', ITMCD:'ITM001', ITMNM:'イタリア製レザーソファ3人掛け', QTY:2, UNTPRC:198000, AMT:396000, ORDSTS:'2', DLVDT:'20260515', SHIPDT:'', RMRK:'色：ブラック' },
  { ORDNO:'ORD0000002', ORDDT:'20260502', CUSTCD:'C002', CUSTNM:'鈴木家具販売株式会社', ITMCD:'ITM003', ITMNM:'北欧デザイン ダイニングテーブル', QTY:5, UNTPRC:85000, AMT:425000, ORDSTS:'1', DLVDT:'20260520', SHIPDT:'', RMRK:'' },
  { ORDNO:'ORD0000003', ORDDT:'20260503', CUSTCD:'C003', CUSTNM:'東京インテリアショップ', ITMCD:'ITM005', ITMNM:'アンティーク調デスク', QTY:3, UNTPRC:120000, AMT:360000, ORDSTS:'3', DLVDT:'20260510', SHIPDT:'20260509', RMRK:'急ぎ出荷対応' },
  { ORDNO:'ORD0000004', ORDDT:'20260504', CUSTCD:'C001', CUSTNM:'株式会社山田インテリア', ITMCD:'ITM007', ITMNM:'シャンデリア（クリスタル）', QTY:4, UNTPRC:65000, AMT:260000, ORDSTS:'2', DLVDT:'20260525', SHIPDT:'', RMRK:'' },
  { ORDNO:'ORD0000005', ORDDT:'20260505', CUSTCD:'C004', CUSTNM:'大阪リビング株式会社', ITMCD:'ITM002', ITMNM:'ウォールナット無垢材ベッドフレーム', QTY:10, UNTPRC:155000, AMT:1550000, ORDSTS:'1', DLVDT:'20260601', SHIPDT:'', RMRK:'Queen/King各5台' },
  { ORDNO:'ORD0000006', ORDDT:'20260506', CUSTCD:'C005', CUSTNM:'名古屋家具センター株式会社', ITMCD:'ITM009', ITMNM:'スチール製本棚（幅90cm）', QTY:20, UNTPRC:28000, AMT:560000, ORDSTS:'1', DLVDT:'20260530', SHIPDT:'', RMRK:'' },
  { ORDNO:'ORD0000007', ORDDT:'20260507', CUSTCD:'C002', CUSTNM:'鈴木家具販売株式会社', ITMCD:'ITM004', ITMNM:'ファブリックアームチェア', QTY:8, UNTPRC:45000, AMT:360000, ORDSTS:'9', DLVDT:'20260520', SHIPDT:'', RMRK:'顧客都合キャンセル' },
  { ORDNO:'ORD0000008', ORDDT:'20260508', CUSTCD:'C006', CUSTNM:'福岡インテリアプロ株式会社', ITMCD:'ITM010', ITMNM:'ガラストップダイニングテーブル', QTY:3, UNTPRC:98000, AMT:294000, ORDSTS:'2', DLVDT:'20260525', SHIPDT:'', RMRK:'' },
  { ORDNO:'ORD0000009', ORDDT:'20260509', CUSTCD:'C007', CUSTNM:'横浜リビングスタイル', ITMCD:'ITM006', ITMNM:'フロアランプ（真鍮仕上げ）', QTY:15, UNTPRC:32000, AMT:480000, ORDSTS:'1', DLVDT:'20260605', SHIPDT:'', RMRK:'' },
  { ORDNO:'ORD0000010', ORDDT:'20260510', CUSTCD:'C003', CUSTNM:'東京インテリアショップ', ITMCD:'ITM008', ITMNM:'マホガニー製チェスト（5段）', QTY:6, UNTPRC:72000, AMT:432000, ORDSTS:'3', DLVDT:'20260515', SHIPDT:'20260514', RMRK:'展示用' },
];

let items = [
  { ITMCD:'ITM001', ITMNM:'イタリア製レザーソファ3人掛け', ITMKN:'イタリアセイレザーソファサンニンガケ', CATCD:'S001', CATNM:'ソファ・チェア', UNTPRC:198000, CPRC:110000, SAFSTK:5, ORDPT:3, ORDQTY:10, SUPCD:'SUP001', SUPNM:'イタリアインポート株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM002', ITMNM:'ウォールナット無垢材ベッドフレーム', ITMKN:'ウォールナットムクザイベッドフレーム', CATCD:'B001', CATNM:'ベッド・寝具', UNTPRC:155000, CPRC:85000, SAFSTK:10, ORDPT:5, ORDQTY:20, SUPCD:'SUP002', SUPNM:'北欧ウッドクラフト社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM003', ITMNM:'北欧デザイン ダイニングテーブル', ITMKN:'ホクオウデザイン ダイニングテーブル', CATCD:'T001', CATNM:'テーブル・デスク', UNTPRC:85000, CPRC:45000, SAFSTK:8, ORDPT:5, ORDQTY:15, SUPCD:'SUP003', SUPNM:'スカンジナビアン商事', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM004', ITMNM:'ファブリックアームチェア', ITMKN:'ファブリックアームチェア', CATCD:'S001', CATNM:'ソファ・チェア', UNTPRC:45000, CPRC:22000, SAFSTK:15, ORDPT:10, ORDQTY:30, SUPCD:'SUP004', SUPNM:'国内家具製造株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM005', ITMNM:'アンティーク調デスク', ITMKN:'アンティークチョウデスク', CATCD:'T001', CATNM:'テーブル・デスク', UNTPRC:120000, CPRC:68000, SAFSTK:3, ORDPT:2, ORDQTY:5, SUPCD:'SUP005', SUPNM:'ヨーロッパ家具輸入商会', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM006', ITMNM:'フロアランプ（真鍮仕上げ）', ITMKN:'フロアランプ（シンチュウシアゲ）', CATCD:'L001', CATNM:'照明・ランプ', UNTPRC:32000, CPRC:16000, SAFSTK:20, ORDPT:10, ORDQTY:50, SUPCD:'SUP006', SUPNM:'デザイン照明株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM007', ITMNM:'シャンデリア（クリスタル）', ITMKN:'シャンデリア（クリスタル）', CATCD:'L001', CATNM:'照明・ランプ', UNTPRC:65000, CPRC:35000, SAFSTK:5, ORDPT:3, ORDQTY:10, SUPCD:'SUP006', SUPNM:'デザイン照明株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM008', ITMNM:'マホガニー製チェスト（5段）', ITMKN:'マホガニーセイチェスト（ゴダン）', CATCD:'C001', CATNM:'収納家具', UNTPRC:72000, CPRC:40000, SAFSTK:8, ORDPT:5, ORDQTY:15, SUPCD:'SUP005', SUPNM:'ヨーロッパ家具輸入商会', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM009', ITMNM:'スチール製本棚（幅90cm）', ITMKN:'スチールセイホンダナ（ハバキュウジュッセンチ）', CATCD:'C001', CATNM:'収納家具', UNTPRC:28000, CPRC:14000, SAFSTK:30, ORDPT:20, ORDQTY:50, SUPCD:'SUP004', SUPNM:'国内家具製造株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM010', ITMNM:'ガラストップダイニングテーブル', ITMKN:'ガラストップダイニングテーブル', CATCD:'T001', CATNM:'テーブル・デスク', UNTPRC:98000, CPRC:55000, SAFSTK:6, ORDPT:4, ORDQTY:10, SUPCD:'SUP001', SUPNM:'イタリアインポート株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM011', ITMNM:'オットマン（牛革）', ITMKN:'オットマン（ギュウカワ）', CATCD:'S001', CATNM:'ソファ・チェア', UNTPRC:38000, CPRC:20000, SAFSTK:10, ORDPT:5, ORDQTY:20, SUPCD:'SUP001', SUPNM:'イタリアインポート株式会社', ITMSTS:'1', UPDDT:'20260401' },
  { ITMCD:'ITM012', ITMNM:'ペルシャ絨毯（2m×3m）', ITMKN:'ペルシャジュウタン', CATCD:'R001', CATNM:'ラグ・カーペット', UNTPRC:280000, CPRC:150000, SAFSTK:3, ORDPT:2, ORDQTY:5, SUPCD:'SUP007', SUPNM:'中東インポート商事', ITMSTS:'1', UPDDT:'20260401' },
];

let inventory = [
  { ITMCD:'ITM001', LOCCD:'WH-A-001', ITMNM:'イタリア製レザーソファ3人掛け', STKQTY:12, ALCQTY:4, AVLQTY:8, RCVQTY:20, SHPQTY:8, LSTRCVDT:'20260420', LSTSHPDT:'20260509', UPDDT:'20260601' },
  { ITMCD:'ITM002', LOCCD:'WH-A-002', ITMNM:'ウォールナット無垢材ベッドフレーム', STKQTY:25, ALCQTY:10, AVLQTY:15, RCVQTY:35, SHPQTY:10, LSTRCVDT:'20260415', LSTSHPDT:'20260514', UPDDT:'20260601' },
  { ITMCD:'ITM003', LOCCD:'WH-B-001', ITMNM:'北欧デザイン ダイニングテーブル', STKQTY:18, ALCQTY:5, AVLQTY:13, RCVQTY:30, SHPQTY:12, LSTRCVDT:'20260410', LSTSHPDT:'20260509', UPDDT:'20260601' },
  { ITMCD:'ITM004', LOCCD:'WH-B-002', ITMNM:'ファブリックアームチェア', STKQTY:45, ALCQTY:8, AVLQTY:37, RCVQTY:60, SHPQTY:15, LSTRCVDT:'20260405', LSTSHPDT:'20260509', UPDDT:'20260601' },
  { ITMCD:'ITM005', LOCCD:'WH-C-001', ITMNM:'アンティーク調デスク', STKQTY:6, ALCQTY:0, AVLQTY:6, RCVQTY:10, SHPQTY:4, LSTRCVDT:'20260420', LSTSHPDT:'20260514', UPDDT:'20260601' },
  { ITMCD:'ITM006', LOCCD:'WH-C-002', ITMNM:'フロアランプ（真鍮仕上げ）', STKQTY:55, ALCQTY:15, AVLQTY:40, RCVQTY:80, SHPQTY:25, LSTRCVDT:'20260401', LSTSHPDT:'20260508', UPDDT:'20260601' },
  { ITMCD:'ITM007', LOCCD:'WH-D-001', ITMNM:'シャンデリア（クリスタル）', STKQTY:14, ALCQTY:4, AVLQTY:10, RCVQTY:20, SHPQTY:6, LSTRCVDT:'20260415', LSTSHPDT:'20260509', UPDDT:'20260601' },
  { ITMCD:'ITM008', LOCCD:'WH-D-002', ITMNM:'マホガニー製チェスト（5段）', STKQTY:22, ALCQTY:0, AVLQTY:22, RCVQTY:30, SHPQTY:8, LSTRCVDT:'20260410', LSTSHPDT:'20260514', UPDDT:'20260601' },
  { ITMCD:'ITM009', LOCCD:'WH-E-001', ITMNM:'スチール製本棚（幅90cm）', STKQTY:80, ALCQTY:20, AVLQTY:60, RCVQTY:120, SHPQTY:40, LSTRCVDT:'20260401', LSTSHPDT:'20260510', UPDDT:'20260601' },
  { ITMCD:'ITM010', LOCCD:'WH-E-002', ITMNM:'ガラストップダイニングテーブル', STKQTY:10, ALCQTY:3, AVLQTY:7, RCVQTY:15, SHPQTY:5, LSTRCVDT:'20260415', LSTSHPDT:'20260514', UPDDT:'20260601' },
  { ITMCD:'ITM011', LOCCD:'WH-F-001', ITMNM:'オットマン（牛革）', STKQTY:30, ALCQTY:0, AVLQTY:30, RCVQTY:40, SHPQTY:10, LSTRCVDT:'20260401', LSTSHPDT:'20260505', UPDDT:'20260601' },
  { ITMCD:'ITM012', LOCCD:'WH-F-002', ITMNM:'ペルシャ絨毯（2m×3m）', STKQTY:5, ALCQTY:0, AVLQTY:5, RCVQTY:8, SHPQTY:3, LSTRCVDT:'20260320', LSTSHPDT:'20260501', UPDDT:'20260601' },
];

let arRecords = [
  { INVNO:'INV0000001', INVDT:'20260509', DUEDT:'20260608', CUSTCD:'C003', CUSTNM:'東京インテリアショップ', ORDNO:'ORD0000003', ITMCD:'ITM005', ITMNM:'アンティーク調デスク', QTY:3, UNTPRC:120000, INVAMT:396000, TAXAMT:36000, RCVAMT:396000, BALAMT:0, RCVDT:'20260525', RCVMTD:'01', ARSTS:'3', UPDDT:'20260525' },
  { INVNO:'INV0000002', INVDT:'20260514', DUEDT:'20260613', CUSTCD:'C003', CUSTNM:'東京インテリアショップ', ORDNO:'ORD0000010', ITMCD:'ITM008', ITMNM:'マホガニー製チェスト（5段）', QTY:6, UNTPRC:72000, INVAMT:475200, TAXAMT:43200, RCVAMT:200000, BALAMT:275200, RCVDT:'20260530', RCVMTD:'02', ARSTS:'2', UPDDT:'20260530' },
  { INVNO:'INV0000003', INVDT:'20260601', DUEDT:'20260701', CUSTCD:'C001', CUSTNM:'株式会社山田インテリア', ORDNO:'ORD0000001', ITMCD:'ITM001', ITMNM:'イタリア製レザーソファ3人掛け', QTY:2, UNTPRC:198000, INVAMT:435600, TAXAMT:39600, RCVAMT:0, BALAMT:435600, RCVDT:'', RCVMTD:'', ARSTS:'1', UPDDT:'20260601' },
  { INVNO:'INV0000004', INVDT:'20260601', DUEDT:'20260701', CUSTCD:'C001', CUSTNM:'株式会社山田インテリア', ORDNO:'ORD0000004', ITMCD:'ITM007', ITMNM:'シャンデリア（クリスタル）', QTY:4, UNTPRC:65000, INVAMT:286000, TAXAMT:26000, RCVAMT:0, BALAMT:286000, RCVDT:'', RCVMTD:'', ARSTS:'1', UPDDT:'20260601' },
  { INVNO:'INV0000005', INVDT:'20260601', DUEDT:'20260701', CUSTCD:'C006', CUSTNM:'福岡インテリアプロ株式会社', ORDNO:'ORD0000008', ITMCD:'ITM010', ITMNM:'ガラストップダイニングテーブル', QTY:3, UNTPRC:98000, INVAMT:323400, TAXAMT:29400, RCVAMT:0, BALAMT:323400, RCVDT:'', RCVMTD:'', ARSTS:'1', UPDDT:'20260601' },
];

let apRecords = [
  { PONO:'PO00000001', PODT:'20260401', PAYDT:'20260430', SUPCD:'SUP001', SUPNM:'イタリアインポート株式会社', ITMCD:'ITM001', ITMNM:'イタリア製レザーソファ3人掛け', QTY:10, CPRC:110000, POAMT:1210000, TAXAMT:110000, PAYAMT:1210000, BALAMT:0, ACTPAYDT:'20260428', PAYMTD:'01', APSTS:'3', UPDDT:'20260428' },
  { PONO:'PO00000002', PODT:'20260415', PAYDT:'20260515', SUPCD:'SUP003', SUPNM:'スカンジナビアン商事', ITMCD:'ITM003', ITMNM:'北欧デザイン ダイニングテーブル', QTY:15, CPRC:45000, POAMT:742500, TAXAMT:67500, PAYAMT:500000, BALAMT:242500, ACTPAYDT:'20260510', PAYMTD:'02', APSTS:'2', UPDDT:'20260510' },
  { PONO:'PO00000003', PODT:'20260501', PAYDT:'20260531', SUPCD:'SUP002', SUPNM:'北欧ウッドクラフト社', ITMCD:'ITM002', ITMNM:'ウォールナット無垢材ベッドフレーム', QTY:20, CPRC:85000, POAMT:1870000, TAXAMT:170000, PAYAMT:0, BALAMT:1870000, ACTPAYDT:'', PAYMTD:'', APSTS:'1', UPDDT:'20260501' },
  { PONO:'PO00000004', PODT:'20260510', PAYDT:'20260610', SUPCD:'SUP006', SUPNM:'デザイン照明株式会社', ITMCD:'ITM006', ITMNM:'フロアランプ（真鍮仕上げ）', QTY:50, CPRC:16000, POAMT:880000, TAXAMT:80000, PAYAMT:0, BALAMT:880000, ACTPAYDT:'', PAYMTD:'', APSTS:'1', UPDDT:'20260510' },
  { PONO:'PO00000005', PODT:'20260520', PAYDT:'20260620', SUPCD:'SUP004', SUPNM:'国内家具製造株式会社', ITMCD:'ITM009', ITMNM:'スチール製本棚（幅90cm）', QTY:50, CPRC:14000, POAMT:770000, TAXAMT:70000, PAYAMT:0, BALAMT:770000, ACTPAYDT:'', PAYMTD:'', APSTS:'1', UPDDT:'20260520' },
];

// =======================================================================
// ORDMGR相当ロジック
// =======================================================================
const ordMgr = {
  getAll: () => orders,

  getById: (ordNo) => orders.find(o => o.ORDNO === ordNo),

  search: ({ ordNo, custCd, status }) => {
    return orders.filter(o => {
      if (ordNo && !o.ORDNO.includes(ordNo)) return false;
      if (custCd && o.CUSTCD !== custCd) return false;
      if (status && o.ORDSTS !== status) return false;
      return true;
    });
  },

  create: (data) => {
    const seq = orders.length + 1;
    const ordNo = 'ORD' + String(seq).padStart(7, '0');
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const amt = data.QTY * data.UNTPRC;
    const rec = {
      ORDNO:   ordNo,
      ORDDT:   today,
      CUSTCD:  data.CUSTCD,
      CUSTNM:  data.CUSTNM,
      ITMCD:   data.ITMCD,
      ITMNM:   data.ITMNM,
      QTY:     Number(data.QTY),
      UNTPRC:  Number(data.UNTPRC),
      AMT:     amt,
      ORDSTS:  '1',
      DLVDT:   data.DLVDT || '',
      SHIPDT:  '',
      RMRK:    data.RMRK || '',
    };
    orders.push(rec);
    // 在庫引当
    invMgr.allocate(rec.ITMCD, rec.QTY);
    return rec;
  },

  update: (ordNo, data) => {
    const idx = orders.findIndex(o => o.ORDNO === ordNo);
    if (idx === -1) return null;
    const rec = orders[idx];
    Object.assign(rec, data);
    rec.AMT = rec.QTY * rec.UNTPRC;
    return rec;
  },

  cancel: (ordNo) => {
    const rec = orders.find(o => o.ORDNO === ordNo);
    if (!rec) return null;
    const prevSts = rec.ORDSTS;
    rec.ORDSTS = '9';
    // 在庫引当解除
    if (prevSts === '2') invMgr.deallocate(rec.ITMCD, rec.QTY);
    return rec;
  },

  getBacklog: () => orders.filter(o => o.ORDSTS !== '3' && o.ORDSTS !== '9'),
};

// =======================================================================
// INVMGR相当ロジック
// =======================================================================
const invMgr = {
  getAllItems: () => items,

  getItemById: (itmCd) => items.find(i => i.ITMCD === itmCd),

  getAllStock: () => inventory,

  getStockById: (itmCd) => inventory.find(i => i.ITMCD === itmCd),

  searchStock: ({ itmCd, locCd, catCd }) => {
    return inventory.filter(inv => {
      if (itmCd && inv.ITMCD !== itmCd) return false;
      if (locCd && inv.LOCCD !== locCd) return false;
      if (catCd) {
        const item = items.find(i => i.ITMCD === inv.ITMCD);
        if (!item || item.CATCD !== catCd) return false;
      }
      return true;
    });
  },

  receive: (itmCd, locCd, qty) => {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    let inv = inventory.find(i => i.ITMCD === itmCd && i.LOCCD === locCd);
    if (!inv) return { ok: false, msg: '在庫レコードが存在しません' };
    inv.STKQTY += Number(qty);
    inv.RCVQTY += Number(qty);
    inv.AVLQTY  = inv.STKQTY - inv.ALCQTY;
    inv.LSTRCVDT = today;
    inv.UPDDT    = today;
    return { ok: true, inv };
  },

  ship: (itmCd, locCd, qty) => {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const inv = inventory.find(i => i.ITMCD === itmCd && i.LOCCD === locCd);
    if (!inv) return { ok: false, msg: '在庫レコードが存在しません' };
    if (inv.AVLQTY < qty) return { ok: false, msg: `有効在庫不足（有効在庫: ${inv.AVLQTY}）` };
    inv.STKQTY -= Number(qty);
    inv.SHPQTY += Number(qty);
    inv.AVLQTY  = inv.STKQTY - inv.ALCQTY;
    inv.LSTSHPDT = today;
    inv.UPDDT    = today;
    return { ok: true, inv };
  },

  allocate: (itmCd, qty) => {
    const inv = inventory.find(i => i.ITMCD === itmCd);
    if (!inv) return false;
    inv.ALCQTY += Number(qty);
    inv.AVLQTY  = inv.STKQTY - inv.ALCQTY;
    return true;
  },

  deallocate: (itmCd, qty) => {
    const inv = inventory.find(i => i.ITMCD === itmCd);
    if (!inv) return false;
    inv.ALCQTY  = Math.max(0, inv.ALCQTY - Number(qty));
    inv.AVLQTY  = inv.STKQTY - inv.ALCQTY;
    return true;
  },

  adjust: (itmCd, locCd, newQty) => {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const inv = inventory.find(i => i.ITMCD === itmCd && i.LOCCD === locCd);
    if (!inv) return { ok: false, msg: '在庫レコードが存在しません' };
    inv.STKQTY = Number(newQty);
    inv.AVLQTY = inv.STKQTY - inv.ALCQTY;
    inv.UPDDT  = today;
    return { ok: true, inv };
  },

  getLowStock: () => {
    return inventory.filter(inv => {
      const item = items.find(i => i.ITMCD === inv.ITMCD);
      return item && inv.STKQTY <= item.SAFSTK;
    });
  },
};

// =======================================================================
// ACCMGR相当ロジック
// =======================================================================
const accMgr = {
  getAllAr: () => arRecords,

  getArById: (invNo) => arRecords.find(r => r.INVNO === invNo),

  searchAr: ({ custCd, invNo, status }) => {
    return arRecords.filter(r => {
      if (custCd && r.CUSTCD !== custCd) return false;
      if (invNo  && !r.INVNO.includes(invNo)) return false;
      if (status && r.ARSTS !== status) return false;
      return true;
    });
  },

  receive: (invNo, rcvAmt, rcvDt, rcvMtd) => {
    const rec = arRecords.find(r => r.INVNO === invNo);
    if (!rec) return { ok: false, msg: '売掛レコードが見つかりません' };
    if (rcvAmt > rec.BALAMT) return { ok: false, msg: '入金額が残高を超えています' };
    rec.RCVAMT += Number(rcvAmt);
    rec.BALAMT  = rec.INVAMT - rec.RCVAMT;
    rec.RCVDT   = rcvDt;
    rec.RCVMTD  = rcvMtd;
    rec.ARSTS   = rec.BALAMT === 0 ? '3' : rec.RCVAMT > 0 ? '2' : '1';
    rec.UPDDT   = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    return { ok: true, rec };
  },

  getArSummary: () => {
    return arRecords.filter(r => r.ARSTS !== '9').reduce((s, r) => {
      s.totInv   += r.INVAMT;
      s.totRcv   += r.RCVAMT;
      s.totBal   += r.BALAMT;
      return s;
    }, { totInv: 0, totRcv: 0, totBal: 0 });
  },

  getAllAp: () => apRecords,

  getApById: (poNo) => apRecords.find(r => r.PONO === poNo),

  pay: (poNo, payAmt, payDt, payMtd) => {
    const rec = apRecords.find(r => r.PONO === poNo);
    if (!rec) return { ok: false, msg: '買掛レコードが見つかりません' };
    if (payAmt > rec.BALAMT) return { ok: false, msg: '支払額が残高を超えています' };
    rec.PAYAMT += Number(payAmt);
    rec.BALAMT  = rec.POAMT - rec.PAYAMT;
    rec.ACTPAYDT = payDt;
    rec.PAYMTD   = payMtd;
    rec.APSTS    = rec.BALAMT === 0 ? '3' : rec.PAYAMT > 0 ? '2' : '1';
    rec.UPDDT    = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    return { ok: true, rec };
  },

  getApSummary: () => {
    return apRecords.filter(r => r.APSTS !== '9').reduce((s, r) => {
      s.totPo  += r.POAMT;
      s.totPay += r.PAYAMT;
      s.totBal += r.BALAMT;
      return s;
    }, { totPo: 0, totPay: 0, totBal: 0 });
  },
};

// =======================================================================
// UTILSRV相当ロジック
// =======================================================================
const utilSrv = {
  fmtNum: (n) => Number(n).toLocaleString('ja-JP'),
  today:  () => new Date().toISOString().slice(0, 10).replace(/-/g, ''),
  calcTax: (amt) => Math.floor(amt * TAX_RATE),
};

module.exports = { ordMgr, invMgr, accMgr, utilSrv };
