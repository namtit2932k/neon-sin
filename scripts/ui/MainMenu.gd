extends Control


# ==================================================
# REFERENCES
# ==================================================

@onready var main_menu_panel: Control = $MainMenuPanel
@onready var settings_menu: Control = $SettingsMenu

@onready var start_button: TextureButton = $MainMenuPanel/StartButton
@onready var settings_button: TextureButton = $MainMenuPanel/SettingsButton
@onready var exit_button: TextureButton = $MainMenuPanel/ExitButton

@onready var background_music: AudioStreamPlayer = $BackgroundMusic


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Settings handles its own volume, the menu only
	# opens and closes the shared scene.
	settings_menu.back_pressed.connect(_on_settings_back_pressed)

	# The imported stream has looping disabled by default.
	if background_music.stream is AudioStreamOggVorbis:
		background_music.stream.loop = true

	background_music.play()


# ==================================================
# BUTTONS
# ==================================================

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")


func _on_settings_pressed() -> void:
	main_menu_panel.visible = false
	settings_menu.open()


func _on_settings_back_pressed() -> void:
	settings_menu.close()
	main_menu_panel.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()