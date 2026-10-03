extends SceneTree
var report: Dictionary = {}
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var valley=game.battlefield
	var life=valley.get_node("VillageLife")
	report.buildings_face_streets=true
	for front in get_nodes_in_group("village_districts"):
		var expected: Vector3=front.get_meta("door")-front.position
		expected.y=0
		if front.global_basis.z.dot(expected.normalized())<0.99: report.buildings_face_streets=false
	report.building_front_count=valley.building_fronts.size()
	report.catapult_platforms=get_nodes_in_group("future_catapult_sockets").size()==4
	report.residents=life.residents.size()
	report.birds=life.flyers.size()
	report.noncombat_residents=true
	report.animated_animals=true
	report.animation_clips={}
	for resident in life.residents:
		if resident.actor is BattleUnit or resident.actor is CollisionObject3D: report.noncombat_residents=false
		if resident.player==null:
			report.animated_animals=false
		else:
			report.animation_clips[resident.kind]=Array(resident.player.get_animation_list())
			var changing:=false
			for clip in resident.player.get_animation_list():
				var anim: Animation=resident.player.get_animation(clip)
				for track in anim.get_track_count():
					if anim.track_get_key_count(track)>1:
						var first=anim.track_get_key_value(track,0)
						for k in range(1,anim.track_get_key_count(track)):
							if anim.track_get_key_value(track,k)!=first: changing=true;break
			if not changing: report.animated_animals=false
	var first_positions: Array[Vector3]=[]
	for resident in life.residents: first_positions.append(resident.actor.position)
	for step in 270: life._process(0.1)
	report.grounded=true
	report.moving_residents=0
	for i in life.residents.size():
		var actor: Node3D=life.residents[i].actor
		if actor.position.distance_to(first_positions[i])>0.1: report.moving_residents+=1
		if absf(actor.position.y-valley.height_at(actor.position.x,actor.position.z))>0.01: report.grounded=false
	report.grass_present=valley.batches.has("living_grass") and valley.batches.has("living_wheat")
	report.grass_patches=valley.batches.living_grass.transforms.size()
	report.flow_obstacles=valley.water_obstacles.size()==24
	var rig=game.camera_rig
	for i in 25:
		var event:=InputEventMouseButton.new()
		event.pressed=true
		event.button_index=MOUSE_BUTTON_WHEEL_UP
		event.position=root.get_visible_rect().size*0.5
		root.push_input(event,true)
	report.close_zoom=is_equal_approx(rig.zoom,6.0)
	rig.reset_view()
	var passed:=true
	for key in report:
		if report[key] is bool and not report[key]: passed=false
	report.passed=passed
	print("LIVING_VILLAGE "+JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
