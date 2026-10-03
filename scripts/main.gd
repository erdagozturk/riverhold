@tool
extends Node3D

const PLAN = preload("res://scripts/village_plan.gd")
const UNIT := preload("res://scripts/battle_unit.gd")
const ARROW := preload("res://scripts/arrow_projectile.gd")
const LIGHTNING := preload("res://scripts/altar_lightning.gd")
const BATTLEFIELD := preload("res://scripts/planned_battlefield.gd")
const CAMERA_CONTROL := preload("res://scripts/battle_camera.gd")

var augments = [preload("res://scripts/war_augments.gd").new(),preload("res://scripts/war_augments.gd").new()]
var team_caps := [20,20]
var team_income := [0,0]
var card_round := 0
var card_tier := 0
var recruit_queue: Array[int]=[]
var recruit_elapsed := 0.0
var augment_buttons: Array[Button] = []
var augment_title: Label
var combat_feedback: Node3D
var world_feedback: Node3D
var units: Array[BattleUnit] = []
var player_gold := 160
var enemy_gold := 160
var income_elapsed := 0.0
var enemy_spawn_elapsed := 0.0
var card_elapsed := 0.0
var game_time := 0.0
var player_defending := false
var player_spawn_index := 0
var enemy_spawn_index := 0
var enemy_role_index := 0
var player_kills := 0
var enemy_kills := 0
var population_cap := 20
var damage_multiplier := 1.0
var health_multiplier := 1.0
var income_bonus := 0
var match_over := false
var winner := -1
var blue_base: BattleUnit
var red_base: BattleUnit
var camera_rig: Node3D
var camera: Camera3D
var battlefield: Node3D
var status_label: Label
var blue_health: ProgressBar
var red_health: ProgressBar
var feedback_label: Label
var card_overlay: Control
var result_overlay: Control
var result_label: Label

func _ready() -> void:
	augments[1].team=1
	build_world()
	if Engine.is_editor_hint():
		return
	combat_feedback = preload("res://scripts/combat_feedback.gd").new()
	add_child(combat_feedback)
	combat_feedback.setup(camera_rig)
	world_feedback=preload("res://scripts/world_feedback.gd").new()
	add_child(world_feedback)
	build_ui()
	blue_base = spawn_base(0, PLAN.altar(0))
	red_base = spawn_base(1, PLAN.altar(1))
	spawn_initial_units()
	if not "--script" in OS.get_cmdline_args() and not "--smoke-test" in OS.get_cmdline_user_args():
		var shell=preload("res://scripts/game_shell.gd").new()
		shell.name="GameShell";add_child(shell);shell.setup(self)
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("run_smoke_test")

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if match_over: return
	prune_units()
	process_recruits(delta)
	game_time += delta
	income_elapsed += delta
	while income_elapsed >= 2.0:
		income_elapsed -= 2.0
		player_gold += 20 + income_bonus + team_income[0]
		enemy_gold += 20 + team_income[1]
	enemy_spawn_elapsed += delta
	if enemy_spawn_elapsed >= 3.5*pow(0.85,augments[1].count("training")):
		enemy_spawn_elapsed = 0.0
		spawn_unit(1, choose_enemy_role(), true)
		enemy_role_index += 1
	card_elapsed += delta
	if card_elapsed >= 30.0: open_card_choice()
	update_ui()

func build_world() -> void:
	battlefield = BATTLEFIELD.new()
	add_child(battlefield)
	battlefield.build()
	var backdrop=preload("res://scripts/cinematic_backdrop.gd").new()
	add_child(backdrop)
	backdrop.setup()
	if not Engine.is_editor_hint():
		var cycle=preload("res://scripts/day_night.gd").new()
		add_child(cycle)
		cycle.setup(battlefield)
		var render_director=preload("res://scripts/render_director.gd").new()
		add_child(render_director);render_director.setup(battlefield)
	camera_rig = CAMERA_CONTROL.new()
	add_child(camera_rig)
	camera_rig.setup()
	camera = camera_rig.camera

func spawn_base(team: int, pos: Vector3) -> BattleUnit:
	var base := UNIT.new()
	add_child(base)
	base.position = pos
	base.configure(self, team, 0, 0.0, true)
	base.unit_died.connect(on_unit_died)
	units.append(base)
	return base

func spawn_initial_units() -> void:
	spawn_unit(0, 0, false)
	spawn_unit(1, 0, false)

func role_cost(role: int) -> int:
	return [40, 60, 80][role]

func population(team: int) -> int:
	var count := 0
	for unit in units:
		if is_instance_valid(unit) and not unit.dead and not unit.is_base and unit.team == team: count += 1
	return count

