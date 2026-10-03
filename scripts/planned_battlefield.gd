@tool
extends "res://scripts/reference_battlefield.gd"
const PLAN = preload("res://scripts/village_plan.gd")
var planted_points: Array[Vector3] = []

func ground_point(side: float,x: float,z: float) -> Vector3:
	return Vector3(side*x,height_at(side*x,z),z)

func height_at(x: float,z: float) -> float:
	# Both villages share traversable heights; rising scenery starts beyond their walls.
	var edge := maxf(absf(x)-35.0,0.0)
	var back := maxf(-z-23.0,0.0)
	var front := maxf(z-19.0,0.0)
	var h:=SURFACE_Y+edge*0.08+back*0.12+front*0.025+noise.get_noise_2d(absf(x),z)*minf((edge+back+front)*0.13,2.0)
	var castle_terrace:=smoothstep(13.0,16.0,absf(x))*(1.0-smoothstep(24.0,26.0,absf(x)))*smoothstep(9.0,13.0,-z)*(1.0-smoothstep(22.0,25.0,-z))
	h+=castle_terrace*1.25
	# Carve the dock access into the land so the descending stairs stay above it.
	var start:=Vector2(17.5,19.2)
	var end:=Vector2(absf(bank_edge(21,1.0))-0.2,22.6)
	var point:=Vector2(absf(x),z)
	var closest:=Geometry2D.get_closest_point_to_segment(point,start,end)
	var distance:=point.distance_to(closest)
	var t:=clampf((closest-start).dot(end-start)/(end-start).length_squared(),0,1)
	if distance<1.6:
		h=lerpf(h,lerpf(SURFACE_Y-0.12,WATER_Y+0.40,t),1.0-smoothstep(0.7,1.6,distance))
	return h

func setup_materials() -> void:
	super.setup_materials()
	materials.deck.albedo_texture=load(MED+"T_WoodTrim_BaseColor.png")
	materials.deck.uv1_scale=Vector3(1.0,0.24,1.0)
	materials.deck.albedo_color=Color("a18560")
	var wear:=ShaderMaterial.new()
	wear.shader=load("res://shaders/bridge_wear.gdshader")
	materials.deck.next_pass=wear
	materials.path=ShaderMaterial.new()
	materials.path.shader=load("res://shaders/village_paving.gdshader")
	materials.path.set_shader_parameter("dirt_map",load("res://assets/textures/fantasy/floor_ground_dirt.png"))
	materials.path.set_shader_parameter("stone_map",load("res://assets/textures/fantasy/floor_stone_sand_random.png"))
	materials.stone.albedo_color=Color("c2bbaa")
	materials.stone.uv1_scale=Vector3.ONE*0.29
	materials.trim.uv1_scale=Vector3.ONE*0.32
	materials.rock=texture_material("T_RockTrim_BaseColor.png","T_RockTrim_Normal.png",Color("8d9890"),0.28)

