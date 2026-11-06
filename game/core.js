(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.GameCore=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const SEASONS={
    spring:{name:'Mùa xuân',icon:'✿',grass:'#9abf72',dark:'#86ac60',light:'#b1cd8a',path:'#dfcea3',leaf:'#76a65b',particle:'#ffe2de',crop:'Cà rốt',price:12,growth:1},
    summer:{name:'Mùa hè',icon:'☀',grass:'#91b65c',dark:'#7fa34d',light:'#a8c771',path:'#e5d39c',leaf:'#5d9449',particle:'#fff2a8',crop:'Cà chua',price:14,growth:.85},
    autumn:{name:'Mùa thu',icon:'❧',grass:'#b3b173',dark:'#a29a61',light:'#c6bc87',path:'#dbbf8e',leaf:'#c38848',particle:'#d79c58',crop:'Bí ngô',price:16,growth:1.1},
    winter:{name:'Mùa đông',icon:'❄',grass:'#dce6de',dark:'#c8d8d1',light:'#eef2e9',path:'#c7c7ba',leaf:'#a2bdb0',particle:'#ffffff',crop:'Củ cải',price:18,growth:1.25}
  };
  const FISH = {
    carp:{name:'Cá chép',price:14},
    bluegill:{name:'Cá rô xanh',price:18},
    sunset_koi:{name:'Cá koi hoàng hôn',price:30}
  };
  const QUESTS=[['lesson','Tiết học đầu tiên','Tòa nhà chính · Trả lời một câu hỏi'],['library','Một trang sách mới','Ghé thư viện và đọc sách'],['plant','Gieo một hy vọng','Farm · Gieo hạt trên luống trống'],['water','Chăm chút mỗi ngày','Tưới nước cho cây đã gieo'],['harvest','Thành quả đầu tiên','Thu hoạch một luống đã chín'],['sell','Phiên chợ nhỏ','Bán nông sản tại quầy']];
  const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
  function fresh(map='school'){return {version:1,map:map==='farm'?'farm':'school',player:{x:map==='farm'?400:960,y:760},coins:30,xp:0,seeds:12,crops:0,bait:6,fish:{},day:1,clock:0,quests:{},plots:Array.from({length:9},()=>({stage:0,watered:false,growth:0})),visits:{},tool:'hand'};}
  function restore(raw,config){const s=fresh(config.startMap);if(!raw||raw.version!==1)return s;for(const key of ['coins','xp','seeds','crops','day','clock'])if(Number.isFinite(raw[key]))s[key]=clamp(raw[key],key==='day'?1:0,key==='clock'?config.dayLengthSeconds:1000000);s.map=['school','farm'].includes(raw.map)?raw.map:s.map;if(raw.player&&Number.isFinite(raw.player.x)&&Number.isFinite(raw.player.y))s.player={x:clamp(raw.player.x,40,config.worldWidth-40),y:clamp(raw.player.y,80,config.worldHeight-40)};for(const [id] of QUESTS)s.quests[id]=raw.quests?.[id]===true;for(const key of ['lesson','library','gym','cafeteria','honey'])if(Number.isFinite(raw.visits?.[key]))s.visits[key]=raw.visits[key];if(Array.isArray(raw.plots)&&raw.plots.length===9)s.plots=raw.plots.map(p=>({stage:clamp(Math.floor(Number(p?.stage)||0),0,2),watered:p?.watered===true,growth:clamp(Number(p?.growth)||0,0,10000)}));if (Number.isFinite(raw.bait)) s.bait = clamp(Math.floor(raw.bait),0,1000000);
    for (const id of Object.keys(FISH)) {
      if (Number.isFinite(raw.fish?.[id])) s.fish[id] = clamp(Math.floor(raw.fish[id]),0,1000000);
    }
    return s;
  }
  function castLine(state) {
    if (state.bait < 1) return false;
    state.bait--;
    return true;
  }
  function catchFish(state, roll) {
    const id = roll < .6 ? 'carp' : roll < .9 ? 'bluegill' : 'sunset_koi';
    state.fish[id] = (state.fish[id] || 0) + 1;
    return id;
  }
  function fishValue(state) {
    return Object.entries(FISH).reduce((sum,[id,fish]) => sum + fish.price * (state.fish[id] || 0),0);
  }
  function sellFish(state) {
    const value = fishValue(state);
    state.coins += value;
    state.fish = {};
    return value;
  }
  function buyBait(state) {
    if (state.coins < 8) return false;
    state.coins -= 8;
    state.bait += 5;
    return true;
  }
  function complete(s,id){if(s.quests[id])return false;s.quests[id]=true;s.xp+=10;return true;}
  function plotAction(s,index,tool){const p=s.plots[index];if(!p)return {ok:false,message:'Không tìm thấy luống.'};if(p.stage===2){s.crops++;s.plots[index]={stage:0,watered:false,growth:0};complete(s,'harvest');return {ok:true,kind:'harvest',message:'Thu hoạch +1 nông sản!'};}if(tool==='seed'){if(p.stage)return {ok:false,message:'Luống này đã có cây. Chọn bình tưới (3).'};if(s.seeds<=0)return {ok:false,message:'Hết hạt giống. Mua thêm ở quầy nông sản.'};s.seeds--;p.stage=1;complete(s,'plant');return {ok:true,kind:'plant',message:'Đã gieo hạt. Chọn bình tưới (3) để chăm cây.'};}if(tool==='water'){if(!p.stage)return {ok:false,message:'Hãy gieo hạt trước (phím 2).'};if(p.watered)return {ok:false,message:'Cây đã đủ nước, hãy đợi lớn.'};p.watered=true;complete(s,'water');return {ok:true,kind:'water',message:'Đã tưới! Cây bắt đầu lớn.'};}return {ok:false,message:p.stage?'Cây đang lớn. Chọn bình tưới (3) nếu đất khô.':'Chọn hạt giống (2), rồi nhấn E để gieo.'};}
  function grow(s,dt,duration){for(const p of s.plots)if(p.stage===1&&p.watered){p.growth+=dt;if(p.growth>=duration){p.stage=2;p.growth=duration;}}}
  function sell(s,price){if(s.crops<1)return 0;const money=s.crops*price;s.coins+=money;s.crops=0;complete(s,'sell');return money;}
  function buySeeds(s){if(s.coins<10)return false;s.coins-=10;s.seeds+=5;return true;}
  function collides(x,y,r,boxes){return boxes.some(b=>x+r>b.x&&x-r<b.x+b.w&&y+r>b.y&&y-r<b.y+b.h);}
  function move(p,dx,dy,dt,speed,boxes,w,h){const len=Math.hypot(dx,dy);if(!len)return false;const vx=dx/len*speed*dt,vy=dy/len*speed*dt;const steps=Math.max(1,Math.ceil(Math.max(Math.abs(vx),Math.abs(vy))/5));let moved=false;for(let i=0;i<steps;i++){const x=clamp(p.x+vx/steps,30,w-30);if(!collides(x,p.y,12,boxes)){moved||=x!==p.x;p.x=x;}const y=clamp(p.y+vy/steps,55,h-30);if(!collides(p.x,y,12,boxes)){moved||=y!==p.y;p.y=y;}}return moved;}
  return {SEASONS,QUESTS,FISH,castLine,catchFish,fishValue,sellFish,buyBait,clamp,fresh,restore,complete,plotAction,grow,sell,buySeeds,collides,move};
});

