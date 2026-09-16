extends SceneTree

func _init():
	print("=== Testing Scene Instantiation ===")

	var scenes = [
		"res://scenes/Title.tscn",
		"res://scenes/HowToPlay.tscn",
		"res://scenes/Board.tscn",
		"res://scenes/Dice.tscn",
		"res://scenes/Main.tscn"
	]

	for s_path in scenes:
		print("Loading scene: ", s_path)
		var p_scene = load(s_path)
		assert(p_scene != null, "Failed to load: " + s_path)
		var instance = p_scene.instantiate()
		assert(instance != null, "Failed to instantiate: " + s_path)
		print("  -> Instantiated successfully: ", instance.name)
		instance.queue_free()

	print("=== All Scenes Instantiated Successfully! ===")
	quit(0)