func build_terrain() -> void:
	for side in [-1.0,1.0]:
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for iz in 126:
			var z: float=-105.0+iz*1.2
			for ix in 34:
				var a:=land_point(ix,z,side)
				var b:=land_point(ix+1,z,side)
				var c:=land_point(ix+1,z+1.2,side)
				var d:=land_point(ix,z+1.2,side)
				triangle(st,a,c,b,side<0)
				triangle(st,a,d,c,side<0)
		st.generate_normals()
		mesh_node("ValleyLand",st.commit(),materials.ground)
		# Broad interlocking shelves instead of a fence of stretched rock needles.
		for i in 44:
			var z: float=-96.0+i*3.1
			var edge:=bank_edge(z,side)
			var top:=height_at(edge+side,z)
			for layer in 3:
				var y: float=WATER_Y-0.45+layer*(top-WATER_Y)/3.0
				var inset: float=0.25+layer*0.44
				var dims:=Vector3(4.0,(top-WATER_Y)/3.0+0.85,4.4)
				asset(NAT+"Rock_2.glb",Vector3(edge+side*inset,y,z+sin(i*2.7+layer)*0.5),dims,sin(i*1.3)*0.4)
			if absf(z)>5:
				asset(NAT+"Bush.glb",Vector3(edge+side*1.8,top-0.05,z),Vector3(1.3,0.85,1.3),0)
		for j in 22:
			var z: float=-42.0+j*3.2
			if absf(z)<5.0 or z>16.0: continue
			var edge:=bank_edge(z,side)
			for tier in 2:
				var y: float=lerpf(WATER_Y,height_at(edge,z),0.33+tier*0.36)
				var x: float=edge+side*(0.6+tier*0.4)
				asset(NAT+"Bush.glb",Vector3(x,y,z),Vector3(1.8,1.1,1.5),j*0.7)
			asset(NAT+"Flower_1_Clump.glb",Vector3(edge+side*1.9,height_at(edge+side*1.9,z),z),Vector3(0.6,0.4,0.6),0)
		# Side ridges frame the generated horizon without covering its central valley opening.
		for ridge in 3:
			for i in 5:
				var x: float=side*(28+i*8)
				var z: float=-55-ridge*20+sin(i*2.1)*3
				asset(NAT+"Rock_2.glb",Vector3(x,height_at(x,z)-0.8,z),Vector3(12,4.5+ridge*1.2,14),i*0.8)
		for road in PLAN.roads():
			path_ribbon(Vector3(side*road.a.x,0,road.a.y),Vector3(side*road.b.x,0,road.b.y),road.width)
		# Every authored entrance gets a continuous spur to the existing street network.
		for spec in PLAN.buildings(0 if side<0 else 1):
			var closest: Vector2 = spec.door
			var best := INF
			for road in PLAN.roads():
				var candidate := Geometry2D.get_closest_point_to_segment(spec.door, road.a, road.b)
				var distance: float = candidate.distance_to(spec.door)
				if distance < best:
					best = distance
					closest = candidate
			var approach: Vector2 = spec.pos.lerp(spec.door, 0.70)
			path_ribbon(Vector3(side*approach.x,0,approach.y),Vector3(side*spec.door.x,0,spec.door.y),1.35)
			if best > 0.01:
				path_ribbon(Vector3(side*spec.door.x,0,spec.door.y),Vector3(side*closest.x,0,closest.y),1.35)
		# The altar is surrounded by a proper paved village square.
		box(Vector3(side*24,0.30,0),Vector3(8.4,0.05,7.3),materials.path)
		box(Vector3(side*29,0.30,-8.0),Vector3(7.0,0.05,5.0),materials.path)

