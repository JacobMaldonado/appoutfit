// =============================================
// Clo·set — SVG Clothing Silhouettes
// =============================================
// Each function returns an SVG string for a clothing type.
// viewBox is always "0 0 60 70".
// Usage: getSVG(type, color, pattern, uniquePatternId)

function _lighten(hex, amt) {
  const c = hex.replace('#', '');
  const r = Math.min(255, parseInt(c.slice(0,2),16) + amt);
  const g = Math.min(255, parseInt(c.slice(2,4),16) + amt);
  const b = Math.min(255, parseInt(c.slice(4,6),16) + amt);
  return '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('');
}
function _darken(hex, amt) {
  const c = hex.replace('#', '');
  const r = Math.max(0, parseInt(c.slice(0,2),16) - amt);
  const g = Math.max(0, parseInt(c.slice(2,4),16) - amt);
  const b = Math.max(0, parseInt(c.slice(4,6),16) - amt);
  return '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('');
}

function _patternDefs(pid, color, pattern) {
  if (pattern === 'solid') return '';
  const lt = _lighten(color, 35);
  const defs = {
    striped:
      `<defs><pattern id="${pid}" width="7" height="7" patternUnits="userSpaceOnUse">
        <rect width="7" height="7" fill="${color}"/>
        <line x1="0" y1="3.5" x2="7" y2="3.5" stroke="${lt}" stroke-width="2.5"/>
      </pattern></defs>`,
    floral:
      `<defs><pattern id="${pid}" width="11" height="11" patternUnits="userSpaceOnUse">
        <rect width="11" height="11" fill="${color}"/>
        <circle cx="5.5" cy="5.5" r="2" fill="${lt}" opacity="0.75"/>
        <circle cx="1.5" cy="1.5" r="1.1" fill="${lt}" opacity="0.45"/>
        <circle cx="9.5" cy="9.5" r="1.1" fill="${lt}" opacity="0.45"/>
        <circle cx="9.5" cy="1.5" r="0.8" fill="${lt}" opacity="0.35"/>
        <circle cx="1.5" cy="9.5" r="0.8" fill="${lt}" opacity="0.35"/>
      </pattern></defs>`,
    plaid:
      `<defs><pattern id="${pid}" width="10" height="10" patternUnits="userSpaceOnUse">
        <rect width="10" height="10" fill="${color}"/>
        <line x1="5" y1="0" x2="5" y2="10" stroke="${lt}" stroke-width="2.2"/>
        <line x1="0" y1="5" x2="10" y2="5" stroke="${lt}" stroke-width="2.2"/>
      </pattern></defs>`,
    printed:
      `<defs><pattern id="${pid}" width="13" height="13" patternUnits="userSpaceOnUse">
        <rect width="13" height="13" fill="${color}"/>
        <circle cx="4" cy="4" r="1.8" fill="${lt}" opacity="0.6"/>
        <circle cx="10" cy="9" r="1.8" fill="${lt}" opacity="0.6"/>
        <circle cx="10" cy="3" r="1.1" fill="${lt}" opacity="0.4"/>
        <circle cx="4" cy="10" r="1.1" fill="${lt}" opacity="0.4"/>
      </pattern></defs>`,
  };
  return defs[pattern] || '';
}
function _fill(pid, color, pattern) {
  return pattern === 'solid' ? color : `url(#${pid})`;
}
function _svg(inner, vb='0 0 60 70') {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" fill="none">${inner}</svg>`;
}

// ---- TOPS ----

