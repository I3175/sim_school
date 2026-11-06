// Farm art uses the original frame grids in the bundled reference packs.
(() => {
  const ranch = 'assets/farm-reference/farm-ranch-life/FarmRanchLife/';
  const lite = 'assets/farm-reference/cozy-farm-lite/cozy-farm-lite/';
  const original = 'assets/mam-xanh/';
  const sheets = {};
  const add = (id, path, width, height, sourceX = 0) => {
    sheets[id] = {path, width, height, sourceX};
  };
  for (const {map,id} of window.NPC_CATALOG) {
    const folder = 'assets/characters/' + map + '/' + id + '/';
    add('npc:'+id, folder+'sprites/walk.png',32,32);
    add('npc-idle:'+id, folder+'sprites/idle.png',32,32);
    add('portrait:'+id, folder+'portraits/default.png',64,64);
  }
  for (const [family, breed, size] of [
    ['cow','cow_jersey',32], ['sheep','sheep_brown',32], ['goat','goat_alpine',32],
    ['pig','pig_spotted',32], ['chicken','chicken_speckled',16], ['duck','duck_mallard',16],
    ['rabbit','rabbit_brown',16],
  ]) add('animal:' + family, ranch + '04_Ranch_Animals/' + family + '/' + breed + '_sheet.png', size, size);
  for (const name of ['apple','cherry','orange']) {
    add('orchard:' + name, original + name + '.png', 32, 48);
  }
  for (const name of ['carp','bluegill','sunset_koi']) {
    add('fish:' + name, ranch + '08_Items/fish/' + name + '.png', 16, 16);
  }
  add('fishing:bobber', ranch + '11_Fishing/bobber_float_4f.png', 16, 16);
  add('fishing:rod', ranch + '06_Characters_Tools/Tool_Icons/iron_tier_for_pack1_tools_scythe_hoe_watering_can_axe_pickaxe_fishing_rod.png', 16, 16, 80);
  ['fence-h','fence-v','fence-nw','fence-ne','fence-sw','fence-se','gate-open']
    .forEach((name,i)=>add('fence:'+name, original+'fences.png',16,16,i*16));
  add('ground:soil', original+'soil.png',16,16);
  add('ground:palette', original+'ground.png',16,16);
  add('water:fall', original+'fall.png',16,32);
  add('water:foam', original+'foam.png',48,16);
  for (const name of ['bush','flowers','rock']) {
    add('nature:' + name, lite + 'props/1x/' + name + '.png',16,16);
  }
  window.FARM_ART = sheets;
})();
