extends CanvasLayer
class_name DialogueBox

# Reusable dialogue UI laid out to mirror the reference mock:
# portrait frame bottom-left, nameplate overhanging the box top,
# choices stacked above the box, right-aligned to its edge, and a
# blinking arrow to the right of the highlighted choice.
#
# All children live on a fixed 1920x1080 "design" panel that is
# scaled to the viewport height, so proportions match the mock at
# any window size.
#
# Runs while the tree is paused (DialogueManager pauses the game).

signal typing_finished
signal arrow_pressed
signal choice_made(index: int)


# ==================================================
# ART
# ==================================================

const BOX_TEXTURE := preload("res://art/ui/Dialogue/dialogue_box.png")
const NAMEPLATE_TEXTURE := preload("res://art/ui/Dialogue/dialogue_nameplate.png")
const PLAYER_PORTRAIT_TEXTURE := preload("res://art/ui/PlayerHUD/portrait_frame_with_face.png")
const ARROW_TEXTURE := preload("res://art/ui/Dialogue/dialogue_continue_arrow.png")
const CHOICE_NORMAL_TEXTURE := preload("res://art/ui/Dialogue/dialogue_choice_normal.png")
const CHOICE_HOVER_TEXTURE := preload("res://art/ui/Dialogue/dialogue_choice_hover.png")

const FONT: Font = preload(
	# Godot only parses BMFont text/binary .fnt files — its XML
	# variant renders hex-code boxes. This is the text variant
	# with its page PNG copied next to it so the importer can
	# resolve the glyphs texture (clean copy in dialogue_font/).
	"res://art/font/dialogue_font/WhitePeaberryOutline.fnt"
)


# ==================================================
# LOOK (design-space pixels, 1920x1080)
# ==================================================

const DESIGN_SIZE := Vector2(1920, 1080)

# Outline font bakes its black outline; keep the fill white.
# Bitmap glyphs are crisp at whole multiples of their 16 px
# design size, so the body text runs at 3x.
const FONT_COLOR := Color.WHITE
const TEXT_FONT_SIZE := 48
const NAME_FONT_SIZE := 32
const CHOICE_FONT_SIZE := 32

const TYPE_CHARS_PER_SECOND := 40.0
const ARROW_BLINK_INTERVAL := 0.35

# Dialogue box strip along the bottom. Height equals the
# texture's native 248 px (no nine-patch distortion) and
# the portrait frame shares the same height.

const BOX_SIZE := Vector2(1580, 248)
const BOX_POS := Vector2(315, 1075.0 - BOX_SIZE.y)

# Nameplate overhangs the box top by 42 px.

const NAMEPLATE_POS := Vector2(375, BOX_POS.y - 42)
const NAMEPLATE_SIZE := Vector2(384, 64)

# Portrait shares the box height, bottom edges flush.
# The PlayerHUD texture already bakes the frame and face.

const PORTRAIT_POS := Vector2(75, BOX_POS.y)
const PORTRAIT_SIZE := Vector2(BOX_SIZE.y, BOX_SIZE.y)

# Text starts just right of the portrait, high in the box.

const TEXT_POS := Vector2(360, BOX_POS.y + 22)
const TEXT_SIZE := Vector2(1470, BOX_SIZE.y - 44)

# Choices sit above the box, right-aligned near its edge.
# Default focus is the top option.

const CHOICE_SIZE := Vector2(925, 62)
const CHOICE_GAP := 16.0
const CHOICE_RIGHT_X := 1870.0
const CHOICES_BOTTOM_Y := BOX_POS.y - 40


# ==================================================
# NODES (built in _ready)
# ==================================================

var _root: Control
var _panel: Control
var _nameplate: NinePatchRect
var _name_label: Label
var _text: RichTextLabel
var _arrow: TextureRect
var _choices: Array[TextureButton] = []


# ==================================================
# STATE
# ==================================================

var _chars_per_second: float = TYPE_CHARS_PER_SECOND
var _type_bucket: float = 0.0
var _blink_timer: float = 0.0
var _arrow_blinking: bool = false
var _arrow_on_finish: bool = true


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:

	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_ui()

	# Redo the cover-scale whenever the window resizes.

	_root.resized.connect(_relayout)
	_relayout.call_deferred()


func _process(delta: float) -> void:

	_reveal_characters(delta)
	_blink_arrow(delta)


# ==================================================
# INPUT (this autoload's _input runs before level nodes,
# so a dialogue always wins the keys; Escape is swallowed
# so the pause menu can never open mid-dialogue)
# ==================================================

# Keyboard only: J advances or confirms, W/S pick a
# choice. Mouse input is intentionally ignored.

