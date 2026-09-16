class_name Title
extends Control

@onready var btn_1p = $MarginContainer/VBoxContainer/MenuButtons/Btn1P
@onready var btn_2p = $MarginContainer/VBoxContainer/MenuButtons/Btn2P
@onready var btn_how = $MarginContainer/VBoxContainer/MenuButtons/BtnHowToPlay
@onready var btn_quit = $MarginContainer/VBoxContainer/MenuButtons/BtnQuit
@onready var title_letters_container = $MarginContainer/VBoxContainer/LogoContainer/LettersHBox

# タイトルロゴアニメーション用
var letter_labels: Array[Label] = []

func _ready():
	# ボタンの初期フォーカス設定
	btn_1p.grab_focus()
	
	# ロゴ文字のアニメーション初期化
	for child in title_letters_container.get_children():
		if child is Label:
			letter_labels.append(child)
			child.pivot_offset = child.size / 2.0
	
	_play_title_intro_animation()

func _play_title_intro_animation():
	var delay = 0.05
	for i in range(letter_labels.size()):
		var label = letter_labels[i]
		label.rotation = -PI / 2.0
		label.scale = Vector2(0.2, 0.2)
		label.modulate.a = 0.0

		var tween = create_tween().set_parallel(true)
		tween.tween_property(label, "rotation", 0.0, 0.45).set_delay(i * delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2.ONE, 0.45).set_delay(i * delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 1.0, 0.3).set_delay(i * delay)

func _on_btn_1p_pressed():
	# 1 Player vs CPU
	var main_scene = load("res://scenes/Main.tscn")
	var instance = main_scene.instantiate()
	instance.is_vs_cpu = true
	get_tree().root.add_child(instance)
	get_tree().current_scene = instance
	queue_free()

func _on_btn_2p_pressed():
	# 2 Players
	var main_scene = load("res://scenes/Main.tscn")
	var instance = main_scene.instantiate()
	instance.is_vs_cpu = false
	get_tree().root.add_child(instance)
	get_tree().current_scene = instance
	queue_free()

func _on_btn_how_to_play_pressed():
	get_tree().change_scene_to_file("res://scenes/HowToPlay.tscn")

func _on_btn_quit_pressed():
	get_tree().quit()