func build_settlement(side: float,team: int) -> void:
	for spec in PLAN.buildings(0 if side<0 else 1):
		var p:=ground_point(side,spec.pos.x,spec.pos.y)
		var door:=ground_point(side,spec.door.x,spec.door.y)
		var yaw:=atan2(door.x-p.x,door.z-p.z)
		var kind: String=spec.kind
		if kind=="castle":
			var start:=piece_start()
			box(p+Vector3(0,0.22,0),Vector3(9.8,0.44,8.0),materials.stone)
			house(p+Vector3(0,0.44,0),Vector3(5.4,5.0,4.6),team,true,0)
			house(p+Vector3(side*3.6,0.44,-1.6),Vector3(2.5,3.4,3.5),team,false,0)
			for dx in [-3.7,3.7]: tower(p+Vector3(dx,0.44,2.0),1.8,6.8,team,true,0)
			tower(p+Vector3(-side*3.3,0.44,-3.0),1.6,8.5,team,false,0)
			for i in 4: box(p+Vector3(0,0.06+i*0.10,3.8-i*0.32),Vector3(3.2,0.12,0.36),materials.trim)
			piece_rotate(start,p,yaw)
		elif kind=="barracks":
			highlands_building("Barracks",p,Vector2(7.2,4.8),0)
			# Open muster yard, not a cottage used as a spawn point.
			for dx in [-3.5,3.5]:
				wall(p+Vector3(dx,0,2.5),p+Vector3(dx,0,6.0),0.8)
				flag(p+Vector3(dx,0,6.0),team,0.75)
			for i in 3:
				var target_pos:=p+Vector3(-2+i*2.0,0,2.8)
				beam(target_pos,target_pos+Vector3.UP*1.3,0.10,materials.wood)
				var disc:=CylinderMesh.new()
				disc.top_radius=0.33;disc.bottom_radius=0.33;disc.height=0.08
				var target_node:=mesh_node("ArcheryTarget",disc,materials.cream)
				target_node.position=target_pos+Vector3.UP
				target_node.rotation.x=PI*0.5
		elif kind=="town_center":
			highlands_building("TownCenter",p,spec.size,yaw)
			for dx in [-2.9,2.9]: flag(p+Vector3(dx,0,2.5),team,0.9)
		elif kind=="windmill":
			highlands_building("Windmill",p,spec.size,yaw)
		elif kind=="hut":
			highlands_building("Hut",p,spec.size,yaw)
		elif kind=="market":
			var start:=piece_start()
			market_local(p,team)
			piece_rotate(start,p,yaw)
		else:
			var height:=3.1 if kind in ["guildhall","inn"] else (2.0 if kind=="farmhouse" else 2.5)
			house(p,Vector3(spec.size.x,height,spec.size.y),team,kind in ["townhouse","guildhall","inn"],yaw)
		var marker:=Marker3D.new()
		marker.name="District_"+kind+str(team)
		marker.position=p;marker.rotation.y=yaw
		marker.set_meta("functional",kind in ["castle","barracks","market","blacksmith","warehouse","town_center","windmill","guildhall","inn"]);marker.set_meta("door",door);marker.set_meta("kind",kind);marker.set_meta("team",team)
		marker.add_to_group("village_districts")
		add_child(marker)
	# Continuous perimeter with a deliberate bridge gate and low foreground wall.
	wall(ground_point(side,13,-7),ground_point(side,13,-23),1.65)
	wall(ground_point(side,13,-23),ground_point(side,48,-23),1.65)
	wall(ground_point(side,48,-23),ground_point(side,48,18),1.35)
	wall(ground_point(side,48,18),ground_point(side,19,18),0.95)
	wall(ground_point(side,16,18),ground_point(side,13,18),0.95)
	wall(ground_point(side,13,18),ground_point(side,13,8),1.25)
	for pt in [Vector2(13,-23),Vector2(48,-23),Vector2(48,18),Vector2(13,18)]:
		tower(ground_point(side,pt.x,pt.y),1.55,3.4,team,pt.y>0,-side*0.22)

