class_name DittleLogic
extends RefCounted

# 盤面サイズ
const BOARD_SIZE: int = 7

# プレイヤー定数
const PLAYER_NONE: int = 0
const PLAYER_1: int = 1  # 青 (手前 Y=6)
const PLAYER_2: int = 2  # 赤 (奥 Y=0)

# ダイス初期向き (D6 Standard: 対面の和=7)
# Top=6, Front(相手方向)=4, Bottom=1, Back=3, Left=5, Right=2
const INITIAL_ORIENTATION = {
	"top": 6,
	"bottom": 1,
	"front": 4,
	"back": 3,
	"left": 5,
	"right": 2
}

class DieData:
	var id: int
	var owner: int # PLAYER_1 or PLAYER_2
	var pos: Vector2i
	var orientation: Dictionary # top, bottom, front, back, left, right

	func _init(p_id: int, p_owner: int, p_pos: Vector2i, p_ori: Dictionary = {}):
		id = p_id
		owner = p_owner
		pos = p_pos
		if p_ori.is_empty():
			orientation = INITIAL_ORIENTATION.duplicate()
		else:
			orientation = p_ori.duplicate()

	func duplicate_die() -> DieData:
		var d = DieData.new(id, owner, pos, orientation)
		return d

class MoveStep:
	var type: String # "roll" or "jump"
	var from_pos: Vector2i
	var to_pos: Vector2i
	var direction: String # "forward", "left", "right"

	func _init(p_type: String, p_from: Vector2i, p_to: Vector2i, p_dir: String):
		type = p_type
		from_pos = p_from
		to_pos = p_to
		direction = p_dir

class Move:
	var die_id: int
	var start_pos: Vector2i
	var end_pos: Vector2i
	var steps: Array[MoveStep] = []
	var final_orientation: Dictionary
	var move_type: String # "roll", "jump", "chain_jump", "combo"

	func _init(p_die_id: int, p_start: Vector2i, p_end: Vector2i, p_steps: Array[MoveStep], p_final_ori: Dictionary, p_type: String):
		die_id = p_die_id
		start_pos = p_start
		end_pos = p_end
		steps = p_steps.duplicate()
		final_orientation = p_final_ori.duplicate()
		move_type = p_type

# ダイス回転計算 (相対方向: "forward", "left", "right")
static func rotate_die_orientation(ori: Dictionary, dir: String) -> Dictionary:
	var res = ori.duplicate()
	match dir:
		"forward":
			res["top"] = ori["back"]
			res["bottom"] = ori["front"]
			res["front"] = ori["top"]
			res["back"] = ori["bottom"]
		"left":
			res["top"] = ori["right"]
			res["bottom"] = ori["left"]
			res["left"] = ori["top"]
			res["right"] = ori["bottom"]
		"right":
			res["top"] = ori["left"]
			res["bottom"] = ori["right"]
			res["left"] = ori["bottom"]
			res["right"] = ori["top"]
	return res

# プレイヤー視点での移動ベクトル取得
static func get_player_directions(player: int) -> Dictionary:
	if player == PLAYER_1:
		return {
			"forward": Vector2i(0, -1),
			"left": Vector2i(-1, 0),
			"right": Vector2i(1, 0)
		}
	else:
		return {
			"forward": Vector2i(0, 1),
			"left": Vector2i(1, 0),
			"right": Vector2i(-1, 0)
		}

# 盤面内判定
static func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE

# 盤面状態
var dice: Array[DieData] = []
var current_player: int = PLAYER_1

func _init():
	reset_board()

func reset_board():
	dice.clear()
	current_player = PLAYER_1
	var id_counter = 0
	# P2 (Y=0)
	for x in range(BOARD_SIZE):
		dice.append(DieData.new(id_counter, PLAYER_2, Vector2i(x, 0)))
		id_counter += 1
	# P1 (Y=6)
	for x in range(BOARD_SIZE):
		dice.append(DieData.new(id_counter, PLAYER_1, Vector2i(x, 6)))
		id_counter += 1

func duplicate_state():
	var script = get_script()
	var s = script.new()
	s.dice.clear()
	for d in dice:
		s.dice.append(d.duplicate_die())
	s.current_player = current_player
	return s

func get_die_at(pos: Vector2i) -> DieData:
	for d in dice:
		if d.pos == pos:
			return d
	return null

func get_die_by_id(id: int) -> DieData:
	for d in dice:
		if d.id == id:
			return d
	return null

func get_player_dice(player: int) -> Array[DieData]:
	var res: Array[DieData] = []
	for d in dice:
		if d.owner == player:
			res.append(d)
	return res

