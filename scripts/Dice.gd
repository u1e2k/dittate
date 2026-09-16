class_name Dice
extends Node2D

const DittleLogic = preload("res://scripts/DittleLogic.gd")

@export var die_size: float = 64.0
@export var corner_radius: float = 14.0

var die_data: DittleLogic.DieData = null
var is_selected: bool = false
var is_in_goal: bool = false
var pulse_time: float = 0.0

# 色定義
const P1_COLOR = Color("#0284c7") # 鮮やかシアンブルー
const P1_BORDER = Color("#7dd3fc")
const P2_COLOR = Color("#dc2626") # 鮮やかクリムゾンレッド
const P2_BORDER = Color("#fca5a5")
const PIP_COLOR = Color("#ffffff")
const GOLD_BORDER = Color("#fbbf24")
const SELECT_BORDER = Color("#fde047")

func _ready():
	queue_redraw()

func _process(delta: float):
	if is_selected or is_in_goal:
		pulse_time += delta * 5.0
		queue_redraw()

func setup(data: DittleLogic.DieData):
	die_data = data
	queue_redraw()

func set_selected(selected: bool):
	is_selected = selected
	pulse_time = 0.0
	queue_redraw()

func set_in_goal(in_goal: bool):
	is_in_goal = in_goal
	queue_redraw()

func _draw():
	if not die_data:
		return

	var half = die_size / 2.0
	var rect = Rect2(-half, -half, die_size, die_size)

	# 影
	draw_circle(Vector2(0, 4), half + 2, Color(0, 0, 0, 0.35))

	# ダイス本体背景
	var bg_color = P1_COLOR if die_data.owner == DittleLogic.PLAYER_1 else P2_COLOR
	var border_color = P1_BORDER if die_data.owner == DittleLogic.PLAYER_1 else P2_BORDER

	if is_in_goal:
		border_color = GOLD_BORDER

	var border_width = 3.5
	if is_selected:
		border_color = SELECT_BORDER
		border_width = 4.5 + sin(pulse_time) * 1.5

	# 本体塗りつぶし
	_draw_rounded_rect(rect, corner_radius, bg_color)
	# 枠線
	_draw_rounded_rect_stroke(rect, corner_radius, border_color, border_width)

	# 天面の数字描画 (Pips)
	var top_val = die_data.orientation.get("top", 6)
	_draw_pips(top_val, half)

	# ゴールインアイコン（王冠マーク風のゴールド点）
	if is_in_goal:
		var pulse_scale = 1.0 + sin(pulse_time * 0.8) * 0.1
		draw_circle(Vector2(0, -half + 7), 4.0 * pulse_scale, Color("#fef08a"))

# 角丸四角形の塗りつぶし
func _draw_rounded_rect(r: Rect2, radius: float, col: Color):
	# 4つの角の円と中央の十字
	var inner_r = r.grow(-radius)
	draw_rect(Rect2(r.position.x + radius, r.position.y, r.size.x - radius * 2, r.size.y), col)
	draw_rect(Rect2(r.position.x, r.position.y + radius, r.size.x, r.size.y - radius * 2), col)
	draw_circle(Vector2(inner_r.position.x, inner_r.position.y), radius, col)
	draw_circle(Vector2(inner_r.position.x + inner_r.size.x, inner_r.position.y), radius, col)
	draw_circle(Vector2(inner_r.position.x, inner_r.position.y + inner_r.size.y), radius, col)
	draw_circle(Vector2(inner_r.position.x + inner_r.size.x, inner_r.position.y + inner_r.size.y), radius, col)

# 角丸四角形の枠線
func _draw_rounded_rect_stroke(r: Rect2, radius: float, col: Color, width: float):
	var segments = 8
	var points = PackedVector2Array()
	
	# Top-Right arc
	var tr_center = Vector2(r.position.x + r.size.x - radius, r.position.y + radius)
	for i in range(segments + 1):
		var ang = -PI/2 + (PI/2) * (float(i) / segments)
		points.append(tr_center + Vector2(cos(ang), sin(ang)) * radius)
		
	# Bottom-Right arc
	var br_center = Vector2(r.position.x + r.size.x - radius, r.position.y + r.size.y - radius)
	for i in range(segments + 1):
		var ang = 0 + (PI/2) * (float(i) / segments)
		points.append(br_center + Vector2(cos(ang), sin(ang)) * radius)

	# Bottom-Left arc
	var bl_center = Vector2(r.position.x + radius, r.position.y + r.size.y - radius)
	for i in range(segments + 1):
		var ang = PI/2 + (PI/2) * (float(i) / segments)
		points.append(bl_center + Vector2(cos(ang), sin(ang)) * radius)

	# Top-Left arc
	var tl_center = Vector2(r.position.x + radius, r.position.y + radius)
	for i in range(segments + 1):
		var ang = PI + (PI/2) * (float(i) / segments)
		points.append(tl_center + Vector2(cos(ang), sin(ang)) * radius)

	points.append(points[0])
	draw_polyline(points, col, width)

