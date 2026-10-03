@tool
extends Node3D
## World coordinates preserve the combat corridor: x +/-14, z +/-2.1, feet y=0.35.
## Decorative landscape extends beyond the camera; the river is 6.5 m below it.

const MED := "res://assets/medieval/"
const NAT := "res://assets/nature_fixed/"
const WATER_Y := -6.4
const SURFACE_Y := 0.30
const BRIDGE_HALF_LENGTH := 10.0
const GATE_X := 12.6
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var library: Dictionary = {}
var batches: Dictionary = {}
var materials: Dictionary = {}
var birds: Array[Node3D] = []
var torches: Array[Node3D] = []
var elapsed := 0.0
var water_material: ShaderMaterial
var falls_material: ShaderMaterial
var grass_wind_texture: NoiseTexture2D
var turret_sockets: Array[Marker3D] = []
var building_fronts: Array[Marker3D] = []
var village_routes: Array[Dictionary] = []
var water_obstacles: Array[Vector4] = []

func build() -> void:
	name = "ReferenceValley"
	rng.seed = 281826
	noise.seed = 418
	noise.frequency = 0.095
	setup_materials()
	build_lighting()
	build_terrain()
	build_river()
	build_bridge()
	build_settlement(-1.0, 0)
	build_settlement(1.0, 1)
	build_village_gate(-1.0, 0)
	build_village_gate(1.0, 1)
	build_village_details(-1.0,0)
	build_village_details(1.0,1)
	build_vegetation()
	build_meadow()
	build_waterfalls()
	flush_batches()
	var life := preload("res://scripts/village_life.gd").new()
	add_child(life)
	life.setup(self,village_routes)
	set_meta("river_depth", SURFACE_Y - WATER_Y)
	set_meta("combat_surface", SURFACE_Y)
	set_meta("bridge_width", 3.2)
	set_meta("bridge_length", 20.4)

func setup_materials() -> void:
	materials.stone = texture_material("T_UnevenBrick_BaseColor.png", "T_UnevenBrick_Normal.png", Color("b5b0a3"), 0.65)
	materials.trim = texture_material("T_RockTrim_BaseColor.png", "T_RockTrim_Normal.png", Color("a6ada8"), 0.8)
	materials.wood = texture_material("T_WoodTrim_BaseColor.png", "T_WoodTrim_Normal.png", Color("b39468"), 0.5)
	materials.plaster = texture_material("T_Plaster_BaseColor.png", "T_Plaster_Normal.png", Color("e2c595"), 0.55)
	materials.path = texture_material("T_Brick_BaseColor.png", "T_Brick_Normal.png", Color("bdad80"), 1.05)
	materials.dark = solid(Color("343829"))
	materials.iron = solid(Color("383c39"))
	materials.gold = solid(Color("bb893d"))
	materials.blue = solid(Color("145a9f"))
	materials.red = solid(Color("a62925"))
	materials.cream = solid(Color("ecdcb6"))
	materials.ground = terrain_material()
	materials.deck = solid(Color("bc9b69"))
	materials.deck.albedo_texture = load(MED+"T_WoodTrim_BaseColor.png")
	materials.deck.uv1_scale = Vector3(1.0,0.24,1.0)
	materials.deck.uv1_offset = Vector3(0.0,0.035,0.0)
	materials.soil = solid(Color("59432c"))
	setup_water_materials()

func flow_texture(seed_value: int, normal_map: bool, frequency: float) -> NoiseTexture2D:
	var generator := FastNoiseLite.new()
	generator.seed = seed_value
	generator.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	generator.frequency = frequency
	generator.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.as_normal_map = normal_map
	texture.bump_strength = 2.1
	texture.noise = generator
	return texture

func setup_water_materials() -> void:
	var normals := flow_texture(312, true, 0.022)
	var normals_b := flow_texture(733, true, 0.031)
	var foam := flow_texture(918, false, 0.036)
	grass_wind_texture = flow_texture(1407, false, 0.018)
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://shaders/valley_water.gdshader")
	water_material.set_shader_parameter("wave_normal", normals)
	water_material.set_shader_parameter("wave_normal_b", normals_b)
	water_material.set_shader_parameter("foam_noise", foam)
	falls_material = ShaderMaterial.new()
	falls_material.shader = load("res://shaders/valley_falls.gdshader")
	falls_material.set_shader_parameter("flow_noise", foam)
	falls_material.set_shader_parameter("wave_normal", normals)

