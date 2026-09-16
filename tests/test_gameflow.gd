extends SceneTree

const AIPlayer = preload("res://scripts/AIPlayer.gd")

func _init():
	_run_test()

func _run_test():
	print("=== Running Game Flow Simulation ===")
	var main_scene = load("res://scenes/Main.tscn")
	var main_node = main_scene.instantiate()
	main_node.is_vs_cpu = true
	root.add_child(main_node)

	# 1フレーム待機して _ready() を完了させる
	await process_frame

	# 最初の状態確認
	print("Initial current player: ", main_node.board_state.current_player)
	assert(main_node.board_state.current_player == 1)

	# P1の手を1つ選んで実行
	var p1_moves = main_node.board_state.get_all_legal_moves(1)
	print("P1 legal moves count: ", p1_moves.size())
	assert(p1_moves.size() > 0)

	var move_p1 = p1_moves[0]
	print("Executing P1 move: die_id=", move_p1.die_id, " to: ", move_p1.end_pos)
	main_node.board_state.apply_move(move_p1)
	assert(main_node.board_state.current_player == 2)
	print("Current player after P1 move: ", main_node.board_state.current_player)

	# P2 (CPU) の手を評価・選択
	var p2_move = AIPlayer.select_best_move(main_node.board_state, 2)
	assert(p2_move != null)
	print("CPU selected move: die_id=", p2_move.die_id, " to: ", p2_move.end_pos)
	main_node.board_state.apply_move(p2_move)
	assert(main_node.board_state.current_player == 1)
	print("Current player after CPU move: ", main_node.board_state.current_player)

	main_node.queue_free()
	print("=== Game Flow Simulation PASSED! ===")
	quit(0)
