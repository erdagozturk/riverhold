extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	var total:=0;var visible:=0
	for node in game.battlefield.find_children("*","GeometryInstance3D",true,false):
		total+=1
		if node.visible:visible+=1
	var plate=game.cinematic_plate
	var checks={"plate_exists":is_instance_valid(plate),"plate_enabled":plate.plate_enabled,"texture_loaded":plate.plate.texture!=null,"world_hidden":visible==0,"canvas_background":plate.environment.background_mode==Environment.BG_CANVAS}
	var passed:=true
	for value in checks.values():passed=passed and value
	print("CINEMATIC_PLATE "+JSON.stringify({"passed":passed,"checks":checks,"geometry_total":total,"geometry_visible":visible,"plate_layer":plate.layer,"plate_rect":[plate.plate.position.x,plate.plate.position.y,plate.plate.size.x,plate.plate.size.y]}))
	quit(0 if passed else 1)