func build_village_details(side: float,team: int) -> void:
	# Food production is attached to the farmhouse, with clear walking aisles.
	for row in 9:
		for col in 10:
			var p:=ground_point(side,20.4+row*0.59,8.4+col*0.32)
			box(p+Vector3.UP*0.015,Vector3(0.46,0.04,0.31),materials.soil)
			grass_patch(p,Vector3(0.46,0.73,0.34),true)
	for z in [7.9,12.0]:
		for i in 4: asset(MED+"Prop_WoodenFence_Single.gltf",ground_point(side,20.6+i*1.4,z),Vector3(1.35,0.65,0.15),0)
	for i in 4:
		asset(MED+"Prop_Crate.gltf",ground_point(side,15.0+i*0.5,16.0),Vector3.ONE*0.45,0)
	asset(MED+"Prop_Wagon.gltf",ground_point(side,16,10),Vector3(1.4,1.1,2),-side*PI/2)
	# The craft quarter reads as a workplace: deliveries, timber and an open forge yard.
	asset(MED+"Prop_Wagon.gltf",ground_point(side,40.2,-11.0),Vector3(1.5,1.15,2.1),side*PI*0.5)
	for offset in [Vector2(40.5,-13.0),Vector2(41.2,-12.4),Vector2(39.8,-12.2),Vector2(42.0,-13.2)]:
		asset(MED+"Prop_Crate.gltf",ground_point(side,offset.x,offset.y),Vector3.ONE*0.48,offset.x)
	for i in 5:
		var timber:=ground_point(side,34.0+i*0.42,-11.2)
		beam(timber,timber+Vector3(side*1.45,0.08,0),0.10,materials.wood)
	# Market stock is grouped around stalls instead of sprinkled through the village.
	for offset in [Vector2(17.6,7.7),Vector2(18.3,7.9),Vector2(23.8,7.7),Vector2(24.5,7.8)]:
		asset(MED+"Prop_Crate.gltf",ground_point(side,offset.x,offset.y),Vector3.ONE*0.42,offset.y)
	# Residential gardens create small private spaces behind the main street.
	for x in [37.0,42.0]:
		for i in 3:
			asset(MED+"Prop_WoodenFence_Single.gltf",ground_point(side,x+i*1.25,10.0),Vector3(1.2,0.62,0.14),0)
	# Well is a small market landmark off the combat avenue.
	var well:=ground_point(side,16.1,4.7)
	for i in 12:
		var angle:=TAU*i/12.0
		box(well+Vector3(cos(angle)*0.55,0.34,sin(angle)*0.55),Vector3(0.27,0.68,0.27),materials.trim,angle)
	for dx in [-0.65,0.65]: beam(well+Vector3(dx,0,0),well+Vector3(dx,1.9,0),0.1,materials.wood)
	beam(well+Vector3(-0.7,1.9,0),well+Vector3(0.7,1.9,0),0.12,materials.wood)
	beam(well+Vector3(0,1.9,0),well+Vector3(0,0.5,0),0.022,materials.dark)
	# Rear stairs make the future artillery positions accessible from the village.
	for z in [-7.0,7.0]:
		var platform:=ground_point(side,13.5,z)+Vector3.UP*2.7
		box(platform-Vector3.UP*1.35,Vector3(2.8,2.7,2.7),materials.stone)
		box(platform,Vector3(3.0,0.2,2.9),materials.trim)
		for i in 11:
			box(Vector3(side*(17.1-i*0.25),SURFACE_Y+(i+1)*0.23*0.5,z),Vector3(0.28,(i+1)*0.23,1.1),materials.trim)
		var socket:=Marker3D.new()
		socket.name="CatapultPlatform";socket.position=platform+Vector3.UP*0.12
		socket.rotation.y=-side*PI*0.5
		socket.set_meta("team",team);socket.set_meta("combat_enabled",false)
		socket.add_to_group("future_catapult_sockets");add_child(socket)
	# Dock descent cuts across the cliff in switchbacks rather than floating in it.
	var bank:=bank_edge(21,side)
	var dock_y:=WATER_Y+0.65
	path_ribbon(ground_point(side,18,15.8),ground_point(side,17.5,19.2),1.6)
	for i in 30:
		var t:=float(i)/29.0
		var x:=lerpf(side*17.5,bank-side*0.2,t)
		box(Vector3(x,lerpf(SURFACE_Y,dock_y,t),19.2+t*3.4),Vector3(0.35,0.24,1.5),materials.trim)
	var dock_x:=bank-side*1.0
	for i in 23: box(Vector3(dock_x,dock_y,21.0+i*0.18),Vector3(3.2,0.12,0.17),materials.deck)
	for dx in [-1.35,1.35]:
		for z in [21.2,24.7]: beam(Vector3(dock_x+dx,WATER_Y-1,z),Vector3(dock_x+dx,dock_y+0.65,z),0.16,materials.wood)
	add_route(side,"villager",[Vector2(27.8,5.8),Vector2(27.8,4.5),Vector2(19,4.5),Vector2(27.8,4.5)],2)
	add_route(side,"farmer",[Vector2(24,12.8),Vector2(26.9,12.8),Vector2(26.9,8.1),Vector2(26.9,12.8)],1)
	add_route(side,"Cat",[Vector2(18,14),Vector2(18,8),Vector2(18,4.5),Vector2(18,8)],1)
	add_route(side,"Dog",[Vector2(27.8,5.8),Vector2(27.8,11),Vector2(27.8,12.8),Vector2(27.8,11)],1)
	add_route(side,"Chick",[Vector2(26.6,14),Vector2(27,15.7),Vector2(26.3,16.2),Vector2(26.4,15)],3)
	set_meta("village_features",["castle","town_center","guildhall","inn","market","barracks","blacksmith","windmill","field","well","dock","catapult_platforms","altar_square","streets","residential_quarter"])

func add_route(side: float,kind: String,points: Array,count: int) -> void:
	var route: Array[Vector3]=[]
	for p in points: route.append(ground_point(side,p.x,p.y))
	village_routes.append({"side":side,"kind":kind,"points":route,"count":count})