func _input(event: InputEvent) -> void:

	if not visible:
		return

	var advance: bool = event.is_action_pressed("attack")
	var up: bool = event.is_action_pressed("choice_up")
	var down: bool = event.is_action_pressed("choice_down")

	if event.is_action_pressed("ui_cancel"):

		# Reserved for the pause menu.

		get_viewport().set_input_as_handled()
		return

	if not (advance or up or down):
		return

	get_viewport().set_input_as_handled()

	if not _choices.is_empty():

		if advance:
			_confirm_focused_choice()
		else:
			_move_choice_focus(-1 if up else 1)

	elif advance:

		_handle_advance_input()


# ==================================================
# OPEN / CLOSE
# ==================================================

func open_line(speaker: String) -> void:

	visible = true
	_nameplate.visible = not speaker.is_empty()
	_name_label.text = speaker
	_arrow_blinking = false
	_arrow.visible = false

func close() -> void:

	_free_choices()

	visible = false
	_arrow_blinking = false
	_arrow.visible = false


# ==================================================
# TYPING
# ==================================================

func type_text(line: String, characters_per_second: float, with_arrow_on_finish: bool = true) -> void:

	_chars_per_second = maxf(characters_per_second, 1.0)
	_type_bucket = 0.0
	_arrow_blinking = false
	_arrow.visible = false
	_arrow_on_finish = with_arrow_on_finish

	_text.text = line
	_text.visible_characters = 0

	# Empty line: nothing to reveal, finish on the next
	# idle moment so waiting for typing_finished never hangs.

	if _text.get_total_character_count() == 0:
		_complete_line.call_deferred()

func _is_typing() -> bool:

	return (
		_text.visible_characters >= 0
		and _text.visible_characters < _text.text.length()
	)

func _reveal_characters(delta: float) -> void:

	if not _is_typing():
		return

	_type_bucket += delta * _chars_per_second

	while _type_bucket >= 1.0 and _is_typing():

		_type_bucket -= 1.0
		_text.visible_characters += 1

	if not _is_typing():
		_complete_line()

# Marks the line fully revealed: fires typing_finished exactly
# once, whether the text finished naturally or was skipped.

func _complete_line() -> void:

	if _text.visible_characters < 0:
		return

	_text.visible_characters = -1

	if _arrow_on_finish:
		_show_box_arrow()

	typing_finished.emit()

func _handle_advance_input() -> void:

	# First press while typing skips to the full line,
	# the next press advances the conversation.

	if _is_typing():
		_complete_line()
	else:
		_arrow_blinking = false
		_arrow.visible = false
		arrow_pressed.emit()

# Blinks in the box's bottom-right corner while the
# player can advance a plain (non-choice) line.

func _show_box_arrow() -> void:

	_arrow_blinking = true
	_blink_timer = 0.0
	_arrow.visible = true
	_arrow.position = BOX_POS + Vector2(
		BOX_SIZE.x - ARROW_TEXTURE.get_width() - 28.0,
		BOX_SIZE.y - ARROW_TEXTURE.get_height() - 24.0
	)


# ==================================================
# CHOICES
# ==================================================

func show_choices(options: Array[String]) -> void:

	_free_choices()

	_arrow_blinking = false
	_arrow.visible = false

	for i in options.size():

		var button := TextureButton.new()
		button.texture_normal = CHOICE_NORMAL_TEXTURE
		button.texture_hover = CHOICE_HOVER_TEXTURE
		button.texture_pressed = CHOICE_HOVER_TEXTURE
		button.texture_focused = CHOICE_HOVER_TEXTURE
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.focus_mode = Control.FOCUS_ALL

		# Keyboard-driven: no mouse hover or click.

		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.set_meta("choice_index", i)
		button.focus_entered.connect(_select_choice.bind(i))

		var label := Label.new()
		label.text = options[i]
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		label.add_theme_color_override("font_color", FONT_COLOR)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)

		# Offsets must come after the anchor preset (the preset
		# resets them): these lift the text above true center.

		label.offset_bottom = -12.0
		label.offset_left = 32.0
		label.offset_right = -48.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		button.add_child(label)
		_panel.add_child(button)
		_layout_choice(button, i)
		_choices.append(button)

	if not _choices.is_empty():
		_choices[0].grab_focus()

func _select_choice(index: int) -> void:

	# The blinking arrow appears only on the highlighted
	# choice, inside it and hugging its right edge.

	var button := _choices[index]
	var center_y: float = button.position.y + button.size.y * 0.5

	_arrow.position = Vector2(
		button.position.x + button.size.x
			- ARROW_TEXTURE.get_width() - 18.0,
		center_y - ARROW_TEXTURE.get_height() * 0.5
	)

	_arrow_blinking = true
	_blink_timer = 0.0
	_arrow.visible = true

