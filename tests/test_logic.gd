extends SceneTree

const DittleLogic = preload("res://scripts/DittleLogic.gd")
const AIPlayer = preload("res://scripts/AIPlayer.gd")

func _init():
	print("=== Running DittleLogic Tests ===")
	
	# 1. Orientation test
	var ori = DittleLogic.INITIAL_ORIENTATION.duplicate()
	assert(ori["top"] == 6)
	assert(ori["front"] == 4)

	# Forward roll: new_top = back (3), new_front = top (6), new_bottom = front (4), new_back = bottom (1)
	var forward_ori = DittleLogic.rotate_die_orientation(ori, "forward")
	print("Forward Roll: Top=", forward_ori["top"], " Front=", forward_ori["front"], " Bottom=", forward_ori["bottom"], " Back=", forward_ori["back"])
	assert(forward_ori["top"] == 3)
	assert(forward_ori["front"] == 6)
	assert(forward_ori["bottom"] == 4)
	assert(forward_ori["back"] == 1)
	assert(forward_ori["left"] == 5)
	assert(forward_ori["right"] == 2)

	# Left roll: new_top = right (2), new_bottom = left (5), new_left = top (6), new_right = bottom (1)
	var left_ori = DittleLogic.rotate_die_orientation(ori, "left")
	print("Left Roll: Top=", left_ori["top"], " Left=", left_ori["left"], " Right=", left_ori["right"])
	assert(left_ori["top"] == 2)
	assert(left_ori["bottom"] == 5)
	assert(left_ori["left"] == 6)
	assert(left_ori["right"] == 1)

	# Right roll: new_top = left (5), new_bottom = right (2), new_left = bottom (1), new_right = top (6)
	var right_ori = DittleLogic.rotate_die_orientation(ori, "right")
	print("Right Roll: Top=", right_ori["top"], " Left=", right_ori["left"], " Right=", right_ori["right"])
	assert(right_ori["top"] == 5)
	assert(right_ori["bottom"] == 2)
	assert(right_ori["left"] == 1)
	assert(right_ori["right"] == 6)

	# 2. Board state and legal move generation (Initial state)
	var board = DittleLogic.new()
	assert(board.dice.size() == 14)
	var p1_dice = board.get_player_dice(DittleLogic.PLAYER_1)
	assert(p1_dice.size() == 7)
	
	# P1 at (0,6): Forward=(0,5) is empty, Right=(1,6) is occupied and (2,6) is also occupied.
	var d0 = board.get_die_at(Vector2i(0, 6))
	var moves0 = board.get_legal_moves_for_die(d0)
	print("Initial Die at (0,6) moves count: ", moves0.size())
	assert(moves0.size() == 1)
	assert(moves0[0].end_pos == Vector2i(0, 5))

	# 3. Test Jump when landing spot is empty
	# (0,6) を (0,5) に動かした後の状態を作る
	board.apply_move(moves0[0])
	# P1の手番を再度P1にする（テスト用）
	board.current_player = DittleLogic.PLAYER_1
	# (1,6) のダイスは、左上の (0,5) は別として、上 (1,5) へのRoll、
	# および左(0,6: 空きマス)へのJump (0,6のマスは先ほど空いたので (1,6) から飛び越えられるか？
	# (1,6) の左は (0,6) (距離1) であり、飛び越える対象ではない。
	# では (0,5) のダイス:
	# 下(後退)は不可。前(0,4)へRoll可能。
	# 右(1,5)へRoll可能。
	var d_05 = board.get_die_at(Vector2i(0, 5))
	var moves_05 = board.get_legal_moves_for_die(d_05)
	var endpoints_05: Array[Vector2i] = []
	for m in moves_05:
		endpoints_05.append(m.end_pos)
	print("Endpoints from (0,5): ", endpoints_05)
	assert(Vector2i(0, 4) in endpoints_05) # Roll Forward
	assert(Vector2i(1, 5) in endpoints_05) # Roll Right

	# 4. AI move selection
	var ai_move = AIPlayer.select_best_move(board, DittleLogic.PLAYER_2)
	assert(ai_move != null)
	print("AI chose move for die_id=", ai_move.die_id, " from: ", ai_move.start_pos, " to: ", ai_move.end_pos, " type: ", ai_move.move_type)

	print("=== All DittleLogic Tests PASSED! ===")
	quit(0)
