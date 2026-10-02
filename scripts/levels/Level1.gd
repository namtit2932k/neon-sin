extends Node2D

# ==================================================
# ESCAPE → MAIN MENU
# ==================================================

# Bấm Escape (ui_cancel) trong màn chơi
# để quay về main menu.

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_cancel"):

		# change_scene_to_file giải phóng màn chơi
		# → nhạc LevelMusic tự dừng theo.

		get_tree().change_scene_to_file(
			"res://scenes/menu/MainMenu.tscn"
		)
