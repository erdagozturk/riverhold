class_name BattleUnit
extends Node3D

signal unit_died(unit: BattleUnit)

static var role_libraries: Dictionary = {}
var bow_socket: Node3D
var since_damage := 0.0
var impact_tween: Tween
var last_stand_spent := false
var battle: Node
var team := 0
var role := 0
var is_base := false
var max_health := 100.0
var health := 100.0
var damage := 20.0
var move_speed := 2.0
var attack_range := 1.25
var attack_contact := 0.32
var attack_duration := 0.85
var attack_cooldown := 0.2
var cooldown := 0.0
var attack_elapsed := 0.0
var attacking := false
var damage_released := false
var movement_stalled := false
var formation_wait_elapsed := 0.0
var base_attack_cooldown := 0.0
var dead := false
var hold_defense := false
var defense_x := 0.0
var lane_z := 0.0
var spawn_order := 0
var formation_row := 0
var death_elapsed := 0.0
var death_delay := 1.15
var death_duration := 1.8
var death_start_position := Vector3.ZERO
var death_start_scale := Vector3.ONE
var target: BattleUnit
var visual_anchor: Node3D
var anim_player: AnimationPlayer
var current_anim := ""
var original_visual_scale := Vector3.ONE
var team_light: OmniLight3D
var deploying := false
var deployment_route: Array[Vector3] = []
var deployment_index := 0

func configure(p_battle: Node, p_team: int, p_role: int, p_lane_z: float, p_is_base := false) -> void:
	battle = p_battle
	team = p_team
	role = p_role
	lane_z = p_lane_z
	is_base = p_is_base
	if is_base:
		max_health = 600.0
		health = max_health
		damage = 18.0
		move_speed = 0.0
		attack_range = 6.4
		build_base_visual()
		return
	match role:
		0:
			max_health = 70.0; damage = 18.0; move_speed = 3.2; attack_range = 0.78
			attack_contact = 0.28; attack_duration = 0.82; attack_cooldown = 0.18
		1:
			max_health = 55.0; damage = 15.0; move_speed = 2.25; attack_range = 4.4
			attack_contact = 0.45; attack_duration = 1.15; attack_cooldown = 0.35
		2:
			max_health = 180.0; damage = 30.0; move_speed = 1.45; attack_range = 0.88
			attack_contact = 0.52; attack_duration = 1.25; attack_cooldown = 0.35
	health = max_health
	build_character_visual()

func build_base_visual() -> void:
	name="BlueAltar" if team==0 else "RedAltar"
	for i in 3:
		var step:=MeshInstance3D.new()
		var cylinder:=CylinderMesh.new()
		cylinder.top_radius=1.7-i*0.28
		cylinder.bottom_radius=cylinder.top_radius
		cylinder.height=0.24
		cylinder.radial_segments=8
		step.mesh=cylinder
		step.position.y=0.12+i*0.24
		step.material_override=battle.battlefield.materials.trim
		add_child(step)
	var core_mat:=make_material(Color("2697bb") if team==0 else Color("ba4037"))
	core_mat.emission_enabled=true
	core_mat.emission=core_mat.albedo_color
	core_mat.emission_energy_multiplier=0.55
	for upper in [false,true]:
		var crystal:=MeshInstance3D.new()
		var mesh:=CylinderMesh.new()
		mesh.radial_segments=6
		mesh.top_radius=0.0 if upper else 0.65
		mesh.bottom_radius=0.65 if upper else 0.0
		mesh.height=1.05 if upper else 0.55
		crystal.mesh=mesh
		crystal.position.y=1.52 if upper else 0.72
		crystal.material_override=core_mat
		add_child(crystal)
	var light:=OmniLight3D.new()
	light.light_color=core_mat.albedo_color
	light.light_energy=1.0;light.omni_range=4.0
	light.position.y=1.4
	add_child(light)

