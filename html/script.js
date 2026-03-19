const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'tss-shops';

function nui(name, data = {}) {
  return fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).then((r) => r.json().catch(() => ({})));
}

const THEME_KEY = 'tss-shops-theme';

const state = {
  open: false,
  vendingOpen: false,
  busy: false,
  vendingBusy: false,
  shopId: null,
  items: [],
  itemIndex: new Map(),
  basket: new Map(),
  vendingMachineId: null,
  vendingItems: [],
  vendingSelected: null,
  balances: { cash: 0, bank: 0, business: 0 },
  accounts: ['cash', 'bank'],
  selectedAccount: 'cash',
  search: '',
  sort: 'name_asc',
  theme: 'dark',
};

const root = document.getElementById('shop-root');
const vendingRoot = document.getElementById('vending-root');
const body = document.body;

const el = {
  shopLabel: document.getElementById('shop-label'),
  shopSubtitle: document.getElementById('shop-subtitle'),
  shopMeta: document.getElementById('shop-meta'),
  shopLogo: document.getElementById('shop-logo'),
  themeToggle: document.getElementById('themeToggle'),
  balCash: document.getElementById('bal-cash'),
  balBank: document.getElementById('bal-bank'),
  balBusiness: document.getElementById('bal-business'),
  businessRow: document.getElementById('business-row'),
  accountSelect: document.getElementById('account-select'),
  searchInput: document.getElementById('search-input'),
  sortSelect: document.getElementById('sort-select'),
  itemsGrid: document.getElementById('items-grid'),
  itemsCount: document.getElementById('items-count'),
  basketList: document.getElementById('basket-list'),
  basketLines: document.getElementById('basket-lines'),
  itemCount: document.getElementById('itemcount'),
  grandTotal: document.getElementById('grandtotal'),
  status: document.getElementById('status'),
  btnPurchase: document.getElementById('btn-purchase'),
  btnClose: document.getElementById('btn-close'),
  basketClear: document.getElementById('basket-clear'),
  vendingTitle: document.getElementById('vending-title'),
  vendingSubtitle: document.getElementById('vending-subtitle'),
  vendingGrid: document.getElementById('vending-grid'),
  vendingSelectedImage: document.getElementById('vending-selected-image'),
  vendingSelectedName: document.getElementById('vending-selected-name'),
  vendingSelectedPrice: document.getElementById('vending-selected-price'),
  vendingStatus: document.getElementById('vending-status'),
  vendingPurchase: document.getElementById('vending-purchase'),
  vendingClose: document.getElementById('vending-close'),
};

const money = (n) => `$${Number(n || 0).toLocaleString('en-US')}`;

function clampQty(value, fallback = 1) {
  const parsed = parseInt(value, 10);
  if (Number.isNaN(parsed)) return fallback;
  return Math.max(1, Math.min(999, parsed));
}

