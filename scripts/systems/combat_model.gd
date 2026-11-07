class_name CombatModel
extends RefCounted
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/combat.json"))

func damage(attack: float, defense: float, variance: float = 1.0, critical: bool = false) -> int:
	var base := maxi(1, roundi(maxf(0.0, attack) * 100.0 / (100.0 + maxf(0.0, defense)) * variance))
	return maxi(1, roundi(base * (float(rules.critical_multiplier) if critical else 1.0)))

func experience(data: MonsterData, resident_level: int, tier: int = 0) -> int:
	var difference := clampf(1.0 + 0.1 * (data.level - resident_level), 0.25, 1.5)
	return roundi(data.base_xp * float(rules.xp_tier_multipliers[clampi(tier, 0, 4)]) * difference)

func roll_loot(data: MonsterData, seed_value: int) -> Array[Dictionary]:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var items: Array[Dictionary] = []
	for entry: Dictionary in data.loot:
		if random.randf() < float(entry.chance):
			items.append({"id": entry.id, "amount": int(entry.amount), "quality": 0})
	return items

func in_attack_arc(origin: Vector2, facing: Vector2, target: Vector2, reach: float, degrees: float) -> bool:
	var offset := target - origin
	if offset.length() > reach:
		return false
	return degrees >= 360.0 or offset == Vector2.ZERO or absf(facing.angle_to(offset)) <= deg_to_rad(degrees / 2.0)