func advance_deployment(delta: float) -> void:
	if deployment_index>=deployment_route.size():
		deploying=false
		return
	var goal:=deployment_route[deployment_index]
	var speed:=move_speed
	# Recruits travel at the older cohort's pace, preventing a fast recruit overtaking its tank.
	for other in battle.units:
		if not is_instance_valid(other) or other.dead or other.is_base or other.team!=team: continue
		if other.deploying and other.spawn_order<spawn_order: speed=minf(speed,other.move_speed)
		# The shorter inside turn must not let later recruits enter the battle first.
		if deployment_index==2 and other.deploying and other.spawn_order<spawn_order and other.deployment_index<2:
			play_animation("idle")
			return
	var old:=global_position
	var next:=old.move_toward(goal,speed*delta)
	# Only physically overlapping predecessors hold this path; no global front-row dependency.
	for other in battle.units:
		if not is_instance_valid(other) or other==self or other.dead or other.is_base or other.team!=team: continue
		if other.spawn_order>=spawn_order: continue
		if flat_distance(next,other.global_position)<0.69 and flat_distance(next,other.global_position)<flat_distance(old,other.global_position):
			play_animation("idle")
			return
	face_target(goal)
	global_position=next
	if old.distance_to(next)>0.001: play_animation("walk")
	else: play_animation("idle")
	if flat_distance(next,goal)<0.03:
		deployment_index+=1
		if deployment_index>=deployment_route.size(): deploying=false

func build_character_visual() -> void:
	visual_anchor = Node3D.new()
	visual_anchor.name = "Visual"
	add_child(visual_anchor)
	var scene: PackedScene = load("res://assets/characters/models/"+["Rogue","Ranger","Barbarian"][role]+".glb")
	if scene:
		var model := scene.instantiate()
		visual_anchor.add_child(model)
		apply_team_glow(model)
		anim_player = AnimationPlayer.new()
		model.add_child(anim_player)
		anim_player.add_animation_library("",character_library(role))
		var skeleton: Skeleton3D = model.get_node("Rig_Medium/Skeleton3D")
		var socket:=BoneAttachment3D.new()
		socket.bone_name="handslot.l" if role==1 else "handslot.r"
		skeleton.add_child(socket)
		var weapon: Node3D=load("res://assets/characters/weapons/"+["dagger","bow_withString","sword_2handed"][role]+".gltf").instantiate()
		socket.add_child(weapon)
		if role==1:
			# KayKit bow's authored forward axis is opposite to the hand socket.
			weapon.rotation_degrees.y=180.0
			bow_socket=socket
		var s := 0.70 if role == 0 else (0.78 if role == 1 else 1.02)
		visual_anchor.scale = Vector3.ONE * s
		original_visual_scale = visual_anchor.scale
	else:
		var fallback := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.38 if role != 2 else 0.52
		capsule.height = 1.55 if role != 2 else 1.9
		fallback.mesh = capsule
		fallback.position.y = capsule.height * 0.5
		fallback.material_override = make_material(Color("4ba7ff") if team == 0 else Color("f15b4a"))
		visual_anchor.add_child(fallback)
	add_team_light()
	play_animation("idle")

func add_team_light() -> void:
	team_light = OmniLight3D.new()
	team_light.name = "TeamGlow"
	team_light.light_color = Color("3398ff") if team == 0 else Color("ff4038")
	team_light.light_energy = 0.24
	team_light.omni_range = 1.75 if role != 2 else 2.05
	team_light.omni_attenuation = 1.65
	team_light.shadow_enabled = false
	team_light.position = Vector3(0.0, 0.9, 0.0)
	add_child(team_light)

func apply_team_glow(root: Node) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		stylize_character_mesh(mesh_instance)
		var glow := ShaderMaterial.new()
		glow.shader=preload("res://shaders/team_rim.gdshader")
		glow.set_shader_parameter("team_color",Color("3b9cff") if team==0 else Color("ff5148"))
		mesh_instance.material_overlay = glow
	for child in root.get_children():
		apply_team_glow(child)

