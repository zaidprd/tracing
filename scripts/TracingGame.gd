extends Control
## Tracing gameplay. Hosts a TraceCanvas inside a notebook panel, tracks stroke
## progress, lets the child move between glyphs, and celebrates a finished glyph
## before moving on to the ResultScreen.

const PANEL_RECT := Rect2(40, 250, 1000, 1000)
const CANVAS_MARGIN := 40.0

var _canvas: TraceCanvas
var _title: Label
var _instruction: Label
var _dots_row: HBoxContainer
var _dots: Array = []
var _prev_btn: TextureButton
var _next_btn: TextureButton
var _redo_btn: TextureButton
var _celebrating := false

func _ready() -> void:
	add_child(Game.make_background(Game.C_SKY, Game.C_SKY_LIGHT))
	_build_topbar()
	_build_panel()
	_build_controls()
	_load_current()

# ----------------------------------------------------------------- UI building
func _build_topbar() -> void:
	var back := Game.make_icon_button("res://assets/Sprites/category/back.png", 120)
	back.position = Vector2(28, 50)
	back.pressed.connect(_go_back)
	add_child(back)

	_title = Game.make_label("Trace", 78, Game.C_ORANGE)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 56
	_title.offset_bottom = 150
	add_child(_title)

	_dots_row = HBoxContainer.new()
	_dots_row.add_theme_constant_override("separation", 18)
	_dots_row.position = Vector2(0, 178)
	_dots_row.size = Vector2(1080, 44)
	_dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_dots_row)

func _build_panel() -> void:
	var panel := Panel.new()
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.C_CREAM
	sb.set_corner_radius_all(48)
	sb.set_border_width_all(16)
	sb.border_color = Color("c98a3c")
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 10)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_canvas = TraceCanvas.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.offset_left = CANVAS_MARGIN
	_canvas.offset_top = CANVAS_MARGIN
	_canvas.offset_right = -CANVAS_MARGIN
	_canvas.offset_bottom = -CANVAS_MARGIN
	_canvas.stroke_completed.connect(_on_stroke_completed)
	_canvas.glyph_completed.connect(_on_glyph_completed)
	panel.add_child(_canvas)

func _build_controls() -> void:
	_prev_btn = Game.make_icon_button("res://assets/Sprites/write/previous.png", 150)
	_prev_btn.position = Vector2(60, 1320)
	_prev_btn.pressed.connect(_on_prev)
	add_child(_prev_btn)

	_next_btn = Game.make_icon_button("res://assets/Sprites/write/next.png", 150)
	_next_btn.position = Vector2(870, 1320)
	_next_btn.pressed.connect(_on_next)
	add_child(_next_btn)

	_instruction = Game.make_label("Trace it!", 56, Game.C_TEXT)
	_instruction.position = Vector2(240, 1340)
	_instruction.size = Vector2(600, 110)
	add_child(_instruction)

	_redo_btn = Game.make_icon_button("res://assets/Sprites/retry.png", 150)
	_redo_btn.position = Vector2(465, 1560)
	_redo_btn.pressed.connect(_on_redo)
	add_child(_redo_btn)

	var redo_label := Game.make_label("Start Over", 40, Game.C_TEXT)
	redo_label.position = Vector2(340, 1715)
	redo_label.size = Vector2(400, 60)
	add_child(redo_label)

# ------------------------------------------------------------------ Glyph load
func _load_current() -> void:
	_celebrating = false
	var g := Game.current_glyph()
	_title.text = "Trace   %s" % g
	_instruction.text = "Trace the  %s  !" % g
	var strokes := Glyphs.get_strokes(g)
	_canvas.setup(strokes)
	_build_dots(strokes.size())
	_update_arrows()

func _build_dots(count: int) -> void:
	for d in _dots:
		d.queue_free()
	_dots.clear()
	for i in range(count):
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(36, 36)
		_dots.append(dot)
		_dots_row.add_child(dot)
		_set_dot(dot, false)

func _set_dot(dot: Panel, filled: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.C_GREEN if filled else Color(1, 1, 1, 0.85)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Game.C_GREEN.darkened(0.2) if filled else Color(0.6, 0.45, 0.2, 0.5)
	dot.add_theme_stylebox_override("panel", sb)

func _update_arrows() -> void:
	_prev_btn.disabled = not Game.has_prev()
	_prev_btn.modulate.a = 1.0 if Game.has_prev() else 0.35
	_next_btn.disabled = not Game.has_next()
	_next_btn.modulate.a = 1.0 if Game.has_next() else 0.35

# -------------------------------------------------------------------- Signals
func _on_stroke_completed(index: int) -> void:
	if index >= 0 and index < _dots.size():
		_set_dot(_dots[index], true)

func _on_glyph_completed() -> void:
	if _celebrating:
		return
	_celebrating = true
	var g := Game.current_glyph()
	Game.mark_completed(g)
	Game.play_success()
	_instruction.text = "Great job!"

	# Lock controls so the celebration can't be interrupted.
	_prev_btn.disabled = true
	_next_btn.disabled = true
	_redo_btn.disabled = true

	# Star burst at the centre of the tracing panel + green congratulations flash.
	Game.spawn_burst(self, PANEL_RECT.position + PANEL_RECT.size * 0.5)
	var tw := create_tween()
	tw.tween_property(_canvas, "modulate", Game.C_GREEN_LIGHT, 0.15)
	tw.tween_property(_canvas, "modulate", Color.WHITE, 0.5)

	get_tree().create_timer(1.2).timeout.connect(_go_result)

func _go_result() -> void:
	Game.goto(Game.SCENE_RESULT)

# -------------------------------------------------------------------- Controls
func _on_prev() -> void:
	if _celebrating:
		return
	Game.go_prev()
	_load_current()

func _on_next() -> void:
	if _celebrating:
		return
	Game.go_next()
	_load_current()

func _on_redo() -> void:
	if _celebrating:
		return
	_canvas.restart()
	for d in _dots:
		_set_dot(d, false)

func _go_back() -> void:
	Game.goto(Game.SCENE_SELECT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
