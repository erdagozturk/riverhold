extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var valley=game.battlefield
	var result: Dictionary={"upward_paving":true,"path_count":0,"cascades":0,"cascade_in_frame":false,"landmarks_in_frame":true,"flat_combat_surface":true,"summer_trees":false}
	var cascade_positions: Array=[]
	for node in valley.get_children():
		if node is MeshInstance3D and node.get_meta("scene_kind","")=="VillagePath":
			result.path_count+=1
			var arrays: Array=node.mesh.surface_get_arrays(0)
			for normal in arrays[Mesh.ARRAY_NORMAL]:
				if normal.y<0.5: result.upward_paving=false
		if node is MeshInstance3D and node.get_meta("scene_kind","")=="ValleyCascade":
			result.cascades+=1
			var uv: Vector2=game.camera.unproject_position(node.position)/root.get_visible_rect().size
			cascade_positions.append([uv.x,uv.y])
			if uv.x>0.1 and uv.x<0.9 and uv.y>0.05 and uv.y<0.7: result.cascade_in_frame=true
	var frames: Array=[]
	for point in [Vector3(-24,1,0),Vector3(24,1,0),Vector3(-20,9,-17),Vector3(20,9,-17),Vector3(0,0.35,0)]:
		var uv: Vector2=game.camera.unproject_position(point)/root.get_visible_rect().size
		frames.append([uv.x,uv.y])
		if uv.x<0.03 or uv.x>0.97 or uv.y<0.12 or uv.y>0.80: result.landmarks_in_frame=false
	for x in range(10,33):
		for z in range(-7,3):
			if absf(valley.height_at(x,z)-0.3)>0.001 or absf(valley.height_at(-x,z)-0.3)>0.001: result.flat_combat_surface=false
	for part in valley.library["res://assets/nature_fixed/MapleTree_4.glb"].parts:
		for i in part.mesh.get_surface_count():
			var mat: Material=part.mesh.surface_get_material(i)
			if mat is ShaderMaterial and mat.get_shader_parameter("summer_canopy")==true: result.summer_trees=true
	result.dense_grass=valley.batches.living_grass.transforms.size()>6000
	result.focus_protected=game.camera_rig.lens.dof_blur_far_distance>game.camera.position.distance_to(game.camera_rig.focus)+10 and game.camera_rig.lens.dof_blur_near_distance<game.camera.position.distance_to(game.camera_rig.focus)-10
	var passed: bool=result.dense_grass and result.focus_protected and result.upward_paving and result.path_count>=26 and result.cascades==3 and result.cascade_in_frame and result.landmarks_in_frame and result.flat_combat_surface and result.summer_trees
	print("COMPOSITION "+JSON.stringify({"passed":passed,"checks":result,"landmarks":frames,"cascade_screens":cascade_positions}))
	quit(0 if passed else 1)
