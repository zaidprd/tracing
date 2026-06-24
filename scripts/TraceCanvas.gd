extends Control
class_name TraceCanvas
## Core tracing mechanic. Renders a glyph as a set of follow-the-road stroke
## tracks and lets the player trace each stroke with a finger. Gives green-glow
## feedback when on the path and a red shake when the finger strays. Emits
## `glyph_completed` once every stroke has been traced in order.

signal stroke_completed(index: int)
signal glyph_completed

# --- Tuning (generous, child-friendly) ---
const CHANNEL_W := 78.0          # width of the road the child traces inside
const TRACE_W := 60.0            # width of the coloured trail that fills in
const ON_TOL := 70.0             # how far the finger may be from the path
const START_TOL := 110.0         # how close to the start dot to begin a stroke
const RESAMPLE_STEP := 16.0      # spacing of path sample points (px)

var strokes_norm: Array = []     # Array[PackedVector2Array] in [0,1] space

var _strokes: Array = []         # Array[PackedVector2Array] in pixel space
var _origin := Vector2.ZERO
var _box := 1.0
var _cur := 0                    # current stroke index
var _prog := 0                   # sample index reached on current stroke
var _finished := false

var _tracing := false
var _finger := Vector2.ZERO
var _show_finger := false
var _on_path := true

var _t := 0.0                    # animation clock
var _shake := 0.0                # remaining shake time
const SHAKE_TIME := 0.32
const SHAKE_MAG := 16.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_remap)
	set_process(true)

## Load a glyph by its ordered list of normalized strokes.
func setup(strokes: Array) -> void:
	strokes_norm = strokes
	restart()
	_remap()

## Re-trace the same glyph from the beginning.
func restart() -> void:
	_cur = 0
	_prog = 0
	_finished = false
	_tracing = false
	_show_finger = false
	_on_path = true
	_shake = 0.0
	modulate = Color.WHITE
	queue_redraw()

func is_finished() -> bool:
	return _finished

# ------------------------------------------------------------------ geometry
func _remap() -> void:
	if strokes_norm.is_empty():
		return
	_box = minf(size.x, size.y) * 0.9
	_origin = (size - Vector2(_box, _box)) * 0.5
	_strokes.clear()
	for ns in strokes_norm:
		var px := PackedVector2Array()
		for p in ns:
			px.append(_origin + Vector2(p.x * _box, p.y * _box))
		_strokes.append(_resample(px, RESAMPLE_STEP))
	_cur = clampi(_cur, 0, maxi(0, _strokes.size() - 1))
	queue_redraw()

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
	var last := pts[pts.size() - 1]
	if out[out.size() - 1].distance_to(last) > step * 0.5:
		out.append(last)
	return out

# --------------------------------------------------------------------- input
func _input(event: InputEvent) -> void:
	if _finished or _strokes.is_empty():
		return
	if event is InputEventScreenTouch and event.index == 0:
		var lp: Vector2 = event.position - global_position
		if event.pressed:
			var head: Vector2 = _strokes[_cur][_prog]
			if lp.distance_to(head) <= START_TOL:
				_tracing = true
				_finger = lp
				_show_finger = true
				_advance(lp)
		else:
			_tracing = false
			_show_finger = false
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == 0 and _tracing:
		var lp: Vector2 = event.position - global_position
		_finger = lp
		_show_finger = true
		_advance(lp)
		queue_redraw()

func _advance(lp: Vector2) -> void:
	var stroke: PackedVector2Array = _strokes[_cur]
	var n := stroke.size()
	var window := maxi(6, n / 6)
	var best_i := _prog
	var best_d := INF
	for i in range(_prog, mini(n, _prog + window + 1)):
		var d := lp.distance_to(stroke[i])
		if d < best_d:
			best_d = d
			best_i = i
	if best_d <= ON_TOL:
		_on_path = true
		_shake = 0.0
		if best_i > _prog:
			_prog = best_i
		if _prog >= n - 2:
			_complete_current_stroke()
	else:
		# Finger wandered off the road — gentle red shake, no progress lost.
		if _on_path:
			_shake = SHAKE_TIME
		_on_path = false

