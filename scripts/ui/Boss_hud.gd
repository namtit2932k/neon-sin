extends CanvasLayer


# ==================================================
# REFERENCES
# ==================================================

@onready var hp_bar: TextureProgressBar = $Layout/BossHP


# ==================================================
# HP TEXTURES
# ==================================================

const HP_FILL := preload(
	"res://art/ui/BossHUD/boss_hp_fill.png"
)

const HP_FILL_LOW := preload(
	"res://art/ui/BossHUD/boss_hp_fill_low.png"
)


# ==================================================
# SETTINGS
# ==================================================

@export_range(0.0, 1.0)
var low_hp_threshold: float = 0.3


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	hp_bar.texture_progress = HP_FILL


# ==================================================
# SET BOSS HP
# ==================================================

func set_boss_hp(
	current_hp: float,
	max_hp: float
) -> void:

	# =========================
	# MAX HP
	# =========================

	hp_bar.max_value = max_hp


	# =========================
	# CURRENT HP
	# =========================

	hp_bar.value = clampf(
		current_hp,
		0.0,
		max_hp
	)


	# =========================
	# HP PERCENT
	# =========================

	var hp_percent: float = 0.0

	if max_hp > 0.0:

		hp_percent = current_hp / max_hp


	# =========================
	# CHANGE TEXTURE
	# =========================

	if hp_percent <= low_hp_threshold:

		hp_bar.texture_progress = HP_FILL_LOW

	else:

		hp_bar.texture_progress = HP_FILL
