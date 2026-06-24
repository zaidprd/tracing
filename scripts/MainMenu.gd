extends Control
## Main menu: choose Letters or Numbers. Big, bright, child-safe buttons.

func _ready() -> void:
	add_child(Game.make_background(Game.C_SKY, Game.C_SKY_LIGHT))
	_add_floating_cards()

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 44)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	var title := Game.make_label("Tracing Fun", 130, Game.C_ORANGE)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(title)

	var sub := Game.make_label("Let's learn to write!", 50, Game.C_TEXT)
	sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(sub)

	col.add_child(_spacer(40))

	var letters := Game.make_text_button("ABC  Letters", Vector2(660, 190), Game.C_GREEN)
	letters.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	letters.pressed.connect(_start.bind("letters"))
	col.add_child(letters)

	var numbers := Game.make_text_button("123  Numbers", Vector2(660, 190), Game.C_PURPLE)
	numbers.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	numbers.pressed.connect(_start.bind("numbers"))
	col.add_child(numbers)

func _start(mode: String) -> void:
	Game.set_mode(mode)
	Game.goto(Game.SCENE_SELECT)

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

## A few drifting letter/number cards for a playful backdrop.
func _add_floating_cards() -> void:
	var picks := ["A", "5", "B", "3", "C"]
	var xs := [120.0, 820.0, 60.0, 880.0, 700.0]
	var ys := [360.0, 300.0, 1500.0, 1560.0, 1640.0]
	for i in range(picks.size()):
		var holder := Control.new()
		holder.size = Vector2(220, 130)
		holder.pivot_offset = Vector2(110, 65)
		holder.position = Vector2(xs[i], ys[i])
		holder.rotation_degrees = -10.0 + 20.0 * (i % 2)
		holder.modulate.a = 0.5
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(Game.make_glyph_visual(picks[i]))
		add_child(holder)
