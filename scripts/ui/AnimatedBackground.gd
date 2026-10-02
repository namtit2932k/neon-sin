extends TextureRect

# ==================================================
# ANIMATED BACKGROUND
# ==================================================

# Phát chuỗi frame PNG (tách từ GIF)
# làm nền động cho menu, lặp vô hạn.
#
# Frame nằm trong art/ui/Menu/background/
# với tên: frame_000_delay-0.1s.png ...
#
# Script tự đếm số frame cho tới khi
# không tìm thấy frame tiếp theo.

const FRAME_PATTERN := "res://art/ui/Menu/background/frame_%03d_delay-0.1s.png"

# Mỗi frame hiển thị 0.1 giây (= 10 FPS như GIF gốc).
@export var frame_interval: float = 0.1


# ==================================================
# STATE
# ==================================================

var frames: Array[Texture2D] = []
var frame_index: int = 0
var timer: float = 0.0


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	_load_frames()

	if frames.is_empty():
		return

	texture = frames[0]


# ==================================================
# PROCESS
# ==================================================

func _process(delta: float) -> void:

	if frames.size() < 2:
		return

	timer += delta

	if timer >= frame_interval:

		timer -= frame_interval

		frame_index = (
			(frame_index + 1) % frames.size()
		)

		texture = frames[frame_index]


# ==================================================
# LOAD FRAMES
# ==================================================

func _load_frames() -> void:

	# Tải frame 000, 001, 002... cho tới khi
	# không còn frame nào tiếp theo.

	var index: int = 0

	while true:

		var path := FRAME_PATTERN % index

		if not ResourceLoader.exists(path):
			break

		var tex := load(path) as Texture2D

		if tex == null:
			break

		frames.append(tex)

		index += 1
