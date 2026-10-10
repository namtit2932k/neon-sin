extends Node

# Starts the opening conversation over Level1's gameplay
# (the tree is paused, music keeps playing) and shows the
# branch the player picked.

const IntroDialogueScript := preload(
	"res://scripts/dialogue/intro_dialogue.gd"
)


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	# Defer so the level finishes loading and the HUD
	# draws before the screen fades to the dialogue.

	_start_intro.call_deferred()


# ==================================================
# INTRO
# ==================================================

func _start_intro() -> void:

	var intro := IntroDialogueScript.new()
	var lines := intro.get_intro_lines()

	var answer: int = await DialogueManager.start_conversation(lines)

	# Play the branch the player chose, then free this node.

	var branch := intro.get_branch(answer)

	if branch.is_empty():
		return

	await DialogueManager.start_conversation(branch)
