// =============================================
// Clo·set — Database & localStorage helpers
// =============================================

const DB_KEY      = 'closet_wardrobe';
const OUTFITS_KEY = 'closet_outfits';
const HISTORY_KEY = 'closet_history';

const TYPE_COVERAGE = {
  shirt: 'top', blouse: 'top', tshirt: 'top', tank: 'top', sweater: 'top',
  pants: 'bottom', jeans: 'bottom', skirt: 'bottom', shorts: 'bottom',
  dress: 'fullbody', jumpsuit: 'fullbody',
  jacket: 'layer', coat: 'layer', cardigan: 'layer', blazer: 'layer',
};

const TYPE_LABELS = {
  shirt: 'Shirt', blouse: 'Blouse', tshirt: 'T-Shirt', tank: 'Tank Top',
  sweater: 'Sweater', pants: 'Pants', jeans: 'Jeans', skirt: 'Skirt',
  shorts: 'Shorts', dress: 'Dress', jumpsuit: 'Jumpsuit',
  jacket: 'Jacket', coat: 'Coat', cardigan: 'Cardigan', blazer: 'Blazer',
};

const COVERAGE_LABELS = {
  top: 'Top', bottom: 'Bottom', fullbody: 'Full Body', layer: 'Layer'
};

const MOOD_LABELS = {
  casual: '😊 Casual', work: '💼 Work', brunch: '☕ Brunch',
  night: '🌙 Night Out', active: '🏃 Active',
};

const MOOD_LABELS_SHORT = {
  casual: 'Casual', work: 'Work', brunch: 'Brunch', night: 'Night Out', active: 'Active',
};

// 18-item seed wardrobe — covers all 14 clothing types + variety
const SEED_DATA = [
  { id: 's01', name: 'White Button Shirt',  type: 'shirt',    color: '#F0EADF', pattern: 'solid'   },
  { id: 's02', name: 'Striped Blouse',       type: 'blouse',   color: '#B8CCDE', pattern: 'striped' },
  { id: 's03', name: 'Black Tee',            type: 'tshirt',   color: '#2D2D2D', pattern: 'solid'   },
  { id: 's04', name: 'Linen Tank',           type: 'tank',     color: '#E2D4C0', pattern: 'solid'   },
  { id: 's05', name: 'Cream Sweater',        type: 'sweater',  color: '#EEE2D0', pattern: 'solid'   },
  { id: 's06', name: 'Floral Blouse',        type: 'blouse',   color: '#F0AABB', pattern: 'floral'  },
  { id: 's07', name: 'Tailored Trousers',    type: 'pants',    color: '#484038', pattern: 'solid'   },
  { id: 's08', name: 'Blue Jeans',           type: 'jeans',    color: '#4A6898', pattern: 'solid'   },
  { id: 's09', name: 'Midi Skirt',           type: 'skirt',    color: '#C07888', pattern: 'solid'   },
  { id: 's10', name: 'Denim Shorts',         type: 'shorts',   color: '#5A78A8', pattern: 'solid'   },
  { id: 's11', name: 'Floral Sundress',      type: 'dress',    color: '#E8AEC0', pattern: 'floral'  },
  { id: 's12', name: 'Little Black Dress',   type: 'dress',    color: '#1E1E1E', pattern: 'solid'   },
  { id: 's13', name: 'Linen Jumpsuit',       type: 'jumpsuit', color: '#C0B090', pattern: 'solid'   },
  { id: 's14', name: 'Denim Jacket',         type: 'jacket',   color: '#6088B8', pattern: 'solid'   },
  { id: 's15', name: 'Trench Coat',          type: 'coat',     color: '#C8A070', pattern: 'solid'   },
  { id: 's16', name: 'Pink Cardigan',        type: 'cardigan', color: '#E098AA', pattern: 'solid'   },
  { id: 's17', name: 'Black Blazer',         type: 'blazer',   color: '#242424', pattern: 'solid'   },
  { id: 's18', name: 'Plaid Flannel Shirt',  type: 'shirt',    color: '#905858', pattern: 'plaid'   },
];

// ---- Wardrobe CRUD ----

function getWardrobe() {
  try { return JSON.parse(localStorage.getItem(DB_KEY)); } catch { return null; }
}

function setWardrobe(items) {
  localStorage.setItem(DB_KEY, JSON.stringify(items));
}

function initDB() {
  if (getWardrobe() === null) {
    setWardrobe(SEED_DATA.map(s => ({ ...s, coverage: TYPE_COVERAGE[s.type] })));
  }
}

function addItem(item) {
  const wardrobe = getWardrobe() || [];
  item.id = 'u' + Date.now();
  item.coverage = TYPE_COVERAGE[item.type] || 'top';
  wardrobe.push(item);
  setWardrobe(wardrobe);
  return item;
}

function removeItem(id) {
  setWardrobe((getWardrobe() || []).filter(i => i.id !== id));
}

// ---- Outfits ----

function getOutfits() {
  try { return JSON.parse(localStorage.getItem(OUTFITS_KEY)) || []; } catch { return []; }
}

function setOutfits(outfits) {
  localStorage.setItem(OUTFITS_KEY, JSON.stringify(outfits));
}

function toggleSave(outfitId) {
  const outfits = getOutfits();
  const idx = outfits.findIndex(o => o.id === outfitId);
  if (idx > -1) {
    outfits[idx].saved = !outfits[idx].saved;
    setOutfits(outfits);
    return outfits[idx].saved;
  }
  return false;
}

function getFavorites() {
  return getOutfits().filter(o => o.saved);
}

// ---- History ----

function getHistory() {
  try { return JSON.parse(localStorage.getItem(HISTORY_KEY)) || []; } catch { return []; }
}

function addBatch(batch) {
  const history = getHistory();
  history.unshift(batch);
  if (history.length > 60) history.splice(60);
  localStorage.setItem(HISTORY_KEY, JSON.stringify(history));
}

function clearHistory() {
  localStorage.removeItem(HISTORY_KEY);
  // Also remove non-saved outfits
  setOutfits(getOutfits().filter(o => o.saved));
}

// ---- Helpers ----

function uid() {
  return Math.random().toString(36).slice(2, 9) + Date.now().toString(36);
}

function timeAgo(ts) {
  const diff = Date.now() - ts;
  const m = Math.floor(diff / 60000);
  if (m < 1) return 'Just now';
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d === 1) return 'Yesterday';
  return `${d} days ago`;
}

function showToast(msg) {
  const t = document.getElementById('toast');
  if (!t) return;
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.classList.remove('show'), 2200);
}

function resolveItems(itemIds) {
  const map = Object.fromEntries((getWardrobe() || []).map(i => [i.id, i]));
  return itemIds.map(id => map[id]).filter(Boolean);
}

function orderedItems(items) {
  return [
    ...items.filter(i => i.coverage === 'layer'),
    ...items.filter(i => i.coverage === 'top' || i.coverage === 'fullbody'),
    ...items.filter(i => i.coverage === 'bottom'),
  ];
}
