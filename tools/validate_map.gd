extends SceneTree
var results: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func mouse_button(button: MouseButton, pressed: bool, position: Vector2, shifted := false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.shift_pressed = shifted
	root.push_input(event, true)

func motion(delta: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = delta
	event.position = Vector2(800,400)
	root.push_input(event, true)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	var rig = game.camera_rig
	var valley = game.battlefield
	var camera: Camera3D = game.camera
	var center: Vector2 = camera.unproject_position(Vector3(0,0.3,0))/root.get_visible_rect().size
	results.bridge_centered = absf(center.x-0.5)<0.03 and center.y>0.45 and center.y<0.65
	results.bridge_length = valley.get_meta("bridge_length")
	results.wider_camera = is_equal_approx(rig.zoom,48.0)
	results.bases_visible = true
	for p in [Vector3(-24,1.6,0),Vector3(24,1.6,0),Vector3(-20,8,-17),Vector3(20,8,-17)]:
		var screen: Vector2 = camera.unproject_position(p)/root.get_visible_rect().size
		if screen.x<0.03 or screen.x>0.97 or screen.y<0.10 or screen.y>0.81: results.bases_visible=false
	results.symmetric_gate_sockets = valley.turret_sockets.size()==4
	for i in 2:
		var a: Vector3 = valley.turret_sockets[i].position
		var b: Vector3 = valley.turret_sockets[i+2].position
		results.symmetric_gate_sockets = results.symmetric_gate_sockets and Vector3(-a.x,a.y,a.z).is_equal_approx(b)
		results.symmetric_gate_sockets = results.symmetric_gate_sockets and not valley.turret_sockets[i].get_meta("combat_enabled")
	results.symmetric_combat_terrain = true
	for x in range(10,25):
		for z in range(-4,5):
			if not is_equal_approx(valley.height_at(x,z),valley.height_at(-x,z)): results.symmetric_combat_terrain=false
	mouse_button(MOUSE_BUTTON_MIDDLE,true,Vector2(800,400))
	motion(Vector2(100,40))
	results.middle_mouse_orbit = rig.dragging and not is_equal_approx(rig.yaw,7.0) and not is_equal_approx(rig.pitch,27.0)
	mouse_button(MOUSE_BUTTON_MIDDLE,false,Vector2(800,400))
	results.release_mouse = not rig.dragging and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE
	mouse_button(MOUSE_BUTTON_WHEEL_UP,true,Vector2(800,400))
	results.wheel_zoom = rig.zoom<48.0
	mouse_button(MOUSE_BUTTON_MIDDLE,true,Vector2(800,400),true)
	motion(Vector2(90,50))
	mouse_button(MOUSE_BUTTON_MIDDLE,false,Vector2(800,400),true)
	results.shift_pan = rig.focus.distance_to(Vector3(0,0.3,-3.8))>0.1
	mouse_button(MOUSE_BUTTON_LEFT,true,Vector2(800,72))
	mouse_button(MOUSE_BUTTON_LEFT,false,Vector2(800,72))
	results.reset_button = is_equal_approx(rig.zoom,48.0) and is_equal_approx(rig.yaw,7.0) and rig.focus.is_equal_approx(Vector3(0,0.3,-3.8))
	var before: int = game.population(0)
	mouse_button(MOUSE_BUTTON_LEFT,true,Vector2(100,800))
	mouse_button(MOUSE_BUTTON_LEFT,false,Vector2(100,800))
	results.unit_card_mouse = game.population(0)==before+1
	mouse_button(MOUSE_BUTTON_MIDDLE,true,Vector2(800,400))
	game.open_card_choice()
	results.pause_releases_mouse = not rig.dragging and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE
	game.choose_card(0)
	rig.orbit(Vector2(5000,5000))
	results.orbit_limits = rig.yaw>=-32.0 and rig.yaw<=32.0 and rig.pitch==48.0
	rig.reset_view()
	var passed := true
	for key in results:
		if results[key] is bool and not results[key]: passed=false
	results.passed=passed
	print("ORBIT_VALIDATION "+JSON.stringify(results))
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)