func spawn_unit(team: int, role: int, charge: bool) -> bool:
	if match_over or population(team) >= team_caps[team]: return false
	var cost: int = ceili(role_cost(role)*augments[team].cost_multiplier())
	if charge:
		if team == 0 and player_gold < cost:
			feedback_label.text = "Yetersiz altın" if feedback_label else ""
			return false
		if team == 1 and enemy_gold < cost: return false
		if team == 0: player_gold -= cost
		else: enemy_gold -= cost
	var formation_index := player_spawn_index if team == 0 else enemy_spawn_index
	if team == 0: player_spawn_index += 1
	else: enemy_spawn_index += 1
	var slot := population(team)
	var lane_order: Array[int] = [0, 1]
	var lane: int = lane_order[slot % 2]
	var column := slot / 2
	var lane_z := (lane - 0.5) * 1.1
	var unit := UNIT.new()
	add_child(unit)
	unit.position = PLAN.recruit_position(team,lane_z,column)
	unit.configure(self, team, role, lane_z)
	unit.spawn_order = formation_index
	unit.formation_row = column
	unit.defense_x = PLAN.side(team)*PLAN.DEFENSE_X
	unit.deployment_route = PLAN.recruit_route(team,lane_z)
	unit.deploying = true
	unit.hold_defense = player_defending if team == 0 else false
	if team == 0:
		unit.apply_damage_multiplier(damage_multiplier)
		unit.apply_health_multiplier(health_multiplier)
	augments[team].apply_unit(unit)
	unit.unit_died.connect(on_unit_died)
	units.append(unit)
	refresh_team_formation(team)
	if team == 0 and feedback_label: feedback_label.text = ["Hızlı üretildi", "Menzilli üretildi", "Tank üretildi"][role]
	return true

func spawn_arrow(source: BattleUnit, target: BattleUnit, amount: float) -> void:
	var arrow := ARROW.new()
	add_child(arrow)
	arrow.global_position = source.bow_socket.global_position if is_instance_valid(source.bow_socket) else source.global_position + Vector3.UP * 1.0
	arrow.setup(self, source, target, amount)

func spawn_stone(source: BattleUnit, target: BattleUnit, amount: float) -> void:
	var stone := ARROW.new()
	add_child(stone)
	stone.global_position = source.global_position + Vector3.UP * 3.2
	stone.setup(self, source, target, amount, "stone")

func spawn_altar_lightning(source: BattleUnit,target: BattleUnit,amount: float) -> void:
	var lightning:=LIGHTNING.new()
	add_child(lightning)
	lightning.setup(source,target,amount)

func on_unit_died(unit: BattleUnit) -> void:
	if match_over: return
	if unit.is_base:
		end_match(1 - unit.team)
		return
	combat_feedback.reward(unit.global_position, unit.team == 1)
	units.erase(unit)
	if unit.team == 1:
		player_gold += augments[0].reward_amount()
		player_kills += 1
		feedback_label.text = "Ganimet toplandı"
	else:
		enemy_gold += augments[1].reward_amount()
		enemy_kills += 1
	refresh_team_formation(unit.team)

func refresh_team_formation(team: int) -> void:
	var living: Array[BattleUnit] = []
	for unit_variant in units:
		if not is_instance_valid(unit_variant): continue
		var unit: BattleUnit = unit_variant as BattleUnit
		if is_instance_valid(unit) and not unit.dead and not unit.is_base and unit.team == team:
			living.append(unit)
	living.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.spawn_order < b.spawn_order)
	var lane_order: Array[int] = [0, 1]
	for index in living.size():
		var unit := living[index]
		var lane: int = lane_order[index % 2]
		unit.formation_row = index / 2
		unit.lane_z = (lane - 0.5) * 1.1

func set_defending(enabled: bool) -> void:
	player_defending = enabled
	for unit in units:
		if is_instance_valid(unit) and unit.team == 0 and not unit.is_base and not unit.dead:
			unit.hold_defense = enabled
	feedback_label.text = "Köy kapısında savun" if enabled else "Ordu ilerliyor"