func solid(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.metallic = 0.0
	mat.metallic_specular = 0.48
	mat.roughness = 0.88
	return mat

func texture_material(file: String, normal: String, tint: Color, tiling: float) -> StandardMaterial3D:
	var mat := solid(tint)
	mat.albedo_texture = load(MED + file)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * tiling
	mat.normal_enabled = true
	mat.normal_texture = load(MED + normal)
	mat.normal_scale = 0.45
	return mat

func terrain_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/valley_ground.gdshader")
	mat.set_shader_parameter("rock_texture", load("res://assets/landscape/Rocks.png"))
	mat.set_shader_parameter("soil_texture",load("res://assets/textures/fantasy/floor_ground_dirt.png"))
	mat.set_shader_parameter("grass_texture",load("res://assets/textures/fantasy/floor_ground_grass.png"))
	return mat

func build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "ValleyDaylight"
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader=load("res://shaders/kenney_sky.gdshader")
	sky_mat.set_shader_parameter("day_map",load("res://assets/sky/skybox-day.png"))
	sky_mat.set_shader_parameter("morning_map",load("res://assets/sky/skybox-morning.png"))
	sky_mat.set_shader_parameter("night_map",load("res://assets/sky/skybox-night.png"))
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.34
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.10
	env.glow_enabled = true
	env.glow_bloom = 0.0
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.6
	env.ssao_enabled = RenderingServer.get_current_rendering_method() != "mobile"
	if env.ssao_enabled:
		env.ssao_radius = 1.4
		env.ssao_intensity = 1.15
	env.fog_enabled = true
	env.fog_light_color = Color("a5c9df")
	env.fog_density = 0.00024
	env.fog_sky_affect = 0.15
	env.fog_height = -5.5
	env.fog_height_density = 0.0
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "AfternoonSun"
	sun.rotation_degrees = Vector3(-48.0, -38.0, 0.0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	sun.light_angular_distance = 0.8
	sun.directional_shadow_max_distance = 115.0
	add_child(sun)
	# Capture static land once. Water and spray use layer 2 and never reflect themselves.
	var reflection := ReflectionProbe.new()
	reflection.name = "RiverAndVillageReflection"
	reflection.position = Vector3(0.0, -0.5, -8.0)
	reflection.size = Vector3(112.0, 40.0, 166.0)
	reflection.max_distance = 150.0
	reflection.cull_mask = 1
	reflection.box_projection = true
	reflection.intensity = 0.75
	reflection.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(reflection)

func river_center(z: float) -> float:
	var distant := clampf((-z - 8.0) / 28.0, 0.0, 1.0)
	return sin((-z - 8.0) * 0.072) * 7.0 * distant

func bank_edge(z: float, side: float) -> float:
	var distant := clampf((absf(z) - 3.4) / 8.0, 0.0, 1.0)
	return river_center(z) + side * (BRIDGE_HALF_LENGTH + (sin(z * 0.38 + 1.0) * 0.8 + sin(z * 0.83) * 0.45) * distant)

func height_at(x: float, z: float) -> float:
	var distance_from_lane := maxf(absf(z) - 4.2, 0.0)
	var rise := smoothstep(0.0, 13.0, distance_from_lane)
	var h := SURFACE_Y + rise * (noise.get_noise_2d(absf(x), z) * 1.8 + 0.65)
	if z < -18.0:
		h += (-z - 18.0) * 0.105 + noise.get_noise_2d(absf(x) * 0.65, z * 0.6) * 4.0 * smoothstep(-18.0, -55.0, z)
	# Level building terraces; transition to rolling terrain outside them.
	for side in [-1.0, 1.0]:
		var d := Vector2(x - side * 17.0, z + 9.0).length()
		h = lerpf(h, 0.75, 1.0 - smoothstep(5.8, 8.8, d))
	return h

func build_terrain() -> void:
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for iz in 126:
			var z := -105.0 + iz * 1.2
			for ix in 34:
				var a := land_point(ix, z, side)
				var b := land_point(ix + 1, z, side)
				var c := land_point(ix + 1, z + 1.2, side)
				var d := land_point(ix, z + 1.2, side)
				triangle(st, a, c, b, side < 0.0)
				triangle(st, a, d, c, side < 0.0)
		st.generate_normals()
		mesh_node("SculptedRiverbank", st.commit(), materials.ground)
		# Irregular overlapping textured cliff pillars; no exposed rectangular platform edge.
		for i in 70:
			var z := -88.0 + i * 1.85
			var edge := bank_edge(z, side)
			var top := height_at(edge + side, z)
			var rock_height := top - WATER_Y + rng.randf_range(0.4, 1.7)
			if absf(z)<4.0: rock_height=top-WATER_Y-0.35
			asset(NAT + "Rock_4.glb", Vector3(edge + side * 0.5, WATER_Y - 0.4, z), Vector3(rng.randf_range(2.3, 3.6), rock_height, rng.randf_range(2.0, 3.5)), rng.randf_range(-0.35, 0.35))
			if i % 2 == 0:
				asset(NAT + "Rock_2.glb", Vector3(edge - side * 0.7, WATER_Y - 0.5, z + 0.5), Vector3(2.1, 2.5, 2.2), rng.randf_range(0.0, TAU))
		for ridge in 3:
			for i in 9:
				var z := -45.0 - ridge * 20.0 + rng.randf_range(-3.0, 3.0)
				var x := side * (12.0 + i * 4.2)
				asset(NAT + "Rock_2.glb", Vector3(x, height_at(x, z) - 2.0, z), Vector3(7.0, 6.0 + ridge * 4.0 + rng.randf_range(0.0, 5.0), 10.0), rng.randf_range(0.0, TAU))
		# Main approach: level cobblestones on the unchanged combat surface.
		box(Vector3(side * 12.4, 0.23, 0.0), Vector3(4.8, 0.14, 6.4), materials.path)
		for z in [-5.7, 5.5]:
			path_ribbon(Vector3(side * 12.0, 0, z), Vector3(side * 21.0, 0, z + 5.0), 1.65)
		path_ribbon(Vector3(side * 14.0, 0, -3.0), Vector3(side * 11.8, 0, -5.5), 1.65)
		path_ribbon(Vector3(side * 11.8, 0, -5.5), Vector3(side * 11.8, 0, -10.3), 1.65)
		path_ribbon(Vector3(side * 11.8, 0, -10.3), Vector3(side * 14.9, 0, -10.3), 2.1)

func land_point(ix: int, z: float, side: float) -> Vector3:
	var x := bank_edge(z, side) + side * ix * 1.6
	return Vector3(x, height_at(x, z), z)

func path_ribbon(start: Vector3, end: Vector3, width: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var direction := (end - start).normalized()
	var tangent := Vector3(-direction.z, 0.0, direction.x) * width * 0.5
	for i in 16:
		var a := start.lerp(end, float(i) / 16.0)
		var b := start.lerp(end, float(i + 1) / 16.0)
		var points: Array[Vector3] = [a-tangent, a+tangent, b+tangent, b-tangent]
		for k in 4:
			points[k].y = height_at(points[k].x, points[k].z) + 0.025
		triangle(st, points[0], points[2], points[1],true)
		triangle(st, points[0], points[3], points[2],true)
	st.generate_normals()
	var road_material: Material=materials.path
	if road_material is ShaderMaterial:
		road_material=road_material.duplicate()
		road_material.set_shader_parameter("road_start",Vector2(start.x,start.z))
		road_material.set_shader_parameter("road_end",Vector2(end.x,end.z))
		road_material.set_shader_parameter("road_half_width",width*0.5)
	mesh_node("VillagePath", st.commit(), road_material)

func build_river() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in 155:
		var z := -110.0 + iz
		var center := river_center(z)
		var next := river_center(z + 1.0)
		for ix in 28:
			var x := -14.0 + ix
			triangle(st, Vector3(center+x,WATER_Y,z),Vector3(next+x+1,WATER_Y,z+1),Vector3(center+x+1,WATER_Y,z))
			triangle(st, Vector3(center+x,WATER_Y,z),Vector3(next+x,WATER_Y,z+1),Vector3(next+x+1,WATER_Y,z+1))
	st.generate_normals()
	var river_mesh := st.commit()
	var surface := mesh_node("DeepTurquoiseRiver", river_mesh, water_material)
	surface.layers = 2
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bed_material := texture_material("T_RockTrim_BaseColor.png", "T_RockTrim_Normal.png", Color("666349"), 0.65)
	var bed := mesh_node("SubmergedRiverbed", river_mesh, bed_material)
	bed.position.y = -3.2
	for i in 45:
		var z := rng.randf_range(-72.0, 28.0)
		var x := river_center(z) + rng.randf_range(-5.4, 5.4)
		if absf(z) < 4.0: continue
		asset(NAT + "Rock_2.glb", Vector3(x,WATER_Y-0.65,z), Vector3(rng.randf_range(0.7,1.9),rng.randf_range(0.7,2.1),rng.randf_range(0.8,2.0)), rng.randf_range(0,TAU))
		if water_obstacles.size()<24: water_obstacles.append(Vector4(x,z,0.85,1.0))
	water_material.set_shader_parameter("obstacle_count",water_obstacles.size())
	var centers := PackedVector4Array(water_obstacles)
	centers.resize(24)
	water_material.set_shader_parameter("obstacles",centers)

func build_bridge() -> void:
	# Three open masonry arches with individually outlined voussoirs.
	box(Vector3(0,-0.08,0),Vector3(20.4,0.76,3.2),materials.stone)
	for x in [-10.0,-3.333,3.333,10.0]:
		box(Vector3(x,-3.15,0),Vector3(0.95,6.0,2.85),materials.stone)
		for z in [-1.43,1.43]:
			asset(NAT+"Rock_4.glb",Vector3(x,WATER_Y-0.25,z),Vector3(1.5,2.0,1.7),0.0)
	for center in [-6.667,0.0,6.667]:
		for i in 16:
			var a := PI * float(i) / 16.0
			var b := PI * float(i+1) / 16.0
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var inner_a := Vector2(center+cos(a)*2.78,-3.4+sin(a)*2.35)
			var inner_b := Vector2(center+cos(b)*2.78,-3.4+sin(b)*2.35)
			var outer_a := Vector2(center+cos(a)*3.23,-3.4+sin(a)*2.80)
			var outer_b := Vector2(center+cos(b)*3.23,-3.4+sin(b)*2.80)
			for z in [-1.62,1.62]:
				quad(st,Vector3(inner_a.x,inner_a.y,z),Vector3(inner_b.x,inner_b.y,z),Vector3(outer_b.x,outer_b.y,z),Vector3(outer_a.x,outer_a.y,z),z>0)
			quad(st,Vector3(inner_a.x,inner_a.y,-1.62),Vector3(inner_a.x,inner_a.y,1.62),Vector3(inner_b.x,inner_b.y,1.62),Vector3(inner_b.x,inner_b.y,-1.62))
			# Fill the spandrel above each arch; leave the arch opening clear.
			for z in [-1.58,1.58]:
				quad(st,Vector3(outer_a.x,outer_a.y,z),Vector3(outer_b.x,outer_b.y,z),Vector3(outer_b.x,-0.4,z),Vector3(outer_a.x,-0.4,z),z>0)
			st.generate_normals()
			mesh_node("ArchMasonry",st.commit(),materials.trim)
	# Board-local UVs avoid the former brick-like repeated trim pattern on the deck.
	var deck_wood: Material = materials.deck
	for i in 79:
		box(Vector3(-10.06+i*0.258,0.325,0),Vector3(0.245,0.05,2.98),deck_wood)
	for z in [-1.67,1.67]:
		box(Vector3(0,0.62,z),Vector3(20.7,0.63,0.30),materials.trim)
		beam(Vector3(-10.0,1.3,z),Vector3(10.0,1.3,z),0.075,materials.iron)
		for i in 28:
			box(Vector3(-9.95+i*0.737,1.01,z),Vector3(0.075,0.63,0.075),materials.iron)
		for x in [-10.15,10.15]:
			box(Vector3(x,0.85,z),Vector3(0.78,1.7,0.78),materials.trim)
			box(Vector3(x,1.67,z),Vector3(1.0,0.20,1.0),materials.stone)
			add_torch(Vector3(x,1.9,z),true)
	for x in [-6.67,6.67]:
		banner(Vector3(x,-0.55,1.85),0 if x<0 else 1,0.80,2.05)

func build_settlement(side: float, team: int) -> void:
	var castle := Vector3(side*17.0,0.75,-10.3)
	var castle_start := piece_start()
	# Great hall and unequal roofed towers give a castle silhouette, not repeated cottages.
	house(castle,Vector3(5.4,5.3,4.2),team,true,0.0)
	house(castle+Vector3(side*3.7,0.0,-1.8),Vector3(3.0,3.8,3.4),team,true,0.0)
	for dx in [-3.25,3.25]:
		tower(castle+Vector3(dx,0.0,1.45),2.1,6.5 if dx*side>0 else 7.3,team,true,0.0)
	tower(castle+Vector3(-side*3.1,0.0,-3.0),1.7,7.8,team,false,0.0)
	for i in 8:
		box(castle+Vector3(0.0,-0.45+i*0.09,3.5-i*0.20),Vector3(3.0,0.18,0.30),materials.trim)
	piece_rotate(castle_start,castle,-side*PI*0.5)
	wall(Vector3(side*13.0,0,-7),Vector3(side*13.0,0,-8.6),1.65)
	wall(Vector3(side*13.0,0,-12),Vector3(side*13.0,0,-15),1.65)
	asset(MED+"Wall_Arch.gltf",Vector3(side*13,height_at(side*13,-10.3),-10.3),Vector3(3.4,2.5,0.55),-side*PI*0.5)
	wall(Vector3(side*13.0,height_at(side*13.0,-15),-15),Vector3(side*23.5,height_at(side*23.5,-15),-15),1.65)
	for z in [-7.0,-14.8]:
		tower(Vector3(side*13.0,height_at(side*13.0,z),z),1.3,3.6,team,false)
	# Front walls stop short of the bridge approach so combat stays visible.
	wall(Vector3(side*20.5,height_at(side*20.5,8),8),Vector3(side*13.0,height_at(side*13,8),8),1.2)
	tower(Vector3(side*20.5,height_at(side*20.5,8),8),1.55,4.2,team,true)
	tower(Vector3(side*13.0,height_at(side*13.0,8),8),1.2,3.3,team,false)
	var villages: Array[Vector3] = [Vector3(side*21,0,3.8),Vector3(side*14,0,9.2),Vector3(side*22,0,12.0),Vector3(side*23,0,-3.8),Vector3(side*25,0,-5.3)]
	for i in villages.size():
		var p := villages[i]
		p.y=height_at(p.x,p.z)
		house(p,Vector3(2.5+(i%2)*0.6,2.0+(i%2)*0.5,2.3),team,false)
	market(Vector3(side*14.5,height_at(side*14.5,-6),-6),team)
	market(Vector3(side*19.6,height_at(side*19.6,4.0),4.0),team)
	for z in [-4.3,4.3]:
		for i in 2:
			var x := side*(15.0+i*1.7)
			asset(MED+"Prop_WoodenFence_Single.gltf",Vector3(x,height_at(x,z),z),Vector3(1.5,0.7,0.16),0.0)
	for i in 7:
		var p := Vector3(side*(15.0+i*0.54),0.0,-5.0-float(i%2)*0.48)
		p.y=height_at(p.x,p.z)
		asset(MED+"Prop_Crate.gltf",p,Vector3.ONE*0.45,rng.randf_range(-0.2,0.2))
	asset(MED+"Prop_Wagon.gltf",Vector3(side*16.7,height_at(side*16.7,5),5),Vector3(1.5,1.2,2.1),side*0.35)
	# Small cultivated plots and flower edges fill the village without blocking the lane.
	for i in 6:
		var p := Vector3(side*(16.0+i*0.43),0.0,-4.8)
		p.y=height_at(p.x,p.z)+0.03
		box(p,Vector3(0.22,0.06,1.6),materials.wood)
		for j in 7:
			asset(NAT+"Grass_Large_Extruded.glb",p+Vector3(0,0.07,j*0.21-0.7),Vector3(0.3,0.45,0.3),0.0)

func build_village_gate(side: float, team: int) -> void:
	# The same two sockets, opening and elevations on both sides. No turret logic yet.
	for index in 2:
		var z := -4.05 if index==0 else 4.05
		var p := Vector3(side*GATE_X,SURFACE_Y,z)
		tower(p,1.40,2.80,team,false)
		var socket := Marker3D.new()
		socket.name = ("Blue" if team==0 else "Red")+"TurretSocket"+str(index)
		socket.position = p+Vector3.UP*3.06
		socket.rotation.y = PI*0.5 if team==0 else -PI*0.5
		socket.set_meta("team",team)
		socket.set_meta("slot",index)
		socket.set_meta("combat_enabled",false)
		socket.add_to_group("future_turret_sockets")
		add_child(socket)
		turret_sockets.append(socket)
		wall(Vector3(side*GATE_X,SURFACE_Y,z+signf(z)*0.65),Vector3(side*13.0,0,(-7.0 if z<0 else 8.0)),1.55)
	# Segmented shallow arch over a 6.6 m clear opening; soldiers walk below it.
	for i in 18:
		var a := PI*float(i)/18.0
		var b := PI*float(i+1)/18.0
		var inner_a := Vector2(cos(a)*3.30,2.10+sin(a)*0.86)
		var inner_b := Vector2(cos(b)*3.30,2.10+sin(b)*0.86)
		var outer_a := Vector2(cos(a)*3.63,2.10+sin(a)*1.24)
		var outer_b := Vector2(cos(b)*3.63,2.10+sin(b)*1.24)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for offset in [-0.35,0.35]:
			var x: float = side*GATE_X+offset
			quad(st,Vector3(x,inner_a.y,inner_a.x),Vector3(x,inner_b.y,inner_b.x),Vector3(x,outer_b.y,outer_b.x),Vector3(x,outer_a.y,outer_a.x),offset<0)
		quad(st,Vector3(side*GATE_X-0.35,inner_a.y,inner_a.x),Vector3(side*GATE_X+0.35,inner_a.y,inner_a.x),Vector3(side*GATE_X+0.35,inner_b.y,inner_b.x),Vector3(side*GATE_X-0.35,inner_b.y,inner_b.x))
		st.generate_normals()
		mesh_node("VillageEntranceArch",st.commit(),materials.trim)
	set_meta("gate_clear_width",6.6)

func piece_start() -> Dictionary:
	var counts: Dictionary = {}
	for key in batches: counts[key]=batches[key].transforms.size()
	return {"counts":counts,"child_count":get_child_count()}

func piece_rotate(start: Dictionary,pivot: Vector3,yaw: float) -> void:
	var rotation := Basis(Vector3.UP,yaw)
	var transform := Transform3D(rotation,pivot-rotation*pivot)
	for key in batches:
		for i in range(int(start.counts.get(key,0)),batches[key].transforms.size()):
			batches[key].transforms[i]=transform*batches[key].transforms[i]
	for i in range(start.child_count,get_child_count()):
		var child := get_child(i)
		if child is Node3D: child.transform=transform*child.transform

func house(p: Vector3, size: Vector3, team: int, grand: bool, yaw: float = INF) -> void:
	var start := piece_start()
	house_local(p,size,team,grand)
	var facing := Marker3D.new()
	facing.name="BuildingFront"
	facing.position=p
	facing.set_meta("team",team)
	facing.set_meta("grand",grand)
	add_child(facing)
	building_fronts.append(facing)
	piece_rotate(start,p,(PI*0.5 if team==0 else -PI*0.5) if is_inf(yaw) else yaw)

func house_local(p: Vector3, size: Vector3, team: int, grand: bool) -> void:
	box(p+Vector3(0,size.y*0.5,0),size,materials.plaster)
	box(p+Vector3(0,0.18,0),Vector3(size.x+0.08,0.36,size.z+0.08),materials.stone)
	for x in [-size.x*0.48,size.x*0.48]:
		for z in [-size.z*0.48,size.z*0.48]:
			box(p+Vector3(x,size.y*0.5,z),Vector3(0.14,size.y,0.14),materials.wood)
	for y in [size.y*0.48,size.y*0.96]:
		box(p+Vector3(0,y,size.z*0.51),Vector3(size.x,0.12,0.12),materials.wood)
	var roof_file := "Roof_RoundTiles_6x6.gltf" if grand else "Roof_RoundTiles_4x4.gltf"
	asset(MED+roof_file,p+Vector3(0,size.y,0),Vector3(size.x*1.2,size.x*0.49,size.z*1.22),0.0)
	asset(MED+"Door_2_Round.gltf",p+Vector3(0,0.06,size.z*0.513),Vector3(size.x*0.25,1.5 if grand else 1.15,0.15),0.0)
	for x in [-size.x*0.3,size.x*0.3]:
		for y in ([1.0,3.2] if grand else [0.9]):
			asset(MED+"Window_Wide_Round1.gltf",p+Vector3(x,y,size.z*0.521),Vector3(0.65,0.85,0.16),0.0)
	if grand:
		banner(p+Vector3(0,size.y*0.83,size.z*0.54),team,0.70,2.0)
		flag(p+Vector3(0,size.y+size.x*0.52,0),team,1.2)
	else:
		asset(MED+"Prop_Chimney.gltf",p+Vector3(size.x*0.25,size.y+size.x*0.18,-0.3),Vector3(0.40,1.1,0.40),0.0)
		smoke(p+Vector3(size.x*0.25,size.y+size.x*0.18+1.15,-0.3))
	asset(MED+"Prop_Vine1.gltf",p+Vector3(-size.x*0.35,0.2,size.z*0.53),Vector3(0.6,minf(size.y,2.0),0.15),0.0)
	# Side windows keep buildings readable while orbiting, without a fake front on every side.
	for side in [-1.0,1.0]:
		asset(MED+"Window_Thin_Round1.gltf",p+Vector3(side*size.x*0.51,size.y*0.48,0),Vector3(0.5,0.85,0.15),side*PI*0.5)

func build_village_details(side: float,team: int) -> void:
	# Barracks: long hall, training yard, weapon racks; same footprint on both teams.
	var p := Vector3(side*24.0,height_at(side*24,-18),-18)
	house(p,Vector3(3.3,2.65,5.8),team,false)
	for i in 3:
		var target_pos := Vector3(side*(20.8+i*0.7),height_at(side*(20.8+i*0.7),-17),-17)
		beam(target_pos,target_pos+Vector3.UP*1.4,0.10,materials.wood)
		var target := CylinderMesh.new()
		target.top_radius=0.31
		target.bottom_radius=0.31
		target.height=0.10
		var target_node := mesh_node("TrainingTarget",target,materials.cream)
		target_node.position=target_pos+Vector3.UP
		target_node.rotation.z=PI*0.5
	path_ribbon(Vector3(side*24,0,-15),Vector3(side*25.8,0,-7),1.3)
	# A real field footprint, crop rows, fence and a farmworker route.
	var field := Vector3(side*24,height_at(side*24,7),7)
	for row in 8:
		for column in 10:
			var crop_pos := field+Vector3(side*(row*0.47-1.65),0,column*0.36-1.62)
			crop_pos.y=height_at(crop_pos.x,crop_pos.z)
			box(crop_pos,Vector3(0.38,0.045,0.34),materials.soil)
			grass_patch(crop_pos,Vector3(0.42,0.70,0.40),true)
	for edge in [-1.0,1.0]:
		for i in 3:
			var fp := field+Vector3(side*(i*1.3-1.3),0,edge*2.2)
			fp.y=height_at(fp.x,fp.z)
			asset(MED+"Prop_WoodenFence_Single.gltf",fp,Vector3(1.3,0.72,0.15),0)
	path_ribbon(Vector3(side*19,0,1.8),Vector3(side*23,0,3.5),1.15)
	path_ribbon(Vector3(side*23,0,3.5),Vector3(side*26,0,3.5),1.15)
	path_ribbon(Vector3(side*26,0,3.5),Vector3(side*26,0,9),1.15)
	# Market props and a well, arranged around accessible paths.
	var well := Vector3(side*20,height_at(side*20,0),0)
	for i in 12:
		var angle := TAU*float(i)/12.0
		box(well+Vector3(cos(angle)*0.52,0.34,sin(angle)*0.52),Vector3(0.27,0.68,0.27),materials.trim,angle)
	for dx in [-0.6,0.6]: beam(well+Vector3(dx,0,0),well+Vector3(dx,1.9,0),0.11,materials.wood)
	beam(well+Vector3(-0.65,1.9,0),well+Vector3(0.65,1.9,0),0.14,materials.wood)
	beam(well+Vector3(0,1.9,0),well+Vector3(0,0.6,0),0.025,materials.dark)
	# Broad wall-top platforms reserve functional space for later catapults/turrets.
	for z in [-6.9,7.8]:
		var platform := Vector3(side*13.0,height_at(side*13,z)+2.9,z)
		box(platform,Vector3(2.8,0.28,2.7),materials.trim)
		for edge in [-1.0,1.0]:
			box(platform+Vector3(0,0.45,edge*1.28),Vector3(2.8,0.65,0.22),materials.stone)
		var socket := Marker3D.new()
		socket.name="CatapultPlatform"
		socket.position=platform+Vector3.UP*0.2
		socket.rotation.y=-side*PI*0.5
		socket.set_meta("team",team)
		socket.set_meta("combat_enabled",false)
		socket.add_to_group("future_catapult_sockets")
		add_child(socket)
	# Dock sits at the water, connected to the bank by a stepped descent.
	var dock_z := 17.0
	var bank := bank_edge(dock_z,side)
	var dock_x := bank-side*1.5
	var dock_y := WATER_Y+0.65
	for i in 22:
		box(Vector3(dock_x,dock_y,dock_z-2.1+i*0.20),Vector3(3.8,0.12,0.19),materials.deck)
	for x in [-1.6,1.6]:
		for z in [-1.85,1.85]:
			beam(Vector3(dock_x+x,WATER_Y-1.3,dock_z+z),Vector3(dock_x+x,dock_y+0.65,dock_z+z),0.16,materials.wood)
	var top := height_at(bank+side*2.4,10)
	for i in 30:
		var t := float(i)/29.0
		box(Vector3(bank+side*2.4,lerpf(top,dock_y,t),lerpf(10.0,17.0,t)),Vector3(1.65,0.24,0.30),materials.trim)
	box(Vector3(bank+side*0.8,dock_y,17),Vector3(3.2,0.16,1.65),materials.deck)
	asset(MED+"Prop_Crate.gltf",Vector3(dock_x-side*0.5,dock_y+0.08,dock_z+1.2),Vector3.ONE*0.6,0.1)
	# Ambient paths are deliberately disjoint from the x-axis battle corridor.
	village_routes.append({"side":side,"kind":"villager","points":[Vector3(side*17.5,0,-3.5),Vector3(side*19,0,-3.5),Vector3(side*19,0,-1.7),Vector3(side*18,0,1.8)],"count":3})
	village_routes.append({"side":side,"kind":"farmer","points":[Vector3(side*26,0,4.0),Vector3(side*26,0,8.4),Vector3(side*24,0,8.4),Vector3(side*24,0,4.0)],"count":1})
	village_routes.append({"side":side,"kind":"Cat","points":[Vector3(side*22,0,-2.0),Vector3(side*24,0,-1.0),Vector3(side*24,0,1.0),Vector3(side*22,0,1.0)],"count":1})
	village_routes.append({"side":side,"kind":"Dog","points":[Vector3(side*17.5,0,-3.4),Vector3(side*19,0,-3.4),Vector3(side*19,0,1.6),Vector3(side*17.5,0,1.6)],"count":1})
	village_routes.append({"side":side,"kind":"Chick","points":[Vector3(side*27,0,5.5),Vector3(side*28,0,6.5),Vector3(side*27.5,0,8),Vector3(side*26.8,0,7)],"count":4})
	set_meta("village_features",["castle","market","barracks","field","well","dock","catapult_platforms"])

func grass_patch(p: Vector3,size: Vector3,wheat: bool=false) -> void:
	var key := "living_wheat" if wheat else "living_grass"
	if not batches.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var local_rng := RandomNumberGenerator.new()
		local_rng.seed=619
		for i in 20:
			var x := local_rng.randf_range(-0.5,0.5)
			var z := local_rng.randf_range(-0.5,0.5)
			var h := local_rng.randf_range(0.55,1.0)
			var angle := local_rng.randf_range(0,TAU)
			var right := Vector3(cos(angle),0,sin(angle))*0.035
			var bottom := Vector3(x,0,z)
			var middle := bottom+Vector3(0.03,h*0.55,0.02)
			quad(st,bottom-right,bottom+right,middle+right*0.5,middle-right*0.5)
			triangle(st,middle-right*0.5,middle+right*0.5,bottom+Vector3(0.07,h,0.05))
		st.generate_normals()
		var mat := ShaderMaterial.new()
		mat.shader=load("res://shaders/living_grass.gdshader")
		mat.set_shader_parameter("wheat",wheat)
		mat.set_shader_parameter("wind_texture",grass_wind_texture)
		mat.set_shader_parameter("wind_velocity",Vector2(0.58,0.24))
		mat.set_shader_parameter("wind_strength",0.22 if wheat else 0.34)
		batches[key]={"mesh":st.commit(),"material":mat,"transforms":[]}
	batches[key].transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU))*Basis.from_scale(size),p))

