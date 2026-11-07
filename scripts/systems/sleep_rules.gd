class_name SleepRules
extends RefCounted

static func recovery(minute: int) -> float:
	# Clock minute_of_day wraps at midnight; before 06:00 belongs to the old day.
	if minute >= 360 and minute < 1440:
		return 1.0
	var since_midnight := minute % 1440
	return maxf(0.7, 1.0 - floori(since_midnight / 10.0) * 0.05)

static func faint_penalty(coins: int) -> int:
	return mini(500, floori(maxi(0, coins) * 0.05))
