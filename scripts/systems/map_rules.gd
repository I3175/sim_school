class_name MapRules
extends RefCounted
static func available(definition: Dictionary, minute: int, weekday: int, flags: Dictionary) -> bool:
	var required: String = str(definition.get("required_flag", ""))
	if required != "" and not flags.get(required, false):
		return false
	if (definition.get("closed_weekdays", []) as Array).any(func(value: Variant) -> bool: return int(value) == weekday):
		return false
	var opening := int(definition.get("opening", 0))
	var closing := int(definition.get("closing", 0))
	if opening == closing:
		return true
	if weekday == 6:
		return false
	if opening < closing:
		return minute >= opening and minute < closing
	return minute >= opening or minute < closing