func near_building(x: float,z: float,padding: float) -> bool:
	if PLAN.occupied(Vector2(absf(x),z),padding): return true
	if absf(x)<18.0+padding and z>15 and z<26: return true
	if absf(x)<17.7+padding and absf(z)<9: return true
	if absf(absf(x)-48)<padding+0.8 and z>-24 and z<19: return true
	if absf(z-18)<padding+0.8 and absf(x)<49: return true
	if absf(z+23)<padding+0.8 and absf(x)<49: return true
	return false

func build_vegetation() -> void:
	# Authored groves: outskirts, castle backdrop, orchard, river rim. Jitter only within a grove.
	var groves: Array[Vector3]=[Vector3(38,0,-18),Vector3(40,0,10),Vector3(31,0,26),Vector3(17,0,30),Vector3(24,0,-32),Vector3(19,0,-45),Vector3(38,0,-55),Vector3(19,0,-70)]
	for side in [-1.0,1.0]:
		for grove in groves:
			for i in 23:
				var x: float=side*(grove.x+rng.randf_range(-6,6))
				var z: float=grove.z+rng.randf_range(-6,6)
				if near_building(x,z,2.0) or absf(x)<absf(bank_edge(z,side))+1.5: continue
				var h:=rng.randf_range(3.4,5.8)
				var file: String="PineTree_1.glb" if i%3==0 else "MapleTree_4.glb"
				var p:=Vector3(x,height_at(x,z)-0.04,z)
				asset(NAT+file,p,Vector3(h*0.82,h,h*0.82),rng.randf_range(0,TAU))
				planted_points.append(p)
		# Expanded residential garden inside the outer wall, with room around the homes.
		for z in [5.5,9.0,16.0]:
			var p:=ground_point(side,35.2,z)
			if PLAN.occupied(Vector2(35.2,z),1.1):continue
			asset(NAT+"MapleTree_4.glb",p,Vector3(2.6,3.3,2.6),z*0.1)
			planted_points.append(p)
		# Small deliberate garden groups, away from doors and the battle.
		for center in [Vector2(32,8),Vector2(32,15),Vector2(16,-12),Vector2(26,-20)]:
			for i in 7:
				var p:=ground_point(side,center.x+sin(i*2.4)*0.65,center.y+cos(i*2.4)*0.65)
				if near_building(p.x,p.z,0.4): continue
				asset(NAT+"Bush.glb",p,Vector3.ONE*0.65,i)

func build_meadow() -> void:
	# Continuous coverage on unused land. The road/building plan is the exclusion mask.
	for ix in 56:
		for iz in 116:
			var x:=11.0+ix*0.62+rng.randf_range(-0.09,0.09)
			var z: float=-38.0+iz*0.62+rng.randf_range(-0.09,0.09)
			if near_building(x,z,0.40): continue
			for side in [-1.0,1.0]:
				if absf(side*x)<absf(bank_edge(z,side))+0.8: continue
				var p:=ground_point(side,x,z)
				grass_patch(p,Vector3(0.92,rng.randf_range(0.14,0.25),0.92))
				if (ix+iz*3)%79==0: asset(NAT+"Flower_1_Clump.glb",p,Vector3(0.48,0.28,0.48),0)
	set_meta("meadow_spacing",0.62)

func cache_asset(path: String) -> void:
	super.cache_asset(path)
	if path.ends_with("MapleTree_4.glb") and library.has(path):
		for part in library[path].parts:
			for i in part.mesh.get_surface_count():
				var mat: Material=part.mesh.surface_get_material(i)
				if mat is ShaderMaterial: mat.set_shader_parameter("summer_canopy",true)

func build_lighting() -> void:
	super.build_lighting()
	var env: Environment=get_node("ValleyDaylight").environment
	env.ambient_light_energy=0.43
	env.fog_density=0.0014
	env.fog_sky_affect=0.0
	get_node("AfternoonSun").light_energy=1.1
	get_node("AfternoonSun").light_angular_distance=1.2
	# Keep sky reflections but avoid the old boxed probe's cloudy white streaks.
	get_node("RiverAndVillageReflection").intensity=0.25

func build_waterfalls() -> void:
	# The main river enters from the upstream valley and exits downstream.
	# No isolated headwater pools: cascades stay removed until an elevated feeder exists.
	set_meta("visible_cascades",0)
	set_meta("river_source","upstream_valley_z_minus_110")
	set_meta("river_outflow","downstream_z_45")