func open_card_choice() -> void:
	if match_over or card_overlay.visible: return
	camera_rig.finish_drag()
	card_round += 1
	# A single shared rarity roll; neither team rolls its own quality.
	var chance := randf()
	card_tier = 2 if chance < 0.12 else (1 if chance < 0.45 else 0)
	for book in augments:book.roll(card_tier)
	augment_title.text = "%s • BİR GÜÇLENDİRME SEÇ" % ["GÜMÜŞ","ALTIN","PRİZMATİK"][card_tier]
	for i in 3:
		var card: Dictionary = augments[0].offered[i]
		augment_buttons[i].get_node("Tag").text=card.tag
		augment_buttons[i].get_node("Title").text=card.name
		augment_buttons[i].get_node("Description").text=card.desc
		augment_buttons[i].tooltip_text = "Mevcut seviye: %d / %d" % [augments[0].count(card.id),card.max]
		augment_buttons[i].modulate = Color.WHITE
	card_overlay.get_parent().get_parent().refresh_cards()
	card_overlay.visible = true
	get_tree().paused = true

func choose_card(index: int) -> void:
	if not card_overlay.visible: return
	if not augments[0].choose(self,index):return
	var enemy_choice := randi_range(0,2)
	augments[1].choose(self,enemy_choice)
	feedback_label.text += " • Rakip: "+str(augments[1].offered[enemy_choice].name)
	card_elapsed = 0.0
	card_overlay.visible = false
	get_tree().paused = false

func end_match(winning_team: int) -> void:
	if match_over: return
	camera_rig.finish_drag()
	match_over = true
	winner = winning_team
	get_tree().paused = false
	result_label.text = "ZAFER" if winner == 0 else "YENİLGİ"
	result_label.modulate = Color("62e875") if winner == 0 else Color("ff5b4d")
	result_overlay.visible = true

func prune_units() -> void:
	units = units.filter(func(unit): return is_instance_valid(unit))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: request_recruit(0)
		elif event.keycode == KEY_2: request_recruit(1)
		elif event.keycode == KEY_3: request_recruit(2)
		elif event.keycode == KEY_F: set_defending(false)
		elif event.keycode == KEY_G: set_defending(true)

func build_ui() -> void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var hud=preload("res://scripts/battle_hud.gd").new()
	hud.name="BattleHUD"
	layer.add_child(hud)
	hud.setup(self)

func update_ui() -> void:
	if not status_label: return
	status_label.text = "Altın: %d   Nüfus: %d/%d   Skor: %d-%d   Kart: %ds   Emir: %s" % [player_gold, population(0), population_cap, player_kills, enemy_kills, maxi(0, ceili(30.0-card_elapsed)), "SAVUN" if player_defending else "İLERLE"]
	blue_health.max_value = blue_base.max_health if is_instance_valid(blue_base) else 600.0
	blue_health.value = blue_base.health if is_instance_valid(blue_base) else 0.0
	red_health.max_value = red_base.max_health if is_instance_valid(red_base) else 600.0
	red_health.value = red_base.health if is_instance_valid(red_base) else 0.0

