extends Control
const FantasyUI=preload("res://scripts/fantasy_theme.gd")
var game: Node
var design: Control
var recruit_buttons: Array[Button]=[]
var gold: Label
var army: Label
var clock_label: Label
var owned: Label
var queue_label: Label
var training: ProgressBar
var attack: Button
var defend: Button
var confirm: Button
var selected := -1
var last_round := -1
var serif := SystemFont.new()
const GOLD=Color("c8a567")
const PALE=Color("f2dfb6")
const INK=Color("0c141f")

func label(parent: Node,text: String,pos: Vector2,dimensions: Vector2,font_size: int=20,display: bool=false) -> Label:
	var l:=Label.new();l.text=text;l.position=pos;l.size=dimensions;l.mouse_filter=MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",PALE if display else Color("e4e8e9"))
	if display:l.add_theme_font_override("font",serif)
	parent.add_child(l);return l

func style(fill: Color,border: Color=GOLD,width: int=1) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=fill;s.border_color=border;s.set_border_width_all(width);s.set_corner_radius_all(3)
	s.shadow_color=Color(0,0,0,0.7);s.shadow_size=5;s.shadow_offset=Vector2(0,2)
	return s

func panel(parent: Node,pos: Vector2,dimensions: Vector2) -> Panel:
	var p:=Panel.new();p.position=pos;p.size=dimensions;p.add_theme_stylebox_override("panel",FantasyUI.panel());parent.add_child(p);return p

func button(parent: Node,text: String,pos: Vector2,dimensions: Vector2) -> Button:
	var b:=Button.new();b.text=text;b.position=pos;b.size=dimensions;b.add_theme_font_size_override("font_size",19);b.add_theme_color_override("font_color",PALE)
	parent.add_child(b);return b

func picture(parent: Node,path: String,pos: Vector2,dimensions: Vector2) -> TextureRect:
	var t:=TextureRect.new();t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.texture=load(path);t.position=pos;t.stretch_mode=TextureRect.STRETCH_SCALE;t.mouse_filter=MOUSE_FILTER_IGNORE;parent.add_child(t);t.size=dimensions;t.set_deferred("size",dimensions);return t

func bar(parent: Node,pos: Vector2,dimensions: Vector2,color: Color) -> ProgressBar:
	var b:=ProgressBar.new();b.position=pos;b.size=dimensions;b.show_percentage=false;b.mouse_filter=MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("background",style(Color("030a11"),Color("4f4d40")))
	var fill=style(color,color.lightened(0.25));fill.shadow_size=0;b.add_theme_stylebox_override("fill",fill);parent.add_child(b);return b

