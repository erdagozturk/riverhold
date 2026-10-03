extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	game.set_process(false)
	for u in game.units:u.set_process(false)
	for role in 3:
		game.spawn_unit(0,role,false)
		var u=game.units.back();u.set_process(false);u.position=Vector3((role-1)*2.1,0.35,0)
		u.rotation.y=0.0;u.play_animation("idle")
	game.camera_rig.set_process(false)
	game.camera.size=8.0
	game.camera.global_position=Vector3(4,5,9);game.camera.look_at(Vector3(0,1,0))
	game.camera.attributes.dof_blur_far_enabled=false
	game.camera.attributes.dof_blur_near_enabled=false
	await create_timer(1).timeout
	root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/roles.png")
	quit()
