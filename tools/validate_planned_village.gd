extends SceneTree
const PLAN=preload("res://scripts/village_plan.gd")
var checks: Dictionary={}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var valley=game.battlefield
	checks.altar_objectives=game.blue_base.position.is_equal_approx(PLAN.altar(0)) and game.red_base.position.is_equal_approx(PLAN.altar(1))
	checks.district_count=get_nodes_in_group("village_districts").size()==PLAN.buildings().size()*2
	checks.doors_face_streets=true
	for district in get_nodes_in_group("village_districts"):
		var expected: Vector3=district.get_meta("door")-district.position
		expected.y=0
		if district.basis.z.dot(expected.normalized())<0.99: checks.doors_face_streets=false
	checks.camera_composition=true
	var screen_positions: Dictionary={}
	for key in {"blue_altar":Vector3(-24,1,0),"red_altar":Vector3(24,1,0),"blue_castle":Vector3(-20,7,-17),"red_castle":Vector3(20,7,-17),"bridge":Vector3(0,0.35,0)}:
		var point: Vector3={"blue_altar":Vector3(-24,1,0),"red_altar":Vector3(24,1,0),"blue_castle":Vector3(-20,7,-17),"red_castle":Vector3(20,7,-17),"bridge":Vector3(0,0.35,0)}[key]
		var screen: Vector2=game.camera.unproject_position(point)/root.get_visible_rect().size
		screen_positions[key]=[screen.x,screen.y]
		if screen.x<0.03 or screen.x>0.97 or screen.y<0.12 or screen.y>0.79: checks.camera_composition=false
	checks.symmetric_terrain=true
	for x in range(10,34):
		for z in range(-10,19):
			if not is_equal_approx(valley.height_at(x,z),valley.height_at(-x,z)): checks.symmetric_terrain=false
	checks.symmetric_sockets=valley.turret_sockets.size()==4 and get_nodes_in_group("future_catapult_sockets").size()==4
	checks.trees_clear_roads=true
	for point in valley.planted_points:
		if PLAN.occupied(Vector2(absf(point.x),point.z),1.0): checks.trees_clear_roads=false
	checks.route_avoids_altar=true
	for team in 2:
		for lane in [-0.55,0.55]:
			var previous:=PLAN.recruit_position(team,lane,0)
			for next in PLAN.recruit_route(team,lane):
				for step in 20:
					var point:=previous.lerp(next,step/20.0)
					if BattleUnit.flat_distance(point,PLAN.altar(team))<2.2: checks.route_avoids_altar=false
				previous=next
	checks.bird_scale_and_habitat=true
	var life=valley.get_node("VillageLife")
	for bird in life.flyers:
		if bird.actor.name.begins_with("DistantEagle") and bird.center_z>-50: checks.bird_scale_and_habitat=false
	game.player_gold=100000;game.enemy_gold=100000
	for team in 2:
		for i in 19: game.spawn_unit(team,2 if i==0 else i%3,false)
	var army: Array=game.units.duplicate()
	for unit in army: unit.set_process(false)
	var deployed: Dictionary={}
	var first_blood:=false
	for step in 2100:
		for unit in army:
			if not is_instance_valid(unit): continue
			unit._process(1.0/60.0)
			if not unit.is_base and not unit.deploying: deployed[unit.get_instance_id()]=true
			if not unit.is_base and unit.health<unit.max_health: first_blood=true
		# Projectiles run in this deterministic simulation, not at display frame rate.
		for child in game.get_children():
			if child.get_script()==load("res://scripts/arrow_projectile.gd"):
				child.set_process(false);child._process(1.0/60.0)
		if step%120==0: await process_frame
	checks.all_recruits_reach_battle=deployed.size()==40
	checks.fighting_after_deployment=first_blood
	checks.altar_ends_match=true
	game.red_base.take_damage(999999,game.blue_base)
	checks.altar_ends_match=game.match_over and game.winner==0
	var passed:=true
	for value in checks.values(): passed=passed and value
	print("PLANNED_VILLAGE "+JSON.stringify({"passed":passed,"checks":checks,"screen_positions":screen_positions,"deployed":deployed.size()}))
	quit(0 if passed else 1)

