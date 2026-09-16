class_name Board
extends Node2D

const DittleLogic = preload("res://scripts/DittleLogic.gd")

const BOARD_SIZE: int = 7
const TILE_SIZE: float = 80.0
const BOARD_PIXEL_SIZE: float = 560.0 # 80 * 7

# 盤面配置 (720x720の画面中央: X=80, Y=80)
@export var board_offset: Vector2 = Vector2(80, 80)

# カーソル位置 (0,0) ~ (6,6)
var cursor_pos: Vector2i = Vector2i(3, 3)
var is_cursor_visible: bool = true
var cursor_anim_time: float = 0.0

# ハイライト対象の手 (Vector2i -> DittleLogic.Move または Moveのリスト)
var highlighted_moves: Dictionary = {} # Vector2i -> DittleLogic.Move
var selected_die_pos: Vector2i = Vector2i(-1, -1)

# 色パレット
const BG_DARK_1 = Color("#0f172a") # 濃いスレート
const BG_DARK_2 = Color("#1e293b") # 明るいスレート
const P1_GOAL_ROW_BG = Color("#0c4a6e", 0.5) # P1ベース（P2にとってのゴール）
const P2_GOAL_ROW_BG = Color("#7f1d1d", 0.5) # P2ベース（P1にとってのゴール）
const TILE_BORDER = Color("#334155", 0.6)
const BOARD_OUTER_BORDER = Color("#475569")

const ROLL_HIGHLIGHT_COLOR = Color("#22c55e") # 緑
const JUMP_HIGHLIGHT_COLOR = Color("#f59e0b") # 金/オレンジ
const CURSOR_COLOR = Color("#38bdf8") # シアン

func _ready():
	queue_redraw()

func _process(delta: float):
	cursor_anim_time += delta * 4.0
	queue_redraw()

func grid_to_world(pos: Vector2i) -> Vector2:
	return board_offset + Vector2(pos.x * TILE_SIZE + TILE_SIZE * 0.5, pos.y * TILE_SIZE + TILE_SIZE * 0.5)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local = world_pos - board_offset
	var gx = int(floor(local.x / TILE_SIZE))
	var gy = int(floor(local.y / TILE_SIZE))
	return Vector2i(clamp(gx, 0, BOARD_SIZE - 1), clamp(gy, 0, BOARD_SIZE - 1))

func set_cursor(pos: Vector2i):
	cursor_pos = Vector2i(clamp(pos.x, 0, BOARD_SIZE - 1), clamp(pos.y, 0, BOARD_SIZE - 1))
	queue_redraw()

func move_cursor(dir: Vector2i):
	set_cursor(cursor_pos + dir)

func set_highlights(moves: Array[DittleLogic.Move], from_pos: Vector2i = Vector2i(-1, -1)):
	highlighted_moves.clear()
	selected_die_pos = from_pos
	for m in moves:
		# 同じマスに複数のMoveがある場合、Combo/Jumpを優先、あるいはどれか1つを紐付け
		if not highlighted_moves.has(m.end_pos) or m.move_type != "roll":
			highlighted_moves[m.end_pos] = m
	queue_redraw()

func clear_highlights():
	highlighted_moves.clear()
	selected_die_pos = Vector2i(-1, -1)
	queue_redraw()