# 指定ダイスの合法手を全て生成
func get_legal_moves_for_die(die: DieData) -> Array[Move]:
	var moves: Array[Move] = []
	var dirs = get_player_directions(die.owner)

	# 1. 単体 Roll & Roll-then-Jump Combo
	for dir_name in dirs:
		var vec: Vector2i = dirs[dir_name]
		var target_pos = die.pos + vec
		if is_in_bounds(target_pos) and get_die_at(target_pos) == null:
			var rolled_ori = rotate_die_orientation(die.orientation, dir_name)
			var roll_step = MoveStep.new("roll", die.pos, target_pos, dir_name)
			
			# 単体Roll
			moves.append(Move.new(
				die.id,
				die.pos,
				target_pos,
				[roll_step],
				rolled_ori,
				"roll"
			))

			# Roll地点からのJump Combo探索
			var visited: Dictionary = {}
			visited[die.pos] = true
			visited[target_pos] = true
			_find_jumps(
				die.id,
				die.owner,
				die.pos,
				target_pos,
				[roll_step],
				rolled_ori,
				visited,
				moves,
				true # is_combo
			)

	# 2. Jump (単体およびChain Jump)
	var visited_direct: Dictionary = {}
	visited_direct[die.pos] = true
	_find_jumps(
		die.id,
		die.owner,
		die.pos,
		die.pos,
		[],
		die.orientation,
		visited_direct,
		moves,
		false # direct jump
	)

	return moves

# ジャンプ再帰探索
func _find_jumps(
	die_id: int,
	owner: int,
	start_pos: Vector2i,
	current_pos: Vector2i,
	current_steps: Array[MoveStep],
	current_ori: Dictionary,
	visited: Dictionary,
	out_moves: Array[Move],
	is_combo: bool
):
	var dirs = get_player_directions(owner)
	for dir_name in dirs:
		var vec: Vector2i = dirs[dir_name]
		var over_pos = current_pos + vec
		var land_pos = current_pos + vec * 2

		if is_in_bounds(land_pos):
			var over_die = get_die_at(over_pos)
			var is_over_occupied = (over_die != null and over_die.pos != start_pos) or (over_pos == start_pos and current_pos != start_pos)
			var land_die = get_die_at(land_pos)
			var is_land_empty = (land_die == null or land_die.pos == start_pos) and (land_pos != start_pos or current_steps.is_empty())

			if is_over_occupied and is_land_empty and not visited.has(land_pos):
				var jump_step = MoveStep.new("jump", current_pos, land_pos, dir_name)
				var next_steps = current_steps.duplicate()
				next_steps.append(jump_step)

				var m_type = "jump"
				if is_combo:
					m_type = "combo"
				elif next_steps.size() > 1:
					m_type = "chain_jump"

				out_moves.append(Move.new(
					die_id,
					start_pos,
					land_pos,
					next_steps,
					current_ori,
					m_type
				))

				var next_visited = visited.duplicate()
				next_visited[land_pos] = true

				_find_jumps(
					die_id,
					owner,
					start_pos,
					land_pos,
					next_steps,
					current_ori,
					next_visited,
					out_moves,
					is_combo
				)

# プレイヤーの全合法手を取得
func get_all_legal_moves(player: int) -> Array[Move]:
	var all_moves: Array[Move] = []
	for die in get_player_dice(player):
		var moves = get_legal_moves_for_die(die)
		all_moves.append_array(moves)
	return all_moves

# 手を適用
func apply_move(move: Move):
	var die = get_die_by_id(move.die_id)
	if die:
		die.pos = move.end_pos
		die.orientation = move.final_orientation.duplicate()
	current_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1

# ゲーム終了判定: いずれかのプレイヤーが全7個のダイスを相手ベース行に配置できたか
func is_game_over() -> bool:
	var p1_count = 0
	var p2_count = 0
	for d in dice:
		if d.owner == PLAYER_1 and d.pos.y == 0:
			p1_count += 1
		elif d.owner == PLAYER_2 and d.pos.y == BOARD_SIZE - 1:
			p2_count += 1
	
	return p1_count == BOARD_SIZE or p2_count == BOARD_SIZE

# スコア計算: 相手ベース行にあるダイスのTop値の合計
func get_scores() -> Dictionary:
	var p1_score = 0
	var p2_score = 0
	var p1_in_goal = 0
	var p2_in_goal = 0
	for d in dice:
		if d.owner == PLAYER_1 and d.pos.y == 0:
			p1_score += d.orientation["top"]
			p1_in_goal += 1
		elif d.owner == PLAYER_2 and d.pos.y == BOARD_SIZE - 1:
			p2_score += d.orientation["top"]
			p2_in_goal += 1
	return {
		"p1_score": p1_score,
		"p2_score": p2_score,
		"p1_goal_count": p1_in_goal,
		"p2_goal_count": p2_in_goal
	}

# 勝者判定 (PLAYER_1, PLAYER_2, 0=引き分け)
func get_winner() -> int:
	var scores = get_scores()
	if scores["p1_score"] > scores["p2_score"]:
		return PLAYER_1
	elif scores["p2_score"] > scores["p1_score"]:
		return PLAYER_2
	else:
		return 0
