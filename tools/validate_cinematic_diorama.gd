extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var diorama: Node=game.get("cinematic_diorama")
	var plate: Node=game.get("cinematic_plate")
	var structures:=int(diorama.get_meta("authored_structures",0)) if diorama else 0
	var trees:=int(diorama.get_meta("authored_trees",0)) if diorama else 0
	var bridge:=diorama.find_child("BridgeDeck",true,false) if diorama else null
	var ground:=diorama.find_child("LivingVillageGround",true,false) if diorama else null
	var river:=diorama.find_child("LivingRiver",true,false) if diorama else null
	var towers:=int(diorama.get_meta("defense_towers",0)) if diorama else 0
	var atlas_path:=String(diorama.get_meta("material_atlas","")) if diorama else ""
	var retextured:=int(diorama.get_meta("retextured_surfaces",0)) if diorama else 0
	var passed:=diorama!=null and plate!=null and structures>=50 and trees>=30 and bridge!=null and ground!=null and river!=null and towers>=12 and retextured>=5 and not atlas_path.is_empty()
	print("CINEMATIC_DIORAMA structures=",structures," trees=",trees," towers=",towers," retextured=",retextured," bridge=",bridge!=null," ground=",ground!=null," river=",river!=null," atlas=",atlas_path," passed=",passed)
	quit(0 if passed else 1)
