// =============================================
// Clo·set — Rule-based Outfit Generator
// =============================================

// Items scored higher for mood-appropriate types/patterns
const MOOD_TYPE_BONUS = {
  casual:  ['tshirt', 'jeans', 'shorts', 'tank', 'cardigan'],
  work:    ['blazer', 'shirt', 'blouse', 'pants', 'skirt'],
  brunch:  ['blouse', 'dress', 'skirt', 'cardigan', 'jumpsuit'],
  night:   ['dress', 'jumpsuit', 'blazer', 'blouse'],
  active:  ['tank', 'tshirt', 'shorts'],
};
const MOOD_PATTERN_BONUS = {
  casual:  ['solid', 'striped', 'printed'],
  work:    ['solid', 'plaid', 'striped'],
  brunch:  ['floral', 'solid', 'striped'],
  night:   ['solid'],
  active:  ['solid', 'striped'],
};

function _score(item, mood) {
  let s = Math.random() * 8;
  if ((MOOD_TYPE_BONUS[mood] || []).includes(item.type)) s += 6;
  if ((MOOD_PATTERN_BONUS[mood] || []).includes(item.pattern)) s += 3;
  if (mood === 'night') {
    const hex = item.color.replace('#','');
    const bright = (parseInt(hex.slice(0,2),16) + parseInt(hex.slice(2,4),16) + parseInt(hex.slice(4,6),16)) / 3;
    if (bright < 110) s += 5;
  }
  return s;
}

function _sortByMood(items, mood) {
  return [...items].sort((a,b) => _score(b,mood) - _score(a,mood));
}

function generateOutfits(wardrobe, mood, count = 4) {
  const tops      = wardrobe.filter(i => i.coverage === 'top');
  const bottoms   = wardrobe.filter(i => i.coverage === 'bottom');
  const fullbodies = wardrobe.filter(i => i.coverage === 'fullbody');
  const layers    = wardrobe.filter(i => i.coverage === 'layer');

  const sTops      = _sortByMood(tops, mood);
  const sBottoms   = _sortByMood(bottoms, mood);
  const sFullbody  = _sortByMood(fullbodies, mood);
  const sLayers    = _sortByMood(layers, mood);

  const canFull   = fullbodies.length > 0;
  const canTopBot = tops.length > 0 && bottoms.length > 0;

  if (!canFull && !canTopBot) return [];

  const outfits = [];
  const usedKeys = new Set();
  let fi = 0, ti = 0, bi = 0, li = 0;
  let attempts = 0;

  while (outfits.length < count && attempts < 40) {
    attempts++;
    let items = null;

    // Alternate: even indexes try fullbody path, odd try top+bottom
    const tryFull = canFull && (outfits.length % 2 === 0 || !canTopBot);

    if (tryFull) {
      const fb = sFullbody[fi % sFullbody.length]; fi++;
      items = [fb];
    } else if (canTopBot) {
      const top = sTops[ti % sTops.length]; ti++;
      const bot = sBottoms[bi % sBottoms.length]; bi++;
      items = [top, bot];
    } else if (canFull) {
      const fb = sFullbody[fi % sFullbody.length]; fi++;
      items = [fb];
    }

    if (!items) continue;

    // Optionally add a layer (60% chance)
    if (sLayers.length > 0 && Math.random() < 0.6) {
      items.push(sLayers[li % sLayers.length]);
      li++;
    }

    const key = items.map(i => i.id).sort().join('|');
    if (usedKeys.has(key)) continue;
    usedKeys.add(key);

    outfits.push({
      id: uid(),
      items: items.map(i => i.id),
      mood,
      timestamp: Date.now(),
      saved: false,
    });
  }

  // Persist outfits + batch to history
  const allOutfits = getOutfits();
  outfits.forEach(o => allOutfits.unshift(o));
  // Keep max 200 outfits
  if (allOutfits.length > 200) allOutfits.splice(200);
  setOutfits(allOutfits);

  addBatch({
    id: uid(),
    mood,
    timestamp: Date.now(),
    outfitIds: outfits.map(o => o.id),
  });

  return outfits;
}