func _complete_current_stroke() -> void:
	_prog = _strokes[_cur].size() - 1
	stroke_completed.emit(_cur)
	Game.play_click()
	_cur += 1
	_tracing = false
	_show_finger = false
	if _cur >= _strokes.size():
		_finished = true
		glyph_completed.emit()
	else:
		_prog = 0

# ------------------------------------------------------------------- process
func _process(delta: float) -> void:
	_t += delta
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
	queue_redraw()

func _shake_offset() -> Vector2:
	if _shake <= 0.0:
		return Vector2.ZERO
	var m: float = SHAKE_MAG * (_shake / SHAKE_TIME)
	return Vector2(sin(_t * 70.0) * m, 0.0)

# ---------------------------------------------------------------------- draw
func _draw() -> void:
	if _strokes.is_empty():
		return
	draw_set_transform(_shake_offset(), 0.0, Vector2.ONE)

	# 1) Tracks (the white roads that show the whole letter shape).
	for stroke in _strokes:
		_stamp(stroke, 0, stroke.size() - 1, CHANNEL_W * 0.5 + 5.0, Color(0.5, 0.36, 0.18, 0.35))
	for stroke in _strokes:
		_stamp(stroke, 0, stroke.size() - 1, CHANNEL_W * 0.5, Color(1, 1, 1, 0.96))

	# 2) Coloured fill for completed strokes + current progress.
	for i in range(_strokes.size()):
		var stroke: PackedVector2Array = _strokes[i]
		if i < _cur:
			_stamp(stroke, 0, stroke.size() - 1, TRACE_W * 0.5, Game.C_ORANGE)
		elif i == _cur and _prog > 0:
			_stamp(stroke, 0, _prog, TRACE_W * 0.5, Game.C_ORANGE)

	# 3) Guidance for the active stroke: start dot, direction arrow, glow.
	if not _finished and _cur < _strokes.size():
		var stroke: PackedVector2Array = _strokes[_cur]
		var head: Vector2 = stroke[_prog]
		if _prog == 0:
			_draw_start_dot(head)
		else:
			var pulse := 0.5 + 0.5 * sin(_t * 6.0)
			draw_circle(head, 16.0 + 4.0 * pulse, Color(Game.C_GREEN, 0.9))
		# arrow toward the next sample
		var nxt: int = mini(_prog + 3, stroke.size() - 1)
		if nxt > _prog:
			_draw_arrow(head, stroke[nxt] - head, Game.C_GREEN)

	# 4) The finger handle with green/red glow, drawn in code.
	if _show_finger:
		var glow_col := Game.C_GREEN if _on_path else Game.C_RED
		draw_circle(_finger, 52.0, Color(glow_col, 0.30))
		draw_circle(_finger, 40.0, Color(glow_col, 0.30))
		draw_circle(_finger, 30.0, Color.WHITE)
		draw_arc(_finger, 30.0, 0.0, TAU, 40, glow_col, 7.0, true)

func _stamp(pts: PackedVector2Array, a: int, b: int, radius: float, color: Color) -> void:
	for i in range(a, b + 1):
		draw_circle(pts[i], radius, color)

func _draw_start_dot(at: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(at, 40.0 + 8.0 * pulse, Color(Game.C_GREEN, 0.25))
	draw_circle(at, 26.0, Color.WHITE)
	draw_circle(at, 20.0, Game.C_GREEN)

func _draw_arrow(at: Vector2, dir: Vector2, color: Color) -> void:
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var s := 20.0
	var p1 := at + dir * s
	var p2 := at - dir * (s * 0.3) + perp * (s * 0.8)
	var p3 := at - dir * (s * 0.3) - perp * (s * 0.8)
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color.WHITE)
	var q := 0.78
	draw_colored_polygon(PackedVector2Array([
		at + dir * (s * q),
		at - dir * (s * 0.1) + perp * (s * 0.55),
		at - dir * (s * 0.1) - perp * (s * 0.55)]), color)