func _move_choice_focus(step: int) -> void:

	var count := _choices.size()

	if count == 0:
		return

	var focused := get_viewport().gui_get_focus_owner()
	var index: int = 0

	for i in count:

		if _choices[i] == focused:
			index = i
			break

	index = wrapi(index + step, 0, count)
	_choices[index].grab_focus()

func _confirm_focused_choice() -> void:

	var focused := get_viewport().gui_get_focus_owner()

	for i in _choices.size():

		if _choices[i] == focused:
			_emit_choice(i)
			return

	# No focus yet: take the top option.

	_emit_choice(0)

func _emit_choice(index: int) -> void:

	_free_choices()
	_arrow_blinking = false
	_arrow.visible = false
	choice_made.emit(index)

func _free_choices() -> void:

	for button in _choices:
		button.queue_free()

	_choices.clear()


# ==================================================
# ARROW
# ==================================================

func _blink_arrow(delta: float) -> void:

	if not _arrow_blinking:
		return

	_blink_timer += delta

	if _blink_timer >= ARROW_BLINK_INTERVAL:

		_blink_timer -= ARROW_BLINK_INTERVAL
		_arrow.visible = not _arrow.visible


# ==================================================
# LAYOUT
# ==================================================

# Everything lives on the fixed design panel; only its
# scale and position adapt to the real viewport.

func _relayout() -> void:

	var viewport_size := _root.size

	if viewport_size.y <= 0.0:
		return

	var s: float = viewport_size.y / DESIGN_SIZE.y

	_panel.scale = Vector2(s, s)
	_panel.position = Vector2(
		(viewport_size.x - DESIGN_SIZE.x * s) * 0.5,
		0.0
	)

func _layout_choice(button: TextureButton, index: int) -> void:

	var y: float = (
		CHOICES_BOTTOM_Y
		- CHOICE_SIZE.y
		- index * (CHOICE_SIZE.y + CHOICE_GAP)
	)

	button.position = Vector2(
		CHOICE_RIGHT_X - CHOICE_SIZE.x,
		y
	)
	button.size = CHOICE_SIZE


# ==================================================
# UI BUILD
# ==================================================

func _build_ui() -> void:

	# Full-screen, mouse-transparent cover.

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	add_child(_root)

	# Fixed design panel, scaled to the viewport in _relayout.

	_panel = Control.new()
	_panel.size = DESIGN_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)

	_build_box()
	_build_portrait()
	_build_nameplate()
	_build_text()
	_build_arrow()

func _build_box() -> void:

	var box := NinePatchRect.new()
	box.texture = BOX_TEXTURE
	box.patch_margin_left = 32
	box.patch_margin_right = 32
	box.patch_margin_top = 32
	box.patch_margin_bottom = 32
	box.position = BOX_POS
	box.size = BOX_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)

func _build_portrait() -> void:

	# PlayerHUD portrait (frame + face baked in), scaled up
	# to the dialogue box height.

	var rect := TextureRect.new()
	rect.texture = PLAYER_PORTRAIT_TEXTURE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.position = PORTRAIT_POS
	rect.size = PORTRAIT_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(rect)

func _build_nameplate() -> void:

	_nameplate = NinePatchRect.new()
	_nameplate.texture = NAMEPLATE_TEXTURE
	_nameplate.patch_margin_left = 24
	_nameplate.patch_margin_right = 24
	_nameplate.patch_margin_top = 16
	_nameplate.patch_margin_bottom = 16
	_nameplate.position = NAMEPLATE_POS
	_nameplate.size = NAMEPLATE_SIZE
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_nameplate)

	_name_label = Label.new()
	_name_label.add_theme_font_override("font", FONT)
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	_name_label.add_theme_color_override("font_color", FONT_COLOR)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Name text sits a touch above true vertical center.

	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Offsets must come after the anchor preset (the preset
	# resets them): these lift the text above true center.

	_name_label.offset_bottom = -14.0
	_name_label.offset_left = 20.0
	_name_label.offset_right = -12.0
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate.add_child(_name_label)

func _build_text() -> void:

	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.scroll_active = false
	_text.add_theme_font_override("normal_font", FONT)
	_text.add_theme_font_size_override("normal_font_size", TEXT_FONT_SIZE)
	_text.add_theme_color_override("default_color", FONT_COLOR)
	_text.position = TEXT_POS
	_text.size = TEXT_SIZE
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_text)

func _build_arrow() -> void:

	_arrow = TextureRect.new()
	_arrow.texture = ARROW_TEXTURE

	# Shows above the choice buttons, not behind them.

	_arrow.z_index = 10
	_arrow.visible = false
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_arrow)
