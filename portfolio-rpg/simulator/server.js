'use strict';

const http    = require('http');
const path    = require('path');
const fs      = require('fs');
const { ordMgr, invMgr, accMgr, utilSrv } = require('./rpg-interpreter');

const PORT = 3000;

// =======================================================================
// 簡易ルーター（express不要・Node.js標準モジュールのみ）
// =======================================================================

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', d => { body += d; });
    req.on('end', () => {
      try { resolve(JSON.parse(body)); }
      catch { resolve({}); }
    });
  });
}

function sendJson(res, status, data) {
  const json = JSON.stringify(data);
  res.writeHead(status, {
    'Content-Type':  'application/json; charset=utf-8',
    'Cache-Control': 'no-cache',
  });
  res.end(json);
}

function sendFile(res, filePath) {
  const ext   = path.extname(filePath);
  const types = { '.html':'text/html', '.js':'application/javascript', '.css':'text/css' };
  const ct    = types[ext] || 'text/plain';
  try {
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': ct + '; charset=utf-8' });
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end('Not found');
  }
}

// =======================================================================
// HTTPサーバー
// =======================================================================
const server = http.createServer(async (req, res) => {
  const url    = req.url.split('?')[0];
  const method = req.method;
  const qs     = Object.fromEntries(new URLSearchParams(req.url.split('?')[1] || ''));

  // --- 静的ファイル ---
  if (method === 'GET' && url === '/') {
    return sendFile(res, path.join(__dirname, 'public', 'index.html'));
  }
  if (method === 'GET' && url.startsWith('/public/')) {
    return sendFile(res, path.join(__dirname, url));
  }

  // =======================================================================
  // 受発注API（ORDMGR相当）
  // =======================================================================

  // GET /api/orders — 受注一覧
  if (method === 'GET' && url === '/api/orders') {
    const list = qs.status
      ? ordMgr.search({ status: qs.status })
      : ordMgr.getAll();
    return sendJson(res, 200, list);
  }

  // GET /api/orders/backlog — 受注残一覧
  if (method === 'GET' && url === '/api/orders/backlog') {
    return sendJson(res, 200, ordMgr.getBacklog());
  }

  // GET /api/orders/search — 受注検索
  if (method === 'GET' && url === '/api/orders/search') {
    return sendJson(res, 200, ordMgr.search(qs));
  }

  // GET /api/orders/:id — 受注詳細
  const ordMatch = url.match(/^\/api\/orders\/([^/]+)$/);
  if (method === 'GET' && ordMatch) {
    const rec = ordMgr.getById(ordMatch[1]);
    return rec ? sendJson(res, 200, rec) : sendJson(res, 404, { error: '受注が見つかりません' });
  }

  // POST /api/orders — 受注登録
  if (method === 'POST' && url === '/api/orders') {
    const body = await parseBody(req);
    if (!body.CUSTCD || !body.ITMCD || !body.QTY || !body.UNTPRC) {
      return sendJson(res, 400, { error: '必須項目が不足しています' });
    }
    const rec = ordMgr.create(body);
    return sendJson(res, 201, rec);
  }

  // PUT /api/orders/:id — 受注更新
  const ordUpd = url.match(/^\/api\/orders\/([^/]+)$/);
  if (method === 'PUT' && ordUpd) {
    const body = await parseBody(req);
    const rec  = ordMgr.update(ordUpd[1], body);
    return rec ? sendJson(res, 200, rec) : sendJson(res, 404, { error: '受注が見つかりません' });
  }

  // DELETE /api/orders/:id — 受注取消
  const ordDel = url.match(/^\/api\/orders\/([^/]+)\/cancel$/);
  if (method === 'POST' && ordDel) {
    const rec = ordMgr.cancel(ordDel[1]);
    return rec ? sendJson(res, 200, rec) : sendJson(res, 404, { error: '受注が見つかりません' });
  }

  // =======================================================================
  // 在庫管理API（INVMGR相当）
  // =======================================================================

  // GET /api/items — 商品マスタ一覧
  if (method === 'GET' && url === '/api/items') {
    return sendJson(res, 200, invMgr.getAllItems());
  }

  // GET /api/inventory — 在庫一覧
  if (method === 'GET' && url === '/api/inventory') {
    const list = (qs.itmCd || qs.locCd || qs.catCd)
      ? invMgr.searchStock(qs)
      : invMgr.getAllStock();
    return sendJson(res, 200, list);
  }

  // GET /api/inventory/low-stock — 安全在庫割れ一覧
  if (method === 'GET' && url === '/api/inventory/low-stock') {
    return sendJson(res, 200, invMgr.getLowStock());
  }

  // POST /api/inventory/receive — 入庫処理
  if (method === 'POST' && url === '/api/inventory/receive') {
    const body = await parseBody(req);
    const result = invMgr.receive(body.ITMCD, body.LOCCD, body.QTY);
    return sendJson(res, result.ok ? 200 : 400, result);
  }

  // POST /api/inventory/ship — 出庫処理
  if (method === 'POST' && url === '/api/inventory/ship') {
    const body = await parseBody(req);
    const result = invMgr.ship(body.ITMCD, body.LOCCD, body.QTY);
    return sendJson(res, result.ok ? 200 : 400, result);
  }

  // POST /api/inventory/adjust — 在庫調整
  if (method === 'POST' && url === '/api/inventory/adjust') {
    const body = await parseBody(req);
    const result = invMgr.adjust(body.ITMCD, body.LOCCD, body.STKQTY);
    return sendJson(res, result.ok ? 200 : 400, result);
  }

  // =======================================================================
  // 会計API（ACCMGR相当）
  // =======================================================================

  // GET /api/ar — 売掛金一覧
  if (method === 'GET' && url === '/api/ar') {
    const list = qs.custCd
      ? accMgr.searchAr(qs)
      : accMgr.getAllAr();
    return sendJson(res, 200, list);
  }

  // GET /api/ar/summary — 売掛金サマリー
  if (method === 'GET' && url === '/api/ar/summary') {
    return sendJson(res, 200, accMgr.getArSummary());
  }

  // POST /api/ar/receive — 入金消込
  if (method === 'POST' && url === '/api/ar/receive') {
    const body = await parseBody(req);
    const result = accMgr.receive(body.INVNO, body.RCVAMT, body.RCVDT, body.RCVMTD);
    return sendJson(res, result.ok ? 200 : 400, result);
  }

  // GET /api/ap — 買掛金一覧
  if (method === 'GET' && url === '/api/ap') {
    return sendJson(res, 200, accMgr.getAllAp());
  }

  // GET /api/ap/summary — 買掛金サマリー
  if (method === 'GET' && url === '/api/ap/summary') {
    return sendJson(res, 200, accMgr.getApSummary());
  }

  // POST /api/ap/pay — 支払処理
  if (method === 'POST' && url === '/api/ap/pay') {
    const body = await parseBody(req);
    const result = accMgr.pay(body.PONO, body.PAYAMT, body.PAYDT, body.PAYMTD);
    return sendJson(res, result.ok ? 200 : 400, result);
  }

  // --- 404 ---
  sendJson(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log('==================================================');
  console.log(' インテリア商社 AS/400 基幹システム シミュレータ');
  console.log(`  http://localhost:${PORT}`);
  console.log('==================================================');
  console.log(' 受発注管理  : /api/orders');
  console.log(' 在庫管理   : /api/inventory');
  console.log(' 会計管理   : /api/ar  /api/ap');
  console.log('==================================================');
});
