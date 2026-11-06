// ĐỔI MÙA TẠI ĐÂY rồi tải lại trang. Save không ghi đè cấu hình mùa.
window.GAME_CONFIG = Object.freeze({
  season: 'spring', // 'spring' | 'summer' | 'autumn' | 'winter'
  startMap: 'school',
  cropGrowthSeconds: 18, // thời gian test; chỉ lớn khi đã tưới
  dayLengthSeconds: 720,
  startHour: 8,
  playerSpeed: 170,
  runMultiplier: 1.65,
  saveKey: 'school-sprout-desktop-v1',
  enableSound: false,
});
