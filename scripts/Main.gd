class_name Main
extends Node2D

const DittleLogic = preload("res://scripts/DittleLogic.gd")
const AIPlayer = preload("res://scripts/AIPlayer.gd")
const BoardScript = preload("res://scripts/Board.gd")
const DiceScript = preload("res://scripts/Dice.gd")
const DiceScene = preload("res://scenes/Dice.tscn")

@export var is_vs_cpu: bool = true

# UI要素
@onready var board: Node2D = $Board
@onready var dice_container = $DiceContainer

@onready var p2_score_label = $UI/TopBar/MarginContainer/HBoxContainer/P2ScoreBox/ScoreLabel
@onready var p2_goal_label = $UI/TopBar/MarginContainer/HBoxContainer/P2ScoreBox/GoalCountLabel
@onready var turn_indicator = $UI/TopBar/MarginContainer/HBoxContainer/TurnBox/TurnLabel
@onready var p1_score_label = $UI/BottomBar/MarginContainer/HBoxContainer/P1ScoreBox/ScoreLabel
@onready var p1_goal_label = $UI/BottomBar/MarginContainer/HBoxContainer/P1ScoreBox/GoalCountLabel
@onready var help_label = $UI/BottomBar/MarginContainer/HBoxContainer/HelpBox/HelpLabel

# モーダルUI
@onready var pause_dialog = $UI/PauseDialog
@onready var pause_resume_btn = $UI/PauseDialog/Panel/VBoxContainer/ResumeBtn
@onready var game_over_dialog = $UI/GameOverDialog
@onready var go_result_label = $UI/GameOverDialog/Panel/VBoxContainer/ResultLabel
@onready var go_details_label = $UI/GameOverDialog/Panel/VBoxContainer/DetailsLabel
@onready var go_rematch_btn = $UI/GameOverDialog/Panel/VBoxContainer/RematchBtn

# 内部状態
var board_state: DittleLogic
var dice_nodes: Dictionary = {} # die_id -> Dice node
var selected_die_id: int = -1
var current_legal_moves: Array[DittleLogic.Move] = []
var is_animating: bool = false
var is_game_active: bool = true
var cycle_index: int = 0

func _ready():
	_start_new_match()

func _start_new_match():
	# 既存のダイスノードをクリーンアップ
	for child in dice_container.get_children():
		child.queue_free()
	dice_nodes.clear()

	board_state = DittleLogic.new()
	selected_die_id = -1
	current_legal_moves.clear()
	is_animating = false
	is_game_active = true
	cycle_index = 0

	board.clear_highlights()
	board.set_cursor(Vector2i(3, 3))

	# ダイスノードのインスタンス化
	for die_data in board_state.dice:
		var d_instance = DiceScene.instantiate()
		dice_container.add_child(d_instance)
		d_instance.position = board.grid_to_world(die_data.pos)
		d_instance.setup(die_data)
		dice_nodes[die_data.id] = d_instance

	_update_ui()
	_update_dice_visuals()

	# 初手P1
	_check_turn_start()

func _process(_delta: float):
	pass