func setup(g: Node) -> void:
	game=g;theme=FantasyUI.create();serif.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE
	design=Control.new();design.size=Vector2(1600,900);design.mouse_filter=MOUSE_FILTER_IGNORE;add_child(design)
	for team in 2:
		var p=panel(design,Vector2(22 if team==0 else 1190,18),Vector2(388,76))
		label(p,"MAVİ SUNAK" if team==0 else "KIRMIZI SUNAK",Vector2(18,8),Vector2(340,26),21,true)
		var health=bar(p,Vector2(18,40),Vector2(352,21),Color("1479b8") if team==0 else Color("b52b39"))
		var values=label(health,"",Vector2.ZERO,health.size,15);values.name="Values";values.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if team==0:game.blue_health=health
		else:game.red_health=health
	var economy=panel(design,Vector2(535,12),Vector2(530,72))
	gold=label(economy,"",Vector2(22,25),Vector2(150,33),29,true);label(economy,"HAZİNE",Vector2(22,7),Vector2(150,20),12)
	army=label(economy,"",Vector2(185,29),Vector2(155,27),19);label(economy,"ORDU",Vector2(185,7),Vector2(160,20),12)
	clock_label=label(economy,"",Vector2(361,15),Vector2(150,44),17)
	var pause=button(design,"II",Vector2(1550,110),Vector2(30,32));pause.tooltip_text="Duraklat • Esc";pause.pressed.connect(func():
		var shell=game.get_node_or_null("GameShell")
		if shell:shell.show_pause())
	var watch=button(design,"Savaşı izle",Vector2(1350,110),Vector2(148,32));watch.pressed.connect(game.camera_rig.watch_battle)
	var reset=button(design,"⌖",Vector2(1510,110),Vector2(30,32));reset.tooltip_text="Kamerayı sıfırla\nOrta tuş: döndür • Shift + orta tuş: kaydır • Tekerlek: yakınlaş";reset.pressed.connect(game.camera_rig.reset_view)
	var units=panel(design,Vector2(495,728),Vector2(610,158))
	label(units,"ORDUNU KUR",Vector2(17,-29),Vector2(350,28),17,true)
	for i in 3:
		var b=button(units,"",Vector2(15+i*198,12),Vector2(184,133));recruit_buttons.append(b);b.pressed.connect(func():game.request_recruit(i))
		b.tooltip_text=["Akıncı: okçulara karşı güçlü. 1 saniyede eğitilir.","Okçu: arkadan destek. Barbarlar oklara dirençlidir. 1,8 saniyede eğitilir.","Barbar: ön safta okları karşılar. 2,6 saniyede eğitilir."][i]
		var t:=TextureRect.new();t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;var atlas:=AtlasTexture.new();atlas.atlas=load("res://assets/characters/portraits/"+["rogue","ranger","barbarian"][i]+".png");atlas.region=Rect2(650,260,300,440)
		t.texture=atlas;t.position=Vector2(18,8);t.size=Vector2(62,107);t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;t.mouse_filter=MOUSE_FILTER_IGNORE;b.add_child(t);t.size=Vector2(62,107);t.set_deferred("size",Vector2(62,107))
		label(b,["Akıncı","Okçu","Barbar"][i],Vector2(84,30),Vector2(99,26),21,true)
		var cost=label(b,"",Vector2(84,62),Vector2(99,25),18);cost.name="Cost";cost.modulate=PALE
		var availability=label(b,"EĞİT",Vector2(84,91),Vector2(96,36),12);availability.name="Availability";availability.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(b,str(i+1),Vector2(8,5),Vector2(18,18),12).modulate=GOLD
	var orders=panel(design,Vector2(1120,770),Vector2(330,116))
	label(orders,"ORDU EMRİ",Vector2(15,8),Vector2(300,22),16,true)
	attack=button(orders,"SALDIR",Vector2(12,37),Vector2(147,62));attack.pressed.connect(func():game.set_defending(false))
	defend=button(orders,"SAVUN",Vector2(171,37),Vector2(147,62));defend.pressed.connect(func():game.set_defending(true))
	var queue=panel(design,Vector2(150,770),Vector2(330,116))
	label(queue,"EĞİTİM SIRASI",Vector2(15,8),Vector2(300,22),16,true)
	queue_label=label(queue,"",Vector2(15,37),Vector2(300,45),16);queue_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	training=bar(queue,Vector2(15,91),Vector2(300,8),Color("b8924d"))
	owned=label(design,"",Vector2(160,695),Vector2(1280,28),15);owned.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;owned.modulate=GOLD
	game.feedback_label=label(design,"",Vector2(400,657),Vector2(800,28),16);game.feedback_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.status_label=Label.new();game.status_label.hide();design.add_child(game.status_label)
	resized.connect(layout_ui)
	layout_ui()
	attack.toggle_mode=true;defend.toggle_mode=true
	build_cards()
	game.result_overlay=game.make_overlay(design)
	var result=panel(game.result_overlay,Vector2(530,260),Vector2(540,330))
	game.result_label=label(result,"",Vector2(20,58),Vector2(500,90),52,true);game.result_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(result,"ANA MENÜYE DÖN",Vector2(110,220),Vector2(320,60)).pressed.connect(func():get_tree().paused=false;get_tree().reload_current_scene())
	game.result_overlay.hide()


func build_cards() -> void:
	game.card_overlay=game.make_overlay(design)
	var backing=panel(game.card_overlay,Vector2(185,128),Vector2(1230,614))
	backing.mouse_filter=MOUSE_FILTER_IGNORE
	game.augment_title=label(game.card_overlay,"",Vector2(205,138),Vector2(1190,58),34,true);game.augment_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for i in 3:
		var b=button(game.card_overlay,"",Vector2(235+i*395,195),Vector2(340,510))
		for key in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(key,StyleBoxEmpty.new())
		picture(b,"res://assets/ui/fetih/card-frame.png",Vector2.ZERO,b.size)
		var art=picture(b,"res://assets/ui/fetih/valor.png",Vector2(55,77),Vector2(230,220));art.name="Art"
		var title=label(b,"",Vector2(37,280),Vector2(266,57),25,true);title.name="Title";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var desc=label(b,"",Vector2(42,342),Vector2(256,100),17);desc.name="Description";desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var marker=label(b,"",Vector2(55,470),Vector2(230,24),14,true);marker.name="Selection";marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var tag=label(b,"",Vector2(45,444),Vector2(250,25),12);tag.name="Tag";tag.modulate=GOLD;tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		b.focus_entered.connect(func():select_card(i))
		b.pressed.connect(func():select_card(i));b.mouse_entered.connect(func():if selected!=i:b.modulate=Color(1.12,1.12,1.12));b.mouse_exited.connect(func():update_selection())
		game.augment_buttons.append(b)
	confirm=button(game.card_overlay,"BİR KART SEÇ",Vector2(655,759),Vector2(290,62));confirm.add_theme_font_override("font",serif);confirm.add_theme_font_size_override("font_size",27)
	confirm.pressed.connect(func():if selected>=0:game.choose_card(selected));confirm.disabled=true;FantasyUI.primary(confirm)
	var help=label(game.card_overlay,"Rakip de aynı nadirlikte bir güçlendirme alır.",Vector2(320,837),Vector2(960,28),16);help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.card_overlay.hide()

