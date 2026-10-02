extends CanvasLayer


# ==================================================
# CONSTANTS
# ==================================================

const HP_FILL := preload("res://art/ui/PlayerHUD/hp_fill.png")
const HP_FILL_LOW := preload("res://art/ui/PlayerHUD/hp_fill_low.png")
const SP_FILL := preload("res://art/ui/PlayerHUD/sp_fill.png")
const SP_FILL_EXHAUSTED := preload(
	"res://art/ui/PlayerHUD/sp_fill_exhausted.png"
)

# Below this fraction of max HP the bar switches to
# the low health texture.
const LOW_HP_RATIO: float = 0.25


# ==================================================
# STATE
# ==================================================

var current_hp: float = 100.0
var max_hp: float = 100.0
var current_stamina: float = 100.0
var max_stamina: float = 100.0


# ==================================================
# REFERENCES
# ==================================================

@onready var hp_bar: TextureProgressBar = $HP/HPBar
@onready var sp_bar: TextureProgressBar = $SP/SPBar


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	_refresh_hp_bar()
	_refresh_stamina_bar()


# ==================================================
# PUBLIC API
# ==================================================

func update_hp(hp: float, max_value: float) -> void:
	current_hp = hp
	max_hp = max_value

	if is_node_ready():
		_refresh_hp_bar()


func update_stamina(stamina: float, max_value: float) -> void:
	current_stamina = stamina
	max_stamina = max_value

	if is_node_ready():
		_refresh_stamina_bar()


# ==================================================
# BARS
# ==================================================

func _refresh_hp_bar() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	hp_bar.texture_progress = (
		HP_FILL_LOW
		if current_hp <= max_hp * LOW_HP_RATIO
		else HP_FILL
	)


func _refresh_stamina_bar() -> void:
	sp_bar.max_value = max_stamina
	sp_bar.value = current_stamina

	sp_bar.texture_progress = (
		SP_FILL_EXHAUSTED if current_stamina <= 0.0 else SP_FILL
	)