function escapeHtml(input) {
  return String(input ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function imageFor(item) {
  if (item.icon && item.icon.startsWith('nui://')) return item.icon;
  if (item.icon && (item.icon.endsWith('.png') || item.icon.includes('/'))) return item.icon;
  return `nui://qb-inventory/html/images/${item.name}.png`;
}

function setStatus(message, type = 'info') {
  el.status.textContent = message || '';
  if (type === 'error') {
    el.status.style.color = 'var(--danger)';
    return;
  }
  if (type === 'ok') {
    el.status.style.color = 'var(--good)';
    return;
  }
  el.status.style.color = 'var(--text-muted)';
}

function setVendingStatus(message, type = 'info') {
  el.vendingStatus.textContent = message || '';
  if (type === 'error') {
    el.vendingStatus.style.color = 'var(--danger)';
    return;
  }
  if (type === 'ok') {
    el.vendingStatus.style.color = 'var(--good)';
    return;
  }
  el.vendingStatus.style.color = 'var(--text-muted)';
}

function setTheme(theme) {
  state.theme = theme === 'light' ? 'light' : 'dark';
  body.classList.toggle('theme-light', state.theme === 'light');
  body.classList.toggle('theme-dark', state.theme !== 'light');
  const isLight = state.theme === 'light';
  el.themeToggle.textContent = isLight ? '\u2600' : '\u263E';
  el.themeToggle.title = isLight ? 'Light Mode' : 'Dark Mode';
  el.themeToggle.setAttribute('aria-label', isLight ? 'Light Mode' : 'Dark Mode');

  try {
    localStorage.setItem(THEME_KEY, state.theme);
  } catch (err) {
    console.debug('theme save skipped', err);
  }
}

function loadTheme() {
  try {
    const saved = localStorage.getItem(THEME_KEY);
    if (saved === 'light' || saved === 'dark') {
      setTheme(saved);
      return;
    }
  } catch (err) {
    console.debug('theme load skipped', err);
  }
  setTheme('dark');
}

function getBasketDraftKey() {
  if (!state.shopId) return null;
  return `tss-shops-basket:${state.shopId}`;
}

function saveBasketDraft() {
  const key = getBasketDraftKey();
  if (!key) return;

  try {
    const rows = Array.from(state.basket.values()).map((row) => ({
      name: row.name,
      qty: row.qty,
    }));
    localStorage.setItem(key, JSON.stringify(rows));
  } catch (err) {
    console.debug('basket save skipped', err);
  }
}

function loadBasketDraft() {
  state.basket.clear();
  const key = getBasketDraftKey();
  if (!key) return;

  try {
    const raw = localStorage.getItem(key);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return;

    parsed.forEach((row) => {
      const item = state.itemIndex.get(row.name);
      if (!item) return;
      const qty = clampQty(row.qty, 1);
      state.basket.set(item.name, {
        name: item.name,
        label: item.label,
        price: item.price,
        qty,
      });
    });
  } catch (err) {
    console.debug('basket load skipped', err);
  }
}

function clearBasketDraft() {
  const key = getBasketDraftKey();
  if (!key) return;

  try {
    localStorage.removeItem(key);
  } catch (err) {
    console.debug('basket clear skipped', err);
  }
}

function setBalances(next = {}) {
  state.balances.cash = Number(next.cash ?? state.balances.cash ?? 0);
  state.balances.bank = Number(next.bank ?? state.balances.bank ?? 0);
  state.balances.business = Number(next.business ?? state.balances.business ?? 0);

  el.balCash.textContent = money(state.balances.cash);
  el.balBank.textContent = money(state.balances.bank);
  el.balBusiness.textContent = money(state.balances.business);

  const hasBusiness = state.accounts.includes('business');
  el.businessRow.classList.toggle('hidden', !hasBusiness);
}

function renderAccountOptions() {
  el.accountSelect.innerHTML = '';
  state.accounts.forEach((account) => {
    const btn = document.createElement('button');
    btn.className = `account-btn${account === state.selectedAccount ? ' active' : ''}`;
    btn.type = 'button';
    btn.dataset.account = account;
    btn.textContent = account.charAt(0).toUpperCase() + account.slice(1);
    el.accountSelect.appendChild(btn);
  });
}

function sortItems(rows) {
  const sorted = [...rows];

  if (state.sort === 'name_desc') {
    return sorted.sort((a, b) => b.label.localeCompare(a.label));
  }
  if (state.sort === 'price_asc') {
    return sorted.sort((a, b) => Number(a.price || 0) - Number(b.price || 0));
  }
  if (state.sort === 'price_desc') {
    return sorted.sort((a, b) => Number(b.price || 0) - Number(a.price || 0));
  }
  return sorted.sort((a, b) => a.label.localeCompare(b.label));
}

function getVisibleItems() {
  const query = state.search.trim().toLowerCase();
  const rows = query
    ? state.items.filter((item) => item.label.toLowerCase().includes(query) || item.name.toLowerCase().includes(query))
    : state.items;
  return sortItems(rows);
}

function getBasketSummary() {
  let lines = 0;
  let quantity = 0;
  let total = 0;

  state.basket.forEach((row) => {
    lines += 1;
    quantity += row.qty;
    total += row.price * row.qty;
  });

  return { lines, quantity, total };
}

function updateSummaryUi() {
  const summary = getBasketSummary();
  el.basketLines.textContent = `${summary.lines} lines`;
  el.itemCount.textContent = String(summary.quantity);
  el.grandTotal.textContent = money(summary.total);

  if (!state.busy) {
    el.btnPurchase.disabled = summary.total <= 0;
  }
  el.btnPurchase.textContent = summary.quantity > 0 ? `Purchase (${summary.quantity})` : 'Purchase';

  if (summary.quantity > 0) {
    el.shopMeta.textContent = `${summary.quantity} items ready to checkout`;
  } else {
    el.shopMeta.textContent = 'Basket is ready';
  }
}

function setBasketQty(name, qty) {
  const row = state.basket.get(name);
  if (!row) return;

  const nextQty = clampQty(qty, row.qty);
  row.qty = nextQty;
  saveBasketDraft();
  renderBasket();
}

function removeFromBasket(name) {
  state.basket.delete(name);
  if (state.basket.size === 0) {
    clearBasketDraft();
  } else {
    saveBasketDraft();
  }
  renderBasket();
}

function clearBasket() {
  state.basket.clear();
  clearBasketDraft();
  renderBasket();
}

function addToBasket(item, qty) {
  const addQty = clampQty(qty, 1);
  const existing = state.basket.get(item.name);

  if (existing) {
    existing.qty = clampQty(existing.qty + addQty, existing.qty);
  } else {
    state.basket.set(item.name, {
      name: item.name,
      label: item.label,
      price: item.price,
      qty: addQty,
    });
  }

  saveBasketDraft();
  renderBasket();
  setStatus(`${item.label} added to basket.`, 'ok');
}

function makeQtyControl(initial, onApply) {
  const wrap = document.createElement('div');
  wrap.className = 'basket-qty-row';

  const minus = document.createElement('button');
  minus.className = 'qty-btn';
  minus.type = 'button';
  minus.textContent = '-';

  const input = document.createElement('input');
  input.className = 'basket-qty';
  input.type = 'number';
  input.min = '1';
  input.max = '999';
  input.value = String(clampQty(initial));

  const plus = document.createElement('button');
  plus.className = 'qty-btn';
  plus.type = 'button';
  plus.textContent = '+';

  minus.addEventListener('click', () => {
    const next = clampQty(Number(input.value) - 1, 1);
    input.value = String(next);
    onApply(next);
  });

  plus.addEventListener('click', () => {
    const next = clampQty(Number(input.value) + 1, 1);
    input.value = String(next);
    onApply(next);
  });

  input.addEventListener('change', () => {
    const next = clampQty(input.value, 1);
    input.value = String(next);
    onApply(next);
  });

  input.addEventListener('keydown', (event) => {
    if (event.key !== 'Enter') return;
    event.preventDefault();
    const next = clampQty(input.value, 1);
    input.value = String(next);
    onApply(next);
  });

  wrap.append(minus, input, plus);
  return wrap;
}

function renderItems() {
  const rows = getVisibleItems();
  el.itemsGrid.innerHTML = '';
  el.itemsCount.textContent = `${rows.length} items`;

  if (!rows.length) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'No matching items.';
    el.itemsGrid.appendChild(empty);
    return;
  }

  rows.forEach((item) => {
    const card = document.createElement('article');
    card.className = 'item-card';

    const title = escapeHtml(item.label);

    card.innerHTML = `
      <img class="item-thumb" src="${imageFor(item)}" alt="${title}" />
      <h3 class="item-title">${title}</h3>
      <p class="item-price">${money(item.price)}</p>
    `;

    const qtyControl = makeQtyControl(1, (next) => {
      qtyInput.value = String(next);
    });

    const qtyInput = qtyControl.querySelector('input');
    qtyInput.classList.add('qty-input');

    const addBtn = document.createElement('button');
    addBtn.className = 'add-btn';
    addBtn.type = 'button';
    addBtn.textContent = 'Add';
    addBtn.addEventListener('click', () => {
      addToBasket(item, qtyInput.value);
      qtyInput.value = '1';
    });

    qtyInput.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter') return;
      event.preventDefault();
      addToBasket(item, qtyInput.value);
      qtyInput.value = '1';
    });

    const row = document.createElement('div');
    row.className = 'qty-row';
    row.append(qtyControl, addBtn);

    card.appendChild(row);
    el.itemsGrid.appendChild(card);
  });
}

