class_name AIPlayer
extends RefCounted

const DittleLogic = preload("res://scripts/DittleLogic.gd")

# CPUが最適な手を選択
static func select_best_move(board: DittleLogic, player: int = DittleLogic.PLAYER_2) -> DittleLogic.Move:
	var moves = board.get_all_legal_moves(player)
	if moves.is_empty():
		return null

	var best_score: float = -999999.0
	var best_moves: Array[DittleLogic.Move] = []

	for move in moves:
		var score = evaluate_move(board, move, player)
		if score > best_score + 0.001:
			best_score = score
			best_moves.clear()
			best_moves.append(move)
		elif abs(score - best_score) <= 0.001:
			best_moves.append(move)

	# 同スコアの中からランダム選択
	return best_moves.pick_random()

# 各手の評価関数
static func evaluate_move(board: DittleLogic, move: DittleLogic.Move, player: int) -> float:
	var score: float = 0.0
	var die = board.get_die_by_id(move.die_id)
	if not die:
		return -9999.0

	var goal_y = (DittleLogic.BOARD_SIZE - 1) if player == DittleLogic.PLAYER_2 else 0
	var forward_dir = 1 if player == DittleLogic.PLAYER_2 else -1

	var is_already_in_goal = (die.pos.y == goal_y)
	var is_reaching_goal = (move.end_pos.y == goal_y)

	# 1. すでにゴールに到達しているダイスを動かす場合の処理
	if is_already_in_goal:
		# ゴール列内での横移動
		if move.end_pos.y == goal_y:
			# Topの目が良くなるなら多少考慮、悪くなるなら大幅減点
			var diff = move.final_orientation["top"] - die.orientation["top"]
			score += diff * 15.0 - 20.0
		else:
			score -= 200.0 # 後退はそもそもルール上不可だが安全策

	# 2. ゴールへの到達
	if is_reaching_goal and not is_already_in_goal:
		score += 300.0
		# ゴール時のTopの出目が高ければ超高得点 (Top 6なら +120点)
		score += move.final_orientation["top"] * 20.0

	# 3. 前進距離ボーナス
	var forward_progress = (move.end_pos.y - move.start_pos.y) * forward_dir
	score += forward_progress * 25.0

	# 4. 出目（Top）の評価 (相手陣地に近づくほどTopの数字の価値が上がる)
	var distance_to_goal = abs(goal_y - move.end_pos.y)
	var top_face = move.final_orientation["top"]
	var face_weight = (7.0 - distance_to_goal) / 7.0 # ゴールに近いほど1.0に近い
	score += top_face * (4.0 + face_weight * 8.0)

	# 5. マルチジャンプ・コンボ評価 (一気に進む手は爽快かつ有利)
	if move.steps.size() > 1:
		score += move.steps.size() * 12.0

	# 6. 中央コントロール (盤面端 x=0, 6 よりも中央 x=2~4 を好む)
	var center_dist = abs(3.0 - float(move.end_pos.x))
	score += (3.0 - center_dist) * 2.0

	# 7. 微小なランダム性 (多様なゲーム展開を生む)
	score += randf_range(0.0, 1.5)

	return score
