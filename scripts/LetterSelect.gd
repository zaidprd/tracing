extends Control
## Grid of glyph cards to pick from. Shows session progress and a star on each
## glyph that has been completed this session.

const COLS := 2
const CARD_W := 486.0
const CARD_H := 258.0   # matches the 1299x692 "hole" sprite aspect

func _ready() -> void:
	add_child(Game.make_background(Game.C_SKY, Game.C_SKY_LIGHT))
	_build_header()
	_build_grid()

func _build_header() -> void:
	var back := Game.make_icon_button("res://assets/Sprites/category/back.png", 130)
	back.position = Vector2(28, 56)
	back.pressed.connect(_go_back)
	add_child(back)

	var title_text := "Pick a Letter" if Game.mode == "letters" else "Pick a Number"
	var title := Game.make_label(title_text, 70, Game.C_ORANGE)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 70
	title.offset_bottom = 160
	add_child(title)

	var prog := Game.make_label("%d / %d" % [Game.completed_count(), Game.total_count()], 52, Game.C_GREEN)
	prog.add_theme_color_override("font_color", Game.C_GREEN.darkened(0.1))
	prog.position = Vector2(760, 78)
	prog.size = Vector2(290, 70)
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(prog)
	var star := Game.make_label("★", 52, Game.C_SUN)
	star.position = Vector2(700, 78)
	star.size = Vector2(64, 70)
	add_child(star)

func _build_grid() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 200
	scroll.offset_left = 24
	scroll.offset_right = -24
	scroll.offset_bottom = -24
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for i in range(Game.sequence.length()):
		grid.add_child(_make_card(Game.glyph_at(i), i))

func _make_card(glyph: String, index: int) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.pivot_offset = Vector2(CARD_W, CARD_H) * 0.5

	var visual := Game.make_glyph_visual(glyph, 150)
	card.add_child(visual)

	if Game.is_completed(glyph):
		var badge := Game.make_label("★", 86, Game.C_SUN)
		badge.add_theme_color_override("font_outline_color", Game.C_ORANGE.darkened(0.2))
		badge.add_theme_constant_override("outline_size", 8)
		badge.position = Vector2(CARD_W - 110, 6)
		badge.size = Vector2(100, 100)
		card.add_child(badge)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.button_down.connect(func(): card.scale = Vector2(0.94, 0.94))
	btn.button_up.connect(func(): card.scale = Vector2.ONE)
	btn.pressed.connect(_pick.bind(index))
	card.add_child(btn)
	return card

func _pick(index: int) -> void:
	Game.play_click()
	Game.select_index(index)
	Game.goto(Game.SCENE_TRACE)

func _go_back() -> void:
	Game.goto(Game.SCENE_MENU)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