func build_meadow() -> void:
	for i in 1500:
		var z := rng.randf_range(-30,24)
		var distance := rng.randf_range(0.4,20)
		for side in [-1.0,1.0]:
			var x: float = bank_edge(z,side)+side*distance
			if absf(z)<4.0 and absf(x)<21: continue
			if near_building(x,z,1.0): continue
			if noise.get_noise_2d(x*2,z*2)<-0.1: continue
			grass_patch(Vector3(x,height_at(x,z)+0.015,z),Vector3(0.85,rng.randf_range(0.20,0.42),0.85))

func tower(p: Vector3, width: float, height: float, team: int, roofed: bool, yaw: float = INF) -> void:
	var start := piece_start()
	tower_local(p,width,height,team,roofed)
	piece_rotate(start,p,(PI*0.5 if team==0 else -PI*0.5) if is_inf(yaw) else yaw)

func tower_local(p: Vector3, width: float, height: float, team: int, roofed: bool) -> void:
	box(p+Vector3(0,height*0.5,0),Vector3(width,height,width),materials.stone)
	for y in [0.15,height*0.43,height-0.15]:
		box(p+Vector3(0,y,0),Vector3(width*1.10,0.25,width*1.10),materials.trim)
	if roofed:
		asset(MED+"Roof_Tower_RoundTiles.gltf",p+Vector3(0,height,0),Vector3(width*1.45,width*0.90,width*1.45),0.0)
		flag(p+Vector3(0,height+width*0.93,0),team,0.85)
	else:
		for dx in [-0.38,0.0,0.38]:
			for dz in [-0.43,0.43]:
				box(p+Vector3(dx*width,height+0.16,dz*width),Vector3(width*0.23,0.48,width*0.22),materials.trim)
	for y in [height*0.4,height*0.7]:
		box(p+Vector3(0,y,width*0.507),Vector3(0.18,0.63,0.06),materials.dark)
	banner(p+Vector3(0,height*0.77,width*0.53),team,width*0.41,height*0.34)
	if height<4.0: add_torch(p+Vector3(0,height+0.58,0),false)

