extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $HP/HPBar
@onready var sp_bar: TextureProgressBar = $SP/SPBar

var hp_fill = preload("res://art/ui/PlayerHUD/hp_fill.png")
var hp_fill_low = preload("res://art/ui/PlayerHUD/hp_fill_low.png")

var sp_fill = preload("res://art/ui/PlayerHUD/sp_fill.png")
var sp_fill_exhausted = preload("res://art/ui/PlayerHUD/sp_fill_exhausted.png")

var current_hp: float = 100.0
var max_hp: float = 100.0

var current_stamina: float = 100.0
var max_stamina: float = 100.0


func _ready() -> void:
	update_hp_bar()
	update_stamina_bar()


func update_hp(hp: float, max_health: float) -> void:
	current_hp = hp
	max_hp = max_health

	if is_node_ready():
		update_hp_bar()


func update_stamina(stamina: float, max_stamina_value: float) -> void:
	current_stamina = stamina
	max_stamina = max_stamina_value

	if is_node_ready():
		update_stamina_bar()


func update_hp_bar() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	if current_hp <= max_hp * 0.25:
		hp_bar.texture_progress = hp_fill_low
	else:
		hp_bar.texture_progress = hp_fill


func update_stamina_bar() -> void:
	sp_bar.max_value = max_stamina
	sp_bar.value = current_stamina

	if current_stamina <= 0:
		sp_bar.texture_progress = sp_fill_exhausted
	else:
		sp_bar.texture_progress = sp_fill
