extends RefCounted
## Shared game theme; source nodes and adaptations documented in assets/ui/figma/SOURCE.txt.
const GOLD=Color("c8aa6e")
const TEXT=Color("f0e6d2")
const SURFACE=Color("1e2328f2")

static func flat(fill:Color,border:Color,width:int=2) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=fill;s.border_color=border;s.set_border_width_all(width)
	s.content_margin_left=16;s.content_margin_right=16
	s.content_margin_top=8;s.content_margin_bottom=8
	return s

static func panel() -> StyleBoxTexture:
	var s:=StyleBoxTexture.new();s.texture=load("res://assets/ui/figma/panel.svg")
	s.texture_margin_left=24;s.texture_margin_right=24
	s.texture_margin_top=12;s.texture_margin_bottom=12
	s.content_margin_left=24;s.content_margin_right=24
	s.content_margin_top=20;s.content_margin_bottom=20
	return s

static func blue(state:String) -> StyleBoxTexture:
	var s:=StyleBoxTexture.new();s.texture=load("res://assets/ui/figma/blue_"+state+".svg")
	s.texture_margin_left=28;s.texture_margin_right=28
	s.texture_margin_top=10;s.texture_margin_bottom=10
	s.content_margin_left=32;s.content_margin_right=32
	s.content_margin_top=8;s.content_margin_bottom=8
	return s

static func heading_font() -> SystemFont:
	var font:=SystemFont.new();font.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	return font

static func create() -> Theme:
	var t:=Theme.new();t.default_font_size=18
	t.set_color("font_color","Label",TEXT)
	t.set_font("font","Button",heading_font())
	t.set_font_size("font_size","Button",19)
	t.set_color("font_color","Button",Color("cdbe91"))
	t.set_color("font_hover_color","Button",TEXT)
	t.set_color("font_pressed_color","Button",Color("b8a675"))
	t.set_color("font_disabled_color","Button",Color("777b80"))
	t.set_stylebox("normal","Button",flat(SURFACE,GOLD))
	var hover:=flat(SURFACE,Color("f0e5d7"));hover.shadow_color=Color("ffeabf66");hover.shadow_size=4
	t.set_stylebox("hover","Button",hover)
	t.set_stylebox("pressed","Button",flat(Color("11181e"),Color("857044")))
	t.set_stylebox("hover_pressed","Button",hover)
	t.set_stylebox("disabled","Button",flat(Color("161b20"),Color("494844")))
	t.set_stylebox("focus","Button",flat(Color.TRANSPARENT,Color("75d7ed")))
	t.set_stylebox("panel","Panel",panel());t.set_stylebox("panel","PanelContainer",panel())
	t.set_stylebox("panel","TooltipPanel",flat(Color("020b14f5"),GOLD,1))
	t.set_color("font_color","TooltipLabel",TEXT);t.set_font_size("font_size","TooltipLabel",17)
	t.set_stylebox("slider","HSlider",flat(Color("020b14"),GOLD,1))
	t.set_stylebox("grabber_area","HSlider",flat(Color("2586a0"),GOLD,1))
	return t

static func primary(b:Button) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(state,blue(state))
	b.add_theme_color_override("font_color",TEXT)
