extends CanvasLayer


# ==================================================
# CONSTANTS
# ==================================================

const HP_FILL := preload("res://art/ui/BossHUD/boss_hp_fill.png")
const HP_FILL_LOW := preload("res://art/ui/BossHUD/boss_hp_fill_low.png")


# ==================================================
# EXPORTS
# ==================================================

@export_range(0.0, 1.0) var low_hp_threshold: float = 0.3


# ==================================================
# REFERENCES
# ==================================================

@onready var hp_bar: TextureProgressBar = $Layout/BossHP


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	hp_bar.texture_progress = HP_FILL


# ==================================================
# PUBLIC API
# ==================================================

# Connected to the boss health_changed signal.
func set_boss_hp(current_hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = clampf(current_hp, 0.0, max_hp)

	var hp_ratio: float = current_hp / max_hp if max_hp > 0.0 else 0.0

	hp_bar.texture_progress = (
		HP_FILL_LOW if hp_ratio <= low_hp_threshold else HP_FILL
	)