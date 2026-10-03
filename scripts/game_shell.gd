extends CanvasLayer
const FantasyUI=preload("res://scripts/fantasy_theme.gd")
var game: Node
var root: Control
var column: VBoxContainer
var heading: Label
var started := false
var recorded := false
var page := ""
var config := ConfigFile.new()

func setup(g: Node) -> void:
	game=g
	layer=30
	process_mode=Node.PROCESS_MODE_ALWAYS
	config.load("user://preferences.cfg")
	AudioServer.set_bus_volume_db(0,linear_to_db(float(config.get_value("settings","volume",0.7))))
	root=Control.new();root.theme=FantasyUI.create();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
	var shade:=ColorRect.new();shade.color=Color(0.025,0.04,0.065,0.94);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(shade)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(center)
	var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(580,0);center.add_child(frame)
	column=VBoxContainer.new();column.custom_minimum_size=Vector2(520,0);column.add_theme_constant_override("separation",14);frame.add_child(column)
	show_menu()

func clear(title: String, key: String) -> void:
	page=key;root.show();get_tree().paused=true
	game.camera_rig.finish_drag()
	for child in column.get_children():column.remove_child(child);child.queue_free()
	heading=label(title,38)
	heading.add_theme_font_override("font",FantasyUI.heading_font())
	heading.add_theme_color_override("font_color",Color("e4c68b"))

func label(text: String,font: int=20) -> Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",font);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(l);return l

func button(text: String,action: Callable) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=50;b.add_theme_font_size_override("font_size",20)
	column.add_child(b);b.pressed.connect(action)
	if text in ["SAVAŞA HAZIRLAN","SAVAŞI BAŞLAT","DEVAM ET"]:FantasyUI.primary(b)
	return b

func show_menu() -> void:
	clear("FETİH  •  KÖPRÜ MUHAREBESİ","menu")
	label("Tek çağ • İki köy • Bir geçit",19)
	label("Kazanılan savaş: %d" % int(config.get_value("profile","wins",0)),17)
	button("SAVAŞA HAZIRLAN",show_briefing)
	button("AYARLAR",show_settings)
	button("OYUNDAN ÇIK",func():get_tree().quit())

func show_briefing() -> void:
	clear("GEÇİDİ ELE GEÇİR","briefing")
	label("Rakibin köyündeki sunağı yık. Kendi sunağını koru.\n\nAkıncı okçuyu avlar. Barbar okları karşılar.\nOkçu arka saftan destek verir.\n\nBirlik kartlarına tıklayarak eğitim sırası oluştur.\nHer 30 saniyede üç güçlendirmeden birini seç.\nİki takım aynı nadirlikte seçenekler alır.")
	button("SAVAŞI BAŞLAT",resume_battle)
	button("GERİ",show_menu)

func resume_battle() -> void:
	started=true;root.hide();page="battle";get_tree().paused=false

func show_pause() -> void:
	clear("SAVAŞ DURAKLATILDI","pause")
	button("DEVAM ET",resume_battle)
	button("AYARLAR",show_settings)
	button("ANA MENÜYE DÖN",confirm_leave)

func confirm_leave() -> void:
	clear("MEVCUT SAVAŞ SONLANDIRILSIN MI?","leave")
	label("Bu maçın ilerlemesi kaydedilmez.")
	button("SAVAŞA DÖN",resume_battle)
	button("ANA MENÜYE DÖN",func():get_tree().paused=false;get_tree().reload_current_scene())

func show_settings() -> void:
	clear("AYARLAR","settings")
	label("Ses seviyesi")
	var slider:=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=0.05;slider.value=db_to_linear(AudioServer.get_bus_volume_db(0));column.add_child(slider)
	slider.value_changed.connect(func(v):AudioServer.set_bus_volume_db(0,linear_to_db(v));config.set_value("settings","volume",v);config.save("user://preferences.cfg"))
	var fullscreen:=CheckButton.new();fullscreen.text="Tam ekran";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;column.add_child(fullscreen)
	fullscreen.toggled.connect(func(v):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED))
	label("Orta tuş: kamerayı döndür\nShift + orta tuş: kaydır • Tekerlek: yakınlaş\n1 / 2 / 3: birlik • F / G: saldır / savun • Esc: duraklat",17)
	button("GERİ",show_pause if started else show_menu)

func _input(event: InputEvent) -> void:
	if not game:return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		if game.card_overlay.visible or game.match_over:return
		if started:
			if root.visible:resume_battle()
			else:show_pause()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if game and game.match_over and not recorded:
		recorded=true
		if game.winner==0:config.set_value("profile","wins",int(config.get_value("profile","wins",0))+1)
		config.set_value("profile","matches",int(config.get_value("profile","matches",0))+1)
		config.save("user://preferences.cfg")

