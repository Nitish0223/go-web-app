// Tiny renderer for the architecture diagrams. Each page defines window.DIAGRAM =
// { width, height, title, subtitle, groups: [], nodes: [], edges: [] } and loads this file.
// Render to PNG: msedge --headless --screenshot=out.png --window-size=W,H --force-device-scale-factor=2 page.html

(function () {
  const D = window.DIAGRAM;
  const TILE = 64;      // icon tile size (px)
  const LABEL_H = 40;   // room under a tile for its label

  const canvas = document.getElementById('canvas');
  canvas.style.width = D.width + 'px';
  canvas.style.height = D.height + 'px';

  if (D.title) {
    const t = document.createElement('div');
    t.className = 'title';
    t.innerHTML = D.title + (D.subtitle ? `<span>${D.subtitle}</span>` : '');
    canvas.appendChild(t);
  }

  // Dashed boxes that group related components.
  for (const g of D.groups || []) {
    const el = document.createElement('div');
    el.className = 'group' + (g.solid ? ' solid' : '');
    Object.assign(el.style, {
      left: g.x + 'px', top: g.y + 'px', width: g.w + 'px', height: g.h + 'px',
      borderColor: g.color || '#5a6372', background: g.fill || 'transparent',
    });
    const head = document.createElement('div');
    head.className = 'group-title';
    head.style.color = g.color || '#c9d1d9';
    head.innerHTML = (g.badge ? `<b class="badge" style="background:${g.color}">${g.badge}</b>` : '') + g.title;
    el.appendChild(head);
    canvas.appendChild(el);
  }

  // Nodes: an icon tile with a label and an optional sub-label underneath.
  const nodes = {};
  for (const n of D.nodes) {
    nodes[n.id] = n;
    const el = document.createElement('div');
    el.className = 'node';
    el.style.left = n.x - 80 + 'px';
    el.style.top = n.y - TILE / 2 + 'px';
    let tile;
    if (n.icon) {
      tile = `<div class="tile"><img src="icons/${n.icon}.svg"></div>`;
    } else if (n.aws) {
      tile = `<div class="tile aws" style="background:${n.color}">${n.aws}</div>`;
    } else if (n.svg) {
      tile = `<div class="tile" style="${n.tileStyle || ''}">${n.svg}</div>`;
    }
    el.innerHTML = tile +
      `<div class="label">${n.label}</div>` +
      (n.sub ? `<div class="sub">${n.sub}</div>` : '');
    canvas.appendChild(el);
  }

  // Connection point on a side of a node's tile (bottom sits under the label and sub-label lines).
  function anchor(n, side) {
    const h = TILE / 2;
    const subLines = n.sub ? n.sub.split('<br>').length : 0;
    switch (side) {
      case 'l': return [n.x - h - 4, n.y];
      case 'r': return [n.x + h + 4, n.y];
      case 't': return [n.x, n.y - h - 4];
      case 'b': return [n.x, n.y + h + LABEL_H - 6 + subLines * 16];
    }
  }

  function guessSides(a, b) {
    const dx = b.x - a.x, dy = b.y - a.y;
    if (Math.abs(dx) >= Math.abs(dy)) return dx > 0 ? ['r', 'l'] : ['l', 'r'];
    return dy > 0 ? ['b', 't'] : ['t', 'b'];
  }

  const svgNS = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(svgNS, 'svg');
  svg.setAttribute('class', 'edges');
  svg.setAttribute('width', D.width);
  svg.setAttribute('height', D.height);
  svg.innerHTML = `<defs>${['#c9d1d9', '#2ea043', '#f78166', '#58a6ff', '#d29922', '#a371f7']
    .map(c => `<marker id="m${c.slice(1)}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${c}"/></marker>`).join('')}</defs>`;
  canvas.appendChild(svg);

  for (const e of D.edges) {
    const a = nodes[e.from], b = nodes[e.to];
    const [sa, sb] = e.sides || guessSides(a, b);
    const p0 = anchor(a, sa), p1 = anchor(b, sb);
    // Route: straight, or an elbow through explicit waypoints / horizontal-vertical turns.
    let pts = [p0];
    if (e.via) pts.push(...e.via);
    else if (e.route === 'hv') pts.push([p1[0], p0[1]]);
    else if (e.route === 'vh') pts.push([p0[0], p1[1]]);
    pts.push(p1);
    const color = e.color || '#c9d1d9';
    const path = document.createElementNS(svgNS, 'path');
    path.setAttribute('d', 'M' + pts.map(p => p.join(',')).join(' L'));
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', color);
    path.setAttribute('stroke-width', '2');
    path.setAttribute('stroke-linejoin', 'round');
    if (e.dashed !== false) path.setAttribute('stroke-dasharray', '7 6');
    path.setAttribute('marker-end', `url(#m${color.slice(1)})`);
    if (e.both) path.setAttribute('marker-start', `url(#m${color.slice(1)})`);
    svg.appendChild(path);

    if (e.label) {
      // Put the label on the longest segment, or at an explicit position.
      let best = 0, mid = null;
      for (let i = 0; i < pts.length - 1; i++) {
        const len = Math.hypot(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]);
        if (len > best) { best = len; mid = [(pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2]; }
      }
      const [lx, ly] = e.labelAt || mid;
      const lab = document.createElement('div');
      lab.className = 'edge-label';
      lab.style.left = lx + 'px';
      lab.style.top = ly + 'px';
      lab.style.color = color;
      lab.innerHTML = e.label;
      canvas.appendChild(lab);
    }
  }
})();
