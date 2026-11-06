(() => {
  'use strict';
  const tile = 16;
  const point = (x, y) => ({x: x * tile, y: y * tile});
  const box = (x, y, w, h) => ({...point(x, y), w: w * tile, h: h * tile});
  const sprite = (asset, x, y, w, h, options = {}) => ({
    id: asset, asset, ...box(x, y, w, h), ...options
  });
  const building = (name, x, y, w, h, label, room) => sprite(
    'campus-buildings:' + name, x, y, w, h, room ? {label, action:'enter', room} : {label}
  );
  const outdoor = (name, x, y, w, h, options) => sprite('outdoor:' + name, x, y, w, h, options);
  const farmProp = (name, x, y, w, h, options) => sprite('farm:' + name, x, y, w, h, options);
  const trigger = (id, x, y, label, action, options = {}) => ({
    id, ...point(x, y), label, action, noCollision: true, ...options
  });
  const activity = (id, label, action, options = {}) => ({id, label, action, ...options});
  const wall = {noCollision:true, layer:'wall'};
  const overlay = {noCollision:true, layer:'display'};
  const classroom = (...args) => sprite('classroom:' + args[0], ...args.slice(1));
  const special = (...args) => sprite('special-rooms:' + args[0], ...args.slice(1));
  const cafe = (...args) => sprite('cafeteria-hallway:' + args[0], ...args.slice(1));
  const support = (...args) => sprite('support-interiors:' + args[0], ...args.slice(1));
  function paddock() {
    const fence = (name,x,y,open=false) => sprite('fence:' + name,x,y+1,1,1,{
      noCollision:open, footprint:open ? null : box(x-.5,y,1,1)
    });
    const objects = [];
    for (let x=44; x<=80; x++) {
      const open = x >= 59 && x <= 61;
      objects.push(fence(open ? 'gate-open' : x===44 ? 'fence-nw' : x===80 ? 'fence-ne' : 'fence-h',x,82,open));
      objects.push(fence(x===44 ? 'fence-sw' : x===80 ? 'fence-se' : 'fence-h',x,102));
    }
    for (let y=83; y<102; y++) {
      objects.push(fence('fence-v',44,y),fence('fence-v',80,y));
    }
    return objects;
  }
  const animal = (id, family, name, x, y, size) =>
    ({id, sheet:'animal:'+family, name, ...point(x,y), size, origin:x*tile, face:2, animal:true});
  const maps = {
    school: {
      id:'school', name:'Trường học Bình Minh', tag:'KHUÔN VIÊN',
      subtitle:'Một ngày mới. Những điều nhỏ đang chờ bạn khám phá.',
      width:144*tile, height:104*tile, spawn:point(72,94), busSpawn:point(133,56),
      roads:[
        box(10,26,123,4), box(10,53,128,4), box(12,82,122,4),
        box(70,24,4,75), box(17,24,3,62), box(39,26,3,58),
        box(105,25,3,61), box(124,25,3,61),
        box(91,24,3,7), box(119,24,3,7), box(30,47,3,9), box(17,46,3,10),
        box(105,47,3,9), box(124,47,3,9), box(14,76,3,9), box(30,76,3,9),
        box(44,76,3,9), box(113,76,3,9)
      ],
      courts:[box(55,32,33,15), box(126,49,14,11)],
      objects:[
        building('library-building',18,24,19,17,'Thư viện','library'),
        building('main-building',72,24,23,21,'Tòa nhà chính','main'),
        building('science-building',92,24,17,15,'Phòng thí nghiệm','lab'),
        building('art-building',120,24,18,14,'Phòng nghệ thuật','art'),
        building('gym-building',18,47,20,16,'Nhà thể chất','gym'),
        building('pool-complex',31,47,14,11,'Hồ bơi','pool'),
        building('cafeteria-building',106,47,19,14,'Căn tin','cafeteria'),
        building('auditorium',125,47,17,15,'Hội trường','auditorium'),
        building('dormitory',15,76,18,17,'Ký túc xá','dormitory'),
        building('infirmary',31,76,13,11,'Phòng y tế','infirmary'),
        building('restroom-building',45,76,11,9,'Nhà vệ sinh','restroom'),
        building('greenhouse',114,76,15,13,'Nhà kính trường','school-greenhouse'),
        building('guardhouse',137,67,8,9,'Trạm bảo vệ'),
        building('bicycle-shelter',134,77,12,9,'Nhà xe đạp'),
        building('bus-shelter',137,51,9,8,'Trạm xe buýt'),
        outdoor('school-shuttle',133,54,10,6,activity('school-bus','Đến nông trại','travel')),
        outdoor('school-gate',72,100,13,7,{noCollision:true}),
        classroom('noticeboard',65,43,4,4,activity('school-notice','Bảng tin','notice')),
        outdoor('flagpole',76,40,5,9),
        outdoor('stone-bench',58,46,6,4,activity('bench-1','Ghế nghỉ','rest')),
        outdoor('stone-bench',85,46,6,4,activity('bench-2','Ghế nghỉ','rest')),
        outdoor('mini-soccer-field',35,68,16,11,{layer:'ground',noCollision:true}),
        outdoor('grass-patch',54,72,9,6,{layer:'ground',noCollision:true}),
        outdoor('path-patch',122,94,8,6,{layer:'ground',noCollision:true}),
        outdoor('bicycle',131,79,4,3),
        outdoor('motorbike',137,79,5,4),
        outdoor('slide',89,74,5,7,activity('play-slide','Cầu trượt','play')),
        outdoor('swing',97,74,7,6,activity('play-swing','Xích đu','play',{sway:true})),
        outdoor('seesaw',88,90,6,4,activity('play-seesaw','Bập bênh','play')),
        outdoor('climbing-frame',97,92,6,7),
        outdoor('sandbox',105,94,6,5),
        outdoor('flower-bed',62,36,8,4),
        outdoor('flower-bed',81,36,8,4),
        outdoor('flower-bed',119,91,8,4),
      ],
      npcs:[]
    },
    farm: {
      id:'farm', name:'Nông trại Mầm Xanh', tag:'VƯỜN THỰC HÀNH',
      subtitle:'Gieo một hạt nhỏ. Chờ một niềm vui lớn.',
      width:164*tile, height:112*tile, spawn:point(25,47), busSpawn:point(11,46),
      roads:[
        box(7,43,105,5), box(25,27,5,39), box(90,30,5,38),
        box(47,33,28,3), box(47,33,3,24), box(72,33,3,24),
        box(47,54,28,3), box(46,26,3,8), box(25,59,25,3),
        box(90,29,17,3), box(90,59,19,3), box(10,59,18,3),
        box(108,43,11,5), box(113,43,5,43), box(93,82,56,5),
        box(58,67,5,17), box(60,77,37,4), box(91,59,5,27),
      ],
      pond:box(15,66,19,8),
      lake:box(120,53,34,27),
      ridge:box(119,12,36,42),
      waterfall:box(134,43,4,14),
      docks:[box(118,64,6,4),box(135,76,4,6)],
      pasture:box(44,82,37,21),
      objects:[
        farmProp('greenhouse',27,27,18,18,activity('farm-house','Nhà kính','enter',{room:'farm-greenhouse'})),
        farmProp('potting-bench',49,26,8,8,activity('farm-pot','Bàn làm vườn','guide')),
        farmProp('seedling-tray',57,25,5,4),
        farmProp('farm-stall',91,30,16,14,activity('farm-stall','Quầy nông sản','shop')),
        farmProp('strawberry-crate',84,29,4,4),
        farmProp('carrot-basket',83,33,4,4),
        farmProp('seed-sacks',97,32,4,4),
        farmProp('rain-barrel',40,62,6,7,activity('farm-well','Thùng nước','water')),
        farmProp('watering-can',43,61,3,3),
        farmProp('compost-bin',31,63,7,7,activity('farm-compost','Thùng ủ phân','compost')),
        farmProp('beehive',89,60,8,9,activity('farm-bee','Thùng nuôi ong','honey',{bees:true})),
        farmProp('jam-stove',103,60,8,9,activity('farm-jam','Bếp nấu mứt','jam',{steam:true})),
        farmProp('cider-press',106,29,8,9,activity('farm-press','Máy ép táo','press')),
        farmProp('tool-rack',19,62,7,8,activity('farm-tools','Giá dụng cụ','guide')),
        farmProp('pumpkin-wheelbarrow',76,64,9,7),
        farmProp('scarecrow',70,32,5,8,{sway:true}),
        building('storage-shed',12,60,10,9,'Kho dụng cụ'),
        outdoor('school-shuttle',11,42,9,6,activity('farm-bus','Về trường học','travel')),
        outdoor('flower-bed',83,61,5,3), outdoor('flower-bed',94,63,5,3),
        ...paddock(),
        trigger('west-dock',119,66,'Bến câu phía tây','fish',{cast:point(126,66)}),
        trigger('south-dock',137,81,'Bến câu dưới thác','fish',{cast:point(137,76)}),
        ...[
          ['apple',26,88],['apple',32,88],['cherry',26,96],['cherry',32,96],
          ['orange',88,91],['orange',94,95],['apple',101,96],['cherry',106,91],
          ['cherry',132,17],['apple',142,20],['orange',145,25],
          ['apple',129,33],['cherry',145,34],['orange',153,47],
          ['cherry',155,73],['apple',157,77],
        ].map(([name,x,y]) => sprite('orchard:'+name,x,y,4,6,{orchard:true})),
        ...[
          ['bush',112,50],['flowers',114,58],['rock',117,41],
          ['bush',116,75],['flowers',125,83],['flowers',145,84],
          ['rock',149,50],['rock',153,84],['bush',156,70],
          ['flowers',50,79],['rock',38,82],['bush',40,95],
          ['flowers',29,85],['bush',104,103],['rock',113,99],
        ].map(([name,x,y]) => sprite('nature:'+name,x,y,2,2,{noCollision:true})),
      ],
      npcs:[
        animal('cow-1','cow','Bò sữa',53,90,56),
        animal('sheep-1','sheep','Cừu nâu',67,90,52),
        animal('goat-1','goat','Dê núi',73,95,50),
        animal('pig-1','pig','Heo đốm',57,98,52),
        animal('hen-1','chicken','Gà mái',50,96,31),
        animal('duck-1','duck','Vịt',69,99,32),
        animal('rabbit-1','rabbit','Thỏ nâu',31,101,30),
      ]
    }
  };

  // Sidewalls and furniture use the same footprint data as movement.
  function room(id, name, w, h, floor, objects, options = {}) {
    const exit = trigger('exit', w / 2, h - 2, 'Ra khỏi ' + name.toLowerCase(), 'exit');
    return {
      id, name, tag:'TRONG NHÀ', subtitle:'E để tương tác hoặc ra cửa.',
      width:w*tile, height:h*tile, floor, spawn:point(w / 2, h - 3),
      objects:[...objects, exit], walls:[], npcs:[], ...options
    };
  }

  const rooms = {
    main:room('main','Tòa nhà chính',36,26,'stone',[
      support('reception-desk',8,19,7,5),
      cafe('lockers',6,24,7,3),
      cafe('bench',30,23,6,3),
      cafe('water-dispenser',24,20,2,4),
      support('principal-desk',7,7,6,4),
      support('office-chair',7,5,3,3),
      support('filing-cabinet',3,8,3,4),
      support('printer',11,7,3,3),
      support('safe',12,4,3,3),
      support('meeting-table',27,7,8,5),
      support('coffee-machine',33,7,3,4),
      classroom('door',18,12,3,4,{...wall,label:'Vào lớp học',action:'enter',room:'classroom'}),
      classroom('noticeboard',30,17,5,3,wall),
    ],{walls:[box(1,11,14,1),box(21,11,14,1)]}),
    classroom:room('classroom','Phòng học',20,15,'wood',[
      classroom('chalkboard',10,4,7,3,wall),
      classroom('whiteboard',16,4,4,3,wall),
      classroom('window',4,4,4,3,wall),
      classroom('clock',7,3,2,2,wall),
      classroom('air-conditioner',18,2,3,2,wall),
      classroom('teacher-desk',10,6,5,3,activity('lesson-desk','Bàn giáo viên','lesson')),
      classroom('student-desk',4,9,4,3), classroom('student-chair',4,10,2,2),
      classroom('double-desk',15,9,5,3), classroom('student-chair',15,10,2,2),
      classroom('bookcase',3,6,3,4), classroom('low-bookshelf',17,13,3,2),
      classroom('projector',10,8,2,2,wall), classroom('ceiling-fan',7,7,3,3,wall),
      classroom('trash-bin',3,13,2,2),
    ]),
    library:room('library','Thư viện',30,20,'wood',[
      special('library-shelves',6,6,7,5), special('library-shelves',15,6,7,5),
      special('library-shelves',24,6,7,5), special('lookup-computer',24,11,4,4),
      special('reading-table',13,12,6,4,activity('read-table','Bàn đọc sách','library')),
      special('reading-chair',8,12,3,3), special('reading-chair',18,12,3,3),
      classroom('low-bookshelf',24,16,5,3),
    ]),
    lab:room('lab','Phòng thí nghiệm',20,15,'stone',[
      special('lab-bench',10,7,9,4),
      special('microscope',7,6,3,3,overlay),
      special('test-tubes',10,6,3,3,overlay),
      special('atom-model',13,6,3,3,overlay),
      cafe('handwash-sink',16,9,3,3),
    ]),
    art:room('art','Phòng nghệ thuật',20,15,'wood',[
      special('easel',6,7,4,5,activity('art-easel','Giá vẽ','art')),
      special('paint-palette',6,8,2,2,overlay),
      special('plaster-bust',14,6,4,4),
      special('pottery-wheel',15,10,4,3),
    ]),
    gym:room('gym','Nhà thể chất',40,30,'court',[
      special('basketball-hoop',20,7,5,6,activity('gym-court','Sân tập phản xạ','gym')),
      special('bleachers',7,12,8,6), special('exercise-mat',30,19,6,4,{...overlay,layer:'ground'}),
      special('badminton-racket',34,21,3,3),
    ]),
    cafeteria:room('cafeteria','Căn tin',30,20,'stone',[
      cafe('food-counter',15,7,12,5,activity('lunch-counter','Quầy bữa trưa','cafeteria')),
      cafe('pho-bowl',11,6,2,2,overlay), cafe('banh-mi',13,6,2,2,overlay),
      cafe('sandwich',15,6,2,2,overlay), cafe('milk-and-juice',17,6,2,2,overlay),
      cafe('fruit-basket',19,6,2,2,overlay),
      cafe('refrigerator',5,6,3,4), cafe('microwave',24,5,3,3),
      cafe('drink-machine',26,8,3,4),
      cafe('dining-table',8,13,6,4), cafe('lunch-tray',8,12,2,2,overlay),
      cafe('dining-chair',8,15,3,3), cafe('dining-table',22,13,6,4), cafe('dining-chair',22,15,3,3),
    ]),
    pool:room('pool','Hồ bơi',35,25,'stone',[
      support('lifeguard-chair',29,10,4,6),
      support('shower',6,19,4,5),
      cafe('bench',28,19,5,3),
    ],{water:box(8,5,18,12)}),
    auditorium:room('auditorium','Hội trường',40,30,'wood',[
      support('stage',20,10,21,8), support('podium',20,11,4,4),
      ...[16,20,24].flatMap(y => [11,29].map(x => cafe('bench',x,y,11,3))),
    ]),
    dormitory:room('dormitory','Ký túc xá',30,40,'wood',[
      support('bunk-bed',6,9,5,7), support('bunk-bed',24,9,5,7),
      support('bunk-bed',6,20,5,7), support('bunk-bed',24,20,5,7),
      support('washing-machine',5,32,4,4), support('washing-machine',10,32,4,4),
      cafe('lockers',24,32,7,4),
    ]),
    infirmary:room('infirmary','Phòng y tế',16,12,'stone',[
      support('medical-bed',5,7,4,5), support('medicine-cabinet',11,6,4,4),
    ]),
    restroom:room('restroom','Nhà vệ sinh',14,10,'stone',[
      cafe('handwash-sink',3,5,3,3), support('shower',11,5,3,3),
    ],{walls:[box(8,1,1,4)]}),
    'school-greenhouse':room('school-greenhouse','Nhà kính trường',20,15,'soil',[
      outdoor('flower-bed',5,7,6,4), outdoor('flower-bed',15,7,6,4),
      outdoor('stone-bench',6,11,5,3),
    ]),
    'farm-greenhouse':room('farm-greenhouse','Nhà kính Mầm Xanh',20,15,'soil',[
      farmProp('potting-bench',10,6,6,4),
      farmProp('seedling-tray',5,9,4,3,activity('season-guide','Khay ươm và sổ mùa vụ','greenhouse')),
      farmProp('seedling-tray',15,9,4,3),
    ]),
  };

  // Keep the original positions and indexes so saved plots remain in place.
  const plots = Array.from({length:9}, (_,index) => ({
    id:'plot-'+index, index, x:845+(index%3)*95, y:600+Math.floor(index/3)*95,
    w:78, h:70, label:'Luống '+(index+1), action:'plot'
  }));
  // Shared terrain rows keep the stepped shoreline and collision in agreement.
  function terrainRows(area, insets) {
    return insets.map(([left,right],i)=>({
      x:area.x+left*tile,y:area.y+i*tile,w:area.w-(left+right)*tile,h:tile
    }));
  }
  function withoutDock(row,dock) {
    const left = Math.max(row.x,dock.x), right = Math.min(row.x+row.w,dock.x+dock.w);
    const top = Math.max(row.y,dock.y), bottom = Math.min(row.y+row.h,dock.y+dock.h);
    if (right<=left || bottom<=top) return [row];
    return [
      {x:row.x,y:row.y,w:row.w,h:top-row.y},
      {x:row.x,y:bottom,w:row.w,h:row.y+row.h-bottom},
      {x:row.x,y:top,w:left-row.x,h:bottom-top},
      {x:right,y:top,w:row.x+row.w-right,h:bottom-top}
    ].filter(part=>part.w>0 && part.h>0);
  }
  const farm = maps.farm;
  farm.waterRows = terrainRows(farm.lake,Array.from({length:27},(_,i)=>{
    const edge = Math.min(i,26-i);
    return edge<4 ? [5-edge,5-edge] : [i>19?1:0,i<9?1:0];
  }));
  farm.rockRows = terrainRows(farm.ridge,Array.from({length:42},(_,i)=>{
    const tier=Math.floor(i/14), step=Math.floor((i%14)/4);
    return [Math.max(0,10-tier*4-step), Math.max(0,9-tier*4-step)+(i%14<3?1:0)];
  }));
  const lakeCollision = farm.docks.reduce(
    (rows,dock)=>rows.flatMap(row=>withoutDock(row,dock)),farm.waterRows
  );
  function sceneBounds(scene) {
    const footprints = scene.objects.filter(o => !o.noCollision).map(o => o.footprint || ({
      x:o.x-o.w*.39, y:o.y-o.h*.27, w:o.w*.78, h:o.h*.25
    }));
    return footprints.concat(scene.walls || [], [scene.pond, scene.water].filter(Boolean),
      scene.id==='farm' ? [...scene.rockRows,...lakeCollision] : []);
  }
  for (const scene of [...Object.values(maps), ...Object.values(rooms)]) {
    if (!scene.floor) {
      const across = scene.width / tile;
      const down = scene.height / tile;
      for (let x = 5; x < across - 4; x += 10) {
        scene.objects.push(outdoor('tree', x, 8, 8, 10, {tree:true}));
        if (scene.id === 'farm' || Math.abs(x - 72) > 10) {
          scene.objects.push(outdoor('tree', x, down - 2, 8, 10, {tree:true}));
        }
      }
      for (let y = 18; y < down - 5; y += 10) {
        scene.objects.push(outdoor('tree', 4, y, 7, 9, {tree:true}));
      }
    }
    scene.collision = sceneBounds(scene);
  }
  for (const profile of window.NPC_CATALOG) {
    const scene = maps[profile.scene] || rooms[profile.scene];
    if (!scene) throw new Error('Unknown NPC scene: ' + profile.scene);
    const origin = point(...profile.tile);
    const radius = 12;
    const clear = span => !GameCore.collides(origin.x+span/2,origin.y+span/2,
      radius+span/2,scene.collision);
    const routeSpan = [20,12,0].find(clear) ?? 0;
    scene.npcs.push({
      id:profile.id, name:profile.name, ...origin, origin:origin.x, originY:origin.y,
      face:0, routeSpan, sheet:'npc:'+profile.id, idleSheet:'npc-idle:'+profile.id,
      portrait:'portrait:'+profile.id, lines:profile.dialogue, nextLine:0
    });
  }
  window.WORLD_LAYOUT = {version:2, maps, rooms, plots};
})();
