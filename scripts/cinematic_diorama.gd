extends Node3D
## Authored 3D foreground that follows the ImageGen plate's composition.
## The plate remains distant matte-painting fill; every gameplay landmark is physical 3D.

const PLAN=preload("res://scripts/village_plan.gd")
const SHADER=preload("res://shaders/cinematic_atlas_triplanar.gdshader")
const HIGHLANDS:="res://assets/highlands/"
const NATURE:="res://assets/nature_fixed/"
var battlefield: Node3D
var atlas_texture: Texture2D
var materials: Array[ShaderMaterial]=[]
var grass_material: StandardMaterial3D
var structure_count:=0
var tree_count:=0
var retextured_surfaces:=0
var tower_count:=0

func setup(source_battlefield: Node3D) -> void:
	name="CinematicDiorama"
	battlefield=source_battlefield
	atlas_texture=load("res://assets/environment/materials/fetih_village_material_atlas_v1.png")
	materials=[
		atlas_material(Vector2(0.0,0.0),Color("ddd4c2"),0.24),
		atlas_material(Vector2(0.5,0.0),Color("fff1cf"),0.22),
		atlas_material(Vector2(0.0,0.5),Color("ffb095"),0.25),
		atlas_material(Vector2(0.5,0.5),Color("ead3a3"),0.20),
	]
	grass_material=StandardMaterial3D.new()
	grass_material.albedo_texture=load("res://assets/environment/materials/fetih_lush_grass_v1.png")
	grass_material.albedo_color=Color("d9edb0")
	grass_material.uv1_triplanar=true
	grass_material.uv1_world_triplanar=true
	grass_material.uv1_scale=Vector3.ONE*0.16
	grass_material.roughness=0.94
	build_foundation()
	build_bridge()
	for team in 2: build_village(team)
	build_framing()
	set_meta("material_atlas",atlas_texture.resource_path if atlas_texture else "")
	set_meta("authored_structures",structure_count)
	set_meta("authored_trees",tree_count)
	set_meta("retextured_surfaces",retextured_surfaces)
	set_meta("defense_towers",tower_count)
	set_meta("plate_role","distant_fill_only")

