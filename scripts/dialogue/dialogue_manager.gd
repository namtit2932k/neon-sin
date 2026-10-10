extends Node

# Dialogue engine autoload ("DialogueManager" in project.godot).
# A conversation is just an Array of line Dictionaries, so new
# dialogues are data, not code.
# The tree is paused while a conversation is on screen; music
# keeps playing because LevelMusic / menu players already use
# process_mode = ALWAYS.

const DIALOGUE_BOX_SCENE := preload(
	"res://scenes/ui/dialogue_box.tscn"
)

const DEFAULT_CHARS_PER_SECOND := 40.0


# ==================================================
# STATE
# ==================================================

var _box: CanvasLayer


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	# Lets the awaits below resume while the tree is paused.

	process_mode = Node.PROCESS_MODE_ALWAYS

	_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(_box)


# ==================================================
# PUBLIC API
# ==================================================

# Plays a conversation and returns the last choice index
# (-1 when the conversation had no choices).
#
# Line shapes:
#   { "speaker": "Neo", "say": "Too dark in here." }
#   { "speaker": "Neo", "ask": {
#       "text": "Did you hear that?",
#       "options": ["What was that noise?", "What is that?"],
#   }}
#
# Example:
#   var answer := await DialogueManager.start_conversation([
#       { "speaker": "Neo", "say": "It is so dark here." },
#       { "speaker": "Neo", "ask": {
#           "text": "What should I do?",
#           "options": ["Listen.", "Look around."],
#       }},
#   ])

func start_conversation(lines: Array) -> int:

	if _box.visible:
		push_warning("Dialogue already running")
		return -1

	get_tree().paused = true

	var last_choice := -1

	for line: Dictionary in lines:

		if not _is_valid_line(line):
			continue

		if line.has("ask"):
			last_choice = await _ask(line)
		else:
			await _say(line)

	_end_conversation()
	return last_choice


# ==================================================
# INTERNAL
# ==================================================

func _say(line: Dictionary) -> void:

	_show_line(line)
	await _box.arrow_pressed

func _ask(line: Dictionary) -> int:

	# The question types out, then the options appear on
	# their own — no extra advance press needed.

	var ask: Dictionary = line.get("ask", {})
	var options: Array[String] = []

	for option in ask.get("options", []):
		options.append(str(option))

	_show_line(line, false)
	await _box.typing_finished

	_box.show_choices(options)

	var chosen: int = await _box.choice_made
	return chosen

func _show_line(line: Dictionary, with_arrow: bool = true) -> void:

	_box.open_line(line.get("speaker", ""))
	_box.type_text(
		line.get("say", line.get("ask", {}).get("text", "")),
		DEFAULT_CHARS_PER_SECOND,
		with_arrow
	)

func _end_conversation() -> void:

	_box.close()
	get_tree().paused = false


# ==================================================
# VALIDATION
# ==================================================

func _is_valid_line(line: Dictionary) -> bool:

	if line.has("say") or line.has("ask"):
		return true

	push_warning("Dialogue line has neither 'say' nor 'ask': %s" % [line])
	return false
