// ===== SAYER SHOPS – NUI UI =====
function nui(name, data = {}) {
  return fetch(`https://tss-shops/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data)
  }).then(r => r.json().catch(() => ({})));
}
const money = (n) => `$${Number(n || 0).toLocaleString()}`;

const root = document.getElementById('shop-root');
const itemsGrid = document.getElementById('items-grid');
const basketList = document.getElementById('basket-list');
const btnClose = document.getElementById('btn-close');
const btnPurchase = document.getElementById('btn-purchase');
const basketClear = document.getElementById('basket-clear');
const subtotalEl = document.getElementById('subtotal');
const grandEl = document.getElementById('grandtotal');
const balCash = document.getElementById('bal-cash');
const balBank = document.getElementById('bal-bank');
const statusEl = document.getElementById('status');
const shopLabel = document.getElementById('shop-label');
const shopSubtitle = document.getElementById('shop-subtitle');
const shopLogo = document.getElementById('shop-logo');

let STATE = {
  open: false,
  items: [],
  balances: { cash: 0, bank: 0 },
  basket: new Map(),
  defaultAccount: 'cash'
};

function setStatus(msg, isError = false) {
  statusEl.textContent = msg || '';
  statusEl.style.color = isError ? '#ff6b6b' : 'var(--muted)';
}
function computeTotals() {
  let sub = 0;
  STATE.basket.forEach(row => sub += row.price * row.qty);
  subtotalEl.textContent = money(sub);
  grandEl.textContent = money(sub);
  btnPurchase.disabled = (sub <= 0);
}
function renderBasket() {
  basketList.innerHTML = '';
  if (STATE.basket.size === 0) {
    basketList.innerHTML = `<div class="badge">Your basket is empty.</div>`;
    computeTotals();
    return;
  }
  STATE.basket.forEach(row => {
    const el = document.createElement('div');
    el.className = 'basket-row';
    el.innerHTML = `
      <div class="basket-title">${escapeHtml(row.label)}</div>
      <div class="basket-price">${money(row.price)}</div>
      <input type="number" class="basket-qty" min="1" max="999" value="${row.qty}" />
      <button class="basket-remove">Remove</button>
      <div class="basket-line-total" style="grid-column: 1 / -1; text-align:right">${money(row.price * row.qty)}</div>
    `;
    const qtyInput = el.querySelector('.basket-qty');
    qtyInput.addEventListener('input', () => {
      let v = parseInt(qtyInput.value || '1', 10);
      if (isNaN(v) || v < 1) v = 1;
      if (v > 999) v = 999;
      qtyInput.value = v;
      row.qty = v;
      el.querySelector('.basket-line-total').textContent = money(row.price * row.qty);
      computeTotals();
    });
    el.querySelector('.basket-remove').addEventListener('click', () => {
      STATE.basket.delete(row.name);
      renderBasket();
    });
    basketList.appendChild(el);
  });
  computeTotals();
}
function addToBasket(item, qty) {
  const existing = STATE.basket.get(item.name);
  const addQty = Math.max(1, Math.min(999, parseInt(qty || '1', 10)));
  if (existing) {
    existing.qty = Math.min(999, existing.qty + addQty);
  } else {
    STATE.basket.set(item.name, { name: item.name, label: item.label, price: item.price, qty: addQty });
  }
  renderBasket();
}
function imageFor(item) {
  if (item.icon && item.icon.startsWith('nui://')) return item.icon;
  if (item.icon && (item.icon.endsWith('.png') || item.icon.includes('/'))) return item.icon;
  return `nui://qb-inventory/html/images/${item.name}.png`;
}
function createCard(item) {
  const el = document.createElement('div');
  el.className = 'card';
  el.innerHTML = `
    <img class="card-img" src="${imageFor(item)}" alt="${escapeHtml(item.label)}"
         onerror="this.onerror=null;this.src='img/fallback.png';" />
    <h3 class="card-title">${escapeHtml(item.label)}</h3>
    <div class="card-meta">
      <span class="badge">${escapeHtml(item.name)}</span>
      <strong>${money(item.price)}</strong>
    </div>
    <div class="qty-row">
      <input type="number" class="qty-input" min="1" max="999" value="1" />
      <button class="btn add-btn">Add</button>
    </div>
  `;
  const qtyInput = el.querySelector('.qty-input');
  el.querySelector('.add-btn').addEventListener('click', () => addToBasket(item, qtyInput.value));
  return el;
}
function renderItems() {
  itemsGrid.innerHTML = '';
  if (!STATE.items || STATE.items.length === 0) {
    itemsGrid.innerHTML = `<div class="badge">No items available.</div>`;
    return;
  }
  STATE.items.forEach(item => itemsGrid.appendChild(createCard(item)));
}
function openShop(payload) {
  STATE.open = true;
  STATE.items = payload.items || [];
  STATE.balances = payload.balances || { cash: 0, bank: 0 };
  STATE.defaultAccount = payload.defaultAccount || 'cash';
  STATE.basket.clear();

  shopLabel.textContent = payload.shopLabel || 'Shop';
  shopSubtitle.textContent = payload.shopSubtitle || '';
  balCash.textContent = money(STATE.balances.cash);
  balBank.textContent = money(STATE.balances.bank);

  if (payload.shopLogo) {
    console.log("logo exists")
    shopLogo.src = payload.shopLogo;
    shopLogo.style.display = 'block';
  } else {
    console.log("logo not exist")
    shopLogo.src = 'nui://tss-shops/html/images/tss_red_128.png';
    shopLogo.style.display = 'none';
  }
  const rads = document.querySelectorAll('input[name="account"]');
  rads.forEach(r => { r.checked = (r.value === STATE.defaultAccount); });

  renderItems();
  renderBasket();
  setStatus('');
  root.classList.remove('hidden');
  document.body.style.pointerEvents = 'auto';
}
function closeShop() {
  root.classList.add('hidden');
  STATE.open = false;
  STATE.basket.clear();
  itemsGrid.innerHTML = '';
  basketList.innerHTML = '';
  setStatus('');
  nui('close', {});
}
btnClose.addEventListener('click', closeShop);
basketClear.addEventListener('click', () => { STATE.basket.clear(); renderBasket(); });
window.addEventListener('keydown', (e) => { if (STATE.open && e.key === 'Escape'){ e.preventDefault(); closeShop(); } });

btnPurchase.addEventListener('click', async () => {
  if (STATE.basket.size === 0) return;
  const total = Array.from(STATE.basket.values()).reduce((s, r) => s + r.price * r.qty, 0);
  const account = document.querySelector('input[name="account"]:checked')?.value || 'cash';

  setStatus('Checking funds…');
  btnPurchase.disabled = true;
  try {
    const check = await nui('checkFunds', { total, account });
    if (!check || check.ok !== true) {
      setStatus(check?.reason || 'Insufficient funds.', true);
      btnPurchase.disabled = false;
      if (typeof check?.cash === 'number') balCash.textContent = money(check.cash);
      if (typeof check?.bank === 'number') balBank.textContent = money(check.bank);
      return;
    }
    setStatus('Processing purchase…');
    const items = Array.from(STATE.basket.values()).map(r => ({ name:r.name, label:r.label, price:r.price, qty:r.qty }));
    const res = await nui('purchaseBasket', { account, items });
    if (!res || res.ok !== true) {
      setStatus(res?.reason || 'Purchase failed.', true);
      btnPurchase.disabled = false;
      return;
    }
    setStatus('Purchase complete!');
    STATE.basket.clear();
    renderBasket();
    if (typeof res.cash === 'number') balCash.textContent = money(res.cash);
    if (typeof res.bank === 'number') balBank.textContent = money(res.bank);
    btnPurchase.disabled = true;
  } catch {
    setStatus('Something went wrong.', true);
    btnPurchase.disabled = false;
  }
});
window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};
  if (action === 'openShop') return openShop(payload || {});
  if (action === 'close') return closeShop();
  if (action === 'updateBalances') {
    STATE.balances.cash = payload?.cash ?? STATE.balances.cash;
    STATE.balances.bank = payload?.bank ?? STATE.balances.bank;
    balCash.textContent = money(STATE.balances.cash);
    balBank.textContent = money(STATE.balances.bank);
  }
});
function escapeHtml(s) {
  return String(s ?? '')
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;')
    .replace(/'/g,'&#39;');
}
document.addEventListener('wheel', (e) => { if (STATE.open) e.stopPropagation(); }, { passive: true });
