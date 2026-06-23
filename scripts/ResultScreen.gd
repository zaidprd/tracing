extends Control
## Reward screen shown after a glyph is finished: confetti, a star burst, the
## glyph that was traced, session progress, and big friendly navigation buttons.

func _ready() -> void:
	add_child(Game.make_background(Game.C_SUN, Game.C_SKY_LIGHT))
	Game.spawn_confetti(self, 1080.0)

	var g := Game.current_glyph()

	var title := Game.make_label("GREAT JOB!", 120, Game.C_ORANGE)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 210
	title.offset_bottom = 360
	add_child(title)

	var holder := Control.new()
	holder.position = Vector2(180, 470)
	holder.size = Vector2(720, 384)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(Game.make_glyph_visual(g, 230))
	add_child(holder)

	var traced := Game.make_label("You traced   %s" % g, 64, Game.C_TEXT)
	traced.position = Vector2(40, 910)
	traced.size = Vector2(1000, 90)
	add_child(traced)

	var prog := Game.make_label("★  %d of %d done!" % [Game.completed_count(), Game.total_count()], 56, Game.C_GREEN.darkened(0.1))
	prog.position = Vector2(40, 1020)
	prog.size = Vector2(1000, 80)
	add_child(prog)

	_build_buttons()

	# Star burst over everything, centred on the glyph.
	Game.spawn_burst(self, Vector2(540, 660))

func _build_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.position = Vector2(0, 1320)
	row.size = Vector2(1080, 200)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	var again := Game.make_text_button("Again", Vector2(300, 180), Game.C_GREEN)
	again.pressed.connect(_again)
	row.add_child(again)

	if Game.has_next():
		var nxt := Game.make_text_button("Next", Vector2(300, 180), Game.C_ORANGE)
		nxt.pressed.connect(_next)
		row.add_child(nxt)

	var menu := Game.make_text_button("Menu", Vector2(300, 180), Game.C_PURPLE)
	menu.pressed.connect(_menu)
	row.add_child(menu)

func _again() -> void:
	Game.goto(Game.SCENE_TRACE)

func _next() -> void:
	Game.go_next()
	Game.goto(Game.SCENE_TRACE)

func _menu() -> void:
	Game.goto(Game.SCENE_SELECT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_menu()
