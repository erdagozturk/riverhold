extends SceneTree

func _initialize()->void:call_deferred("run")

func run()->void:
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	await process_frame
	var world=game.battlefield
	var outline=world.find_child("MobileDepthOutline",true,false)
	var grass_batch: Dictionary=world.batches.get("living_grass",{})
	var grass_material: ShaderMaterial=grass_batch.get("material") as ShaderMaterial
	var grass_wind_ok:=grass_material!=null and grass_material.get_shader_parameter("wind_texture")!=null
	var water_ok: bool=world.water_material!=null and world.water_material.shader.code.contains("shoreline_dark")
	var ranged: BattleUnit
	for unit in game.units:
		if not unit.is_base and unit.team==0:
			unit.queue_free()
	await process_frame
	game.spawn_unit(0,1,false)
	for unit in game.units:
		if is_instance_valid(unit) and not unit.is_base and unit.team==0 and unit.role==1:ranged=unit
	var bow=ranged.bow_socket.get_child(0) if ranged and ranged.bow_socket and ranged.bow_socket.get_child_count()>0 else null
	var bow_ok:=bow!=null and absf(absf(bow.rotation.y)-PI)<0.02
	var target: BattleUnit
	for unit in game.units:
		if is_instance_valid(unit) and not unit.is_base and unit.team==1:target=unit
	var lightning_ok:=false
	if target and game.blue_base:
		var before:=target.health
		game.spawn_altar_lightning(game.blue_base,target,11.0)
		await create_timer(0.4).timeout
		lightning_ok=target.health<=before-11.0
	var passed: bool=outline!=null and grass_wind_ok and water_ok and bow_ok and lightning_ok
	print("STYLE_SHADERS outline=",outline!=null," grass_wind=",grass_wind_ok," waterline=",water_ok," bow_forward=",bow_ok," lightning=",lightning_ok," passed=",passed)
	quit(0 if passed else 1)
