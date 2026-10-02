extends Control

# ==================================================
# REFERENCES
# ==================================================

@onready var main_menu_panel: Control = $MainMenuPanel
@onready var settings_menu: Control = $SettingsMenu

@onready var start_button: TextureButton = $MainMenuPanel/StartButton
@onready var settings_button: TextureButton = $MainMenuPanel/SettingsButton
@onready var exit_button: TextureButton = $MainMenuPanel/ExitButton

# Nhạc nền menu (bus Music)
@onready var background_music: AudioStreamPlayer = $BackgroundMusic


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	# =========================
	# BUTTONS
	# =========================

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Settings là scene dùng chung (scenes/menu/SettingsMenu.tscn)
	# tự load/save volume — MainMenu chỉ mở/đóng nó.

	settings_menu.back_pressed.connect(_on_settings_back_pressed)

	# =========================
	# BACKGROUND MUSIC
	# =========================

	# Bật loop cho nhạc nền menu
	# (import mặc định đang tắt loop).

	if background_music.stream is AudioStreamOggVorbis:

		background_music.stream.loop = true

	background_music.play()


# ==================================================
# BUTTONS
# ==================================================

func _on_start_pressed() -> void:

	# Vào màn chơi chính.

	get_tree().change_scene_to_file(
		"res://scenes/levels/Level1.tscn"
	)


func _on_settings_pressed() -> void:

	# Ẩn menu chính, hiện settings dùng chung.

	main_menu_panel.visible = false
	settings_menu.open()


func _on_settings_back_pressed() -> void:

	# Quay lại menu chính.

	settings_menu.close()
	main_menu_panel.visible = true


func _on_exit_pressed() -> void:

	get_tree().quit()