func build_foundation() -> void:
	# Real walkable-looking foreground; the plate is now only the far valley and skyline.
	for side in [-1.0,1.0]:
		add_box("LivingVillageGround",Vector3(side*30.0,0.03,-2.5),Vector3(37.6,0.56,55.0),grass_material)
	var water:=add_box("LivingRiver",Vector3(0,-6.34,-5.0),Vector3(20.5,0.10,88.0),battlefield.water_material)
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func atlas_material(origin: Vector2,color: Color,scale: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=SHADER
	material.set_shader_parameter("material_atlas",atlas_texture)
	material.set_shader_parameter("atlas_origin",origin)
	material.set_shader_parameter("texture_scale",scale)
	material.set_shader_parameter("tint",color)
	return material

func add_box(label: String,p: Vector3,size: Vector3,material: Material,yaw:=0.0,roll:=0.0) -> MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=size
	var node:=MeshInstance3D.new()
	node.name=label;node.mesh=mesh;node.material_override=material
	node.position=p;node.rotation=Vector3(0,yaw,roll)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(node)
	return node

func build_bridge() -> void:
	# Narrow, long bridge: three ranks fit, while the generated valley remains visible below.
	add_box("BridgeDeck",Vector3(0,0.42,0),Vector3(22.0,0.62,4.0),materials[3])
	add_box("BridgeWood",Vector3(0,0.78,0),Vector3(19.8,0.18,3.2),materials[2])
	for z in [-1.84,1.84]:
		add_box("BridgeParapet",Vector3(0,1.14,z),Vector3(22.0,0.72,0.28),materials[0])
	for x in [-8.8,-3.0,3.0,8.8]:
		add_box("BridgePier",Vector3(x,-3.0,0),Vector3(1.05,6.8,3.8),materials[0])
	for x in [-10.2,10.2]:
		watch_tower(Vector3(x,0.42,-2.5),0,4.4)
		watch_tower(Vector3(x,0.42,2.5),1,4.4)
	structure_count+=1

func build_village(team: int) -> void:
	var side:=-1.0 if team==0 else 1.0
	var tint:=Color("95c7ff") if team==0 else Color("ff9d8f")
	for spec in PLAN.buildings(team):
		var pos:=Vector3(side*spec.pos.x,0.38,spec.pos.y)
		var door:=Vector3(side*spec.door.x,0.38,spec.door.y)
		var yaw:=atan2(door.x-pos.x,door.z-pos.z)
		match String(spec.kind):
			"castle": castle(pos,team,yaw)
			"barracks": landmark_asset("Barracks",pos,Vector3(7.2,5.4,5.0),yaw,team)
			"town_center": landmark_asset("TownCenter",pos,Vector3(7.2,6.6,5.8),yaw,team)
			"windmill": landmark_asset("Windmill",pos,Vector3(5.0,7.2,5.0),yaw,team)
			"hut": landmark_asset("Hut",pos,Vector3(spec.size.x,3.2,spec.size.y),yaw,team)
			"market": market(pos,team,yaw)
			_:
				var height:=4.4 if String(spec.kind) in ["guildhall","inn"] else 3.2
				house(pos,Vector3(spec.size.x,height,spec.size.y),team,yaw,String(spec.kind))
		road_strip(Vector3(side*spec.door.x,0.39,spec.door.y),pos,1.15)
	# Walls describe a defended village rather than surrounding random props.
	wall_line(Vector3(side*13,0.4,-23),Vector3(side*48,0.4,-23),team)
	wall_line(Vector3(side*48,0.4,-23),Vector3(side*48,0.4,18),team)
	wall_line(Vector3(side*48,0.4,18),Vector3(side*14,0.4,18),team)
	wall_line(Vector3(side*13,0.4,-23),Vector3(side*13,0.4,-7),team)
	wall_line(Vector3(side*13,0.4,7),Vector3(side*13,0.4,18),team)
	for z in [-23.0,18.0]:
		watch_tower(Vector3(side*48,0.4,z),team,4.8)
	# Symmetric functional squares, crops and drill yards.
	add_box("VillageSquare",Vector3(side*24,0.37,0),Vector3(8.5,0.08,7.2),materials[3])
	add_box("DrillYard",Vector3(side*29,0.37,-7.8),Vector3(7.2,0.07,5.0),materials[3])
	for row in 6:
		add_box("CropRow",Vector3(side*(21.0+row*0.75),0.46,11.2),Vector3(0.48,0.18,5.2),materials[3])
	# Team colour appears as heraldry, not as a plastic tint over whole buildings.
	for z in [-17.0,0.0,14.0]:
		var banner:=add_box("TeamBanner",Vector3(side*17.0,2.2,z),Vector3(0.08,2.5,1.0),materials[1])
		banner.material_override=flat_material(tint)
	# Layered groves close the settlement silhouette and keep the centre readable.
	for center in [Vector2(39,-21),Vector2(42,13),Vector2(28,21),Vector2(35,-27)]:
		for i in 5:
			var px: float=side*(center.x+sin(i*2.1)*2.2)
			var pz: float=center.y+cos(i*1.7)*2.0
			place_asset(NATURE+("PineTree_3.glb" if i%2==0 else "MapleTree_4.glb"),Vector3(px,0.4,pz),Vector3(3.5,5.2,3.5),i*0.9)
			tree_count+=1

func house(p: Vector3,size: Vector3,team: int,yaw: float,kind: String) -> void:
	var root:=Node3D.new();root.name="House_"+kind;root.position=p;root.rotation.y=yaw;add_child(root)
	var body:=BoxMesh.new();body.size=Vector3(size.x,size.y,size.z)
	var body_node:=MeshInstance3D.new();body_node.mesh=body;body_node.position.y=size.y*0.5;body_node.material_override=materials[1];root.add_child(body_node)
	var roof_width:=size.x*0.58
	for direction in [-1.0,1.0]:
		var roof:=BoxMesh.new();roof.size=Vector3(roof_width,0.22,size.z+0.7)
		var roof_node:=MeshInstance3D.new();roof_node.mesh=roof;roof_node.material_override=materials[2]
		roof_node.position=Vector3(direction*size.x*0.24,size.y+size.x*0.14,0)
		roof_node.rotation.z=direction*deg_to_rad(29.0);root.add_child(roof_node)
	var door:=BoxMesh.new();door.size=Vector3(0.85,1.55,0.12)
	var door_node:=MeshInstance3D.new();door_node.mesh=door;door_node.position=Vector3(0,0.8,size.z*0.5+0.07);door_node.material_override=materials[0];root.add_child(door_node)
	structure_count+=1

func castle(p: Vector3,team: int,yaw: float) -> void:
	house(p,Vector3(7.0,5.4,5.8),team,yaw,"castle_keep")
	for offset in [Vector3(-4.0,0,-2.7),Vector3(4.0,0,-2.7),Vector3(-4.0,0,2.7),Vector3(4.0,0,2.7)]:
		watch_tower(p+offset,team,7.2)
	structure_count+=1

func watch_tower(p: Vector3,team: int,height: float) -> void:
	add_box("DefenseTower",p+Vector3.UP*height*0.5,Vector3(2.2,height,2.2),materials[0])
	for x in [-0.9,0.0,0.9]:
		for z in [-0.9,0.9]: add_box("Merlon",p+Vector3(x,height+0.32,z),Vector3(0.42,0.65,0.42),materials[0])
	for z in [-0.9,0.0,0.9]:
		for x in [-0.9,0.9]: add_box("Merlon",p+Vector3(x,height+0.32,z),Vector3(0.42,0.65,0.42),materials[0])
	structure_count+=1
	tower_count+=1

func wall_line(a: Vector3,b: Vector3,team: int) -> void:
	var delta:=b-a
	var length:=delta.length()
	var center:=(a+b)*0.5+Vector3.UP*1.4
	add_box("VillageWall",center,Vector3(length,2.8,0.55),materials[0],atan2(delta.x,delta.z)-PI*0.5)
	structure_count+=1

func market(p: Vector3,team: int,yaw: float) -> void:
	var team_color:=Color("297fd8") if team==0 else Color("d34c45")
	add_box("MarketCounter",p+Vector3.UP*0.55,Vector3(3.0,1.1,1.3),materials[1],yaw)
	var awning:=add_box("MarketAwning",p+Vector3(0,1.9,0),Vector3(3.4,0.16,2.1),flat_material(team_color),yaw)
	structure_count+=1

func landmark_asset(file: String,p: Vector3,size: Vector3,yaw: float,team: int) -> void:
	var root:=place_asset(HIGHLANDS+file+".glb",p,size,yaw)
	if is_instance_valid(root): retexture_landmark(root)
	structure_count+=1

func place_asset(path: String,p: Vector3,size: Vector3,yaw: float) -> Node3D:
	if not is_instance_valid(battlefield): return null
	if not ResourceLoader.exists(path): return null
	var root: Node3D=battlefield.instantiate_asset(path,size)
	if not is_instance_valid(root): return null
	root.name=path.get_file().get_basename();root.position=p;root.rotation.y=yaw
	add_child(root)
	return root

func retexture_landmark(root: Node) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh:
			child.mesh=child.mesh.duplicate()
			for surface in child.mesh.get_surface_count():
				var source: Material=child.mesh.surface_get_material(surface)
				var hint: String=(String(child.name)+" "+(source.resource_name if source else "")).to_lower()
				var selected: Material=materials[1]
				if "roof" in hint or "tile" in hint or "red" in hint: selected=materials[2]
				elif "stone" in hint or "rock" in hint or "foundation" in hint: selected=materials[0]
				elif "wood" in hint or "beam" in hint: selected=materials[1]
				child.mesh.surface_set_material(surface,selected)
				retextured_surfaces+=1
		retexture_landmark(child)

func road_strip(a: Vector3,b: Vector3,width: float) -> void:
	var delta:=b-a
	add_box("DoorPath",(a+b)*0.5,Vector3(delta.length(),0.06,width),materials[3],atan2(delta.x,delta.z)-PI*0.5)

func build_framing() -> void:
	# Physical near-bank rocks make the 3D foreground meet the painted valley without a hard seam.
	for side in [-1.0,1.0]:
		for i in 9:
			var z:=-26.0+i*6.2
			place_asset(NATURE+"Rock_2.glb",Vector3(side*(10.7+sin(i)*0.6),-0.3,z),Vector3(3.0,2.4,3.5),i*0.7)

func flat_material(color: Color) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.78
	return mat