func _draw():
	# 盤面外枠と背景シャドウ
	var board_rect = Rect2(board_offset, Vector2(BOARD_PIXEL_SIZE, BOARD_PIXEL_SIZE))
	draw_rect(board_rect.grow(4), Color(0, 0, 0, 0.5), true)
	draw_rect(board_rect, Color("#090d16"), true)

	# 各タイルの描画
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var tile_rect = Rect2(
				board_offset.x + x * TILE_SIZE + 2,
				board_offset.y + y * TILE_SIZE + 2,
				TILE_SIZE - 4,
				TILE_SIZE - 4
			)
			
			# 背景色決定
			var cell_color = BG_DARK_1 if (x + y) % 2 == 0 else BG_DARK_2
			if y == 0:
				cell_color = cell_color.lerp(P2_GOAL_ROW_BG, 0.75) # P1のゴール行
			elif y == BOARD_SIZE - 1:
				cell_color = cell_color.lerp(P1_GOAL_ROW_BG, 0.75) # P2のゴール行
			
			# タイル描画（角丸）
			_draw_rounded_rect(tile_rect, 8.0, cell_color)
			_draw_rounded_rect_stroke(tile_rect, 8.0, TILE_BORDER, 1.5)

	# ゴール行の案内マーカーライン
	# P1ゴール (Y=0)
	draw_line(board_offset + Vector2(0, 2), board_offset + Vector2(BOARD_PIXEL_SIZE, 2), Color("#38bdf8", 0.6), 3.0)
	# P2ゴール (Y=6)
	draw_line(board_offset + Vector2(0, BOARD_PIXEL_SIZE - 2), board_offset + Vector2(BOARD_PIXEL_SIZE, BOARD_PIXEL_SIZE - 2), Color("#f87171", 0.6), 3.0)

	# ハイライトマスの描画
	for pos in highlighted_moves:
		var move: DittleLogic.Move = highlighted_moves[pos]
		var center = grid_to_world(pos)
		var h_color = ROLL_HIGHLIGHT_COLOR if move.move_type == "roll" else JUMP_HIGHLIGHT_COLOR
		
		# 光るリングと中心のドット
		var pulse = 0.85 + sin(cursor_anim_time * 1.5) * 0.15
		draw_circle(center, 28.0 * pulse, Color(h_color.r, h_color.g, h_color.b, 0.25))
		draw_arc(center, 26.0, 0, TAU, 32, h_color, 3.5)
		draw_circle(center, 6.0, h_color)
		
		# ジャンプ/コンボの場合の追加アイコン（小さな二重リング）
		if move.move_type != "roll":
			draw_arc(center, 18.0, 0, TAU, 24, Color("#ffffff", 0.8), 2.0)

	# カーソル描画
	if is_cursor_visible:
		var c_center = grid_to_world(cursor_pos)
		var c_half = (TILE_SIZE - 6) / 2.0
		var c_pulse = sin(cursor_anim_time) * 2.0
		var c_rect = Rect2(c_center.x - c_half - c_pulse, c_center.y - c_half - c_pulse, (c_half + c_pulse) * 2, (c_half + c_pulse) * 2)
		
		# コーナーアクセントの描画 (ゲーミング風カーソル)
		var corner_len = 16.0
		var c_color = CURSOR_COLOR
		if highlighted_moves.has(cursor_pos):
			var m = highlighted_moves[cursor_pos]
			c_color = ROLL_HIGHLIGHT_COLOR if m.move_type == "roll" else JUMP_HIGHLIGHT_COLOR

		_draw_cursor_corners(c_rect, corner_len, c_color, 3.5)

	# 盤面外枠ストローク
	_draw_rounded_rect_stroke(board_rect.grow(1), 10.0, BOARD_OUTER_BORDER, 3.0)

func _draw_cursor_corners(r: Rect2, l: float, col: Color, width: float):
	# Top-Left
	draw_line(Vector2(r.position.x, r.position.y + l), r.position, col, width)
	draw_line(r.position, Vector2(r.position.x + l, r.position.y), col, width)
	# Top-Right
	draw_line(Vector2(r.end.x - l, r.position.y), Vector2(r.end.x, r.position.y), col, width)
	draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + l), col, width)
	# Bottom-Right
	draw_line(Vector2(r.end.x, r.end.y - l), r.end, col, width)
	draw_line(r.end, Vector2(r.end.x - l, r.end.y), col, width)
	# Bottom-Left
	draw_line(Vector2(r.position.x + l, r.end.y), Vector2(r.position.x, r.end.y), col, width)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.end.y - l), col, width)

func _draw_rounded_rect(r: Rect2, radius: float, col: Color):
	var inner_r = r.grow(-radius)
	draw_rect(Rect2(r.position.x + radius, r.position.y, r.size.x - radius * 2, r.size.y), col)
	draw_rect(Rect2(r.position.x, r.position.y + radius, r.size.x, r.size.y - radius * 2), col)
	draw_circle(Vector2(inner_r.position.x, inner_r.position.y), radius, col)
	draw_circle(Vector2(inner_r.position.x + inner_r.size.x, inner_r.position.y), radius, col)
	draw_circle(Vector2(inner_r.position.x, inner_r.position.y + inner_r.size.y), radius, col)
	draw_circle(Vector2(inner_r.position.x + inner_r.size.x, inner_r.position.y + inner_r.size.y), radius, col)

func _draw_rounded_rect_stroke(r: Rect2, radius: float, col: Color, width: float):
	var segments = 6
	var points = PackedVector2Array()
	
	var tr = Vector2(r.position.x + r.size.x - radius, r.position.y + radius)
	for i in range(segments + 1):
		var ang = -PI/2 + (PI/2) * (float(i) / segments)
		points.append(tr + Vector2(cos(ang), sin(ang)) * radius)
		
	var br = Vector2(r.position.x + r.size.x - radius, r.position.y + r.size.y - radius)
	for i in range(segments + 1):
		var ang = 0 + (PI/2) * (float(i) / segments)
		points.append(br + Vector2(cos(ang), sin(ang)) * radius)

	var bl = Vector2(r.position.x + radius, r.position.y + r.size.y - radius)
	for i in range(segments + 1):
		var ang = PI/2 + (PI/2) * (float(i) / segments)
		points.append(bl + Vector2(cos(ang), sin(ang)) * radius)

	var tl = Vector2(r.position.x + radius, r.position.y + radius)
	for i in range(segments + 1):
		var ang = PI + (PI/2) * (float(i) / segments)
		points.append(tl + Vector2(cos(ang), sin(ang)) * radius)

	points.append(points[0])
	draw_polyline(points, col, width)
