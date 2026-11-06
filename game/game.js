(() => {
  'use strict';
  const C=window.GAME_CONFIG,K=window.GameCore,$=id=>document.getElementById(id);
  const season=K.SEASONS[C.season]||K.SEASONS.spring;
  const canvas=$('world'),g=canvas.getContext('2d'),mini=$('minimap'),mg=mini.getContext('2d');
  const {maps, rooms, plots, version: layoutVersion} = window.WORLD_LAYOUT;
  const characterFiles = [
    'sprite_A_blonde_red.png', 'sprite_B_black_green.png', 'sprite_C_silver_purple.png',
    'sprite_D_orange_teal.png', 'sprite_E_pink_navy.png', 'sprite_F_dark_skin_gray.png',
  ];
  let state = newGame();
  const roomStack = [];
  try {
    const saved = JSON.parse(localStorage.getItem(C.saveKey));
    const map = maps[saved?.map === 'farm' ? 'farm' : 'school'];
    state = K.restore(saved, {...C, worldWidth:map.width, worldHeight:map.height});
    const scene = maps[state.map];
    if (saved?.layoutVersion !== layoutVersion ||
        K.collides(state.player.x, state.player.y, 12, scene.collision)) {
      state.player = {...scene.spawn};
    }
  } catch {
    // Local storage can be unavailable. The game still starts at the entrance.
  }

  function newGame() {
    const fresh = K.fresh(C.startMap);
    fresh.player = {...maps[fresh.map].spawn};
    return fresh;
  }
  const sprites=new Map(),images=new Map(),keys=new Set();
  const farmSheets = new Map();
  let fishing = null;
  const artSource = id => sprites.get(id) || farmSheets.get(id);
  let ready=false,paused=false,time=0,last=0,walkPhase=0,facing=0,moving=false,nearest=null,actionUntil=0,toastUntil=0,transition=0,sound=C.enableSound,audio=null,uiTick=0,saveTick=0;
  let W=1000,H=650,camera={x:0,y:0},zoom=1;
  let particles=[];
  const dialog=$('dialog'), menu=$('game-menu');
  const groundLayers = new Map();
  function setMenu(open) {
    menu.hidden = !open;
    $('journal-toggle').setAttribute('aria-expanded', String(open));
    keys.clear();
    (open ? $('menu-close') : canvas).focus({preventScroll:true});
  }
  function groundLayer() {
    const scene = current();
    if (!groundLayers.has(scene.id)) {
      groundLayers.set(scene.id, buildGround(scene, season, C.season));
    }
    return groundLayers.get(scene.id);
  }
  function drawToolIcons() {
    for (const icon of document.querySelectorAll('[data-icon]')) {
      const source = artSource(icon.dataset.icon);
      if (!source) continue;
      const ctx = icon.getContext('2d');
      const scale = Math.min(28 / source.w, 28 / source.h);
      const w = Math.round(source.w * scale), h = Math.round(source.h * scale);
      ctx.imageSmoothingEnabled = false;
      ctx.drawImage(source.image, source.x, source.y, source.w, source.h,
        Math.round((32 - w) / 2), Math.round((32 - h) / 2), w, h);
    }
  }
  function current() {
    const entry = roomStack.at(-1);
    return entry ? rooms[entry.room] : maps[state.map];
  }
  function bounds() { return current().collision; }
  function updateZoom() {
    const scene = current();
    zoom = scene.floor ? Math.min(2.15, W / (scene.width + 36), H / (scene.height + 118))
      : Math.max(.58, W / 1650, H / scene.height, W / scene.width);
  }
  function cameraTarget() {
    const scene = current();
    const viewW = W / zoom, viewH = H / zoom;
    if (scene.floor) {
      return {x:(scene.width - viewW) / 2, y:(scene.height - viewH) / 2 + 34 / zoom};
    }
    return {
      x:K.clamp(state.player.x - viewW / 2, 0, scene.width - viewW),
      y:K.clamp(state.player.y - viewH * .65, 0, scene.height - viewH)
    };
  }
  function resize() {
    const frame = canvas.getBoundingClientRect();
    W = frame.width;
    H = frame.height;
    const ratio = Math.min(devicePixelRatio || 1, 2);
    canvas.width = Math.round(W * ratio);
    canvas.height = Math.round(H * ratio);
    g.setTransform(ratio,0,0,ratio,0,0);
    updateZoom();
    camera = cameraTarget();
  }
  addEventListener('resize',resize);new ResizeObserver(resize).observe(canvas);
  function loadImage(src){return new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(new Error('Không tải được '+src));im.src=src;});}
  async function load(){let done=0;const total=ASSET_MANIFEST.length+characterFiles.length+Object.keys(FARM_ART).length;const jobs=ASSET_MANIFEST.map(async a=>{const im=await loadImage(a.image);images.set(a.id,im);for(const f of a.frames){const c=document.createElement('canvas');c.width=f.width;c.height=f.height;const ctx=c.getContext('2d');ctx.drawImage(im,f.x,f.y,f.width,f.height,0,0,f.width,f.height);let crop={x:0,y:0,w:f.width,h:f.height};try{const pixels=ctx.getImageData(0,0,c.width,c.height),d=pixels.data;let minX=c.width,minY=c.height,maxX=0,maxY=0;for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){const i=(y*c.width+x)*4;if(d[i+3]<150){d[i+3]=0;continue;}d[i+3]=255;minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}ctx.putImageData(pixels,0,0);if(maxX>=minX)crop={x:minX,y:minY,w:maxX-minX+1,h:maxY-minY+1};}catch{/* file:// may restrict pixel access; the untrimmed frame still renders. */}sprites.set(a.id+':'+f.id,{image:c,...crop});}done++;$('loading-detail').textContent=`Đã chuẩn bị ${done}/${total} bộ hình`;});
    characterFiles.forEach((name,i)=>jobs.push(loadImage('assets/characters/'+name).then(im=>{images.set('character'+i,im);done++;})));
    for (const [id, frame] of Object.entries(FARM_ART)) {
      jobs.push(loadImage(frame.path).then(image => {
        if (image.width < frame.sourceX + frame.width || image.height < frame.height) {
          throw new Error('Sai kích thước sprite ' + id);
        }
        farmSheets.set(id,{image,x:frame.sourceX,y:0,w:frame.width,h:frame.height});
        done++;
      }));
    }
    const results=await Promise.allSettled(jobs),errors=results.filter(r=>r.status==='rejected');if(errors.length){$('loading').innerHTML='<h2>Chưa tải đủ hình ảnh</h2><p>Mở game bằng RUN_GAME.cmd hoặc máy chủ HTTP.</p><p>'+errors.map(e=>e.reason.message).join('<br>')+'</p><button onclick="location.reload()">Thử lại</button>';return;}
    drawToolIcons();ready=true;$('loading').style.display='none';updateMapUI();updateUI();resize();canvas.focus({preventScroll:true});toast('Chào bạn! WASD để đi, E để khám phá.');
  }
  function toast(text){$('toast').textContent=text;$('toast').classList.add('show');toastUntil=time+4;}
  function beep(freq=660){if(!sound)return;try{audio??=new (window.AudioContext||window.webkitAudioContext)();audio.resume();const o=audio.createOscillator(),v=audio.createGain();o.type='sine';o.frequency.value=freq;v.gain.setValueAtTime(.06,audio.currentTime);v.gain.exponentialRampToValueAtTime(.001,audio.currentTime+.15);o.connect(v);v.connect(audio.destination);o.start();o.stop(audio.currentTime+.16);}catch{}}
  function save(show = true) {
    const player = roomStack[0]?.returnTo || state.player;
    try {
      localStorage.setItem(C.saveKey, JSON.stringify({...state, player, layoutVersion}));
      $('save-status').textContent = '✓ Đã lưu hành trình';
      if (show) toast('Đã lưu hành trình trên trình duyệt này.');
    } catch {
      $('save-status').textContent = 'Chưa lưu được';
      if (show) toast('Trình duyệt đang chặn lưu. Bạn vẫn có thể tiếp tục chơi.');
    }
  }
  function updateMapUI(){const m=current();$('location-name').textContent=m.name;$('location-type').textContent=m.tag;$('location-description').textContent=m.subtitle;$('world-location').textContent=state.map==='school'?'● SÂN TRƯỜNG':'● NÔNG TRẠI';document.querySelectorAll('.map-tab').forEach(b=>{b.classList.toggle('active',b.dataset.map===state.map);b.setAttribute('aria-pressed',b.dataset.map===state.map);});$('season-name').textContent=season.name;$('season-icon').textContent=season.icon;$('tip-title').textContent=state.map==='school'?'Bắt đầu từ một lời chào':'Gieo hạt, tưới nước, chờ lớn';$('tip-body').textContent=state.map==='school'?'Ghé tòa chính để học, thư viện để đọc sách. Xe đưa đón bên phải nối đến nông trại.':`Phím 2: gieo hạt. Phím 3: tưới. Cây chín sau ${Math.round(C.cropGrowthSeconds*season.growth)} giây được tưới. Nhấn E để thu hoạch.`;}
  function updateUI(){let n=0;$('quests').innerHTML=K.QUESTS.map(([id,title,desc])=>{const yes=state.quests[id];if(yes)n++;return `<div class="quest ${yes?'done':''}"><span class="quest-check">${yes?'✓':''}</span><div><b>${title}</b><small>${desc}</small></div></div>`;}).join('');$('quest-count').textContent=n+'/6';$('quest-progress').style.width=(n/6*100)+'%';$('xp').textContent=state.xp;$('coins').textContent=state.coins;$('seed-count').textContent=state.seeds;$('crop-count').textContent=state.crops;
    $('bait-count').textContent=state.bait;
    $('fish-count').textContent=Object.values(state.fish).reduce((total,count)=>total+count,0);$('level-label').textContent='Học sinh · Cấp '+(1+Math.floor(state.xp/50));$('harvest-hint').textContent=season.crop+' · '+season.price+' xu / phần';const hours=(C.startHour+state.clock/C.dayLengthSeconds*12)%24;$('day-time').textContent=`Ngày ${state.day} · ${String(Math.floor(hours)).padStart(2,'0')}:${String(Math.floor(hours%1*60)).padStart(2,'0')}`;}
  function arrive(position) {
    state.player = {...position};
    closeDialog();
    nearest = null;
    transition = 1;
    particles = [];
    updateZoom();
    camera = cameraTarget();
    updateMapUI();
    save(false);
    beep(520);
  }
  function travel(target) {
    if (!ready || !Object.hasOwn(maps, target)) return;
    setMenu(false);
    if (target === state.map && !roomStack.length) return;
    roomStack.length = 0;
    state.map = target;
    arrive(current().busSpawn);
    toast(target === 'farm' ? 'Nông trại Mầm Xanh' : 'Trường học Bình Minh');
  }
  function enterRoom(door) {
    const room = rooms[door.room];
    if (!room) return;
    roomStack.push({room: room.id, returnTo: {x:door.x, y:door.y + 32}});
    arrive(room.spawn);
  }
  function exitRoom() {
    const entry = roomStack.pop();
    if (entry) arrive(entry.returnTo);
  }
  function setTool(tool){state.tool=tool;$('tool-label').textContent={hand:'Bàn tay',seed:'Hạt giống',water:'Bình tưới',rod:'Cần câu'}[tool];document.querySelectorAll('.tool').forEach(b=>b.classList.toggle('active',b.dataset.tool===tool));beep(400);}
  function burst(x,y,color,count=16){for(let i=0;i<count;i++)particles.push({x,y,vx:(Math.random()-.5)*100,vy:-30-Math.random()*70,life:.7+Math.random()*.5,max:1.2,color});}
  function showDialog(title,body,buttons=[],tag='MỘT ĐIỀU NHỎ MỖI NGÀY'){setMenu(false);$('dialog-title').textContent=title;$('dialog-tag').textContent=tag;$('dialog-body').innerHTML=body;$('dialog-actions').replaceChildren();for(const b of buttons){const el=document.createElement('button');el.textContent=b.label;el.className=b.secondary?'secondary':'';el.disabled=!!b.disabled;el.onclick=b.click;$('dialog-actions').append(el);}if(!dialog.open)dialog.showModal();}
  function closeDialog(){fishing=null;if(dialog.open)dialog.close();keys.clear();canvas.focus({preventScroll:true});}
  function art(id){const s=sprites.get(id);if(!s)return;const c=document.createElement('canvas');c.className='modal-art';c.width=180;c.height=120;const cx=c.getContext('2d');cx.imageSmoothingEnabled=false;const scale=Math.min(150/s.w,110/s.h);cx.drawImage(s.image,s.x,s.y,s.w,s.h,(180-s.w*scale)/2,120-s.h*scale,s.w*scale,s.h*scale);$('dialog-body').prepend(c);}
  function finishVisit(key,xp,text){if(state.visits[key]===state.day){toast('Bạn đã hoàn thành hoạt động này hôm nay.');return;}state.visits[key]=state.day;state.xp+=xp;K.complete(state,key);closeDialog();updateUI();save(false);toast(text);burst(state.player.x,state.player.y-30,'#f6dc82');beep(880);}
  function interact(target=nearest){if(!ready||paused||dialog.open||!menu.hidden||!target)return;actionUntil=time+.45;const a=target.action;
    if (a==='fish') { startFishing(target); return; }
    if (a==='talk') {
      showDialog(target.label,'<p>'+target.line+'</p>',[{label:'Chào bạn',click:closeDialog}],'NÔNG TRẠI');
      return;
    }
    if (a==='pet') {
      toast('Bạn vuốt ve ' + target.label.toLowerCase() + '.');
      burst(target.x,target.y-24,'#f3a6b2',8);
      return;
    }
    if(a==='enter'){enterRoom(target);return;}
    if(a==='exit'){exitRoom();return;}
    if(a==='plot'){const result=K.plotAction(state,target.index,state.tool);toast(result.message);if(result.ok){burst(target.x+39,target.y+25,result.kind==='water'?'#b8eaff':result.kind==='harvest'?'#f5d681':'#bde58a');beep(650);save(false);updateUI();}return;}
    if(a==='travel'){travel(state.map==='school'?'farm':'school');return;}
    if(a==='lesson'){const done=state.visits.lesson===state.day;showDialog('Tiết học: Một hạt mầm',`<p>${done?'Bạn đã hoàn thành tiết học hôm nay. Hãy ghé thư viện hoặc đến vườn thực hành.':'Cô Mai: “Cây cần gì để lớn lên khỏe mạnh?”'}</p>`+(done?'':'<div id="quiz"></div>'),[{label:'Đóng',click:closeDialog,secondary:true}],'TÒA NHÀ CHÍNH');art('classroom:student-desk');if(!done){['Ánh sáng, nước và chất dinh dưỡng','Chỉ cần bóng tối','Không cần tưới nước'].forEach((label,i)=>{const b=document.createElement('button');b.className='quiz-option';b.textContent=label;b.onclick=()=>{if(i===0)finishVisit('lesson',15,'Chính xác! +25 kiến thức. Hãy thử trồng cây ở farm.');else{b.disabled=true;b.textContent='Thử lại nhé — hãy nghĩ về ánh nắng và nước!';}};$('quiz').append(b);});}return;}
    if(a==='library'){showDialog('Thư viện yên tĩnh','<p>Cuốn sách “Bốn mùa trong khu vườn” kể rằng: mỗi mùa có một màu sắc riêng. Mùa xuân gieo cà rốt, mùa hè trồng cà chua, mùa thu có bí ngô và mùa đông chăm củ cải.</p>',[{label:state.visits.library===state.day?'Đã đọc hôm nay':'Đọc sách · +20 kiến thức',disabled:state.visits.library===state.day,click:()=>finishVisit('library',10,'Một trang sách mới. +20 kiến thức!')},{label:'Để sau',secondary:true,click:closeDialog}],'THƯ VIỆN');art('special-rooms:reading-table');return;}
    if(a==='gym'){showDialog('Một nhịp vận động','<p>Nhấn nút đúng lúc vạch chạy nằm trong vùng xanh để hoàn thành bài tập phản xạ.</p><div style="height:22px;background:#e6e8db;position:relative;border-radius:6px;overflow:hidden"><span style="position:absolute;left:38%;width:24%;height:100%;background:#91af77"></span><i id="gym-marker" style="position:absolute;top:0;height:100%;width:5px;background:#b77849"></i></div>',[{label:'Bắt nhịp',click:()=>{const v=(Math.sin(time*3)+1)/2;if(v>=.38&&v<=.62){finishVisit('gym',15,'Bắt nhịp thành công! +15 kiến thức.');}else toast('Chưa đúng nhịp. Thử lại khi vạch vào vùng xanh.');}},{label:'Rời sân',secondary:true,click:closeDialog}],'NHÀ THỂ CHẤT');if(state.visits.gym===state.day){closeDialog();toast('Bạn đã luyện tập hôm nay.');}return;}
    if(a==='shop'){showShop();return;}
    if(a==='cafeteria'){showDialog('Bữa trưa ấm áp','<p>Một tô phở nóng và vài phút thư giãn. Giá 5 xu. Mỗi ngày có thể dùng một bữa để nhận 5 kiến thức.</p>',[{label:'Ăn trưa · 5 xu',disabled:state.coins<5||state.visits.cafeteria===state.day,click:()=>{state.coins-=5;finishVisit('cafeteria',5,'Bữa trưa ngon lành! +5 kiến thức.');}},{label:'Để sau',secondary:true,click:closeDialog}],'CĂN TIN');art('cafeteria-hallway:pho-bowl');return;}
    if(a==='rest'){showDialog('Nghỉ dưới bóng cây','<p>Bạn có thể sang ngày mới để tiếp tục các hoạt động ở trường. Cây đã tưới sẽ lớn thêm qua đêm.</p>',[{label:'Sang ngày mới',click:()=>{state.day++;state.clock=0;K.grow(state,C.cropGrowthSeconds*season.growth,C.cropGrowthSeconds*season.growth);closeDialog();updateUI();save(false);toast('Chào ngày '+state.day+'!');}},{label:'Ngồi một chút rồi đi',secondary:true,click:closeDialog}]);return;}
    if(a==='honey'){if(state.visits.honey===state.day){toast('Ong đang làm mật. Ngày mai quay lại nhé.');return;}state.visits.honey=state.day;state.coins+=8;save(false);updateUI();burst(target.x,target.y-70,'#ffe098');toast('Thu một hũ mật ong · +8 xu');return;}
    if(a==='jam'||a==='press'){showDialog(a==='jam'?'Mẻ mứt đầu tiên':'Nước ép trong vườn',`<p>Dùng 2 phần nông sản để chế biến, nhận ${season.price*2+10} xu. Các loại nông sản mùa này được quy đổi chung trong bản thử.</p>`,[{label:'Chế biến 2 nông sản',disabled:state.crops<2,click:()=>{state.crops-=2;state.coins+=season.price*2+10;state.xp+=5;closeDialog();updateUI();save(false);burst(target.x,target.y-70,'#ffe8b6');toast('Chế biến thành công! +5 kiến thức.');}},{label:'Đóng',secondary:true,click:closeDialog}]);art(a==='jam'?'farm:jam-stove':'farm:cider-press');return;}
    if(a==='compost'){const has=state.plots.some(p=>p.stage===1&&p.watered);showDialog('Chăm đất, nuôi cây','<p>Dùng phân hữu cơ để thúc các luống đã tưới lớn thêm 8 giây. Giá 5 xu.</p>',[{label:'Bón phân · 5 xu',disabled:state.coins<5||!has,click:()=>{state.coins-=5;K.grow(state,8,C.cropGrowthSeconds*season.growth);closeDialog();updateUI();save(false);toast('Đã bón phân cho các luống đủ nước.');}},{label:'Đóng',secondary:true,click:closeDialog}]);return;}
    if(a==='water'){setTool('water');toast('Đã chọn bình tưới. Nước không giới hạn trong bản thử.');return;}
    if(a==='notice'){showDialog('Lịch trải nghiệm hôm nay','<p>① Tham gia tiết học ở tòa chính.<br>② Đọc sách tại thư viện.<br>③ Sang farm gieo hạt, tưới và thu hoạch.<br>④ Mang nông sản đến quầy để bán.</p><p>Hoàn thành đủ 6 mục trong nhật ký để khám phá trọn vòng chơi của cả hai map.</p>',[{label:'Bắt đầu nào',click:closeDialog}],'BẢNG TIN');return;}
    if(a==='art'){showDialog('Những màu sắc của mùa','<p>Hãy thử pha một màu cho bức tranh về khu vườn. Màu bạn chọn sẽ tạo hiệu ứng khi trở lại sân trường.</p>',[{label:'Màu nắng',click:()=>{closeDialog();burst(state.player.x,state.player.y-40,'#ffdf8b',36);}},{label:'Màu lá',click:()=>{closeDialog();burst(state.player.x,state.player.y-40,'#9ecc88',36);}}],'PHÒNG NGHỆ THUẬT');art('special-rooms:easel');return;}
    if(a==='play'){burst(target.x,target.y-30,'#f8d78b');toast('Một chút vui chơi giữa giờ!');beep(790);return;}
    showDialog(a==='greenhouse'?'Nhà kính Mầm Xanh':'Sổ tay làm vườn',`<p>Mùa này: <b>${season.name}</b>. Cây trồng: <b>${season.crop}</b>.</p><p>Đi đến một luống đất. Chọn hạt giống (2) rồi E để gieo. Chọn bình tưới (3) rồi E để tưới. Đợi ${Math.round(C.cropGrowthSeconds*season.growth)} giây và E để thu hoạch. Mang đến quầy để bán.</p><p>Ở bản thử, cây vẫn có thể trồng trong cả bốn mùa. Mùa được đặt trong game/config.js.</p>`,[{label:'Đã hiểu',click:closeDialog}],'VƯỜN THỰC HÀNH');art('farm:seedling-tray');
  }
  function startFishing(dock) {
    if (state.tool !== 'rod') {
      toast('Chọn cần câu bằng phím 4 rồi nhấn E.');
      return;
    }
    if (!K.castLine(state)) {
      toast('Hết mồi câu. Mua thêm ở quầy nông sản.');
      return;
    }
    fishing = {dock, started:time};
    updateUI();
    save(false);
    showDialog(dock.label,
      '<p id="fishing-status" aria-live="polite">Đang chờ cá cắn câu…</p>' +
      '<div class="fishing-meter"><span></span><i id="fishing-marker"></i></div>' +
      '<p>Mỗi lượt thả dùng 1 mồi. Khi vạch vào vùng xanh, nhấn E để giật cần.</p>',
      [{label:'Giật cần · E',click:reelFish},{label:'Thu dây',secondary:true,click:closeDialog}],
      'CÂU CÁ');
  }
  function fishingPosition() {
    const elapsed = time - fishing.started;
    return elapsed < 1.1 ? null : (Math.sin((elapsed - 1.1) * 3.6 - Math.PI/2) + 1) / 2;
  }
  function reelFish() {
    if (!fishing) return;
    const position = fishingPosition();
    if (position === null) return;
    const dock = fishing.dock;
    closeDialog();
    if (position < .42 || position > .62) {
      toast('Cá thoát mất. Thử lại khi vạch ở vùng xanh.');
      return;
    }
    const id = K.catchFish(state,Math.random());
    updateUI();
    save(false);
    burst(dock.cast.x,dock.cast.y,'#b5e9eb');
    beep(880);
    toast('Câu được ' + K.FISH[id].name.toLowerCase() + '!');
  }
  function showShop() {
    const fish = Object.entries(K.FISH)
      .filter(([id]) => state.fish[id] > 0)
      .map(([id,item]) => item.name + ' × ' + state.fish[id]).join(', ');
    const value = K.fishValue(state);
    const options = [
      {label:'Bán tất cả · '+state.crops*season.price+' xu',disabled:!state.crops,click:()=>{
        const money=K.sell(state,season.price);closeDialog();updateUI();save(false);
        toast('Đã bán nông sản · +'+money+' xu');beep(880);
      }},
      {label:'Mua 5 hạt · 10 xu',disabled:state.coins<10,click:()=>{
        if(K.buySeeds(state)){updateUI();save(false);showShop();}
      }},
      {label:'Mua 5 mồi · 8 xu',disabled:state.coins<8,click:()=>{
        if(K.buyBait(state)){updateUI();save(false);showShop();}
      }},
      {label:'Bán cá · '+value+' xu',disabled:!value,click:()=>{
        const money=K.sellFish(state);updateUI();save(false);closeDialog();
        toast('Đã bán cá · +'+money+' xu');
      }},
      {label:'Tạm biệt',secondary:true,click:closeDialog}
    ];
    showDialog('Quầy nông sản',
      '<p>Nông sản: <b>'+state.crops+'</b> phần '+season.crop.toLowerCase()+
      ' · '+season.price+' xu/phần.</p><p>Mồi câu: '+state.bait+
      ' · Cá trong túi: '+(fish || 'trống')+'.</p>',options,'PHIÊN CHỢ NHỎ');
    art('farm:strawberry-crate');
  }
  function nearestObject() {
    const scene = current();
    const candidates = scene.objects.filter(o => o.action)
      .map(o => ({...o, ix:o.x, iy:o.y + (o.asset ? 20 : 0)}));
    if (scene.id === 'farm') {
      candidates.push(...plots.map(p => ({...p, ix:p.x+39, iy:p.y+35})));
      candidates.push(...scene.npcs.filter(n => n.sheet).map(n => ({
        ...n, label:n.name, action:n.animal ? 'pet' : 'talk', ix:n.x, iy:n.y
      })));
    }
    let best = null, distance = Infinity;
    for (const object of candidates) {
      const dx = state.player.x - object.ix, dy = state.player.y - object.iy;
      const d = Math.hypot(dx, dy);
      const range = scene.floor || object.sheet ? 44 : object.action === 'plot' ? 78 : 88;
      if (d < range && d < distance) {
        best = object;
        distance = d;
      }
    }
    return best;
  }
  function tick(dt){time+=dt;if(time>toastUntil)$('toast').classList.remove('show');if(!ready)return;const active=!paused&&!dialog.open&&menu.hidden&&!document.hidden;if(active){const dx=(keys.has('d')||keys.has('arrowright')?1:0)-(keys.has('a')||keys.has('arrowleft')?1:0),dy=(keys.has('s')||keys.has('arrowdown')?1:0)-(keys.has('w')||keys.has('arrowup')?1:0);moving=K.move(state.player,dx,dy,dt,C.playerSpeed*(keys.has('shift')?C.runMultiplier:1),bounds(),current().width,current().height);if(dx||dy)facing=Math.abs(dx)>Math.abs(dy)?dx>0?2:1:dy>0?0:3;if(moving)walkPhase+=dt*(keys.has('shift')?12:8);K.grow(state,dt,C.cropGrowthSeconds*season.growth);state.clock+=dt;if(state.clock>=C.dayLengthSeconds){state.clock=0;state.day++;toast('Chào ngày mới!');}for(const n of current().npcs){const phase = time * (n.animal ? .8 : .35) + n.origin;
      const next=n.origin+Math.sin(phase)*(n.animal ? 26 : 24);
      if (!K.collides(next,n.y,12,bounds())) n.x=next;
      n.face=Math.cos(phase)>0?2:1;}}else moving=false;
    nearest=nearestObject();$('interaction').style.display=nearest&&!dialog.open&&!paused&&menu.hidden?'flex':'none';if(nearest){$('interaction-title').textContent=nearest.label;$('interaction-desc').textContent=nearest.action==='plot'?(state.plots[nearest.index].stage===2?'Đã chín · Thu hoạch':state.plots[nearest.index].watered?'Đang lớn · '+Math.floor(state.plots[nearest.index].growth/(C.cropGrowthSeconds*season.growth)*100)+'%':'Gieo hạt / tưới nước'):'Nhấn E để khám phá';}
    for(const p of particles){p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=80*dt;p.life-=dt;}particles=particles.filter(p=>p.life>0);transition=Math.max(0,transition-dt*2.5);
    const target = cameraTarget();
    camera.x += (target.x - camera.x) * Math.min(1, dt * 8);
    camera.y += (target.y - camera.y) * Math.min(1, dt * 8);
    if (fishing && dialog.open) {
      const position = fishingPosition();
      $('fishing-marker').style.left = (position ?? 0) * 100 + '%';
      const biting = position !== null && position >= .42 && position <= .62;
      const label = position === null ? 'Đang chờ cá cắn câu…' : biting ? 'Cá cắn câu! Nhấn E.' : 'Canh vạch vào vùng xanh.';
      if ($('fishing-status').textContent !== label) $('fishing-status').textContent = label;
    }
    if(dialog.open&&$('gym-marker'))$('gym-marker').style.left=((Math.sin(time*3)+1)*50)+'%';uiTick+=dt;saveTick+=dt;if(uiTick>.25){updateUI();uiTick=0;}if(saveTick>10){save(false);saveTick=0;}
  }
  function rect(x,y,w,h,color){g.fillStyle=color;g.fillRect(x,y,w,h);}
  function ellipse(x,y,rx,ry,color){g.fillStyle=color;g.beginPath();g.ellipse(x,y,rx,ry,0,0,Math.PI*2);g.fill();}
  function sprite(id,x,y,w,h,alpha=1){const s=artSource(id);if(!s)return;const scale=Math.min(w/s.w,h/s.h),dw=s.w*scale,dh=s.h*scale;g.save();g.globalAlpha=alpha;g.imageSmoothingEnabled=false;g.drawImage(s.image,s.x,s.y,s.w,s.h,Math.round(x-dw/2),Math.round(y-dh),Math.round(dw),Math.round(dh));g.restore();}
  function terrain() {
    g.imageSmoothingEnabled = false;
    const scene = current();
    g.drawImage(groundLayer(), 0, 0, scene.width, scene.height);
    const pond = scene.pond;
    if (pond) for (let i = 0; i < 7; i++) {
      const x = pond.x + 28 + i * (pond.w - 70) / 6;
      const y = pond.y + pond.h * (.43 + (i % 3) * .07);
      const drift = Math.round(Math.sin(time + i) * 2) * 2;
      rect(x + drift, y, 12 + i % 3 * 4, 2, '#d0e8c987');
    }
    if (scene.lake) drawLake(scene);
    if (scene.id === 'farm') for (const plot of plots) drawPlot(plot);
  }
  function drawLake(scene) {
    const {x,y,w,h} = scene.waterfall;
    rect(x-5,y,w+10,h,'#57645a');
    rect(x,y,w,h,'#59b4c0');
    rect(x+7,y,w-14,h,'#78c9cf');
    for (let i=0;i<14;i++) {
      const yy = y + ((time*142+i*47) % h);
      rect(x+5+i%6*9,yy,3,12+i%4*5,i%3?'#b6e9e1':'#e2f5df');
    }
    for (let i=0;i<10;i++) {
      const offset = (time*18+i*9)%32;
      rect(x-14+i*9,y+h-12+offset,9,3,'#def5e0a8');
    }
    const lake = scene.lake;
    for (let i=0;i<14;i++) {
      const drift = Math.sin(time*1.4+i)*6;
      rect(lake.x+50+i%7*64+drift,lake.y+120+(i%5)*52,14,2,'#a7d8d2a8');
    }
    for (const dock of scene.objects.filter(object=>object.action==='fish')) {
      g.textAlign='center';
      g.font='bold 12px Segoe UI';
      const label = dock.label, width = g.measureText(label).width;
      rect(dock.x-width/2-6,dock.y+18,width+12,19,'#51301deb');
      g.fillStyle='#fff4d5';
      g.fillText(label,dock.x,dock.y+32);
    }
    if (fishing) {
      const cast = fishing.dock.cast;
      g.beginPath();
      g.moveTo(state.player.x,state.player.y-36);
      g.lineTo(cast.x,cast.y);
      g.strokeStyle='#f0dfb9';
      g.lineWidth=1;
      g.stroke();
      const bobber = farmSheets.get('fishing:bobber');
      const frame = Math.floor(time*7)%4;
      g.drawImage(bobber.image,frame*16,0,16,16,cast.x-12,cast.y-12,24,24);
    }
  }
  function drawPlot(p){
    const s=state.plots[p.index];
    const prefix=s.watered ? 'ground:soil-wet-' : 'ground:soil-';
    const edges=['nw','n','ne','w','c','e','sw','s','se'];
    for (let i=0;i<edges.length;i++) {
      const tile=farmSheets.get(prefix+edges[i]);
      const col=i%3,row=Math.floor(i/3);
      const x=p.x+Math.round(col*p.w/3),y=p.y+Math.round(row*p.h/3);
      const w=p.x+Math.round((col+1)*p.w/3)-x,h=p.y+Math.round((row+1)*p.h/3)-y;
      g.drawImage(tile.image,0,0,16,16,x,y,w,h);
    }
    if(nearest?.id===p.id){g.strokeStyle='#fff0b5';g.lineWidth=2;g.strokeRect(p.x-5,p.y-5,p.w+10,p.h+10);}if(s.stage){const progress=s.stage===2?1:Math.max(.15,s.growth/(C.cropGrowthSeconds*season.growth));for(let k=0;k<4;k++){const x=p.x+21+(k%2)*33,y=p.y+25+Math.floor(k/2)*29,sway=Math.sin(time*2+k)*1.8;rect(x-1,y-8-progress*8,3,12+progress*4,'#658c3e');ellipse(x-5+sway,y-9-progress*6,6+progress*2,3,'#89b84b');ellipse(x+5+sway,y-12-progress*6,6+progress*2,3,'#b1d16c');if(progress>.6){const col={spring:'#e5a158',summer:'#d96e50',autumn:'#d99543',winter:'#eee8cc'}[C.season]||'#e5a158';ellipse(x,y,5+progress*3,6+progress*3,col);}}if(s.stage===2){g.fillStyle='#fff0a6';g.font='bold 15px Segoe UI';g.fillText('✦',p.x+58,p.y-5+Math.sin(time*3)*3);}}
  }
  function actor(x,y,face,phase,isMoving,index=0,name=''){ellipse(x,y-2,17,6,'#344a3433');const im=images.get('character'+index);if(!im)return;let col=isMoving?(keys.has('shift')&&index===0?4+Math.floor(phase)%2:1+Math.floor(phase)%3):0,row=face;let lift=0;if(index===0&&time<actionUntil){row=4;col=0;lift=Math.sin((actionUntil-time)*7)*4;}g.imageSmoothingEnabled=false;const size = current().floor ? 50 : 72;
    g.drawImage(im,col*128,row*128,128,128,x-size/2,y-size+3-lift,size,size);if(name){g.font='10px Segoe UI';g.textAlign='center';g.fillStyle='#fff9e5';g.strokeStyle='#3b533a';g.lineWidth=3;g.strokeText(name,x,y-size-1);g.fillText(name,x,y-size-1);}}
  function drawObject(o) {
    if (!o.asset) return;
    if (o.x+o.w<camera.x || o.x-o.w>camera.x+W/zoom ||
        o.y<camera.y || o.y-o.h>camera.y+H/zoom) return;
    if (!o.layer) ellipse(o.x,o.y-3,o.w*.34,Math.min(18,o.w*.08),'#3f583523');
    g.save();
    if (o.tree && C.season === 'autumn') g.filter = 'sepia(.45) saturate(1.2) hue-rotate(-18deg)';
    if (o.tree && C.season === 'winter') g.filter = 'saturate(.25) brightness(1.25)';
    if (o.sway || o.tree) {
      g.translate(o.x,o.y);
      g.rotate(Math.sin(time*1.5+o.x)*.012);
      sprite(o.asset,0,0,o.w,o.h);
    } else if (o.orchard) {
      const sheet = farmSheets.get(o.asset);
      const frame = {spring:2,summer:4,autumn:5,winter:6}[C.season] ?? 2;
      g.drawImage(sheet.image,frame*32,0,32,48,o.x-o.w/2,o.y-o.h,o.w,o.h);
    } else {
      sprite(o.asset,o.x,o.y,o.w,o.h);
    }
    g.restore();
    if (o.label && !current().floor && (o.action === 'enter' || o.action === 'travel' || o.action === 'shop')) {
      g.font = 'bold 12px Segoe UI';
      g.textAlign = 'center';
      const width = g.measureText(o.label).width;
      rect(o.x-width/2-6,o.y+8,width+12,20,'#51301deb');
      g.fillStyle = '#fff4d5';
      g.fillText(o.label,o.x,o.y+23);
    }
    if(o.bees)for(let i=0;i<4;i++){const x=o.x+Math.sin(time*2+i*2)*42,y=o.y-70+Math.cos(time*2.5+i)*25;ellipse(x,y,3,2,'#ffe591');rect(x,y-2,1,4,'#5b4938');}if(o.steam)for(let i=0;i<3;i++){const t=(time*.4+i*.3)%1;ellipse(o.x-20+Math.sin(t*9)*8,o.y-115-t*40,4+t*6,5+t*8,`rgba(255,248,217,${(1-t)*.45})`);}}
  function drawFarmActor(n) {
    const sheet = farmSheets.get(n.sheet);
    const size = n.size || 68;
    const w = size * sheet.w / sheet.h;
    const phase = time * (n.animal ? .8 : .35) + n.origin;
    const walking = Math.abs(Math.cos(phase)) > .32;
    const row = walking ? (n.face === 2 ? 2 : 3) : n.animal ? 4 : 0;
    const col = walking ? Math.floor(time * 7) % 4 : (n.animal ? 0 : 4) + Math.floor(time*2)%2;
    ellipse(n.x,n.y-2,w*.32,4,'#344a3433');
    g.drawImage(sheet.image,col*sheet.w,row*sheet.h,sheet.w,sheet.h,n.x-w/2,n.y-size,w,size);
    if (!n.animal) {
      g.textAlign='center';
      g.font='10px Segoe UI';
      g.strokeStyle='#3b533a';
      g.lineWidth=3;
      g.strokeText(n.name,n.x,n.y-size-3);
      g.fillStyle='#fff9e5';
      g.fillText(n.name,n.x,n.y-size-3);
    }
  }
  function draw(){if(!ready)return;
    const scene = current();
    rect(0,0,W,H,'#30261e');
    g.save();
    g.scale(zoom,zoom);
    g.translate(-camera.x,-camera.y);
    terrain();
    const drawables = [];
    for (const object of scene.objects) {
      if (object.layer === 'ground' || object.layer === 'wall') drawObject(object);
      else drawables.push({y:object.y + (object.layer === 'display' ? 24 : 0),draw:()=>drawObject(object)});
    }
    for(const n of current().npcs)drawables.push({y:n.y,draw:()=>n.sheet ? drawFarmActor(n) : actor(n.x,n.y,n.face,time*5,true,n.color,n.name)});drawables.push({y:state.player.y,draw:()=>actor(state.player.x,state.player.y,facing,walkPhase,moving,0,'Bạn')});drawables.sort((a,b)=>a.y-b.y).forEach(d=>d.draw());for(const p of particles){g.globalAlpha=Math.min(1,p.life);rect(p.x,p.y,4,4,p.color);}g.globalAlpha=1;g.restore();
    if (!scene.floor) for(let i=0;i<25;i++){const x=(i*127+time*(C.season==='winter'?9:17)+Math.sin(time*.6+i)*20)%(W+30)-15,y=(i*79+time*(C.season==='winter'?23:12))%(H+30)-15;g.save();g.translate(x,y);g.rotate(time+i);g.globalAlpha=C.season==='summer'?.25:.55;rect(-2,-1,C.season==='winter'?3:5,3,season.particle);g.restore();}
    if(paused){rect(0,0,W,H,'#15352b77');g.textAlign='center';g.fillStyle='#fff9df';g.font='28px Georgia';g.fillText('Một chút nghỉ ngơi',W/2,H/2);g.font='13px Segoe UI';g.fillText('Nhấn Esc hoặc Tiếp tục',W/2,H/2+30);}if(transition)rect(0,0,W,H,`rgba(250,246,226,${transition})`);if(!menu.hidden)drawMini();}
  function drawMini() {
    const scene = current();
    const scale = Math.min(mini.width/scene.width, mini.height/scene.height);
    const x = (mini.width-scene.width*scale)/2, y = (mini.height-scene.height*scale)/2;
    mg.fillStyle = '#493729';
    mg.fillRect(0,0,mini.width,mini.height);
    mg.save();
    mg.translate(x,y);
    mg.imageSmoothingEnabled = false;
    mg.drawImage(groundLayer(),0,0,scene.width*scale,scene.height*scale);
    for (const o of scene.objects) {
      if (o.action === 'enter' || o.action === 'travel' || o.action === 'exit') {
        mg.fillStyle = o.action === 'travel' ? '#f5b65e' : '#684f33';
        mg.fillRect(o.x*scale-2,o.y*scale-2,5,5);
      } else if (o.asset && !o.layer) {
        mg.fillStyle = o.tree ? '#598048' : '#6a8961';
        mg.fillRect((o.x-o.w/2)*scale,(o.y-o.h*.4)*scale,o.w*scale,o.h*.4*scale);
      }
    }
    mg.fillStyle = '#fff0b6';
    mg.beginPath();
    mg.arc(state.player.x*scale,state.player.y*scale,4,0,Math.PI*2);
    mg.fill();
    mg.restore();
  }
  function togglePause(){if(dialog.open)return;setMenu(false);paused=!paused;keys.clear();$('pause').textContent=paused?'▶ Tiếp tục':'Ⅱ Tạm dừng';document.body.classList.toggle('is-paused',paused);}
  $('journal-toggle').onclick=()=>setMenu(menu.hidden);$('menu-close').onclick=()=>setMenu(false);
  document.querySelectorAll('.map-tab').forEach(b=>b.onclick=()=>travel(b.dataset.map));document.querySelectorAll('.tool').forEach(b=>b.onclick=()=>{setTool(b.dataset.tool);canvas.focus({preventScroll:true});});$('save').onclick=()=>save();$('pause').onclick=togglePause;$('close-dialog').onclick=closeDialog;dialog.addEventListener('close',()=>{keys.clear();fishing=null;});
  $('help').onclick=()=>showDialog('Chào bạn, người bạn mới!','<p><b>WASD / mũi tên:</b> di chuyển · <b>Shift:</b> chạy.<br><b>E:</b> tương tác với điểm gần nhất.<br><b>1 / 2 / 3 / 4:</b> bàn tay, hạt giống, bình tưới, cần câu.<br><b>Esc:</b> đóng cửa sổ / tạm dừng.</p><p>Đi gần cửa tòa nhà hoặc luống đất để thấy gợi ý E. Dùng xe đưa đón hoặc mở nhật ký bằng J để chuyển map.</p><p>Hoàn thành nhật ký 6 việc để test vòng chơi. Tiến độ tự lưu mỗi 10 giây. Đổi mùa trong <b>game/config.js</b> rồi tải lại trang.</p>',[{label:'Đi khám phá',click:closeDialog}],'HƯỚNG DẪN DESKTOP');
  $('sound').onclick=()=>{sound=!sound;$('sound').style.background=sound?'#e0e8ce':'';$('sound').setAttribute('aria-label',sound?'Tắt âm thanh':'Bật âm thanh');toast(sound?'Đã bật hiệu ứng âm thanh.':'Đã tắt âm thanh.');beep();};
  $('reset').onclick=()=>showDialog('Bắt đầu hành trình mới?','<p>Tiến độ của bản desktop trên trình duyệt này sẽ được đặt lại. Bản mobile cũ dùng dữ liệu riêng.</p>',[{label:'Bắt đầu mới',click:()=>{roomStack.length=0;state=newGame();updateZoom();camera=cameraTarget();paused=false;document.body.classList.remove('is-paused');$('pause').textContent='Ⅱ Tạm dừng';setTool('hand');closeDialog();updateMapUI();updateUI();save(false);toast('Một ngày mới đang chờ bạn.');}},{label:'Giữ hành trình',secondary:true,click:closeDialog}]);
  $('fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await document.querySelector('.game-shell').requestFullscreen();}catch{toast('Trình duyệt chưa cho phép toàn màn hình.');}};
  addEventListener('keydown',e=>{if(['INPUT','TEXTAREA','SELECT'].includes(e.target.tagName))return;const key=e.key.toLowerCase();if(['w','a','s','d','arrowup','arrowdown','arrowleft','arrowright',' ','e','1','2','3','4'].includes(key)&&!dialog.open)e.preventDefault();if(key==='escape'){if(dialog.open){e.preventDefault();closeDialog();}else if(!menu.hidden){setMenu(false);}else togglePause();return;}if(dialog.open&&fishing&&key==='e'&&!e.repeat){e.preventDefault();reelFish();return;}if(dialog.open||!ready)return;if(key==='j'&&!e.repeat){setMenu(menu.hidden);return;}if(!menu.hidden)return;if(!e.repeat){if(key==='e')interact();if(key==='1')setTool('hand');if(key==='2')setTool('seed');if(key==='3')setTool('water');if(key==='4')setTool('rod');}keys.add(key);});addEventListener('keyup',e=>keys.delete(e.key.toLowerCase()));addEventListener('blur',()=>keys.clear());document.addEventListener('visibilitychange',()=>{keys.clear();if(document.hidden)save(false);});addEventListener('beforeunload',()=>save(false));
  canvas.addEventListener('pointerdown',()=>canvas.focus({preventScroll:true}));
  if(new URLSearchParams(location.search).has('test'))window.__game={get state(){return state;},get ready(){return ready;},get season(){return season;},maps,rooms,plots,current,travel,interact,nearestObject,bounds,tick,save,closeDialog,setTool,get sprites(){return sprites;},get farmSheets(){return farmSheets;},get camera(){return camera;},get paused(){return paused;}};
  function loop(now){const dt=Math.min((now-last)/1000||0,.05);last=now;tick(dt);draw();requestAnimationFrame(loop);}requestAnimationFrame(loop);load();
})();