func _input(event: InputEvent):
	if not is_game_active or is_animating:
		return

	# ポーズダイアログが開いているときは入力無視
	if pause_dialog.visible or game_over_dialog.visible:
		return

	# CPU手番中のプレイヤー入力はブロック
	if is_vs_cpu and board_state.current_player == DittleLogic.PLAYER_2:
		return

	# タッチ / マウスクリック対応
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_p = board.world_to_grid(event.position)
		board.set_cursor(grid_p)
		_handle_accept()
		return
	elif event is InputEventScreenTouch and event.pressed:
		var grid_p = board.world_to_grid(event.position)
		board.set_cursor(grid_p)
		_handle_accept()
		return

	# カーソル移動
	if event.is_action_pressed("ui_up"):
		board.move_cursor(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		board.move_cursor(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		board.move_cursor(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		board.move_cursor(Vector2i(1, 0))
	
	# クイックサイコロ切り替え (L1 / R1)
	elif event.is_action_pressed("ui_page_up"):
		_cycle_player_dice(-1)
	elif event.is_action_pressed("ui_page_down"):
		_cycle_player_dice(1)

	# 決定 (A ボタン)
	elif event.is_action_pressed("ui_accept"):
		_handle_accept()

	# キャンセル (B ボタン)
	elif event.is_action_pressed("ui_cancel"):
		if selected_die_id != -1:
			_deselect_die()
		else:
			_toggle_pause()

	# ポーズ (Start ボタン)
	elif event.is_action_pressed("pause"):
		_toggle_pause()

# カーソル位置でのAボタン処理
func _handle_accept():
	var cur_pos = board.cursor_pos
	var clicked_die = board_state.get_die_at(cur_pos)

	# 1. すでにダイスが選択されており、カーソル位置が合法移動先である場合
	if selected_die_id != -1:
		var chosen_move: DittleLogic.Move = null
		for m in current_legal_moves:
			if m.end_pos == cur_pos:
				chosen_move = m
				break

		if chosen_move != null:
			# 移動を実行
			_execute_move(chosen_move)
			return

	# 2. カーソル位置に現在手番プレイヤーのダイスがある場合（選択または切り替え）
	if clicked_die != null and clicked_die.owner == board_state.current_player:
		_select_die(clicked_die.id)
	else:
		# 移動先でもなく自軍ダイスでもない場合、選択解除
		_deselect_die()

func _select_die(die_id: int):
	var die = board_state.get_die_by_id(die_id)
	if not die or die.owner != board_state.current_player:
		return

	_deselect_die()
	selected_die_id = die_id
	board.set_cursor(die.pos)

	if dice_nodes.has(die_id):
		dice_nodes[die_id].set_selected(true)

	current_legal_moves = board_state.get_legal_moves_for_die(die)
	board.set_highlights(current_legal_moves, die.pos)
	_update_ui()

func _deselect_die():
	if selected_die_id != -1 and dice_nodes.has(selected_die_id):
		dice_nodes[selected_die_id].set_selected(false)
	selected_die_id = -1
	current_legal_moves.clear()
	board.clear_highlights()
	_update_ui()

# L1 / R1 で動かせるダイスを順にフォーカス
func _cycle_player_dice(direction: int):
	var p_dice = board_state.get_player_dice(board_state.current_player)
	if p_dice.is_empty():
		return

	cycle_index = (cycle_index + direction) % p_dice.size()
	if cycle_index < 0:
		cycle_index += p_dice.size()

	var target_die = p_dice[cycle_index]
	_select_die(target_die.id)

# 移動の実行（アニメーションシーケンス）
func _execute_move(move: DittleLogic.Move):
	is_animating = true
	var die_node = dice_nodes.get(move.die_id)
	_deselect_die()

	if not die_node:
		is_animating = false
		return

	# 各ステップ（RollまたはJump）を順次アニメーション
	var current_ori = die_node.die_data.orientation.duplicate()

	for step in move.steps:
		var target_world = board.grid_to_world(step.to_pos)
		if step.type == "roll":
			current_ori = DittleLogic.rotate_die_orientation(current_ori, step.direction)
			die_node.die_data.orientation = current_ori.duplicate()
			var tw = die_node.animate_roll(target_world, step.direction, 0.22)
			await tw.finished
		elif step.type == "jump":
			var tw = die_node.animate_jump(target_world, 0.3)
			await tw.finished

	# 最終状態の適用
	board_state.apply_move(move)
	die_node.setup(board_state.get_die_by_id(move.die_id))
	board.set_cursor(move.end_pos)

	_update_dice_visuals()
	_update_ui()

	is_animating = false

	# 勝利判定
	if board_state.is_game_over():
		_show_game_over()
		return

	# 次の手番へ
	_check_turn_start()

# ターン開始処理
func _check_turn_start():
	_update_ui()

	if is_vs_cpu and board_state.current_player == DittleLogic.PLAYER_2:
		# CPU手番
		turn_indicator.text = "CPU THINKING..."
		turn_indicator.modulate = Color("#f87171")
		
		# 短いディレイを挟んで自然な思考時間を演出
		await get_tree().create_timer(0.45).timeout
		if not is_game_active:
			return

		var cpu_move = AIPlayer.select_best_move(board_state, DittleLogic.PLAYER_2)
		if cpu_move != null:
			_execute_move(cpu_move)
		else:
			# 動かせる手がない場合はパス
			board_state.current_player = DittleLogic.PLAYER_1
			_check_turn_start()

# ダイスの状態（ゴールイン判定など）のビジュアル更新
func _update_dice_visuals():
	for d in board_state.dice:
		var node = dice_nodes.get(d.id)
		if node:
			node.setup(d)
			var in_goal = (d.owner == DittleLogic.PLAYER_1 and d.pos.y == 0) or (d.owner == DittleLogic.PLAYER_2 and d.pos.y == DittleLogic.BOARD_SIZE - 1)
			node.set_in_goal(in_goal)

# UIテキスト・スコア更新
func _update_ui():
	var scores = board_state.get_scores()
	p1_score_label.text = "%d pts" % scores["p1_score"]
	p1_goal_label.text = "Goal: %d/7" % scores["p1_goal_count"]

	var p2_name = "CPU" if is_vs_cpu else "P2"
	p2_score_label.text = "%s: %d pts" % [p2_name, scores["p2_score"]]
	p2_goal_label.text = "Goal: %d/7" % scores["p2_goal_count"]

	if board_state.current_player == DittleLogic.PLAYER_1:
		turn_indicator.text = "P1 TURN (BLUE)"
		turn_indicator.modulate = Color("#38bdf8")
	else:
		turn_indicator.text = ("CPU TURN (RED)" if is_vs_cpu else "P2 TURN (RED)")
		turn_indicator.modulate = Color("#f87171")

	if selected_die_id != -1:
		help_label.text = "[A] Move to target   [B] Cancel selection"
	else:
		help_label.text = "[D-Pad] Move   [A] Select   [L1/R1] Cycle   [Start] Pause"

# ポーズメニュー開閉
func _toggle_pause():
	if game_over_dialog.visible:
		return

	pause_dialog.visible = not pause_dialog.visible
	if pause_dialog.visible:
		pause_resume_btn.grab_focus()

func _on_pause_resume_pressed():
	pause_dialog.visible = false

func _on_pause_restart_pressed():
	pause_dialog.visible = false
	_start_new_match()

func _on_pause_title_pressed():
	get_tree().change_scene_to_file("res://scenes/Title.tscn")

# ゲーム終了ダイアログ表示
func _show_game_over():
	is_game_active = false
	var scores = board_state.get_scores()
	var winner = board_state.get_winner()

	var result_text = ""
	var result_color = Color("#ffffff")

	if winner == DittleLogic.PLAYER_1:
		result_text = "🎉 PLAYER 1 WINS!"
		result_color = Color("#38bdf8")
	elif winner == DittleLogic.PLAYER_2:
		result_text = ("🏆 CPU WINS!" if is_vs_cpu else "🎉 PLAYER 2 WINS!")
		result_color = Color("#f87171")
	else:
		result_text = "🤝 DRAW GAME!"
		result_color = Color("#fde047")

	go_result_label.text = result_text
	go_result_label.modulate = result_color

	var p2_title = "CPU" if is_vs_cpu else "Player 2"
	go_details_label.text = "[b]FINAL SCORE BREAKDOWN[/b]\n\n" \
		+ "[color=#38bdf8]Player 1 Score:[/color] %d pts (%d/7 in goal)\n" % [scores["p1_score"], scores["p1_goal_count"]] \
		+ "[color=#f87171]%s Score:[/color] %d pts (%d/7 in goal)" % [p2_title, scores["p2_score"], scores["p2_goal_count"]]

	game_over_dialog.visible = true
	go_rematch_btn.grab_focus()

func _on_game_over_rematch_pressed():
	game_over_dialog.visible = false
	_start_new_match()

func _on_game_over_title_pressed():
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