function renderBasket() {
  el.basketList.innerHTML = '';

  if (state.basket.size === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'Your basket is empty.';
    el.basketList.appendChild(empty);
    updateSummaryUi();
    return;
  }

  state.basket.forEach((row) => {
    const item = document.createElement('div');
    item.className = 'basket-row';
    item.innerHTML = `
      <div class="basket-title-row">
        <strong>${escapeHtml(row.label)}</strong>
        <strong>${money(row.price * row.qty)}</strong>
      </div>
      <div class="basket-line-meta">${escapeHtml(row.name)} - ${money(row.price)} each</div>
    `;

    const qtyControl = makeQtyControl(row.qty, (nextQty) => {
      setBasketQty(row.name, nextQty);
    });

    const removeBtn = document.createElement('button');
    removeBtn.className = 'basket-remove';
    removeBtn.type = 'button';
    removeBtn.textContent = 'Remove';
    removeBtn.addEventListener('click', () => removeFromBasket(row.name));

    const actions = document.createElement('div');
    actions.className = 'basket-actions';
    actions.append(qtyControl, removeBtn);

    item.appendChild(actions);
    el.basketList.appendChild(item);
  });

  updateSummaryUi();
}

function openShop(payload = {}) {
  state.open = true;
  state.busy = false;
  state.shopId = payload.shopId || null;

  state.items = (payload.items || []).map((item) => ({
    name: String(item.name || ''),
    label: String(item.label || item.name || 'Item'),
    price: Number(item.price || 0),
    icon: item.icon || '',
  }));

  state.itemIndex.clear();
  state.items.forEach((item) => state.itemIndex.set(item.name, item));

  state.accounts = Array.isArray(payload.accounts) && payload.accounts.length ? payload.accounts : ['cash', 'bank'];

  const defaultAccount = payload.defaultAccount || state.accounts[0] || 'cash';
  state.selectedAccount = state.accounts.includes(defaultAccount) ? defaultAccount : state.accounts[0] || 'cash';

  el.shopLabel.textContent = payload.shopLabel || 'Shop';
  el.shopSubtitle.textContent = payload.shopSubtitle || 'Browse items and checkout.';

  if (payload.shopLogo) {
    el.shopLogo.src = payload.shopLogo;
    el.shopLogo.classList.remove('hidden');
  } else {
    el.shopLogo.src = 'nui://tss-shops/html/images/tss_red_128.png';
    el.shopLogo.classList.remove('hidden');
  }

  setBalances(payload.balances || { cash: 0, bank: 0, business: 0 });
  renderAccountOptions();

  loadBasketDraft();
  renderItems();
  renderBasket();

  setStatus('');
  root.classList.remove('hidden');
}

