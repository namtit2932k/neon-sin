extends CanvasLayer

# ==================================================
# REFERENCES
# ==================================================

@onready var pause_panel: Control = $Root/Panel
@onready var settings_menu: Control = $Root/Settings


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	visible = false


# ==================================================
# ESCAPE
# ==================================================

# PauseMenu có process_mode = ALWAYS nên vẫn nhận
# input khi cả cây scene đang pause:
#
#   - Settings đang mở → đóng settings, về nút pause
#   - Pause đang mở    → resume
#   - Đang chơi        → mở pause

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

	# Ẩn panel pause, hiện settings dùng chung.

	pause_panel.visible = false
	settings_menu.open()


func _on_settings_back_pressed() -> void:

	settings_menu.close()
	pause_panel.visible = true


func _on_main_menu_pressed() -> void:

	# Bỏ pause trước khi đổi scene.

	get_tree().paused = false

	get_tree().change_scene_to_file(
		"res://scenes/menu/MainMenu.tscn"
	)


func _on_quit_pressed() -> void:

	get_tree().quit()