func wall(a: Vector3, b: Vector3, height: float) -> void:
	var distance := Vector2(a.x-b.x,a.z-b.z).length()
	var segments := maxi(1,ceili(distance/0.9))
	for i in segments:
		var p := a.lerp(b,(float(i)+0.5)/segments)
		p.y=height_at(p.x,p.z)
		var angle := atan2(b.x-a.x,b.z-a.z)
		box(p+Vector3.UP*height*0.5,Vector3(0.50,height,distance/segments+0.03),materials.stone,angle)
		box(p+Vector3.UP*(height+0.20),Vector3(0.63,0.40,0.40),materials.trim,angle)

func market(p: Vector3, team: int) -> void:
	var start := piece_start()
	market_local(p,team)
	piece_rotate(start,p,PI*0.5 if team==0 else -PI*0.5)

func market_local(p: Vector3, team: int) -> void:
	box(p+Vector3(0,0.45,0),Vector3(2.15,0.9,1.0),materials.wood)
	for x in [-1.1,1.1]:
		for z in [-0.7,0.7]: box(p+Vector3(x,1.1,z),Vector3(0.10,2.2,0.1),materials.wood)
	for i in 8:
		var mat: Material = materials.cream if i%2==0 else (materials.blue if team==0 else materials.red)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var x := -1.25+i*0.3125
		quad(st,p+Vector3(x,2.1,-0.85),p+Vector3(x+0.313,2.1,-0.85),p+Vector3(x+0.313,1.75,0.95),p+Vector3(x,1.75,0.95),true)
		st.generate_normals()
		mesh_node("StripedMarketCanopy",st.commit(),mat)
	for i in 5:
		asset(MED+"Prop_Crate.gltf",p+Vector3(-0.85+i*0.43,0.92,0),Vector3(0.35,0.25,0.45),0)

