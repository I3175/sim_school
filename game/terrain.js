// Paint the ground once per map at a two-world-pixel grid.
window.buildGround = function buildGround(scene, season, seasonId) {
  const {id: map, pond, lake, ridge, pasture, width, height, roads, courts, floor, walls, water} = scene;
  const surface = document.createElement('canvas');
  surface.width = Math.ceil(width / 2);
  surface.height = Math.ceil(height / 2);
  const ctx = surface.getContext('2d');
  ctx.scale(.5, .5);
  let seed = map === 'farm' ? 521 : 172;
  function random(limit) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return Math.floor(seed / 4294967296 * limit);
  }
  function fill(x, y, w, h, color) {
    ctx.fillStyle = color;
    ctx.fillRect(x, y, w, h);
  }
  function patch(x, y, w, h, color, step = 12) {
    fill(x + step, y, w - 2 * step, h, color);
    fill(x, y + step, w, h - 2 * step, color);
    fill(x + step / 2, y + step / 2, w - step, h - step, color);
  }
  function pebbles(x, y, w, h, count, colors) {
    for (let i = 0; i < count; i++) {
      const px = x + 2 * random(Math.floor(w / 2));
      const py = y + 2 * random(Math.floor(h / 2));
      fill(px, py, 2 + 2 * random(3), 2, colors[random(colors.length)]);
    }
  }
  function stoneCourt(x, y, w, h) {
    patch(x, y + 4, w, h, '#a4875f', 8);
    patch(x, y, w, h, '#d1b88c', 8);
    for (let row = 0; row < Math.floor((h - 16) / 20); row++) {
      const offset = row % 2 ? 14 : 0;
      for (let dx = 8 + offset; dx < w - 12; dx += 30) {
        const dw = Math.min(28, w - dx - 8);
        const dy = y + 8 + row * 20;
        fill(x + dx, dy, dw, 18, ['#e3cea2', '#deca9e', '#e8d3a8'][random(3)]);
        fill(x + dx + 2, dy, dw - 2, 2, '#f2dfb3');
      }
    }
  }
  if (floor) {
    const wood = floor === 'wood' || floor === 'court';
    const base = wood ? '#d4a168' : floor === 'soil' ? '#b48a58' : '#e4cdb0';
    fill(0, 0, width, height, '#52372b');
    fill(12, 32, width - 24, height - 44, base);
    fill(12, 10, width - 24, 30, floor === 'soil' ? '#a4caba' : '#b98462');
    fill(12, 34, width - 24, 6, '#795138');
    const spacing = wood ? 16 : 24;
    for (let y = 40; y < height - 12; y += spacing) {
      fill(12, y, width - 24, 1, '#79513844');
      for (let x = 12 + (wood && (y / spacing | 0) % 2 ? 24 : 0); x < width - 12; x += wood ? 48 : 24) {
        fill(x, y, 1, Math.min(spacing, height - 12 - y), '#79513844');
      }
    }
    if (floor === 'court') {
      ctx.strokeStyle = '#fff1d5';
      ctx.lineWidth = 3;
      ctx.strokeRect(width*.27, 90, width*.46, height-166);
      ctx.strokeRect(width*.41, 90, width*.18, 60);
      ctx.beginPath();
      ctx.arc(width/2, height/2, 30, 0, Math.PI*2);
      ctx.stroke();
    }
    for (const partition of walls) {
      const {x,y,w,h} = partition;
      fill(x,y,w,h,'#8b533b');
      fill(x,y,w,4,'#bd865c');
    }
    if (water) {
      const {x,y,w,h} = water;
      fill(x-4,y-4,w+8,h+8,'#fff4d3');
      fill(x,y,w,h,'#54a5b3');
      fill(x+6,y+6,w-12,h-12,'#398699');
      for (let i=1;i<4;i++) fill(x+12,y+h*i/4,w-24,2,'#b4dfd3');
    }
    const exit = scene.objects.find(o => o.action === 'exit');
    fill(exit.x-20,exit.y-9,40,22,'#ad6950');
    fill(exit.x-16,exit.y-6,32,2,'#e9b281');
    return surface;
  }
  fill(0, 0, width, height, season.grass);
  // Sparse, irregular clusters keep large stretches of grass readable.
  for (let i = 0; i < 540; i++) {
    const x = 2 * random(width / 2), y = 2 * random(height / 2);
    fill(x, y + 4, 12, 4, season.dark);
    fill(x + 2, y, 2, 6, season.light);
    fill(x + 8, y + 2, 2, 6, season.dark);
    if (i % 17 === 0 && seasonId !== 'winter') {
      fill(x + 4, y - 2, 4, 4, season.particle);
      fill(x + 12, y + 2, 4, 4, '#f9dc8e');
    }
  }
  const dirt = seasonId === 'winter' ? '#c9c2a9' : map === 'farm' ? '#dfad68' : '#e2bf85';
  const bank = seasonId === 'winter' ? '#a9ac98' : '#bc8a53';
  for (const {x,y,w,h} of roads) patch(x - 6, y - 6, w + 12, h + 12, bank);
  for (const {x,y,w,h} of roads) patch(x, y, w, h, dirt);
  for (const {x,y,w,h} of roads) {
    pebbles(x + 14, y + 14, w - 28, h - 28, Math.ceil(w*h / 1350),
      [bank, '#f3d49e', dirt]);
  }
  for (const {x,y,w,h} of courts || []) stoneCourt(x,y,w,h);
  if (map === 'farm') {
    patch(812, 570, 316, 310, '#a87547', 20);
    patch(820, 578, 300, 294, '#c48b53', 20);
    pebbles(840, 596, 260, 258, 90, ['#a87247', '#e5ae6a', '#bc824c']);
  }
  if (pasture) {
    patch(pasture.x,pasture.y,pasture.w,pasture.h,season.dark);
    pebbles(pasture.x+12,pasture.y+12,pasture.w-24,pasture.h-24,180,[season.light,season.grass,'#d5b785']);
  }
  if (ridge) {
    const {x,y,w,h} = ridge;
    const cap = seasonId === 'winter' ? '#f2f2df' : '#9db07a';
    // Layered stone faces and grassy shelves follow the stepped mountain profile.
    for (let row = 0; row < h/16; row++) {
      const rise = row / (h/16);
      const inset = Math.round((1-rise) * (1-rise) * w / 2 / 16) * 16;
      const span = Math.max(32,w-inset*2);
      const yy = y+row*16;
      fill(x+(w-span)/2, yy, span,16, ['#6a6455','#807562','#8f8068','#766b59'][row%4]);
      const shelf = row % 6 === 0 || row < 3;
      if (shelf) fill(x+(w-span)/2+4, yy, span-8,6, cap);
      for (let j=0;j<6;j++) {
        fill(x+(w-span)/2+random(span-6),yy+7+random(7),6,2,j%2?'#b3a385':'#574e45');
      }
    }
  }
  // Stepped banks and shallow water share the pond's existing footprint.
  function basin(inset, color) {
    const rx = pond.w / 2 - inset, ry = pond.h / 2 - inset;
    for (let dy = -ry + 2; dy < ry; dy += 4) {
      const span = Math.floor(rx * Math.sqrt(1 - (dy / ry) ** 2) / 4) * 4;
      fill(pond.x + pond.w / 2 - span, pond.y + pond.h / 2 + dy, span * 2, 4, color);
    }
  }
  if (pond) {
    basin(-8, '#946e48');
    basin(-2, '#e2ba80');
    basin(4, seasonId === 'winter' ? '#afcfd9' : '#6cb1ad');
    basin(12, seasonId === 'winter' ? '#8fb5c9' : '#4c969e');
    basin(20, seasonId === 'winter' ? '#94bbcd' : '#448b99');
  }
  if (lake) {
    const {x,y,w,h} = lake;
    patch(x-10,y-10,w+20,h+20,'#8e6b48',38);
    patch(x-4,y-4,w+8,h+8,'#e2bd82',34);
    patch(x,y,w,h,seasonId==='winter' ? '#abcdd5' : '#68aeb2',32);
    patch(x+12,y+12,w-24,h-24,seasonId==='winter' ? '#8cbbcd' : '#3c8f9c',27);
    patch(x+28,y+24,w-56,h-48,seasonId==='winter' ? '#88b3c6' : '#337e93',22);
    for (const dock of scene.objects.filter(object => object.action === 'fish')) {
      const fromWest = dock.x < x;
      const left = fromWest ? dock.x-16 : dock.x-28;
      const top = fromWest ? dock.y-20 : dock.y-68;
      const dw = fromWest ? 90 : 56, dh = fromWest ? 40 : 82;
      fill(left-3,top-3,dw+6,dh+6,'#74543e');
      fill(left,top,dw,dh,'#c79660');
      for (let py=top+6;py<top+dh;py+=8) fill(left,py,dw,2,'#996a43');
    }
  }
  return surface;
};
