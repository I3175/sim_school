class_name ItemData
extends Resource
@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var category: String = ""
@export var rarity: int = 0
@export var stack_size: int = 99
@export var sell_price: int = 0
@export var buy_price: int = 0
@export var icon: Texture2D
@export var world_sprite: Texture2D
@export var held_animation: String = ""
@export var equip_slot: String = ""
@export var stat_modifiers: Dictionary = {}
@export var use_effect: Dictionary = {}
@export var tags: Array[String] = []
@export var quality_enabled: bool = false