func build_vegetation() -> void:
	# Trees mostly outside the combat and architectural silhouettes; seeded, repeatable layout.
	for i in 315:
		var z := rng.randf_range(-95,32)
		var offset := rng.randf_range(0.4,34)
		var scale := rng.randf_range(0.65,1.5)
		var file := "PineTree_1.glb" if i%3==0 else ("MapleTree_4.glb" if i%3==1 else "PineTree_3.glb")
		var height := (3.9 if i%3==0 else 3.1)*scale
		var yaw := rng.randf_range(0,TAU)
		for side in [-1.0,1.0]:
			var x: float = bank_edge(z,side)+side*offset
			if absf(z)<4.1 and absf(x)<19.0: continue
			if near_building(x,z,3.0): continue
			asset(NAT+file,Vector3(x,height_at(x,z)-0.04,z),Vector3(height*0.68,height,height*0.68),side*yaw)
	for i in 775:
		var z := rng.randf_range(-29,24)
		var offset := rng.randf_range(0.1,21.0)
		var file := "Grass_Large_Extruded.glb"
		var size := Vector3(0.5,0.33,0.5)*rng.randf_range(0.6,1.3)
		if i%5==0:
			file="Bush.glb"
			size=Vector3.ONE*rng.randf_range(0.5,1.2)
		elif i%5==1:
			file="Flower_1_Clump.glb"
			size=Vector3(0.45,0.4,0.45)
		elif i%9==0:
			file="Rock_1.glb"
			size=Vector3.ONE*rng.randf_range(0.25,0.65)
		var yaw := rng.randf_range(0,TAU)
		for side in [-1.0,1.0]:
			var x: float = bank_edge(z,side)+side*offset
			if absf(z)<3.65 and absf(x)<18: continue
			if near_building(x,z,1.3): continue
			asset(NAT+file,Vector3(x,height_at(x,z),z),size,side*yaw)

