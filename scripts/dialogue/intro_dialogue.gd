extends RefCounted

# Opening conversation shown when Level1 starts.
# Pure data: add or reorder lines without touching dialogue code.
# Both intro options branch to their own follow-up, then
# converge on the same closing line.

const SPEAKER := "sickyturtlez"


# ==================================================
# BRANCH LINES
# ==================================================

const LINES_1 := [
	{ "speaker": SPEAKER, "say": "That's a bit scary..." },
]

const LINES_2 := [
	{ "speaker": SPEAKER, "say": "What is that thing over there...?" },
]

const OUTRO_LINES := [
	{ "speaker": SPEAKER, "say": "...Better keep moving." },
]


# ==================================================
# INTRO
# ==================================================

func get_intro_lines() -> Array:

	return [
		{ "speaker": SPEAKER, "say": "It's so dark in here... I can't see a thing." },
		{
			"speaker": SPEAKER,
			"ask": {
				"text": "Wait... I think I can hear something.",
				"options": [
					"Hello?",
					"Who's there?",
				],
			},
		},
	]


# ==================================================
# BRANCH RESOLUTION
# ==================================================

# Maps a choice index to its branch. Returning the second
# half keeps Level1's await simple:
#
#   var answer := await DialogueManager.start_conversation(lines)
#   await DialogueManager.start_conversation(IntroDialogue.get_branch(answer))

func get_branch(choice_index: int) -> Array:

	match choice_index:

		0:
			return LINES_1 + OUTRO_LINES
		1:
			return LINES_2 + OUTRO_LINES
		_:
			return OUTRO_LINES
