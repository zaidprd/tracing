extends Node
## Global game state, shared assets and small UI helpers.
## Autoloaded as "Game" — accessible from every script.

# ---------------------------------------------------------------- Scene paths
const SCENE_MENU := "res://scenes/MainMenu.tscn"
const SCENE_SELECT := "res://scenes/LetterSelect.tscn"
const SCENE_TRACE := "res://scenes/TracingGame.tscn"
const SCENE_RESULT := "res://scenes/ResultScreen.tscn"

# ------------------------------------------------------------------- Palette
const C_SKY := Color("66c7b7")          # background top (mint)
const C_SKY_LIGHT := Color("c8efe6")    # background bottom (light mint)
const C_SUN := Color("ffc94d")          # warm golden yellow
const C_ORANGE := Color("ef6351")       # main accent / tracing trail (coral)
const C_GREEN := Color("2bb673")        # success
const C_GREEN_LIGHT := Color("8fe3b0")
const C_RED := Color("e5484d")          # wrong feedback
const C_PINK := Color("ff8fab")
const C_PURPLE := Color("6c63ff")       # indigo
const C_CREAM := Color("fff3cf")        # notebook page (matches sprite cards)
const C_BROWN := Color("8a5a2b")        # panel frame
const C_WHITE := Color("ffffff")
const C_TEXT := Color("3a4a55")         # cool slate text
const CONFETTI := [C_SUN, C_ORANGE, C_GREEN, C_PINK, C_PURPLE, Color("66c7b7")]

# ----------------------------------------------------------------- Game state
var mode: String = "letters"            # "letters" | "numbers"
var sequence: String = ""
var current_index: int = 0
var completed: Dictionary = {}          # glyph(String) -> true, per session

# -------------------------------------------------------------- Loaded assets
var font_title: Font
var font_main: Font
var _click: AudioStreamPlayer
var _success: AudioStreamPlayer
var _star_tex: Texture2D
var _dot_tex: Texture2D

func _ready() -> void:
	font_title = load("res://assets/fonts/ComicNeue-Bold.ttf")
	font_main = load("res://assets/fonts/ComicNeue-Regular.ttf")
	_click = AudioStreamPlayer.new()
	_click.stream = load("res://assets/audio/click.wav")
	_click.volume_db = -2.0
	add_child(_click)
	_success = AudioStreamPlayer.new()
	_success.stream = load("res://assets/audio/success.wav")
	add_child(_success)
	_star_tex = _build_star_texture(22)
	_dot_tex = _build_dot_texture(14)
	set_mode("letters")

# ------------------------------------------------------------------ Mode/flow
func set_mode(m: String) -> void:
	mode = m
	sequence = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" if m == "letters" else "0123456789"
	current_index = 0
	completed.clear()

func current_glyph() -> String:
	if sequence.is_empty():
		set_mode(mode)
	return sequence[current_index]

func glyph_at(i: int) -> String:
	return sequence[i]

func select_index(i: int) -> void:
	current_index = clampi(i, 0, sequence.length() - 1)

func has_next() -> bool:
	return current_index < sequence.length() - 1

func has_prev() -> bool:
	return current_index > 0

func go_next() -> void:
	if has_next():
		current_index += 1

func go_prev() -> void:
	if has_prev():
		current_index -= 1

# --------------------------------------------------------------- Progress
func mark_completed(g: String) -> void:
	completed[g] = true

func is_completed(g: String) -> bool:
	return completed.get(g, false)

func completed_count() -> int:
	return completed.size()

func total_count() -> int:
	return sequence.length()

# ------------------------------------------------------------------- Audio
func play_click() -> void:
	if _click:
		_click.play()

func play_success() -> void:
	if _success:
		_success.play()

# ----------------------------------------------------------------- Navigation
func goto(path: String) -> void:
	get_tree().change_scene_to_file(path)