func stylize_character_mesh(mesh_instance: MeshInstance3D) -> void:
	if not mesh_instance.mesh:
		return
	var styled_mesh: Mesh = mesh_instance.mesh.duplicate()
	for surface_index in styled_mesh.get_surface_count():
		var original := mesh_instance.get_active_material(surface_index)
		if original is StandardMaterial3D:
			var material: StandardMaterial3D = original.duplicate()
			material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			material.specular_mode = BaseMaterial3D.SPECULAR_TOON
			material.metallic = 0.0
			material.metallic_specular = 0.46
			material.roughness = clampf(material.roughness, 0.70, 0.88)
			if material.normal_enabled:
				material.normal_scale = minf(material.normal_scale, 0.55)
			styled_mesh.surface_set_material(surface_index, material)
	mesh_instance.mesh = styled_mesh

func has_team_glow(root: Node = null) -> bool:
	var inspected := root if root else visual_anchor
	if not inspected: return false
	if inspected is MeshInstance3D and (inspected as MeshInstance3D).material_overlay != null:
		return true
	for child in inspected.get_children():
		if has_team_glow(child): return true
	return false

func has_team_light() -> bool:
	return is_instance_valid(team_light) and team_light.light_energy >= 0.2 and team_light.omni_range >= 1.7

func has_ground_marker() -> bool:
	for child in get_children():
		if child is MeshInstance3D: return true
	return false

func find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found := find_animation_player(child)
		if found: return found
	return null

static func character_library(unit_role: int) -> AnimationLibrary:
	if role_libraries.has(unit_role):return role_libraries[unit_role]
	var library:=AnimationLibrary.new()
	for group in ["General","MovementBasic","CombatRanged" if unit_role==1 else "CombatMelee"]:
		var donor: Node=load("res://assets/characters/animations/Rig_Medium_"+group+".glb").instantiate()
		for player in donor.find_children("*","AnimationPlayer",true,false):
			for clip in player.get_animation_list():
				if library.has_animation(clip):continue
				var animation: Animation=player.get_animation(clip).duplicate()
				animation.loop_mode=Animation.LOOP_LINEAR if clip in ["Walking_A","Idle_A","Ranged_Bow_Idle","Melee_2H_Idle"] else Animation.LOOP_NONE
				library.add_animation(clip,animation)
		donor.free()
	role_libraries[unit_role]=library
	return library

func play_animation(kind: String) -> void:
	if not anim_player or (current_anim==kind and anim_player.is_playing()):return
	var clip: String={"idle":["Idle_A","Ranged_Bow_Idle","Melee_2H_Idle"][role],"walk":"Walking_A","attack":["Melee_1H_Attack_Slice_Horizontal","Ranged_Bow_Draw","Melee_2H_Attack_Chop"][role],"death":"Death_A","release":"Ranged_Bow_Release"}.get(kind,"Idle_A")
	if not anim_player.has_animation(clip):return
	var animation:=anim_player.get_animation(clip)
	var speed:=1.0
	if kind=="walk":speed=move_speed/2.6
	if kind=="attack":speed=animation.length/(attack_contact if role==1 else attack_duration)
	if kind=="release":speed=animation.length/maxf(0.1,attack_duration-attack_contact)
	anim_player.play(clip,0.10,speed)
	current_anim=kind