function svgShirt(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,28);
  return _svg(`${d}
    <path d="M14 22L8 13L21 8L25 14Q30 19 35 14L39 8L52 13L46 22L42 22L42 62L18 62L18 22Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M21 8L25 15L30 12L35 15L39 8L30 10Z" fill="${dk}" opacity="0.3"/>
    <path d="M8 13L14 22L18 22L18 17L11 11Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M52 13L46 22L42 22L42 17L49 11Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="30" y1="13" x2="30" y2="61" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <circle cx="30" cy="26" r="1.2" fill="${dk}" opacity="0.5"/>
    <circle cx="30" cy="34" r="1.2" fill="${dk}" opacity="0.5"/>
  `);
}
function svgBlouse(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,28);
  return _svg(`${d}
    <path d="M16 24L9 13L22 8L26 16L26 44Q26 62 30 62Q34 62 34 44L34 16L38 8L51 13L44 24L44 44Q44 66 30 66Q16 66 16 44Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M9 13L7 21L16 26L16 24Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M51 13L53 21L44 26L44 24Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M22 8L26 16L30 21L34 16L38 8L30 11Z" fill="${dk}" opacity="0.28"/>
  `);
}
function svgTshirt(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,28);
  return _svg(`${d}
    <ellipse cx="30" cy="9" rx="8" ry="4" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M22 9L18 21L18 61L42 61L42 21L38 9Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M10 12L18 21L18 17L13 10Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M50 12L42 21L42 17L47 10Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M22 9L10 12L18 21" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M38 9L50 12L42 21" fill="${f}" stroke="${dk}" stroke-width="1"/>
  `);
}
function svgTank(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,28);
  return _svg(`${d}
    <path d="M22 4L22 10Q15 12 14 20L14 62L46 62L46 20Q45 12 38 10L38 4Q34 2 30 2Q26 2 22 4Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M22 4L20 2L26 3L28 8" fill="${f}" stroke="${dk}" stroke-width="1.2" stroke-linecap="round"/>
    <path d="M38 4L40 2L34 3L32 8" fill="${f}" stroke="${dk}" stroke-width="1.2" stroke-linecap="round"/>
    <path d="M14 20Q18 20 20 26" fill="none" stroke="${dk}" stroke-width="0.9"/>
    <path d="M46 20Q42 20 40 26" fill="none" stroke="${dk}" stroke-width="0.9"/>
  `);
}
function svgSweater(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,22);
  return _svg(`${d}
    <ellipse cx="30" cy="10" rx="7" ry="4" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M23 10L13 24L13 64L47 64L47 24L37 10Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M8 13L13 24L13 64L8 64L5 18Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M52 13L47 24L47 64L52 64L55 18Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <rect x="13" y="58" width="34" height="6" rx="1" fill="${dk}" opacity="0.18"/>
    <line x1="16" y1="58" x2="16" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="20" y1="58" x2="20" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="24" y1="58" x2="24" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="28" y1="58" x2="28" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="32" y1="58" x2="32" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="36" y1="58" x2="36" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="40" y1="58" x2="40" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <line x1="44" y1="58" x2="44" y2="64" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
    <rect x="5" y="58" width="8" height="6" rx="1" fill="${dk}" opacity="0.18"/>
    <rect x="47" y="58" width="8" height="6" rx="1" fill="${dk}" opacity="0.18"/>
  `);
}

// ---- BOTTOMS ----