func near_building(x: float,z: float,padding: float) -> bool:
	var sx := absf(x)
	if sx>16.5-padding and sx<24.5+padding and absf(z)<3.6+padding: return true
	if sx>21-padding and sx<29+padding and z>3-padding and z<10+padding: return true
	if sx>19-padding and sx<28+padding and z>-22-padding and z<-14+padding: return true
	if sx>9 and sx<15+padding and z>10 and z<20: return true
	if absf(sx-GATE_X)<padding+1.0 and absf(z)<9.0: return true
	if sx>12.0-padding and sx<23.5+padding and z>-14.0-padding and z<-7.0+padding: return true
	for p in [Vector2(21,3.8),Vector2(14,9.2),Vector2(22,12),Vector2(23,-3.8),Vector2(25,-5.3)]:
		if Vector2(sx,z).distance_to(p)<padding+1.5: return true
	return false

func build_waterfalls() -> void:
	for i in 3:
		var z := -24.0-i*18.0
		var side := -1.0 if i%2==0 else 1.0
		var x := bank_edge(z,side)-side*1.45
		var top := height_at(x+side*3.0,z)+0.06
		var height := top-WATER_Y
		var width := 2.6+float(i)*0.3
		var sheet := PlaneMesh.new()
		sheet.orientation=PlaneMesh.FACE_Z
		sheet.size=Vector2(width,height)
		sheet.subdivide_width=12
		sheet.subdivide_depth=18
		var fall := mesh_node("DistantWaterfall",sheet,falls_material)
		fall.rotation.y=-side*PI*0.5
		fall.position=Vector3(x,WATER_Y+height*0.5,z)
		fall.layers=2
		fall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for edge in [-1.0,1.0]:
			asset(NAT+"Rock_4.glb",Vector3(x+side*0.65,WATER_Y,z+edge*(width*0.5+0.6)),Vector3(2.2,height+0.45,1.5),edge*0.2)
		var pool := PlaneMesh.new()
		pool.size=Vector2(3.8,width)
		var water := mesh_node("UpperWaterfallPool",pool,water_material)
		water.position=Vector3(x+side*1.9,top,z)
		water.layers=2
		water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mist(Vector3(x-side*0.25,WATER_Y+0.1,z))

