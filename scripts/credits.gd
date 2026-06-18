extends Control

var scroll_speed: float = 60.0
var vbox: VBoxContainer
var screen_height: float = 720.0
var finished: bool = false

func _ready():
	# Background space texture
	var bg_tex = TextureRect.new()
	bg_tex.texture = load("res://assets/bg_ref.jpg")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Modulate with the final tier color (Theme 9 - Gold/Yellow)
	bg_tex.modulate = Color(0.35, 0.3, 0.1, 1.0)
	add_child(bg_tex)

	# Blur overlay ColorRect using blur.gdshader
	var blur_overlay = ColorRect.new()
	blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://shaders/blur.gdshader")
	blur_overlay.material = shader_material
	add_child(blur_overlay)

	# Black overlay for extra contrast
	var dark_overlay = ColorRect.new()
	dark_overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dark_overlay)
	
	# Scroll content container
	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 35)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(800, 0)
	add_child(vbox)
	
	# Start below the screen
	vbox.position.y = screen_height
	
	# Title
	var title = Label.new()
	title.text = "ranotot"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(title)
	
	# Credits sections
	_add_credit_section("game design, directed, and developed by", "pandiajason")
	_add_credit_section("dedicated to", "daughter isai and loving wife elam")
	
	# Story / AI note
	var story_text = "the game concept was imagined by pandiajason, who built a godot connector to make antigravity work. it is 100% llm-generated, using claude for tasks, chatgpt for art, gemini for bgm, and antigravity for development. from imagination to ranotot was made possible with agentic ai."
	_add_body_text(story_text)
	
	# Fun Facts
	var fun_fact_text = "fun fact: the name ranotot is complete gibberish. i got this name while preparing formula milk for my daughter. the name hikki studios was born when i woke up during a bus journey."
	_add_body_text(fun_fact_text)
	
	# Meaning of Hikki
	var hikki_text = "hope you enjoyed ranotot! hikki is also complete gibberish, and in japanese hikki refers to a person who stays in their room for days or months—which is exactly what gamers do!"
	_add_body_text(hikki_text)
	
	# Final slogan
	var slogan = Label.new()
	slogan.text = "let's hikki!"
	slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slogan.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	slogan.add_theme_font_size_override("font_size", 44)
	slogan.add_theme_color_override("font_color", Color.WHITE)
	slogan.add_theme_constant_override("outline_size", 10)
	slogan.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(slogan)
	
	# Add a skip button in the top right corner
	var skip_btn = UIFactory.create_glass_button("skip", UIFactory.GOLD_COLOR)
	skip_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip_btn.position = Vector2(1280 - 150, 20)
	skip_btn.pressed.connect(_finish_credits)
	add_child(skip_btn)

func _add_credit_section(role: String, name_str: String):
	var label_role = Label.new()
	label_role.text = role
	label_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_role.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	label_role.add_theme_font_size_override("font_size", 20)
	label_role.add_theme_color_override("font_color", Color.WHITE)
	label_role.add_theme_constant_override("outline_size", 6)
	label_role.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(label_role)
	
	var label_name = Label.new()
	label_name.text = name_str
	label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_name.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	label_name.add_theme_font_size_override("font_size", 32)
	label_name.add_theme_color_override("font_color", Color.WHITE)
	label_name.add_theme_constant_override("outline_size", 8)
	label_name.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(label_name)

func _add_body_text(text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.custom_minimum_size = Vector2(800, 0)
	vbox.add_child(lbl)

func _process(delta: float):
	if finished:
		return
		
	# Center horizontally and scroll upwards
	vbox.position.x = (size.x - vbox.size.x) / 2.0
	vbox.position.y -= scroll_speed * delta
	
	# If scrolled past the top of the screen
	if vbox.position.y + vbox.size.y < 0:
		_finish_credits()

func _finish_credits():
	finished = true
	SceneTransition.transition_to("res://scenes/menu.tscn")