func select_card(index: int) -> void:
	selected=index;confirm.disabled=false;confirm.text="SEÇ";update_selection()

func update_selection() -> void:
	for i in 3:
		var b: Button=game.augment_buttons[i]
		b.modulate=Color.WHITE if selected<0 or selected==i else Color("b2b4be")
		b.position.y=185 if selected==i else 195
		b.get_node("Selection").text="SEÇİLDİ" if selected==i else ""

func refresh_cards() -> void:
	selected=-1;confirm.disabled=true;confirm.text="BİR KART SEÇ";update_selection()
	for i in 3:
		var card: Dictionary=game.augments[0].offered[i]
		var protective: bool=card.id in ["armor","vitality","iron_skin","mobilization","fortification","medics","bulwark","last_stand"] or card.id.begins_with("repair") or card.id.begins_with("vigor")
		var illustration: String="bastion.png" if protective else "valor.png"
		if card.id in ["logistics","spoils","war_economy"] or card.id.begins_with("reserve"):illustration="provisions.png"
		if card.id in ["training","march","weaponsmiths"]:illustration="haste.png"
		game.augment_buttons[i].get_node("Art").texture=load("res://assets/ui/fetih/"+illustration)

func layout_ui() -> void:
	if not is_instance_valid(design):return
	var factor:=minf(size.x/1600.0,size.y/900.0)
	design.scale=Vector2.ONE*factor;design.position=(size-Vector2(1600,900)*factor)*0.5

func _process(_delta: float) -> void:
	if not game:return
	gold.text=str(game.player_gold)+" Altın";army.text="%d / %d" % [game.population(0),game.team_caps[0]]
	clock_label.text="%02d:%02d\nKart: %ds" % [int(game.game_time)/60,int(game.game_time)%60,maxi(0,ceili(30-game.card_elapsed))]
	for health in [game.blue_health,game.red_health]:health.get_node("Values").text="%d / %d" % [health.value,health.max_value]
	var names: Array[String]=[]
	for role in game.recruit_queue:names.append(["Akıncı","Okçu","Barbar"][role])
	queue_label.text=" → ".join(names) if not names.is_empty() else "Birlik kartına tıkla"
	training.visible=not names.is_empty()
	if training.visible:training.value=100*game.recruit_elapsed/([1.0,1.8,2.6][game.recruit_queue[0]]*pow(0.85,game.augments[0].count("training")))
	attack.set_pressed_no_signal(not game.player_defending);defend.set_pressed_no_signal(game.player_defending)
	attack.text="◆ SALDIR" if not game.player_defending else "SALDIR"
	defend.text="◆ SAVUN" if game.player_defending else "SAVUN"
	for i in 3:
		var cost:int=ceili(game.role_cost(i)*game.augments[0].cost_multiplier());recruit_buttons[i].get_node("Cost").text=str(cost)+" Altın"
		var reason:=""
		if game.match_over:reason="Savaş sona erdi"
		elif game.recruit_queue.size()>=6:reason="Eğitim sırası dolu"
		elif game.population(0)+game.recruit_queue.size()>=game.team_caps[0]:reason="Ordu kapasitesi dolu"
		elif game.player_gold<cost:reason="%d altın eksik" % (cost-game.player_gold)
		recruit_buttons[i].disabled=not reason.is_empty()
		recruit_buttons[i].get_node("Availability").text=reason if not reason.is_empty() else "EĞİT"
		recruit_buttons[i].get_node("Availability").modulate=Color("edab83") if not reason.is_empty() else GOLD
	var perks: Array[String]=[]
	for c in game.augments[0].CARDS:
		var n:int=game.augments[0].count(c.id)
		if n>0:perks.append(c.name+" ×"+str(n))
	owned.text="   •   ".join(perks.slice(0,4));owned.tooltip_text="\n".join(perks)
	queue_redraw()

func _draw() -> void:
	if not game or not is_instance_valid(game.camera):return
	for u in game.units:
		if not is_instance_valid(u) or u.dead or u.is_base or u.health>=u.max_health:continue
		var world:Vector3=u.global_position+Vector3.UP*(2.3 if u.role==2 else 1.95)
		if game.camera.is_position_behind(world):continue
		var at:Vector2=game.camera.unproject_position(world)
		var scale_factor:float=clampf(24.0/game.camera.global_position.distance_to(world),0.8,1.4)
		var width:float=50.0*scale_factor;var height:float=6.0*scale_factor
		var rect:=Rect2(at-Vector2(width*0.5,height*0.5),Vector2(width,height))
		draw_rect(rect.grow(2),Color("10151be6"));draw_rect(Rect2(rect.position,Vector2(width*clampf(u.health/u.max_health,0,1),height)),Color("65cce7") if u.team==0 else Color("f17869"))