# ダイスの目（Pips）の描画
func _draw_pips(val: int, half: float):
	var pip_r = 4.8
	var offset = half * 0.52

	var p_c = Vector2(0, 0)
	var p_tl = Vector2(-offset, -offset)
	var p_tr = Vector2(offset, -offset)
	var p_bl = Vector2(-offset, offset)
	var p_br = Vector2(offset, offset)
	var p_ml = Vector2(-offset, 0)
	var p_mr = Vector2(offset, 0)

	match val:
		1:
			draw_circle(p_c, pip_r * 1.4, PIP_COLOR)
		2:
			draw_circle(p_tl, pip_r, PIP_COLOR)
			draw_circle(p_br, pip_r, PIP_COLOR)
		3:
			draw_circle(p_tl, pip_r, PIP_COLOR)
			draw_circle(p_c, pip_r, PIP_COLOR)
			draw_circle(p_br, pip_r, PIP_COLOR)
		4:
			draw_circle(p_tl, pip_r, PIP_COLOR)
			draw_circle(p_tr, pip_r, PIP_COLOR)
			draw_circle(p_bl, pip_r, PIP_COLOR)
			draw_circle(p_br, pip_r, PIP_COLOR)
		5:
			draw_circle(p_tl, pip_r, PIP_COLOR)
			draw_circle(p_tr, pip_r, PIP_COLOR)
			draw_circle(p_c, pip_r, PIP_COLOR)
			draw_circle(p_bl, pip_r, PIP_COLOR)
			draw_circle(p_br, pip_r, PIP_COLOR)
		6:
			draw_circle(p_tl, pip_r, PIP_COLOR)
			draw_circle(p_tr, pip_r, PIP_COLOR)
			draw_circle(p_ml, pip_r, PIP_COLOR)
			draw_circle(p_mr, pip_r, PIP_COLOR)
			draw_circle(p_bl, pip_r, PIP_COLOR)
			draw_circle(p_br, pip_r, PIP_COLOR)

# 転がり（Roll）アニメーション
func animate_roll(target_pos: Vector2, dir_str: String, duration: float = 0.25) -> Tween:
	var tween = create_tween()
	tween.set_parallel(false)

	# 転がる方向に応じた回転角度
	var rot_target = 0.0
	match dir_str:
		"forward":
			rot_target = -PI/2 if die_data.owner == DittleLogic.PLAYER_1 else PI/2
		"left":
			rot_target = -PI/2 if die_data.owner == DittleLogic.PLAYER_1 else PI/2
		"right":
			rot_target = PI/2 if die_data.owner == DittleLogic.PLAYER_1 else -PI/2

	var mid_scale = Vector2(1.15, 0.85) if (dir_str == "left" or dir_str == "right") else Vector2(0.85, 1.15)

	# 前半: 移動 & 潰れ & 回転
	var tw_par1 = tween.parallel()
	tw_par1.tween_property(self, "position", (position + target_pos) * 0.5, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_par1.tween_property(self, "scale", mid_scale, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_par1.tween_property(self, "rotation", rot_target * 0.5, duration * 0.5)

	# 後半: 目的地へ & スケール復帰 & 角度スナップ
	var tw_par2 = tween.chain().parallel()
	tw_par2.tween_property(self, "position", target_pos, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_par2.tween_property(self, "scale", Vector2.ONE, duration * 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw_par2.tween_property(self, "rotation", 0.0, duration * 0.5)

	return tween

# ジャンプ（Jump）アニメーション: 放物線ホップ
func animate_jump(target_pos: Vector2, duration: float = 0.35) -> Tween:
	var tween = create_tween()
	var start_p = position

	# 移動とジャンプの高さを同時に処理
	var tw_par = tween.parallel()
	tw_par.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_LINEAR)
	
	# スケール変化で高さ感を表現 (1.0 -> 1.4 -> 1.0)
	var tw_scale = tween.parallel()
	tw_scale.tween_property(self, "scale", Vector2(1.38, 1.38), duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_scale.chain().tween_property(self, "scale", Vector2.ONE, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	return tween
