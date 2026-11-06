// Paint the ground once per map at a two-world-pixel grid.
window.buildGround = function buildGround(scene, season, seasonId, palette) {
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
  const seasonCol = {spring:0,summer:1,autumn:2,winter:3}[seasonId] ?? 0;
  function stamp(area,row) {
    if (!palette || map !== 'farm') return;
    const {x,y,w,h}=area;
    for (let dy=0;dy<h;dy+=32) for (let dx=0;dx<w;dx+=32) {
      const dw=Math.min(32,w-dx), dh=Math.min(32,h-dy);
      ctx.drawImage(palette,16*seasonCol,16*row,dw/2,dh/2,x+dx,y+dy,dw,dh);
    }
  }
  fill(0, 0, width, height, season.grass);
  stamp({x:0,y:0,w:width,h:height},0);
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
    stamp({x:x+12,y:y+12,w:w-24,h:h-24},1);
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
    const rows = scene.rockRows;
    const grass = seasonId==='winter' ? '#d9e5d4' : seasonId==='autumn' ? '#b4a46a' : '#8eaf65';
    ctx.save();
    ctx.beginPath();
    for (const row of rows) ctx.rect(row.x,row.y,row.w,row.h);
    ctx.clip();
    fill(x,y,w,h,'#796456');
    // Offset vertical rock columns make the cliff face read as layered stone.
    for (let tier=0;tier<3;tier++) {
      const top = y + tier * 224;
      for (let dx=-32;dx<w;dx+=48) {
        const left=x+dx+(tier%2)*24;
        const face= ['#92725a','#a18467','#866c5a'][random(3)];
        fill(left,top,45,224,face);
        fill(left,top,5,224,'#685246');
        fill(left+5,top,7,224,'#ad896b');
        for (let crack=0;crack<5;crack++) {
          const cy=top+22+random(182);
          fill(left+12+random(18),cy,12,3,'#6f5549');
        }
        if (random(3)===0) {
          const mossY=top+45+random(145);
          patch(left+10,mossY,28,19,'#7d9257',5);
        }
      }
      // A scalloped grass lip projects over each rock face.
      for (let dx=0;dx<w;dx+=16) {
        const lip = [16,22,26,20][(dx/16+tier)%4];
        fill(x+dx,top,16,lip+6,'#634a40');
        fill(x+dx,top,16,lip,grass);
        fill(x+dx,top,16,4,'#c1cc84');
      }
    }
    const fall = scene.waterfall;
    const stream = [
      [fall.x-58,y+12,58,176],
      [fall.x-58,y+166,fall.w+58,42],
      [fall.x,y+194,fall.w,fall.y-y-190],
    ];
    for (const [sx,sy,sw,sh] of stream) {
      fill(sx-6,sy,sw+12,sh,'#576d57');
      fill(sx,sy,sw,sh,'#65aeb3');
      fill(sx+8,sy,sw-16,sh,'#438f9d');
      for (let j=0;j<12;j++) fill(sx+8+random(sw-16),sy+random(sh),8,2,'#90ccc1');
    }
    ctx.restore();
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
    for (const {x,y,w,h} of scene.waterRows) fill(x-8,y-5,w+16,h+10,'#9b7655');
    for (const {x,y,w,h} of scene.waterRows) fill(x-4,y-3,w+8,h+6,'#d6ac74');
    for (let i=0;i<scene.waterRows.length;i++) {
      const {x,y,w,h}=scene.waterRows[i];
      fill(x,y,w,h,seasonId==='winter' ? '#a6cbd4' : '#77bfc0');
      if (i>0 && i<26) fill(x+8,y,w-16,h,seasonId==='winter' ? '#81b5c8' : '#53a2ad');
      if (i>1 && i<25) fill(x+20,y,w-40,h,seasonId==='winter' ? '#74a6bd' : '#39889c');
      if (i%4===1) {
        fill(x+7,y+3,12,2,'#b2dbcb');
        fill(x+w-27,y+10,18,2,'#b2dbcb');
      }
      if ([3,7,12,18,23].includes(i)) {
        const bx = i%2 ? x+w+7 : x-13;
        fill(bx,y+5,15,6,'#73925a');
        fill(bx+3,y-10,3,18,'#729257');
        fill(bx+8,y-15,3,22,'#95a46a');
        fill(bx+8,y-15,4,6,'#a47050');
      }
    }
    for (const {x,y,w,h} of scene.docks) {
      fill(x-3,y-3,w+6,h+6,'#72513c');
      fill(x,y,w,h,'#c99860');
      for (let py=y+6;py<y+h;py+=8) {
        fill(x,py,w,2,'#9a6a48');
        fill(x+2,py+2,w-4,1,'#ebbb79');
      }
      for (const px of [x+3,x+w-8]) {
        fill(px,y+2,5,10,'#79513e');
        fill(px,y+2,5,3,'#d9a36b');
      }
    }
  }
  return surface;
};
