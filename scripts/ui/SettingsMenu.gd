extends Control


# ==================================================
# SIGNAL
# ==================================================

# The parent screen decides where Back returns to.
signal back_pressed


# ==================================================
# CONSTANTS
# ==================================================

const SETTINGS_PATH := "user://settings.cfg"


# ==================================================
# REFERENCES
# ==================================================

@onready var music_slider: HSlider = $MusicVolume/Slider
@onready var sfx_slider: HSlider = $SFXVolume/Slider
@onready var voice_slider: HSlider = $VoiceVolume/Slider

@onready var back_button: TextureButton = $BackButton


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	# Load before connecting, otherwise the sliders
	# would rewrite the settings file on startup.
	_load_settings()

	back_button.pressed.connect(_on_back_button_pressed)

	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	voice_slider.value_changed.connect(_on_voice_volume_changed)


# ==================================================
# OPEN / CLOSE
# ==================================================

# Shared by the main menu and the pause menu, so the
# scene starts hidden and the parent screen opens it.

func open() -> void:
	visible = true


func close() -> void:
	visible = false


func _on_back_button_pressed() -> void:
	back_pressed.emit()


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


# Sliders are linear 0..1, audio buses work in decibels.
# A slider at zero mutes the bus instead of going silent.
func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index < 0:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


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
		music_slider.value = config.get_value("audio", "music", 1.0)
		sfx_slider.value = config.get_value("audio", "sfx", 1.0)
		voice_slider.value = config.get_value("audio", "voice", 1.0)
	else:
		music_slider.value = 1.0
		sfx_slider.value = 1.0
		voice_slider.value = 1.0

	_set_bus_volume("Music", music_slider.value)
	_set_bus_volume("SFX", sfx_slider.value)
	_set_bus_volume("Voice", voice_slider.value)