extends SceneTree
func _init():
	var c = ConfigFile.new()
	c.set_value("A", "B", "C")
	print(c.encode_to_text())
	quit()