function svgPants(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,28);
  return _svg(`${d}
    <rect x="12" y="4" width="36" height="8" rx="3" fill="${dk}" opacity="0.65"/>
    <path d="M12 10L12 40L24 40L30 34L36 40L48 40L48 10Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="12" y="40" width="17" height="26" rx="4" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="31" y="40" width="17" height="26" rx="4" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="30" y1="10" x2="30" y2="34" stroke="${dk}" stroke-width="0.8" opacity="0.4"/>
    <line x1="26" y1="10" x2="24" y2="14" stroke="${dk}" stroke-width="0.7" opacity="0.3"/>
    <line x1="34" y1="10" x2="36" y2="14" stroke="${dk}" stroke-width="0.7" opacity="0.3"/>
  `);
}
function svgJeans(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,32);
  return _svg(`${d}
    <rect x="12" y="4" width="36" height="7" rx="2" fill="${dk}" opacity="0.8"/>
    <path d="M12 10L12 40L24 40L30 34L36 40L48 40L48 10Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="12" y="40" width="17" height="26" rx="3" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="31" y="40" width="17" height="26" rx="3" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="30" y1="10" x2="30" y2="34" stroke="${dk}" stroke-width="1" opacity="0.55"/>
    <path d="M15 15Q19 12 22 16" fill="none" stroke="${dk}" stroke-width="0.9" opacity="0.55"/>
    <path d="M45 15Q41 12 38 16" fill="none" stroke="${dk}" stroke-width="0.9" opacity="0.55"/>
    <line x1="12" y1="66" x2="29" y2="66" stroke="${dk}" stroke-width="1.5" stroke-linecap="round" opacity="0.4"/>
    <line x1="31" y1="66" x2="48" y2="66" stroke="${dk}" stroke-width="1.5" stroke-linecap="round" opacity="0.4"/>
  `);
}
function svgSkirt(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,26);
  return _svg(`${d}
    <rect x="16" y="4" width="28" height="7" rx="3" fill="${dk}" opacity="0.6"/>
    <path d="M16 10L7 66L53 66L44 10Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="22" y1="14" x2="14" y2="62" stroke="${dk}" stroke-width="0.6" opacity="0.25"/>
    <line x1="38" y1="14" x2="46" y2="62" stroke="${dk}" stroke-width="0.6" opacity="0.25"/>
    <line x1="30" y1="11" x2="30" y2="65" stroke="${dk}" stroke-width="0.6" opacity="0.2"/>
  `);
}
function svgShorts(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,26);
  return _svg(`${d}
    <rect x="12" y="4" width="36" height="7" rx="3" fill="${dk}" opacity="0.7"/>
    <path d="M12 10L12 32L24 32L30 26L36 32L48 32L48 10Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="12" y="32" width="17" height="18" rx="4" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="31" y="32" width="17" height="18" rx="4" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="30" y1="10" x2="30" y2="26" stroke="${dk}" stroke-width="0.8" opacity="0.4"/>
    <line x1="12" y1="50" x2="29" y2="50" stroke="${dk}" stroke-width="1.2" opacity="0.35"/>
    <line x1="31" y1="50" x2="48" y2="50" stroke="${dk}" stroke-width="1.2" opacity="0.35"/>
  `);
}

// ---- FULL BODY ----

function svgDress(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,26);
  return _svg(`${d}
    <path d="M20 7Q16 5 14 11L14 30Q14 35 20 35L40 35Q46 35 46 30L46 11Q44 5 40 7Q36 3 30 3Q24 3 20 7Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M20 7Q21 3 25 3" fill="none" stroke="${dk}" stroke-width="1.3" stroke-linecap="round"/>
    <path d="M40 7Q39 3 35 3" fill="none" stroke="${dk}" stroke-width="1.3" stroke-linecap="round"/>
    <path d="M14 30L7 67L53 67L46 30Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="14" y1="35" x2="46" y2="35" stroke="${dk}" stroke-width="0.8" opacity="0.4"/>
    <line x1="22" y1="38" x2="16" y2="63" stroke="${dk}" stroke-width="0.5" opacity="0.2"/>
    <line x1="38" y1="38" x2="44" y2="63" stroke="${dk}" stroke-width="0.5" opacity="0.2"/>
  `);
}
function svgJumpsuit(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,26);
  return _svg(`${d}
    <path d="M20 8Q16 6 14 12L14 34L46 34L46 12Q44 6 40 8Q36 4 30 4Q24 4 20 8Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="22" y1="4" x2="20" y2="9" stroke="${dk}" stroke-width="2.2" stroke-linecap="round"/>
    <line x1="38" y1="4" x2="40" y2="9" stroke="${dk}" stroke-width="2.2" stroke-linecap="round"/>
    <rect x="14" y="32" width="32" height="5" rx="1" fill="${dk}" opacity="0.2"/>
    <rect x="14" y="36" width="15" height="29" rx="5" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <rect x="31" y="36" width="15" height="29" rx="5" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="30" y1="9" x2="30" y2="36" stroke="${dk}" stroke-width="0.7" opacity="0.35"/>
  `);
}

// ---- LAYERS ----

