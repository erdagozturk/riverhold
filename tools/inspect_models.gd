extends SceneTree
func _initialize() -> void:
	for file in ["models/Ranger.glb","animations/Rig_Medium_General.glb","animations/Rig_Medium_CombatRanged.glb","animations/Rig_Medium_CombatMelee.glb","animations/Rig_Medium_MovementBasic.glb"]:
		var model=load("res://assets/characters/"+file).instantiate()
		print("MODEL ",file)
		root.add_child(model)
		for node in model.find_children("*","",true,false):
			if node is Skeleton3D:
				print("SKELETON ",model.get_path_to(node))
				for i in node.get_bone_count():
					if "hand" in node.get_bone_name(i).to_lower():print(node.get_bone_name(i))
			if node is AnimationPlayer:
				print("ANIMS ",node.get_animation_list())
				var anim=node.get_animation(node.get_animation_list()[0])
				print("TRACK ",anim.track_get_path(0))
		model.queue_free()
	quit()