# ------------------------------------------------------------- UI factory
## Full-screen vertical gradient background as a child-safe bright backdrop.
func make_background(top: Color = C_SKY, bottom: Color = C_SKY_LIGHT) -> ColorRect:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;
void fragment() {
	COLOR = mix(top_color, bottom_color, UV.y);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("top_color", top)
	mat.set_shader_parameter("bottom_color", bottom)
	bg.material = mat
	return bg

func make_label(text: String, size: int, color: Color = C_TEXT, use_title: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_title if use_title else font_main)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", C_WHITE)
	l.add_theme_constant_override("outline_size", maxi(2, size / 12))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

## A big, rounded, child-safe text button. Plays the click sound automatically.
func make_text_button(text: String, min_size: Vector2, base: Color = C_SUN) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font_title)
	b.add_theme_font_size_override("font_size", int(min_size.y * 0.42))
	b.add_theme_color_override("font_color", C_WHITE)
	b.add_theme_color_override("font_color_hover", C_WHITE)
	b.add_theme_color_override("font_color_pressed", C_CREAM)
	b.add_theme_color_override("font_outline_color", base.darkened(0.35))
	b.add_theme_constant_override("outline_size", 6)
	_style_button(b, base)
	b.pressed.connect(play_click)
	return b

func _style_button(b: Button, base: Color) -> void:
	var radius := 36
	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.set_corner_radius_all(radius)
	normal.border_width_bottom = 10
	normal.border_color = base.darkened(0.28)
	normal.content_margin_left = 28
	normal.content_margin_right = 28
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	var hover := normal.duplicate()
	hover.bg_color = base.lightened(0.08)
	var pressed := normal.duplicate()
	pressed.bg_color = base.darkened(0.10)
	pressed.border_width_bottom = 4
	pressed.content_margin_top = 20
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

## A round icon button drawn in code (no external image assets). Plays click sound.
func make_icon_button(kind: String, diameter: float, bg: Color = C_SUN, icon_color: Color = C_WHITE) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.focus_mode = Control.FOCUS_NONE
	var radius := int(diameter * 0.5)
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(radius)
	normal.border_width_bottom = 8
	normal.border_color = bg.darkened(0.28)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.1)
	pressed.border_width_bottom = 3
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ic := AppIcon.new()
	ic.kind = kind
	ic.color = icon_color
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(ic)
	b.pressed.connect(play_click)
	return b

# ----------------------------------------------------------------- Glyph display
## A non-interactive glyph flashcard, drawn from the stroke data (no sprites).
func make_glyph_visual(g: String) -> Control:
	var card := GlyphCard.new()
	card.glyph = g
	card.trail = C_ORANGE
	card.bg = C_CREAM
	card.border = Color("c98a3c")
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

# ------------------------------------------------------------ Reward particles
func _build_dot_texture(sz: int) -> Texture2D:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)

func _build_star_texture(sz: int) -> Texture2D:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := (sz - 1) / 2.0
	for y in range(sz):
		for x in range(sz):
			var dx: float = abs(x - c)
			var dy: float = abs(y - c)
			# four-point sparkle: diamond body + thin axis spikes
			if dx + dy <= c * 0.75 \
			or (dx <= c * 0.16 and dy <= c) \
			or (dy <= c * 0.16 and dx <= c):
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

## One-shot star burst that frees itself when finished.
func spawn_burst(parent: Node, pos: Vector2) -> void:
	for col in [C_SUN, C_ORANGE, C_PINK]:
		var p := CPUParticles2D.new()
		p.texture = _star_tex
		p.position = pos
		p.one_shot = true
		p.explosiveness = 1.0
		p.amount = 20
		p.lifetime = 1.1
		p.direction = Vector2.UP
		p.spread = 180.0
		p.gravity = Vector2(0, 700)
		p.initial_velocity_min = 350.0
		p.initial_velocity_max = 820.0
		p.scale_amount_min = 1.5
		p.scale_amount_max = 3.6
		p.angular_velocity_min = -420.0
		p.angular_velocity_max = 420.0
		p.color = col
		p.finished.connect(p.queue_free)
		p.emitting = true
		parent.add_child(p)

## Continuous multi-colour confetti rain across the top of the screen.
func spawn_confetti(parent: Node, width: float) -> void:
	for col in CONFETTI:
		var p := CPUParticles2D.new()
		p.texture = _dot_tex
		p.amount = 14
		p.lifetime = 3.2
		p.preprocess = 1.5
		p.position = Vector2(width * 0.5, -20.0)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(width * 0.5, 10.0)
		p.direction = Vector2.DOWN
		p.spread = 22.0
		p.gravity = Vector2(0, 320)
		p.initial_velocity_min = 120.0
		p.initial_velocity_max = 260.0
		p.angular_velocity_min = -300.0
		p.angular_velocity_max = 300.0
		p.scale_amount_min = 2.0
		p.scale_amount_max = 3.6
		p.color = col
		p.emitting = true
		parent.add_child(p)
