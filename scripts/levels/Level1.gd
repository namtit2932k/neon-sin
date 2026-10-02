extends Node2D

# ==================================================
# PAUSE
# ==================================================

# Escape (ui_cancel) giờ được xử lý bởi node PauseMenu
# (process_mode = ALWAYS) nằm trong Level1.tscn:
#
#   - Đang chơi    → mở màn hình pause
#   - Đang pause   → resume
#   - Settings mở  → đóng settings, quay về nút pause
#
# Nhờ vậy Escape không còn quay thẳng về main menu
# như trước nữa. LevelMusic có process_mode = ALWAYS
# nên nhạc nền vẫn phát trong lúc pause.
