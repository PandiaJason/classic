extends Node

# Shared UI styling for a consistent gold glass look
const GOLD_COLOR = Color(1, 0.8, 0.2, 0.8)
const BLUE_COLOR = Color(0.2, 0.6, 1.0, 0.8)
const RED_COLOR = Color(1.0, 0.3, 0.3, 0.8)
const GREEN_COLOR = Color(0.2, 0.8, 0.2, 0.8)
const PURPLE_COLOR = Color(0.7, 0.3, 1.0, 0.8)

func create_glass_panel(border_color: Color = BLUE_COLOR) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_right = 15
	style.corner_radius_bottom_left = 15
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func create_glass_button(text: String, color: Color = BLUE_COLOR, icon_path: String = "") -> Button:
	var btn = Button.new()
	btn.text = " " + text
	
	if icon_path != "":
		var tex = ResourceManager.get_texture(icon_path)
		if tex:
			btn.icon = tex
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 30)
			
	btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	btn.add_theme_font_size_override("font_size", 28)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.4)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_right = 15
	style.corner_radius_bottom_left = 15
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(color.r, color.g, color.b, 0.7)
	
	var focus_style = hover_style.duplicate()
	focus_style.border_color = Color(1.0, 1.0, 1.0, 1.0)
	focus_style.border_width_left = 4
	focus_style.border_width_right = 4
	focus_style.border_width_top = 4
	focus_style.border_width_bottom = 4
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", focus_style)
	# By default all generated buttons are focusable for controller navigation
	btn.focus_mode = Control.FOCUS_ALL
	return btn
