extends CanvasLayer


# ==================================================
# REFERENCES
# ==================================================

@onready var pause_panel: Control = $Root/Panel
@onready var settings_menu: Control = $Root/Settings


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	visible = false


# ==================================================
# INPUT
# ==================================================

# process_mode is ALWAYS, so Escape still works while
# the tree is paused.
#   settings open -> close settings
#   paused       -> resume
#   playing      -> pause

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	get_viewport().set_input_as_handled()

	if settings_menu.visible:
		settings_menu.close()
	elif visible:
		_close_pause()
	else:
		_open_pause()


# ==================================================
# OPEN / CLOSE
# ==================================================

func _open_pause() -> void:
	settings_menu.close()
	visible = true
	get_tree().paused = true


func _close_pause() -> void:
	settings_menu.close()
	visible = false
	get_tree().paused = false


# ==================================================
# BUTTONS
# ==================================================

func _on_resume_pressed() -> void:
	_close_pause()


func _on_settings_pressed() -> void:
	pause_panel.visible = false
	settings_menu.open()


func _on_settings_back_pressed() -> void:
	settings_menu.close()
	pause_panel.visible = true


func _on_main_menu_pressed() -> void:
	# Unpause first, otherwise the next scene stays frozen.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()