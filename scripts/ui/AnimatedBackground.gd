extends TextureRect


# ==================================================
# CONSTANTS
# ==================================================

const FRAME_PATTERN := (
	"res://art/ui/Menu/background/frame_%03d_delay-0.1s.png"
)


# ==================================================
# EXPORTS
# ==================================================

@export var frame_interval: float = 0.1


# ==================================================
# STATE
# ==================================================

var frames: Array[Texture2D] = []
var frame_index: int = 0
var timer: float = 0.0


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	_load_frames()

	if not frames.is_empty():
		texture = frames[0]


func _process(delta: float) -> void:
	if frames.size() < 2:
		return

	timer += delta

	if timer >= frame_interval:
		timer -= frame_interval
		frame_index = (frame_index + 1) % frames.size()
		texture = frames[frame_index]


# ==================================================
# LOADER
# ==================================================

# Frames are numbered, so loading stops at the first
# missing index instead of hardcoding the frame count.
func _load_frames() -> void:
	var index := 0

	while true:
		var path := FRAME_PATTERN % index

		if not ResourceLoader.exists(path):
			break

		var frame := load(path) as Texture2D

		if frame == null:
			break

		frames.append(frame)
		index += 1