function svgJacket(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,26);
  return _svg(`${d}
    <path d="M13 22L8 12L22 7L27 18L27 63L13 63Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M47 22L52 12L38 7L33 18L33 63L47 63Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M22 7L27 18L30 14L33 18L38 7L30 12Z" fill="${dk}" opacity="0.35"/>
    <path d="M8 12L13 22L13 63L8 63L5 18Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M52 12L47 22L47 63L52 63L55 18Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="30" y1="14" x2="30" y2="63" stroke="${dk}" stroke-width="1" opacity="0.4"/>
    <circle cx="30" cy="28" r="1.4" fill="${dk}" opacity="0.5"/>
    <circle cx="30" cy="38" r="1.4" fill="${dk}" opacity="0.5"/>
  `);
}
function svgCoat(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,22);
  return _svg(`${d}
    <path d="M13 20L8 10L22 6L26 16L26 67L13 67Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M47 20L52 10L38 6L34 16L34 67L47 67Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M22 6L26 16L30 12L34 16L38 6L30 10Z" fill="${dk}" opacity="0.38"/>
    <path d="M8 10L13 20L13 67L8 67L5 17Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M52 10L47 20L47 67L52 67L55 17Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <circle cx="30" cy="28" r="1.5" fill="${dk}" opacity="0.55"/>
    <circle cx="30" cy="37" r="1.5" fill="${dk}" opacity="0.55"/>
    <circle cx="30" cy="46" r="1.5" fill="${dk}" opacity="0.55"/>
    <line x1="13" y1="38" x2="47" y2="38" stroke="${dk}" stroke-width="2" opacity="0.2"/>
  `);
}
function svgCardigan(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,20);
  return _svg(`${d}
    <path d="M12 22L8 12L22 8L26 16L26 64L12 64Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M48 22L52 12L38 8L34 16L34 64L48 64Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M22 8L26 16L30 13L34 16L38 8L30 11Z" fill="${dk}" opacity="0.24"/>
    <path d="M8 12L12 22L12 64L8 64L5 18Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <path d="M52 12L48 22L48 64L52 64L55 18Z" fill="${f}" stroke="${dk}" stroke-width="1"/>
    <line x1="20" y1="20" x2="20" y2="60" stroke="${dk}" stroke-width="0.5" opacity="0.18"/>
    <line x1="24" y1="20" x2="24" y2="60" stroke="${dk}" stroke-width="0.5" opacity="0.18"/>
    <line x1="36" y1="20" x2="36" y2="60" stroke="${dk}" stroke-width="0.5" opacity="0.18"/>
    <line x1="40" y1="20" x2="40" y2="60" stroke="${dk}" stroke-width="0.5" opacity="0.18"/>
    <line x1="30" y1="13" x2="30" y2="64" stroke="${dk}" stroke-width="1" opacity="0.38"/>
  `);
}
function svgBlazer(c, pat, pid) {
  const d = _patternDefs(pid,c,pat), f = _fill(pid,c,pat), dk = _darken(c,28);
  return _svg(`${d}
    <path d="M13 22L9 11L22 7L27 18L27 64L13 64Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M47 22L51 11L38 7L33 18L33 64L47 64Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M22 7L27 18L30 14L33 18L38 7L30 11Z" fill="${dk}" opacity="0.42"/>
    <path d="M9 11L13 22L13 64L9 64L7 17Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <path d="M51 11L47 22L47 64L51 64L53 17Z" fill="${f}" stroke="${dk}" stroke-width="1.2"/>
    <rect x="14" y="26" width="9" height="6" rx="1" fill="none" stroke="${dk}" stroke-width="0.8" opacity="0.45"/>
    <circle cx="30" cy="34" r="2" fill="${dk}" opacity="0.45"/>
    <line x1="30" y1="14" x2="30" y2="64" stroke="${dk}" stroke-width="0.8" opacity="0.38"/>
  `);
}

// ---- MASTER DISPATCH ----

function getSVG(type, color, pattern, pid) {
  color   = color   || '#CCCCCC';
  pattern = pattern || 'solid';
  pid     = (pid    || type).replace(/[^a-zA-Z0-9_-]/g, '_');
  const map = {
    shirt: svgShirt, blouse: svgBlouse, tshirt: svgTshirt, tank: svgTank,
    sweater: svgSweater, pants: svgPants, jeans: svgJeans, skirt: svgSkirt,
    shorts: svgShorts, dress: svgDress, jumpsuit: svgJumpsuit,
    jacket: svgJacket, coat: svgCoat, cardigan: svgCardigan, blazer: svgBlazer,
  };
  const fn = map[type];
  return fn ? fn(color, pattern, pid) : `<svg viewBox="0 0 60 70" xmlns="http://www.w3.org/2000/svg"><rect x="10" y="10" width="40" height="50" rx="6" fill="${color}" opacity="0.7"/></svg>`;
}
