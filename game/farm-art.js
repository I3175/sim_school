// Farm art uses the original frame grids in the bundled reference packs.
(() => {
  const ranch = 'assets/farm-reference/farm-ranch-life/FarmRanchLife/';
  const lite = 'assets/farm-reference/cozy-farm-lite/cozy-farm-lite/';
  const sheets = {};
  const add = (id, path, width, height, sourceX = 0) => {
    sheets[id] = {path, width, height, sourceX};
  };
  for (const id of ['fisher','beekeeper','seed_seller','rancher','farmhand_kid','travelling_merchant']) {
    add('npc:' + id, ranch + '07_NPCs/' + id + '_walk_idle_sheet.png', 16, 32);
  }
  for (const [family, breed, size] of [
    ['cow','cow_jersey',32], ['sheep','sheep_brown',32], ['goat','goat_alpine',32],
    ['pig','pig_spotted',32], ['chicken','chicken_speckled',16], ['duck','duck_mallard',16],
    ['rabbit','rabbit_brown',16],
  ]) add('animal:' + family, ranch + '04_Ranch_Animals/' + family + '/' + breed + '_sheet.png', size, size);
  for (const name of ['apple','cherry','orange']) {
    add('orchard:' + name, ranch + '03_Fruit_Trees/' + name + '/' + name + '_tree_states_32x48_7f.png', 32, 48);
  }
  for (const name of ['carp','bluegill','sunset_koi']) {
    add('fish:' + name, ranch + '08_Items/fish/' + name + '.png', 16, 16);
  }
  add('fishing:bobber', ranch + '11_Fishing/bobber_float_4f.png', 16, 16);
  add('fishing:rod', ranch + '06_Characters_Tools/Tool_Icons/iron_tier_for_pack1_tools_scythe_hoe_watering_can_axe_pickaxe_fishing_rod.png', 16, 16, 80);
  for (const name of ['fence-h','fence-v','fence-nw','fence-ne','fence-sw','fence-se','gate-open']) {
    add('fence:' + name, lite + 'fences/1x/' + name + '.png', 16, 16);
  }
  for (const wet of [false,true]) {
    for (const edge of ['nw','n','ne','w','c','e','sw','s','se']) {
      const name = (wet ? 'soil-wet-' : 'soil-') + edge;
      add('ground:' + name, lite + 'tiles/1x/tile-' + name + '.png',16,16);
    }
  }
  for (const name of ['bush','flowers','rock']) {
    add('nature:' + name, lite + 'props/1x/' + name + '.png',16,16);
  }
  window.FARM_ART = sheets;
})();
