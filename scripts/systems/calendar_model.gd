class_name CalendarModel
extends RefCounted
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/calendar.json"))
var total_minutes: float = 360.0
var awaiting_sleep: bool = false
var pauses: Dictionary = {}

func day_index() -> int:
	return maxi(0, floori((total_minutes - float(rules.day_start)) / float(rules.minutes_per_day)))

func season_index() -> int:
	return (day_index() / int(rules.days_per_season)) % int(rules.seasons_per_year)

func year() -> int:
	return day_index() / (int(rules.days_per_season) * int(rules.seasons_per_year)) + 1

func day_of_season() -> int:
	return day_index() % int(rules.days_per_season) + 1

func minute_of_day() -> int:
	return int(total_minutes) % int(rules.minutes_per_day)

func set_paused(reason: String, paused: bool) -> void:
	if paused:
		pauses[reason] = true
	else:
		pauses.erase(reason)

func advance(real_seconds: float) -> Dictionary:
	var before := int(total_minutes)
	if not pauses.is_empty() or awaiting_sleep or real_seconds <= 0.0:
		return {"before": before, "after": before, "forced": false}
	var deadline: float = day_index() * int(rules.minutes_per_day) + int(rules.forced_sleep)
	total_minutes = minf(deadline, total_minutes + real_seconds * float(rules.minutes_per_day) / float(rules.real_seconds_per_day))
	awaiting_sleep = total_minutes >= deadline
	return {"before": before, "after": int(total_minutes), "forced": awaiting_sleep}

func sleep() -> void:
	total_minutes = (day_index() + 1) * int(rules.minutes_per_day) + int(rules.day_start)
	awaiting_sleep = false

func snapshot() -> Dictionary:
	return {"total_game_minutes": total_minutes, "awaiting_sleep": awaiting_sleep}

func restore(state: Dictionary) -> void:
	total_minutes = maxf(float(rules.day_start), float(state.get("total_game_minutes", rules.day_start)))
	awaiting_sleep = bool(state.get("awaiting_sleep", false))
	pauses.clear()
