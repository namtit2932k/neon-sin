extends Control

# ==================================================
# REFERENCES
# ==================================================

@onready var main_menu_panel: Control = $MainMenuPanel
@onready var settings_panel: Control = $SettingsPanel

@onready var start_button: TextureButton = $MainMenuPanel/StartButton
@onready var settings_button: TextureButton = $MainMenuPanel/SettingsButton
@onready var exit_button: TextureButton = $MainMenuPanel/ExitButton

@onready var back_button: TextureButton = $SettingsPanel/BackButton

@onready var music_slider: HSlider = $SettingsPanel/MusicVolume/Slider
@onready var sfx_slider: HSlider = $SettingsPanel/SFXVolume/Slider
@onready var voice_slider: HSlider = $SettingsPanel/VoiceVolume/Slider

# Nhạc nền menu (bus Music)
@onready var background_music: AudioStreamPlayer = $BackgroundMusic


# ==================================================
# SETTINGS FILE
# ==================================================

# Âm lượng lưu tại user://settings.cfg
# để giữ nguyên sau khi tắt game.

const SETTINGS_PATH := "user://settings.cfg"


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	# Load settings TRƯỚC khi connect signal
	# để tránh ghi file lúc mới khởi động.

	_load_settings()

	# =========================
	# BUTTONS
	# =========================

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# =========================
	# SLIDERS
	# =========================

	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	voice_slider.value_changed.connect(_on_voice_volume_changed)


# ==================================================
# BUTTONS
# ==================================================

func _on_start_pressed() -> void:

	# Vào màn chơi chính.

	get_tree().change_scene_to_file(
		"res://scenes/levels/Level1.tscn"
	)


func _on_settings_pressed() -> void:

	# Ẩn menu chính, hiện settings.

	main_menu_panel.visible = false
	settings_panel.visible = true


func _on_back_pressed() -> void:

	# Quay lại menu chính.

	settings_panel.visible = false
	main_menu_panel.visible = true


func _on_exit_pressed() -> void:

	get_tree().quit()


# ==================================================
# VOLUME
# ==================================================

func _on_music_volume_changed(value: float) -> void:

	_set_bus_volume("Music", value)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:

	_set_bus_volume("SFX", value)
	_save_settings()


func _on_voice_volume_changed(value: float) -> void:

	_set_bus_volume("Voice", value)
	_save_settings()


# Chuyển giá trị slider (0.0 → 1.0)
# thành volume_db cho audio bus.

func _set_bus_volume(bus_name: String, value: float) -> void:

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index < 0:
		return

	if value <= 0.0:

		# Slider về 0 → mute bus.

		AudioServer.set_bus_mute(bus_index, true)

	else:

		AudioServer.set_bus_mute(bus_index, false)

		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(value)
		)


func _get_bus_volume(bus_name: String) -> float:

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index < 0:
		return 1.0

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	return db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)


# ==================================================
# SAVE / LOAD
# ==================================================

func _save_settings() -> void:

	var config := ConfigFile.new()

	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("audio", "voice", voice_slider.value)

	config.save(SETTINGS_PATH)


func _load_settings() -> void:

	var config := ConfigFile.new()

	if config.load(SETTINGS_PATH) == OK:

		music_slider.value = config.get_value(
			"audio", "music", 1.0
		)
		sfx_slider.value = config.get_value(
			"audio", "sfx", 1.0
		)
		voice_slider.value = config.get_value(
			"audio", "voice", 1.0
		)

	else:

		music_slider.value = 1.0
		sfx_slider.value = 1.0
		voice_slider.value = 1.0

	# =========================
	# BACKGROUND MUSIC
	# =========================

	# Bật loop cho nhạc nền menu
	# (import mặc định đang tắt loop).

	if background_music.stream is AudioStreamOggVorbis:

		background_music.stream.loop = true

	background_music.play()


	# Áp dụng volume cho audio bus ngay lúc mở.

	_set_bus_volume("Music", music_slider.value)
	_set_bus_volume("SFX", sfx_slider.value)
	_set_bus_volume("Voice", voice_slider.value)