function closeShop() {
  if (!state.open) return;
  state.open = false;
  state.busy = false;
  root.classList.add('hidden');
  setStatus('');
  nui('close', {});
}

function renderVendingSelection() {
  const selected = state.vendingSelected;
  if (!selected) {
    el.vendingSelectedImage.src = 'nui://tss-shops/html/images/tss_red_128.png';
    el.vendingSelectedName.textContent = 'None selected';
    el.vendingSelectedPrice.textContent = '$0';
    el.vendingPurchase.disabled = true;
    return;
  }

  el.vendingSelectedImage.src = imageFor(selected);
  el.vendingSelectedName.textContent = selected.label;
  el.vendingSelectedPrice.textContent = money(selected.price);
  el.vendingPurchase.disabled = state.vendingBusy;
}

function renderVendingGrid() {
  el.vendingGrid.innerHTML = '';

  if (!state.vendingItems.length) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'No items available.';
    el.vendingGrid.appendChild(empty);
    return;
  }

  state.vendingItems.forEach((item) => {
    const card = document.createElement('article');
    const active = state.vendingSelected && state.vendingSelected.name === item.name;
    card.className = `vending-card${active ? ' active' : ''}`;
    card.innerHTML = `
      <img class="item-thumb" src="${imageFor(item)}" alt="${escapeHtml(item.label)}" />
      <h3 class="item-title">${escapeHtml(item.label)}</h3>
      <p class="item-price">${money(item.price)}</p>
    `;
    card.addEventListener('click', () => {
      state.vendingSelected = item;
      renderVendingGrid();
      renderVendingSelection();
      setVendingStatus('');
    });
    el.vendingGrid.appendChild(card);
  });
}

function openVending(payload = {}) {
  state.vendingOpen = true;
  state.vendingBusy = false;
  state.vendingMachineId = payload.machineId || null;
  state.vendingItems = (payload.items || []).map((item) => ({
    name: String(item.name || ''),
    label: String(item.label || item.name || 'Item'),
    price: Number(item.price || 0),
    icon: item.icon || '',
  }));
  state.vendingSelected = state.vendingItems[0] || null;

  el.vendingTitle.textContent = payload.label || 'Vending Machine';
  el.vendingSubtitle.textContent = payload.subtitle || 'Select an item to purchase.';
  setVendingStatus('');
  renderVendingGrid();
  renderVendingSelection();

  root.classList.add('hidden');
  vendingRoot.classList.remove('hidden');
}

function closeVending(notify = true) {
  if (!state.vendingOpen) return;
  state.vendingOpen = false;
  state.vendingBusy = false;
  state.vendingMachineId = null;
  state.vendingItems = [];
  state.vendingSelected = null;
  vendingRoot.classList.add('hidden');
  setVendingStatus('');
  if (notify) {
    nui('close', {});
  }
}

