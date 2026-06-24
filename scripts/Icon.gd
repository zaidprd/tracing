extends Control
class_name AppIcon
## A small vector icon drawn entirely in code (no external image assets).
## kind: "home" | "prev" | "next" | "redo".

var kind := "next"
var color := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var r: float = s * 0.5
	match kind:
		"next":
			_triangle(c, r, 1.0)
		"prev":
			_triangle(c, r, -1.0)
		"home":
			_home(c, r)
		"redo":
			_redo(c, r)

func _triangle(c: Vector2, r: float, dir: float) -> void:
	var w := r * 0.5
	var h := r * 0.62
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(dir * w, 0),
		c + Vector2(-dir * w * 0.7, -h),
		c + Vector2(-dir * w * 0.7, h)]), color)

func _home(c: Vector2, r: float) -> void:
	var w := r * 0.66
	# roof
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r * 0.66),
		c + Vector2(-w, -r * 0.02),
		c + Vector2(w, -r * 0.02)]), color)
	# body
	var bw := w * 0.76
	draw_rect(Rect2(c + Vector2(-bw, -r * 0.06), Vector2(bw * 2.0, r * 0.7)), color)
	# door
	var dw := bw * 0.42
	draw_rect(Rect2(c + Vector2(-dw, r * 0.18), Vector2(dw * 2.0, r * 0.46)), Color(0, 0, 0, 0.2))

func _redo(c: Vector2, r: float) -> void:
	var rad := r * 0.52
	var width := r * 0.2
	var a0 := deg_to_rad(-35.0)
	var a1 := deg_to_rad(255.0)
	draw_arc(c, rad, a0, a1, 40, color, width, true)
	# arrowhead at the open end (a0), pointing along the tangent
	var p := c + Vector2(cos(a0), sin(a0)) * rad
	var tang := Vector2(sin(a0), -cos(a0))   # backwards tangent (open direction)
	var radial := Vector2(cos(a0), sin(a0))
	var hs := r * 0.34
	draw_colored_polygon(PackedVector2Array([
		p + tang * hs,
		p - tang * (hs * 0.2) + radial * (hs * 0.85),
		p - tang * (hs * 0.2) - radial * (hs * 0.85)]), color)