func make_panel(parent: Control, pos: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new(); panel.position = pos; panel.size = size
	var style := StyleBoxFlat.new(); style.bg_color = color; style.corner_radius_top_left = 12; style.corner_radius_top_right = 12; style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12; style.border_width_left = 2; style.border_width_right = 2; style.border_width_top = 2; style.border_width_bottom = 2; style.border_color = color.lightened(0.25)
	panel.add_theme_stylebox_override("panel", style); parent.add_child(panel); return panel

func make_label(parent: Control, text: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new(); label.text = text; label.position = pos; label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", Color.WHITE); parent.add_child(label); return label

func make_button(parent: Control, text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var button := Button.new(); button.text = text; button.position = pos; button.size = size; button.add_theme_font_size_override("font_size", 21)
	var normal := StyleBoxFlat.new(); normal.bg_color = color; normal.corner_radius_top_left = 12; normal.corner_radius_top_right = 12; normal.corner_radius_bottom_left = 12; normal.corner_radius_bottom_right = 12; normal.border_width_left = 3; normal.border_width_right = 3; normal.border_width_top = 3; normal.border_width_bottom = 3; normal.border_color = color.lightened(0.28)
	var hover := normal.duplicate(); hover.bg_color = color.lightened(0.12)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", hover); parent.add_child(button); return button

func make_overlay(parent: Control) -> Control:
	var overlay := ColorRect.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.color = Color(0.015, 0.02, 0.03, 0.84); overlay.process_mode = Node.PROCESS_MODE_ALWAYS; parent.add_child(overlay); return overlay

func run_smoke_test() -> void:
	player_gold = 2000
	for index in 10:
		spawn_unit(0, index % 3, true)
	await get_tree().process_frame
	var living_player: Array[BattleUnit] = []
	var lane_values: Dictionary = {}
	for unit in units:
		if is_instance_valid(unit) and unit.team == 0 and not unit.is_base and not unit.dead:
			living_player.append(unit)
			lane_values[snappedf(unit.lane_z, 0.01)] = true
	var minimum_spacing := INF
	var team_glow_ok := living_player.size() > 0 and living_player[0].has_team_glow()
	var team_light_ok := living_player.size() > 0 and living_player[0].has_team_light()
	var ground_markers_removed := living_player.size() > 0 and not living_player[0].has_ground_marker()
	var walk_loop_ok := false
	if living_player.size() > 0 and living_player[0].anim_player:
		living_player[0].play_animation("walk")
		var walk_animation := living_player[0].anim_player.get_animation(living_player[0].anim_player.current_animation)
		walk_loop_ok = walk_animation != null and walk_animation.loop_mode == Animation.LOOP_LINEAR
	for a_index in living_player.size():
		for b_index in range(a_index + 1, living_player.size()):
			minimum_spacing = minf(minimum_spacing, BattleUnit.flat_distance(living_player[a_index].global_position, living_player[b_index].global_position))
	# Combat fixtures place units directly, after separate route tests.
	for fixture in units:
		if is_instance_valid(fixture): fixture.deploying=false
	var ranged: BattleUnit
	for unit in living_player:
		if unit.role == 1:
			ranged = unit
			break
	var enemy: BattleUnit
	for unit in units:
		if is_instance_valid(unit) and unit.team == 1 and not unit.is_base and not unit.dead:
			enemy = unit
			break
	var lane_targeting_ok := false
	var support_targeting_ok := false
	var fifo_blocking_ok := false
	var stalled_leader_bypass_ok := false
	var facing_ok := false
	var fast_melee_contact_ok := false
	var troop_priority_over_base_ok := false
	var base_stone_defense_ok := false
	if enemy:
		for unit in living_player:
			if is_equal_approx(unit.lane_z, enemy.lane_z):
				lane_targeting_ok = unit.find_target() == enemy
			elif unit.find_target() == enemy:
				support_targeting_ok = true
		var priority_target := living_player[0].find_target()
		troop_priority_over_base_ok = is_instance_valid(priority_target) and not priority_target.is_base
	if living_player.size() >= 2:
		var older := living_player[0]
		var newer := living_player[1]
		var older_position := older.global_position
		var newer_position := newer.global_position
		older.global_position = Vector3(0.0, 0.35, older.lane_z)
		newer.global_position = Vector3(-0.05, 0.35, newer.lane_z)
		fifo_blocking_ok = newer.movement_blocked(Vector3.RIGHT)
		stalled_leader_bypass_ok = not newer.movement_blocked(Vector3.RIGHT, true)
		older.global_position = older_position
		newer.global_position = newer_position
		older.face_target(older.global_position + Vector3.RIGHT)
		newer.face_target(newer.global_position + Vector3.LEFT)
		facing_ok = is_equal_approx(older.rotation.y, PI * 0.5) and is_equal_approx(newer.rotation.y, -PI * 0.5)
	if enemy:
		for unit in living_player:
			if unit.role != 0 or is_equal_approx(unit.lane_z, enemy.lane_z): continue
			var fast_position := unit.global_position
			var enemy_position := enemy.global_position
			var enemy_health := enemy.health
			unit.global_position = Vector3(-0.2, 0.35, unit.lane_z)
			enemy.global_position = Vector3(0.2, 0.35, enemy.lane_z)
			unit.target = enemy
			unit.attacking = false
			unit.cooldown = 0.0
			unit._process(0.01)
			unit._process(0.3)
			fast_melee_contact_ok = enemy.health < enemy_health
			unit.attacking = false
			unit.target = null
			unit.global_position = fast_position
			enemy.global_position = enemy_position
			enemy.health = enemy_health
			break
	var projectile_damage_ok := false
	if ranged and enemy:
		ranged.global_position = Vector3(-1.0, 0.35, 0.0)
		enemy.global_position = Vector3(1.0, 0.35, 0.0)
		var before_health := enemy.health
		spawn_arrow(ranged, enemy, 7.0)
		await get_tree().create_timer(0.6).timeout
		projectile_damage_ok = enemy.health <= before_health - 7.0
	if red_base and living_player.size() > 2:
		var stone_target := living_player[2]
		var stone_target_position := stone_target.global_position
		stone_target.global_position = red_base.global_position + Vector3.LEFT*4.8
		var health_before_stone := stone_target.health
		red_base.base_attack_cooldown = 0.0
		red_base.update_base_defense(0.01)
		await get_tree().create_timer(1.0).timeout
		base_stone_defense_ok = stone_target.health <= health_before_stone - red_base.damage
		stone_target.global_position = stone_target_position
	var pause_unit := living_player[0]
	var before_pause_time := game_time
	var before_pause_gold := player_gold
	var before_pause_position := pause_unit.global_position
	open_card_choice()
	await get_tree().create_timer(0.5, true).timeout
	var full_pause_ok := game_time == before_pause_time and player_gold == before_pause_gold and pause_unit.global_position.is_equal_approx(before_pause_position)
	var selected_id: String=augments[0].offered[0].id
	var before_stack: int=augments[0].count(selected_id)
	choose_card(0)
	var card_applied: bool=augments[0].count(selected_id)==before_stack+1
	var dead_unit: BattleUnit = living_player[1]
	dead_unit.take_damage(99999.0, enemy)
	await get_tree().create_timer(3.3).timeout
	var death_cleanup_ok := not is_instance_valid(dead_unit)
	var spawn_after_cleanup_ok := spawn_unit(0, 0, false)
	var compacted_players: Array[BattleUnit] = []
	for unit_variant in units:
		if not is_instance_valid(unit_variant): continue
		var compacted_unit: BattleUnit = unit_variant as BattleUnit
		if is_instance_valid(compacted_unit) and not compacted_unit.dead and not compacted_unit.is_base and compacted_unit.team == 0:
			compacted_players.append(compacted_unit)
	compacted_players.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.spawn_order < b.spawn_order)
	var formation_compaction_ok := true
	for index in compacted_players.size():
		if compacted_players[index].formation_row != index / 2:
			formation_compaction_ok = false
			break
	var report := {
		"lanes": lane_values.size(),
		"minimum_spawn_spacing": snappedf(minimum_spacing, 0.01),
		"team_glow": team_glow_ok,
		"team_light": team_light_ok,
		"ground_markers_removed": ground_markers_removed,
		"walk_animation_loop": walk_loop_ok,
		"projectile_damage": projectile_damage_ok,
		"full_card_pause": full_pause_ok,
		"selected_card_applied": card_applied,
		"death_cleanup": death_cleanup_ok,
		"spawn_after_cleanup": spawn_after_cleanup_ok,
		"formation_compaction": formation_compaction_ok,
		"same_lane_targeting": lane_targeting_ok,
		"adjacent_lane_support": support_targeting_ok,
		"fifo_blocking": fifo_blocking_ok,
		"stalled_leader_bypass": stalled_leader_bypass_ok,
		"fast_melee_contact": fast_melee_contact_ok,
		"troop_priority_over_base": troop_priority_over_base_ok,
		"base_stone_defense": base_stone_defense_ok,
		"opposing_facing": facing_ok,
		"passed": lane_values.size() == 2 and minimum_spacing >= 0.7 and minimum_spacing <= 0.75 and team_glow_ok and team_light_ok and ground_markers_removed and walk_loop_ok and projectile_damage_ok and base_stone_defense_ok and troop_priority_over_base_ok and full_pause_ok and card_applied and death_cleanup_ok and spawn_after_cleanup_ok and formation_compaction_ok and lane_targeting_ok and support_targeting_ok and fifo_blocking_ok and stalled_leader_bypass_ok and fast_melee_contact_ok and facing_ok
	}
	print("FETIH_SMOKE " + JSON.stringify(report))
	get_tree().quit(0 if report.passed else 1)

func choose_enemy_role() -> int:
	var counts := [0,0,0]
	for u in units:
		if is_instance_valid(u) and not u.dead and not u.is_base and u.team==0:counts[u.role]+=1
	if randf()<0.35:return randi_range(0,2)
	if counts[1]>counts[0]+counts[2]:return 2 if randf()<0.55 else 0
	if counts[2]>counts[0]:return 1 if randf()<0.25 else 2
	return enemy_role_index%3

func request_recruit(role: int) -> bool:
	if match_over or get_tree().paused or role<0 or role>2:return false
	if recruit_queue.size()>=6 or population(0)+recruit_queue.size()>=team_caps[0]:return false
	var cost: int=ceili(role_cost(role)*augments[0].cost_multiplier())
	if player_gold<cost:return false
	player_gold-=cost
	recruit_queue.append(role)
	feedback_label.text=["Akıncı","Okçu","Barbar"][role]+" eğitim sırasına alındı"
	return true

func process_recruits(delta: float) -> void:
	if recruit_queue.is_empty():recruit_elapsed=0.0;return
	recruit_elapsed+=delta
	var duration: float=[1.0,1.8,2.6][recruit_queue[0]]*pow(0.85,augments[0].count("training"))
	if recruit_elapsed>=duration and spawn_unit(0,recruit_queue[0],false):
		recruit_elapsed=0.0
		recruit_queue.pop_front()
