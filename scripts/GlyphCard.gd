extends Control
class_name GlyphCard
## A flashcard that draws a glyph from the shared stroke-path data (no external
## image assets). Used on the selection grid, result screen and menu backdrop.

var glyph := "A"
var trail := Color("ef6351")
var bg := Color("fff3cf")
var border := Color("c98a3c")

func set_glyph(g: String) -> void:
	glyph = g
	queue_redraw()

func _draw() -> void:
	# Card background.
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(10)
	sb.border_color = border
	draw_style_box(sb, Rect2(Vector2.ZERO, size))

	# The glyph, drawn inside a centred square.
	var box: float = minf(size.x, size.y) * 0.68
	var origin: Vector2 = (size - Vector2(box, box)) * 0.5
	for ns in Glyphs.get_strokes(glyph):
		var pts := PackedVector2Array()
		for p in ns:
			pts.append(origin + Vector2(p.x * box, p.y * box))
		var rs := _resample(pts, box * 0.022)
		var rad: float = box * 0.05
		for q in rs:
			draw_circle(q, rad + 2.0, Color(0.5, 0.36, 0.18, 0.25))
		for q in rs:
			draw_circle(q, rad, trail)

func _resample(pts: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.is_empty():
		return out
	out.append(pts[0])
	if pts.size() == 1:
		return out
	var carry := 0.0
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		if seg <= 0.0001:
			continue
		var dir := (b - a) / seg
		var d := step - carry
		while d <= seg:
			out.append(a + dir * d)
			d += step
		carry = seg - (d - step)
	out.append(pts[pts.size() - 1])
	return out
