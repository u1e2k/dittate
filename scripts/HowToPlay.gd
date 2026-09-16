class_name HowToPlay
extends Control

@onready var page_label = $MarginContainer/VBoxContainer/Header/PageLabel
@onready var content_label = $MarginContainer/VBoxContainer/ContentPanel/RichTextLabel
@onready var prev_btn = $MarginContainer/VBoxContainer/Footer/PrevButton
@onready var next_btn = $MarginContainer/VBoxContainer/Footer/NextButton
@onready var back_btn = $MarginContainer/VBoxContainer/Footer/BackButton

var current_page: int = 0

const PAGES = [
	{
		"title": "1. 目的 & 勝敗条件",
		"text": "[b][color=#38bdf8]■ ゲームの目的[/color][/b]\n自軍の[color=#38bdf8]7つのサイコロ[/color]を相手陣地のベース行（最奥列）へ進めます。\n\n[b][color=#fde047]■ ゲーム終了 & スコア[/color][/b]\nどちらかが[b]7個すべてのサイコロを相手ベース行に到達させた瞬間[/b]に終了します。\n相手ベース行に到達している自軍サイコロの[b][color=#fde047]天面（Top）の合計点[/color][/b]が高いプレイヤーが勝利となります！\n\n[color=#94a3b8]※早く到達させるだけでなく、高得点（5や6）の面を上にしてゴールさせることが勝利の鍵です。[/color]"
	},
	{
		"title": "2. 移動と回転（Tilt / Roll）",
		"text": "[b][color=#22c55e]■ 移動方向[/color][/b]\nサイコロは [b]前進（相手方向）・左・右[/b] の3方向にのみ移動できます。\n[color=#f87171]※ 後退（自陣方向）は一切禁止されています。[/color]\n\n[b][color=#38bdf8]■ 転がり移動（Tilt）[/color][/b]\n空いている隣接マスへ1マス進むと、サイコロが[b]90度転がり[/b]、出目が変化します。\n・初期状態: 天面=6, 前面(相手向き)=4\n・前へ1歩進む: 天面が [color=#fde047]3[/color] に変化\n・進む方向によって天面の数字がダイナミックに変化します！"
	},
	{
		"title": "3. ジャンプ & コンボ",
		"text": "[b][color=#f59e0b]■ ジャンプ（Jump）[/color][/b]\n隣接するサイコロ（味方・敵どちらでも）を[b]飛び越えて2マス先の空きマスへ移動[/b]できます。\n[b]★ ジャンプ中はサイコロは回転せず、出目を維持します！[/b]\n\n[b][color=#f59e0b]■ 連続ジャンプ（Chain Jump）[/color][/b]\nジャンプ着地後、さらに飛び越えられるサイコロがあれば、1手番中に連続でジャンプできます。\n\n[b][color=#eab308]■ 転がり＋ジャンプ（Combo）[/color][/b]\n1マスRoll（転がり）した直後、連続してJumpに繋げる強力なコンボも可能です！"
	},
	{
		"title": "4. 操作方法（RG Rotate / Gamepad）",
		"text": "[b][color=#38bdf8]■ 操作キー一覧[/color][/b]\n・[b]D-Pad / 左スティック[/b]: カーソル移動\n・[b]A ボタン / Enter[/b]: サイコロ選択 / 移動先決定\n・[b]B ボタン / Backspace[/b]: 選択キャンセル / 戻る\n・[b]L1 / R1 ボタン[/b]: 動かせる自軍サイコロを順にクイック選択\n・[b]Start ボタン[/b]: ポーズ / 中断メニュー\n\n[color=#94a3b8]直感的な操作でサクサク対局を楽しめます。[/color]"
	}
]

func _ready():
	_update_page()
	next_btn.grab_focus()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_page_up"):
		_prev_page()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_page_down"):
		_next_page()

func _update_page():
	page_label.text = "%s (%d / %d)" % [PAGES[current_page]["title"], current_page + 1, PAGES.size()]
	content_label.text = PAGES[current_page]["text"]
	prev_btn.disabled = (current_page == 0)
	next_btn.disabled = (current_page == PAGES.size() - 1)

func _next_page():
	if current_page < PAGES.size() - 1:
		current_page += 1
		_update_page()

func _prev_page():
	if current_page > 0:
		current_page -= 1
		_update_page()

func _on_prev_pressed():
	_prev_page()

func _on_next_pressed():
	_next_page()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