func _process(delta: float) -> void:
	if dead:
		update_death_removal(delta)
		return
	if not battle or battle.match_over: return
	if is_base:
		update_base_defense(delta)
		return
	since_damage += delta
	var medics: int = battle.augments[team].count("medics")
	if since_damage>4.0 and medics>0:
		health=minf(max_health,health+max_health*0.012*medics*delta)
	if deploying:
		advance_deployment(delta)
		return
	if attacking:
		if not is_instance_valid(target) or target.dead or not target_allowed(target):
			attacking = false
			damage_released = false
			target = null
		else:
			face_target(target.global_position)
			movement_stalled = false
			formation_wait_elapsed = 0.0
			update_attack(delta)
			return
	# Yeni çıkan veya daha yakına giren düşman, üs hedefinden ve uzaktaki
	# eski hedeften hemen önceliklidir. Böylece birliklerin içinden geçilmez.
	target = find_target()
	if not target:
		if hold_defense: move_to_defense(delta)
		else: play_animation("idle")
		return
	face_target(target.global_position)
	cooldown = maxf(0.0, cooldown - delta)
	var distance := flat_distance(global_position, target.global_position)
	var reach := attack_reach(target)
	if distance <= reach:
		movement_stalled = false
		formation_wait_elapsed = 0.0
		play_animation("idle")
		if cooldown <= 0.0: begin_attack()
		return
	var movement_goal := Vector3(target.global_position.x, global_position.y, lane_z)
	# Hedef yan koridordaysa önce düzeni koru, temas bölgesinde ise hedefe
	# çapraz yaklaş. Aksi halde aynı X çizgisinde kalıp vuramıyordu.
	if absf(target.global_position.x - global_position.x) <= reach + 0.7:
		movement_goal.z = target.global_position.z
	var direction := flat_direction(global_position, movement_goal)
	if direction.length_squared() < 0.001:
		movement_stalled = true
		play_animation("idle")
		return
	formation_wait_elapsed = 0.0
	movement_stalled = false
	var effective_speed := formation_move_speed()
	global_position += direction * minf(effective_speed * delta, maxf(0.0, distance - reach))
	apply_friendly_separation()
	play_animation("walk")

func target_allowed(candidate: BattleUnit) -> bool:
	if not hold_defense: return true
	return not candidate.is_base and absf(candidate.global_position.x - defense_x) <= 5.2

func find_target() -> BattleUnit:
	var best: BattleUnit
	var best_score := INF
	var forward_sign := 1.0 if team == 0 else -1.0
	for candidate in battle.units:
		if not is_instance_valid(candidate) or candidate == self or candidate.dead or candidate.team == team: continue
		if not target_allowed(candidate) or candidate.is_base or candidate.deploying: continue
		var dx: float = (candidate.global_position.x - global_position.x) * forward_sign
		var score := absf(candidate.global_position.x - global_position.x) + absf(candidate.global_position.z - global_position.z) * 0.35
		if dx < -0.8: score += 4.0
		if score < best_score:
			best_score = score
			best = candidate
	if best:
		return best
	# Sahada rakip kalmadığında üs hedeflenir.
	for candidate in battle.units:
		if not is_instance_valid(candidate) or candidate.dead or candidate.team == team or not candidate.is_base: continue
		if not target_allowed(candidate): continue
		var distance := flat_distance(global_position, candidate.global_position)
		if distance < best_score:
			best_score = distance
			best = candidate
	return best

func attack_reach(candidate: BattleUnit) -> float:
	return attack_range + candidate.body_radius()

func body_radius() -> float:
	if is_base: return 1.75
	return 0.58 if role == 2 else 0.45

func formation_move_speed() -> float:
	var result := move_speed
	var my_progress := global_position.x if team == 0 else -global_position.x
	for unit_variant in battle.units:
		if not is_instance_valid(unit_variant): continue
		var friendly: BattleUnit = unit_variant as BattleUnit
		if not is_instance_valid(friendly) or friendly == self or friendly.dead or friendly.is_base or friendly.team != team: continue
		if friendly.spawn_order >= spawn_order or friendly.is_in_combat_contact() or friendly.movement_stalled: continue
		var older_progress := friendly.global_position.x if team == 0 else -friendly.global_position.x
		if older_progress >= my_progress - 0.1 and older_progress - my_progress <= 2.5:
			result = minf(result, friendly.move_speed)
	return result

func apply_friendly_separation() -> void:
	for unit_variant in battle.units:
		if not is_instance_valid(unit_variant): continue
		var friendly: BattleUnit = unit_variant as BattleUnit
		if not is_instance_valid(friendly) or friendly == self or friendly.dead or friendly.is_base or friendly.team != team: continue
		var offset := global_position - friendly.global_position
		offset.y = 0.0
		var distance := offset.length()
		var minimum := (body_radius() + friendly.body_radius()) * 0.82
		if distance <= 0.001 or distance >= minimum: continue
		var correction := offset.normalized() * (minimum - distance) * 0.52
		correction.x *= 0.2
		global_position += correction
	global_position.z = clampf(global_position.z, -0.68, 0.68)