func house_local(p: Vector3, size: Vector3, team: int, grand: bool) -> void:
	# Modelled timber/plaster modules replace the flat box facade.
	var floors := 2 if grand else 1
	var floor_height := size.y / floors
	var bays := maxi(1, int(round(size.x / 1.8)))
	if bays % 2 == 0: bays += 1
	var bay_width := size.x / bays
	box(p+Vector3(0,0.15,0),Vector3(size.x+0.12,0.30,size.z+0.12),materials.stone)
	for floor_index in floors:
		var y := floor_index*floor_height
		for bay in bays:
			var x := -size.x*0.5 + (bay+0.5)*bay_width
			var front := "Wall_Plaster_Door_Round.gltf" if floor_index==0 and bay==bays/2 else "Wall_Plaster_Window_Wide_Round.gltf"
			asset(MED+front,p+Vector3(x,y,size.z*0.5),Vector3(bay_width,floor_height,0.22),0)
			asset(MED+"Wall_Plaster_WoodGrid.gltf",p+Vector3(x,y,-size.z*0.5),Vector3(bay_width,floor_height,0.22),PI)
		var side_bays := maxi(1,int(round(size.z/1.8)))
		for side in [-1.0,1.0]:
			for bay in side_bays:
				var z := -size.z*0.5+(bay+0.5)*size.z/side_bays
				asset(MED+"Wall_Plaster_Window_Wide_Round.gltf",p+Vector3(side*size.x*0.5,y,z),Vector3(size.z/side_bays,floor_height,0.22),side*PI*0.5)
		box(p+Vector3(0,y+floor_height-0.06,0),Vector3(size.x+0.15,0.12,size.z+0.15),materials.wood)
	asset(MED+"Door_2_Round.gltf",p+Vector3(0,0.04,size.z*0.5+0.02),Vector3(bay_width*0.62,floor_height*0.70,0.16),0)
	var roof := "Roof_RoundTiles_6x6.gltf" if grand else "Roof_RoundTiles_4x4.gltf"
	asset(MED+roof,p+Vector3(0,size.y,0),Vector3(size.x+0.65,minf(size.x*0.42,2.4),size.z+0.7),0)
	# Sheltered entrance and a usable upstairs balcony; neither blocks the street.
	if grand:
		asset(MED+"Balcony_Simple_Straight.gltf",p+Vector3(0,floor_height-0.18,size.z*0.5+0.38),Vector3(size.x*0.65,0.85,0.85),0)
		banner(p+Vector3(-size.x*0.35,size.y*0.83,size.z*0.5+0.2),team,0.6,1.6)
		flag(p+Vector3(0,size.y+size.x*0.45,0),team,1.0)
	else:
		asset(MED+"Roof_RoundTiles_4x4.gltf",p+Vector3(0,floor_height*0.74,size.z*0.5+0.35),Vector3(minf(size.x*0.7,2.2),0.32,0.9),0)
		for dx in [-0.55,0.55]:
			beam(p+Vector3(dx,0,size.z*0.5+0.7),p+Vector3(dx,floor_height*0.78,size.z*0.5+0.7),0.09,materials.wood)
		asset(MED+"Prop_Chimney2.gltf",p+Vector3(size.x*0.25,size.y+0.25,-0.4),Vector3(0.4,1.15,0.4),0)
		smoke(p+Vector3(size.x*0.25,size.y+1.42,-0.4))
	asset(MED+"Prop_Vine4.gltf",p+Vector3(-size.x*0.43,0.15,size.z*0.5+0.13),Vector3(0.55,minf(size.y,2.1),0.18),0)

func highlands_building(kind: String,p: Vector3,footprint: Vector2,yaw: float) -> void:
	var path: String="res://assets/highlands/"+kind+".glb"
	cache_asset(path)
	if not library.has(path):return
	var bounds: AABB=library[path].bounds
	var ratio:=minf(footprint.x/maxf(bounds.size.x,0.01),footprint.y/maxf(bounds.size.z,0.01))
	asset(path,p,bounds.size*ratio,yaw)
