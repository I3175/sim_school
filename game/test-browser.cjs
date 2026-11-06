const {chromium} = require(process.env.PLAYWRIGHT_PATH ||
  'C:/Users/SKYSOFT/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const assert = require('node:assert/strict');

(async () => {
  const browser = await chromium.launch({
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true,
    args: ['--no-sandbox']
  });
  try {
    const page = await browser.newPage({viewport:{width:1280,height:800}});
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('response', response => {
      if (response.status() >= 400 && !response.url().includes('favicon')) {
        errors.push(response.status() + ' ' + response.url());
      }
    });
    const ready = () => page.waitForFunction(() => window.__game?.ready);
    const scene = () => page.evaluate(() => __game.current().id);
    async function use(id) {
      // Try the current position first, then find a collision-free interaction point.
      await page.evaluate(id => {
        const game = __game;
        if (game.nearestObject()?.id === id) return;
        const objects = [...game.current().objects, ...game.current().npcs,
          ...(game.current().id === 'farm' ? game.plots : [])];
        const target = objects.find(object => object.id === id);
        if (!target) throw new Error('Missing interaction ' + id);
        const original = game.state.player;
        for (let dy = 32; dy >= -48; dy -= 8) {
          for (const dx of [0,-8,8,-16,16,-24,24,-32,32]) {
            const x = target.x + dx + (target.action === 'plot' ? 39 : 0);
            const y = target.y + dy + (target.action === 'plot' ? 35 : 0);
            if (x < 30 || y < 55 || x > game.current().width-30 ||
                y > game.current().height-30 || GameCore.collides(x,y,12,game.bounds())) continue;
            game.state.player = {x,y};
            if (game.nearestObject()?.id === id) return;
          }
        }
        game.state.player = original;
        throw new Error('No valid interaction point for ' + id);
      }, id);
      await page.waitForFunction(id => {
        const nearest = __game.nearestObject();
        return nearest?.id === id && document.querySelector('#interaction-title').textContent === nearest.label;
      }, id);
      await page.keyboard.press('e');
    }
    async function enter(id, target) {
      await use(id);
      assert.equal(await scene(), target);
    }
    async function verifyReachability() {
      const failures = await page.evaluate(() => {
        const game = __game, scene = game.current();
        const targets = scene.objects.filter(o => o.action);
        targets.push(...scene.npcs.filter(n => n.portrait));
        if (scene.id === 'farm') targets.push(...game.plots);
        const missing = new Set(targets.map(o => o.id));
        const old = game.state.player;
        const queue = [scene.spawn], visited = new Set();
        for (let i = 0; i < queue.length && missing.size; i++) {
          const {x,y} = queue[i];
          const key = x + ',' + y;
          if (visited.has(key)) continue;
          visited.add(key);
          if (x < 30 || y < 55 || x > scene.width-30 || y > scene.height-30 ||
              GameCore.collides(x,y,12,game.bounds())) continue;
          game.state.player = {x,y};
          const target = game.nearestObject();
          if (target) missing.delete(target.id);
          queue.push({x:x-8,y},{x:x+8,y},{x,y:y-8},{x,y:y+8});
        }
        game.state.player = old;
        return [...missing];
      });
      assert.deepEqual(failures, [], 'Unreachable from ' + await scene());
    }
    async function exit(expected) {
      await use('exit');
      assert.equal(await scene(), expected);
    }
    const greeted = new Set();
    async function verifyNpcDialogs() {
      const ids = await page.evaluate(() => __game.current().npcs.filter(n=>n.portrait).map(n=>n.id));
      for (const id of ids) {
        await use(id);
        await page.locator('#dialog .modal-art').waitFor({state:'visible'});
        const first = await page.locator('#dialog-body p').textContent();
        await page.keyboard.press('Escape');
        await use(id);
        assert.notEqual(await page.locator('#dialog-body p').textContent(),first);
        await page.keyboard.press('Escape');
        greeted.add(id);
      }
    }
    async function switchMap(name, id) {
      await page.keyboard.press('j');
      await page.getByRole('button',{name,exact:true}).click();
      await page.locator('#game-menu').waitFor({state:'hidden'});
      assert.equal(await scene(), id);
    }

    await page.goto('http://127.0.0.1:8937/?test=1');
    await ready();
    const coverage = await page.evaluate(() => {
      const scenes = [...Object.values(__game.maps), ...Object.values(__game.rooms)];
      const assets = new Set(scenes.flatMap(s => s.objects.map(o => o.asset).filter(Boolean)));
      const npcs = scenes.flatMap(s => s.npcs.filter(n => n.portrait));
      return {used:[...assets].filter(id => __game.sprites.has(id)).length, loaded:__game.sprites.size,
        invalid:[...assets].filter(id => !__game.sprites.has(id) && !__game.farmSheets.has(id)),
        npcCount:npcs.length, uniqueNpcs:new Set(npcs.map(n=>n.id)).size,
        missingNpcArt:npcs.filter(n=>[n.sheet,n.idleSheet,n.portrait].some(id=>!__game.farmSheets.has(id))).map(n=>n.id)};
    });
    assert.deepEqual(coverage,{used:112,loaded:112,invalid:[],npcCount:32,uniqueNpcs:32,missingNpcArt:[]});
    await verifyReachability();
    const x = await page.evaluate(() => __game.state.player.x);
    await page.keyboard.down('d');
    await page.waitForTimeout(400);
    await page.keyboard.up('d');
    assert.ok(await page.evaluate(() => __game.state.player.x) > x + 30);
    await verifyNpcDialogs();
    const rooms = await page.evaluate(() => __game.maps.school.objects.filter(o => o.room).map(o => [o.id,o.room]));
    for (const [door,room] of rooms) {
      await enter(door,room);
      await verifyReachability();
      await verifyNpcDialogs();
      if (room === 'main') {
        await enter('classroom:door','classroom');
        await verifyReachability();
        await verifyNpcDialogs();
        await use('lesson-desk');
        await page.getByRole('button',{name:'Ánh sáng, nước và chất dinh dưỡng',exact:true}).click();
        await exit('main');
      }
      if (room === 'library') {
        await use('read-table');
        await page.getByRole('button',{name:'Đọc sách · +20 kiến thức',exact:true}).click();
      }
      await exit('school');
      const restored = await page.evaluate(id => {
        const door = __game.maps.school.objects.find(o => o.id === id);
        const {x,y} = __game.state.player;
        return x === door.x && y === door.y + 32 && !GameCore.collides(x,y,12,__game.bounds());
      },door);
      assert.equal(restored,true);
    }
    await use('school-bus');
    assert.equal(await scene(),'farm');
    await verifyReachability();
    await verifyNpcDialogs();
    assert.equal(await page.evaluate(() => {
      const farm=__game.maps.farm;
      return !GameCore.collides(1952,1056,12,farm.collision) &&
        !GameCore.collides(2192,1240,12,farm.collision) &&
        GameCore.collides(2208,1090,12,farm.collision) &&
        GameCore.collides(2150,580,12,farm.collision);
    }),true,'dock planks are passable, lake and cliff remain blocked');
    await enter('farm-house','farm-greenhouse');
    await verifyReachability();
    await verifyNpcDialogs();
    assert.equal(greeted.size,32);
    await exit('farm');
    await use('farm-bus');
    assert.equal(await scene(),'school');
    await enter('campus-buildings:library-building','library');
    await switchMap('Nông trại','farm');
    assert.equal(await page.evaluate(() => __game.state.player.x === __game.maps.farm.busSpawn.x),true);
    assert.equal(await page.evaluate(() => __game.maps.farm.width),164*16);
    await use('west-dock');
    assert.equal(await page.locator('#dialog').evaluate(dialog => dialog.open),false);
    assert.equal(await page.evaluate(() => __game.state.bait),6);
    await page.keyboard.press('4');
    await use('south-dock');
    assert.equal(await page.evaluate(() => __game.state.bait),5);
    await page.waitForFunction(() => document.querySelector('#fishing-status')?.textContent.startsWith('Cá cắn'));
    await page.keyboard.press('e');
    assert.equal(await page.evaluate(() => Object.values(__game.state.fish).reduce((a,b)=>a+b,0)),1);
    await use('farm-stall');
    await page.getByRole('button',{name:/Mua 5 mồi/}).click();
    await page.getByRole('button',{name:/Bán cá/}).click();
    assert.equal(await page.evaluate(() => __game.state.bait),10);
    assert.deepEqual(await page.evaluate(() => __game.state.fish),{});
    await page.keyboard.press('2');
    await use('plot-0');
    await page.keyboard.press('3');
    await use('plot-0');
    assert.equal(await page.evaluate(() => __game.state.plots[0].watered),true);
    await page.evaluate(() => {
      const steps = Math.ceil(GAME_CONFIG.cropGrowthSeconds * __game.season.growth / .05) + 1;
      for(let i=0;i<steps;i++) __game.tick(.05);
    });
    assert.equal(await page.evaluate(() => __game.state.plots[0].stage),2);
    await page.keyboard.press('1');
    await use('plot-0');
    assert.equal(await page.evaluate(() => __game.state.crops),1);
    await use('farm-stall');
    await page.getByRole('button',{name:/Bán tất cả/}).click();
    assert.equal(await page.evaluate(() => Object.values(__game.state.quests).filter(Boolean).length),6);

    await enter('farm-house','farm-greenhouse');
    await page.keyboard.press('j');
    await page.getByRole('button',{name:/Lưu hành trình/}).click();
    await page.reload();
    await ready();
    assert.equal(await scene(),'farm');
    assert.equal(await page.evaluate(() => {
      const door = __game.maps.farm.objects.find(o => o.id === 'farm-house');
      return __game.state.quests.sell && __game.state.player.x === door.x &&
        __game.state.player.y === door.y + 32;
    }),true);

    await page.evaluate(() => {
      const state = __game.state;
      const {layoutVersion, ...legacy} = JSON.parse(localStorage.getItem(GAME_CONFIG.saveKey));
      legacy.map = 'school';
      legacy.player = {x:35,y:88};
      legacy.coins = state.coins + 11;
      legacy.plots[8] = {stage:1,watered:false,growth:0};
      // Keep the unload save from replacing the fixture.
      const key = GAME_CONFIG.saveKey;
      localStorage.setItem(key, JSON.stringify(legacy));
      Storage.prototype.setItem = () => {};
    });
    await page.reload();
    await ready();
    assert.equal(await page.evaluate(() => {
      const {state,maps} = __game;
      return state.map === 'school' && state.player.x === maps.school.spawn.x &&
        state.player.y === maps.school.spawn.y && state.quests.sell && state.plots[8].stage === 1;
    }),true);
    await page.keyboard.press('Escape');
    assert.equal(await page.evaluate(() => __game.paused),true);
    await page.keyboard.press('Escape');

    for (const [season,name] of [['spring','Mùa xuân'],['summer','Mùa hè'],['autumn','Mùa thu'],['winter','Mùa đông']]) {
      await page.route('**/game/config.js',async route => {
        const response = await route.fetch();
        const body = (await response.text()).replace(/season: '\w+'/, "season: '" + season + "'");
        await route.fulfill({response,body});
      });
      await page.reload();
      await ready();
      assert.equal(await page.evaluate(() => __game.season.name),name);
      await switchMap('Trường học','school');
      await switchMap('Nông trại','farm');
      await page.unroute('**/game/config.js');
    }
    for (const [width,height] of [[1280,800],[1920,1080]]) {
      await page.setViewportSize({width,height});
      assert.deepEqual(await page.locator('#world').boundingBox(),{x:0,y:0,width,height});
      await page.keyboard.press('j');
      await page.locator('#game-menu').waitFor({state:'visible'});
      await page.keyboard.press('Escape');
    }
    assert.deepEqual(errors,[]);
    console.log('PASS: 32 unique NPCs and dialogs, atlas coverage, 14 interiors, 6 quests, fishing, travel, saves, four seasons, two desktop sizes');
  } finally {
    await browser.close();
  }
})().catch(error => {console.error(error);process.exitCode=1;});