func update_base_defense(delta: float) -> void:
	base_attack_cooldown = maxf(0.0, base_attack_cooldown - delta)
	if base_attack_cooldown > 0.0: return
	var nearest: BattleUnit
	var nearest_distance := INF
	for unit_variant in battle.units:
		if not is_instance_valid(unit_variant): continue
		var enemy: BattleUnit = unit_variant as BattleUnit
		if not is_instance_valid(enemy) or enemy.dead or enemy.is_base or enemy.team == team: continue
		var distance := flat_distance(global_position, enemy.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	if nearest:
		battle.spawn_altar_lightning(self, nearest, damage)
		base_attack_cooldown = 1.35

func movement_blocked(direction: Vector3, ignore_formation := false) -> bool:
	for unit_variant in battle.units:
		if not is_instance_valid(unit_variant): continue
		var friendly: BattleUnit = unit_variant as BattleUnit
		if not is_instance_valid(friendly) or friendly == self or friendly.dead or friendly.is_base or friendly.team != team: continue
		# Aynı sıradakiler yan yana hizalanır. Sıra dolduğunda yeni birlikler
		# sıkı bir arka sıra kurar ve öndeki sırayı geçmez.
		if not ignore_formation and friendly.spawn_order < spawn_order and is_formation_leader(friendly) and not friendly.attacking and not friendly.movement_stalled and not friendly.is_in_combat_contact():
			var my_progress := global_position.x if team == 0 else -global_position.x
			var older_progress := friendly.global_position.x if team == 0 else -friendly.global_position.x
			var row_gap := 0.08 if formation_row == friendly.formation_row else 0.72 * float(formation_row - friendly.formation_row)
			if my_progress >= older_progress - row_gap and direction.x * (1.0 if team == 0 else -1.0) > 0.05:
				return true
		var offset: Vector3 = friendly.global_position - global_position
		offset.y = 0.0
		var forward: float = offset.dot(direction)
		if forward <= 0.0 or forward >= 0.72: continue
		var lateral := absf(offset.cross(direction).y)
		if lateral < 0.62: return true
	return false

func is_formation_leader(candidate: BattleUnit) -> bool:
	for unit_variant in battle.units:
		if not is_instance_valid(unit_variant): continue
		var teammate: BattleUnit = unit_variant as BattleUnit
		if not is_instance_valid(teammate) or teammate.dead or teammate.is_base or teammate.team != team: continue
		if teammate.formation_row == candidate.formation_row and teammate.spawn_order < candidate.spawn_order:
			return false
	return true

func is_in_combat_contact() -> bool:
	return is_instance_valid(target) and not target.dead and flat_distance(global_position, target.global_position) <= attack_reach(target) + 0.25

func move_to_defense(delta: float) -> void:
	var desired := Vector3(defense_x, global_position.y, lane_z)
	if flat_distance(global_position, desired) < 0.12:
		play_animation("idle")
		return
	var direction := flat_direction(global_position, desired)
	if movement_blocked(direction):
		play_animation("idle")
		return
	face_target(desired)
	global_position += direction * minf(move_speed * delta, flat_distance(global_position, desired))
	play_animation("walk")

func begin_attack() -> void:
	if dead or not is_instance_valid(target) or target.dead: return
	attacking = true
	movement_stalled = false
	damage_released = false
	attack_elapsed = 0.0
	play_animation("attack")

func update_attack(delta: float) -> void:
	attack_elapsed += delta
	if not damage_released and attack_elapsed >= attack_contact:
		damage_released = true
		if is_instance_valid(target) and not target.dead and flat_distance(global_position, target.global_position) <= attack_reach(target) + 0.3:
			if role == 1:
				play_animation("release")
				battle.spawn_arrow(self, target, damage)
			else: target.take_damage(damage, self)
	if attack_elapsed >= attack_duration:
		attacking = false
		cooldown = attack_cooldown
		play_animation("idle")

func take_damage(amount: float, _source: BattleUnit, secondary := false) -> void:
	if dead or amount <= 0.0: return
	since_damage=0.0
	if is_instance_valid(_source) and not secondary and not _source.is_base:
		var book = battle.augments[_source.team]
		if not is_base:
			if _source.role==1 and role==2:amount*=0.55
			if _source.role==0 and role==1:amount*=1.35*pow(1.25,book.count("hunter"))
			if _source.role==2 and role==0:amount*=1.2
			if _source.role==1:
				for ally in battle.units:
					if is_instance_valid(ally) and not ally.dead and ally.team==team and ally.role==2 and not ally.is_base and flat_distance(ally.global_position,global_position)<2.3:
						amount*=pow(0.85,battle.augments[team].count("bulwark"));break
		if randf()<0.10*book.count("critical"):amount*=1.8
		if _source.role==2 and book.count("siege")>0:
			for other in battle.units:
				if is_instance_valid(other) and other!=self and not other.dead and not other.is_base and other.team==team and flat_distance(other.global_position,global_position)<1.4:
					other.take_damage(amount*0.25*book.count("siege"),_source,true);break
	if is_instance_valid(battle) and is_instance_valid(battle.combat_feedback):
		battle.combat_feedback.impact(global_position + Vector3.UP * 0.85, is_base or (is_instance_valid(_source) and (_source.is_base or _source.role == 2)))
	# Cosmetic recoil only: no damage scheduling or shared simulation time changes.
	if not is_base and is_instance_valid(visual_anchor):
		if impact_tween and impact_tween.is_valid():impact_tween.kill()
		visual_anchor.rotation.x=-0.13 if role==2 else -0.24
		visual_anchor.scale=original_visual_scale*Vector3(1.08,0.88,1.08)
		visual_anchor.position.y=0.08
		impact_tween=create_tween()
		impact_tween.set_parallel(true)
		impact_tween.tween_property(visual_anchor,"rotation:x",0.0,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		impact_tween.tween_property(visual_anchor,"scale",original_visual_scale,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		impact_tween.tween_property(visual_anchor,"position:y",0.0,0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var actual_damage:=minf(health,amount)
	health = maxf(0.0, health - amount)
	if is_instance_valid(battle.world_feedback):battle.world_feedback.damage(global_position+Vector3.UP*1.8,actual_damage,team)
	if not secondary and not is_base and is_instance_valid(_source) and not _source.dead and not _source.is_base and _source.role!=1:
		_source.health=minf(_source.max_health,_source.health+actual_damage*0.15*battle.augments[_source.team].count("blood_oath"))
	if health>0 and health<max_health*0.25 and not is_base and not last_stand_spent and battle.augments[team].count("last_stand")>0:
		last_stand_spent=true
		health=minf(max_health,health+max_health*0.30)
	if health <= 0.0: die()

func die() -> void:
	if dead: return
	dead = true
	attacking = false
	target = null
	death_elapsed = 0.0
	death_start_position = position
	death_start_scale = scale
	play_animation("death")
	unit_died.emit(self)

func update_death_removal(delta: float) -> void:
	if is_base: return
	death_elapsed += delta
	if death_elapsed <= death_delay: return
	var t := clampf((death_elapsed - death_delay) / death_duration, 0.0, 1.0)
	scale = death_start_scale * maxf(0.02, 1.0 - t)
	position = death_start_position + Vector3.DOWN * 0.7 * t
	if t >= 1.0: queue_free()

func apply_damage_multiplier(multiplier: float) -> void:
	damage *= multiplier

func apply_health_multiplier(multiplier: float) -> void:
	var gain := max_health*(multiplier-1.0)
	max_health += gain
	health = minf(max_health,health+gain)

func face_target(point: Vector3) -> void:
	var direction := point - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001: return
	rotation.y = atan2(direction.x, direction.z)

static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

static func flat_direction(a: Vector3, b: Vector3) -> Vector3:
	var direction := b - a
	direction.y = 0.0
	return direction.normalized()

static func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	material.metallic_specular = 0.46
	material.roughness = 0.84
	return material

