extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var checks:={}
	var districts:=get_nodes_in_group("village_districts")
	var counts:={0:0,1:0}
	var kinds:={0:{},1:{}}
	for district in districts:
		var team: int=district.get_meta("team")
		var kind: String=district.get_meta("kind")
		counts[team]+=1
		kinds[team][kind]=true
	checks.dense_authored_villages=counts[0]>=18 and counts[1]>=18
	checks.landmark_hierarchy=true
	for team in 2:
		for kind in ["castle","town_center","guildhall","inn","barracks","blacksmith","market","windmill","warehouse"]:
			if not kinds[team].has(kind): checks.landmark_hierarchy=false
	checks.distant_matte=game.has_node("CinematicHorizon/LayeredValleyMatte")
	checks.matte_is_non_gameplay=game.get_node("CinematicHorizon").get_meta("gameplay_geometry")==false
	checks.composed_orbit=game.camera_rig.MIN_SIZE<=6.0 and game.camera_rig.MAX_SIZE>=48.0
	checks.impact_camera_connected=game.combat_feedback.camera_rig==game.camera_rig
	checks.hybrid_plate=game.cinematic_plate.plate_enabled and game.cinematic_plate.plate.texture!=null
	checks.hybrid_keeps_live_units=game.units.all(func(unit):return unit.visible if not unit.is_base else not unit.visible)
	var passed:=true
	for value in checks.values(): passed=passed and value
	print("CINEMATIC_PASS "+JSON.stringify({"passed":passed,"checks":checks,"districts":counts}))
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