async function purchaseVendingItem() {
  if (!state.vendingOpen || state.vendingBusy || !state.vendingSelected) return;

  state.vendingBusy = true;
  el.vendingPurchase.disabled = true;
  setVendingStatus('Processing purchase...');

  try {
    const result = await nui('purchaseVendingItem', {
      machineId: state.vendingMachineId,
      itemName: state.vendingSelected.name,
    });

    if (!result || result.ok !== true) {
      setVendingStatus((result && result.reason) || 'Purchase failed.', 'error');
      return;
    }

    setVendingStatus(result.reason || 'Purchase complete.', 'ok');
  } catch (err) {
    console.error('vending purchase error', err);
    setVendingStatus('Something went wrong while purchasing.', 'error');
  } finally {
    state.vendingBusy = false;
    renderVendingSelection();
  }
}

function applyPurchaseResult(result = {}) {
  const failed = Array.isArray(result.failed) ? result.failed : [];
  const failedByName = new Map();
  failed.forEach((row) => {
    if (!row || !row.name) return;
    failedByName.set(row.name, clampQty(row.qty, 1));
  });

  if (failedByName.size === 0) {
    clearBasket();
    return;
  }

  const nextBasket = new Map();
  failedByName.forEach((qty, name) => {
    const source = state.basket.get(name) || state.itemIndex.get(name);
    if (!source) return;
    nextBasket.set(name, {
      name,
      label: source.label,
      price: Number(source.price || 0),
      qty,
    });
  });

  state.basket = nextBasket;
  saveBasketDraft();
  renderBasket();
}

async function purchaseBasket() {
  if (state.busy || state.basket.size === 0) return;

  const summary = getBasketSummary();
  const account = state.selectedAccount || 'cash';
  const items = Array.from(state.basket.values()).map((row) => ({
    name: row.name,
    qty: row.qty,
  }));

  state.busy = true;
  el.btnPurchase.disabled = true;

  try {
    setStatus('Checking funds...');
    const check = await nui('checkFunds', { total: summary.total, account });
    if (!check || check.ok !== true) {
      setStatus((check && check.reason) || 'Insufficient funds.', 'error');
      setBalances(check || {});
      return;
    }

    setStatus('Processing purchase...');
    const result = await nui('purchaseBasket', {
      shopId: state.shopId,
      account,
      items,
    });

    if (!result || result.ok !== true) {
      setStatus((result && result.reason) || 'Purchase failed.', 'error');
      setBalances(result || {});
      return;
    }

    setBalances(result || {});
    applyPurchaseResult(result);

    if (result.partial) {
      setStatus(result.reason || 'Some items could not be purchased.', 'info');
    } else {
      setStatus(result.reason || 'Purchase complete.', 'ok');
    }
  } catch (err) {
    console.error('purchase error', err);
    setStatus('Something went wrong while purchasing.', 'error');
  } finally {
    state.busy = false;
    updateSummaryUi();
  }
}

el.themeToggle.addEventListener('click', () => {
  setTheme(state.theme === 'dark' ? 'light' : 'dark');
});

el.searchInput.addEventListener('input', (event) => {
  state.search = event.target.value || '';
  renderItems();
});

el.sortSelect.addEventListener('change', (event) => {
  state.sort = event.target.value || 'name_asc';
  renderItems();
});

el.accountSelect.addEventListener('click', (event) => {
  const btn = event.target.closest('button[data-account]');
  if (!btn) return;
  state.selectedAccount = btn.dataset.account;
  renderAccountOptions();
});

el.basketClear.addEventListener('click', () => {
  clearBasket();
  setStatus('Basket cleared.', 'info');
});

el.btnClose.addEventListener('click', closeShop);
el.btnPurchase.addEventListener('click', purchaseBasket);
el.vendingClose.addEventListener('click', () => closeVending(true));
el.vendingPurchase.addEventListener('click', purchaseVendingItem);

window.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return;
  event.preventDefault();
  if (state.vendingOpen) {
    closeVending(true);
    return;
  }
  if (state.open) {
    closeShop();
  }
});

window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};

  if (action === 'openShop') {
    openShop(payload || {});
    return;
  }

  if (action === 'openVending') {
    openVending(payload || {});
    return;
  }

  if (action === 'close') {
    closeShop();
    closeVending(false);
    return;
  }

  if (action === 'updateBalances') {
    setBalances(payload || {});
    return;
  }

  if (action === 'setTheme') {
    setTheme((payload && payload.theme) || 'dark');
  }
});

document.addEventListener('wheel', (event) => {
  if (state.open || state.vendingOpen) event.stopPropagation();
}, { passive: true });

loadTheme();