func add_torch(p: Vector3, lit: bool) -> void:
	box(p-Vector3.UP*0.18,Vector3(0.4,0.20,0.4),materials.iron)
	var flame_mesh := QuadMesh.new()
	flame_mesh.size=Vector2(0.7,1.05)
	var fire := ShaderMaterial.new()
	fire.shader=load("res://shaders/living_fire.gdshader")
	var flame := mesh_node("BrazierFlame",flame_mesh,fire)
	flame.position=p+Vector3.UP*0.43
	flame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torches.append(flame)
	if lit:
		var light := OmniLight3D.new()
		light.position=p+Vector3.UP*0.2
		light.light_color=Color("ffac4b")
		light.light_energy=0.65
		light.omni_range=2.2
		add_child(light)

func banner(p: Vector3,team: int,width: float,height: float) -> void:
	var plane := PlaneMesh.new()
	plane.orientation=PlaneMesh.FACE_Z
	plane.size=Vector2(width,height)
	plane.subdivide_width=8
	plane.subdivide_depth=12
	var cloth := ShaderMaterial.new()
	cloth.shader=load("res://shaders/valley_banner.gdshader")
	cloth.set_shader_parameter("team_color",Color("1269b2") if team==0 else Color("b92928"))
	var node := mesh_node("HeraldicBanner",plane,cloth)
	node.position=p-Vector3.UP*height*0.5
	beam(p+Vector3(-width*0.62,0,0),p+Vector3(width*0.62,0,0),0.045,materials.gold)

func flag(p: Vector3,team: int,width: float) -> void:
	beam(p,p+Vector3.UP*1.65,0.035,materials.wood)
	banner(p+Vector3(width*0.5,1.55,0),team,width,0.6)

func smoke(p: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name="ChimneySmoke"
	particles.position=p
	particles.amount=6
	particles.lifetime=4.5
	particles.visibility_aabb=AABB(Vector3(-3,-1,-3),Vector3(8,8,8))
	var process := ParticleProcessMaterial.new()
	process.direction=Vector3(0.2,1,0)
	process.spread=8
	process.initial_velocity_min=0.35
	process.initial_velocity_max=0.5
	process.gravity=Vector3(0.08,0.03,0)
	process.scale_min=0.15
	process.scale_max=0.35
	var gradient := Gradient.new()
	gradient.colors=PackedColorArray([Color(0.7,0.74,0.72,0),Color(0.7,0.74,0.72,0.18),Color(0.7,0.74,0.72,0)])
	gradient.offsets=PackedFloat32Array([0,0.25,1])
	var ramp := GradientTexture1D.new()
	ramp.gradient=gradient
	process.color_ramp=ramp
	particles.process_material=process
	var quad_mesh := QuadMesh.new()
	quad_mesh.size=Vector2.ONE*2
	var material := ShaderMaterial.new()
	material.shader=load("res://shaders/valley_mist.gdshader")
	quad_mesh.material=material
	particles.draw_pass_1=quad_mesh
	add_child(particles)

func mist(p: Vector3) -> void:
	smoke(p)
	var node := get_child(get_child_count()-1) as GPUParticles3D
	node.name="WaterfallSpray"
	node.amount=18
	node.layers=2
	node.scale=Vector3(2,1,2)

func build_birds() -> void:
	for i in 6:
		var root := Node3D.new()
		root.position=Vector3(i,10,-28)
		add_child(root)
		for side in [-1.0,1.0]:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			triangle(st,Vector3.ZERO,Vector3(side*0.38,0.03,0.14),Vector3(side*0.12,0,-0.06))
			st.generate_normals()
			var wing := MeshInstance3D.new()
			wing.mesh=st.commit()
			var mat := solid(Color("344049"))
			mat.cull_mode=BaseMaterial3D.CULL_DISABLED
			wing.material_override=mat
			root.add_child(wing)
		birds.append(root)

func _process(delta: float) -> void:
	elapsed+=delta
	for i in birds.size():
		var angle := elapsed*0.12+i*1.6
		birds[i].position=Vector3(cos(angle)*11,8.0+sin(angle)*0.6,-28+sin(angle)*4)
		birds[i].rotation.y=-angle
	for i in torches.size():
		torches[i].scale=Vector3(1,1.0+sin(elapsed*8+i)*0.13,1)

func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,flip:=false) -> void:
	st.set_uv(Vector2(a.x,a.z))
	st.add_vertex(a)
	# SurfaceTool generates normals for Godot's clockwise front faces.
	var second := b if flip else c
	var third := c if flip else b
	st.set_uv(Vector2(second.x,second.z))
	st.add_vertex(second)
	st.set_uv(Vector2(third.x,third.z))
	st.add_vertex(third)

func quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,flip:=false) -> void:
	triangle(st,a,b,c,flip)
	triangle(st,a,c,d,flip)

func mesh_node(label: String,mesh: Mesh,material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=label
	node.set_meta("scene_kind",label)
	node.mesh=mesh
	node.material_override=material
	add_child(node)
	return node

func box(p: Vector3,size: Vector3,material: Material,yaw:=0.0) -> void:
	var key := "box_"+str(material.get_instance_id())
	if not batches.has(key):
		var mesh := BoxMesh.new()
		mesh.size=Vector3.ONE
		batches[key]={"mesh":mesh,"material":material,"transforms":[]}
	var t := Transform3D(Basis(Vector3.UP,yaw)*Basis.from_scale(size),p)
	batches[key].transforms.append(t)

func beam(a: Vector3,b: Vector3,width: float,material: Material) -> void:
	var direction := b-a
	var basis := Basis()
	if absf(direction.normalized().dot(Vector3.UP))<0.99:
		basis=Basis.looking_at(direction.normalized(),Vector3.UP)*Basis(Vector3.RIGHT,PI*0.5)
	var key := "box_"+str(material.get_instance_id())
	if not batches.has(key):
		var mesh := BoxMesh.new()
		mesh.size=Vector3.ONE
		batches[key]={"mesh":mesh,"material":material,"transforms":[]}
	batches[key].transforms.append(Transform3D(basis*Basis.from_scale(Vector3(width,direction.length(),width)),(a+b)*0.5))

func asset(path: String,p: Vector3,dimensions: Vector3,yaw: float) -> void:
	if not library.has(path): cache_asset(path)
	if not library.has(path): return
	var data: Dictionary=library[path]
	var bounds: AABB=data.bounds
	var scaling := dimensions/bounds.size
	var center := bounds.position+Vector3(bounds.size.x*0.5,0,bounds.size.z*0.5)
	var world := Transform3D(Basis(Vector3.UP,yaw),p)*Transform3D(Basis.from_scale(scaling),Vector3.ZERO)*Transform3D(Basis(),-center)
	for i in data.parts.size():
		var part: Dictionary=data.parts[i]
		var key := path+"_"+str(i)
		if not batches.has(key): batches[key]={"mesh":part.mesh,"material":null,"transforms":[]}
		batches[key].transforms.append(world*part.transform)

func cache_asset(path: String) -> void:
	var scene: PackedScene=load(path)
	if not scene:
		push_error("Missing environment asset: "+path)
		return
	var node := scene.instantiate()
	var parts: Array[Dictionary]=[]
	collect_meshes(node,Transform3D.IDENTITY,parts,path)
	var bounds := AABB()
	var first:=true
	for part in parts:
		var aabb: AABB=part.transform*part.mesh.get_aabb()
		bounds=aabb if first else bounds.merge(aabb)
		first=false
	if bounds.size.x>0 and bounds.size.y>0 and bounds.size.z>0:
		library[path]={"parts":parts,"bounds":bounds}
	node.free()

func instantiate_asset(path: String,dimensions: Vector3) -> Node3D:
	if not library.has(path): cache_asset(path)
	var root := Node3D.new()
	var data: Dictionary=library[path]
	var bounds: AABB=data.bounds
	var center := bounds.position+Vector3(bounds.size.x*0.5,0,bounds.size.z*0.5)
	var placement := Transform3D(Basis.from_scale(dimensions/bounds.size),Vector3.ZERO)*Transform3D(Basis(),-center)
	for part in data.parts:
		var mesh := MeshInstance3D.new()
		mesh.mesh=part.mesh
		mesh.transform=placement*part.transform
		root.add_child(mesh)
	return root

func collect_meshes(node: Node,t: Transform3D,parts: Array[Dictionary],path: String) -> void:
	var local := t
	if node is Node3D: local=t*node.transform
	if node is MeshInstance3D and node.mesh:
		var mesh: Mesh=node.mesh.duplicate()
		for i in mesh.get_surface_count():
			var original: Material=node.get_active_material(i)
			if original is StandardMaterial3D:
				var mat: StandardMaterial3D=original.duplicate()
				mat.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
				mat.specular_mode=BaseMaterial3D.SPECULAR_TOON
				mat.metallic=0.0
				mat.metallic_specular=0.48
				mat.roughness=0.84
				mat.emission_enabled=false
				mat.normal_scale=0.45
				if path.begins_with(MED) and path.get_file().begins_with("Wall_"):
					var aging := ShaderMaterial.new()
					aging.shader = load("res://shaders/village_weathering.gdshader")
					mat.next_pass = aging
				if path.begins_with(MED):
					mat.albedo_color=Color("c4b49b")
					if original.resource_name.contains("RoundTiles"): mat.albedo_color=Color("876d63")
				if path.begins_with(NAT) and mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.alpha_scissor_threshold=0.4
					mat.cull_mode=BaseMaterial3D.CULL_DISABLED
				if path.begins_with(NAT) and (original.resource_name.contains("Leaves") or original.resource_name=="Grass") and mat.albedo_texture:
					var wind := ShaderMaterial.new()
					wind.shader=load("res://shaders/valley_foliage.gdshader")
					wind.set_shader_parameter("leaf_texture",mat.albedo_texture)
					mesh.surface_set_material(i,wind)
				else:
					mesh.surface_set_material(i,mat)
		parts.append({"mesh":mesh,"transform":local})
	for child in node.get_children(): collect_meshes(child,local,parts,path)

func flush_batches() -> void:
	var count:=0
	for key in batches:
		var batch: Dictionary=batches[key]
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=batch.mesh
		mm.instance_count=batch.transforms.size()
		for i in batch.transforms.size(): mm.set_instance_transform(i,batch.transforms[i])
		var node := MultiMeshInstance3D.new()
		node.name="SceneryBatch"
		node.multimesh=mm
		node.material_override=batch.material
		if key=="living_grass": node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		count+=mm.instance_count
	set_meta("batched_instances",count)
	set_meta("batch_count",batches.size())
	print("VALLEY_BUILT instances=",count," batches=",batches.size()," asset_types=",library.size())

