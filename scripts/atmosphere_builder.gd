extends Node3D

var birds: Array[Node3D] = []
var bird_time := 0.0


func setup(environment: Environment) -> void:
	name = "LivingAtmosphere"
	configure_environment(environment)
	build_water_surface()
	build_distant_valley()
	build_grass_fields()
	build_flower_beds()
	build_animated_pennants()
	build_birds()


func configure_environment(environment: Environment) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("4f91c5")
	sky_material.sky_horizon_color = Color("d6e8ea")
	sky_material.ground_bottom_color = Color("405948")
	sky_material.ground_horizon_color = Color("a7c9ad")
	sky_material.sun_angle_max = 22.0
	sky_material.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.72
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.12
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.03
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.12
	environment.glow_enabled = true
	environment.glow_intensity = 0.85
	environment.glow_bloom = 0.18
	environment.fog_enabled = true
	environment.fog_light_color = Color("c8dfe0")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.2
	environment.fog_height = -1.5
	environment.fog_height_density = 0.14


func build_water_surface() -> void:
	var water := MeshInstance3D.new()
	water.name = "AnimatedRiverSurface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(34.0, 23.0)
	plane.subdivide_width = 64
	plane.subdivide_depth = 40
	water.mesh = plane
	water.position = Vector3(0.0, -0.77, -3.0)
	water.material_override = make_water_material()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

	# Açık renkli ince şeritler, nehir yüzeyindeki akış ve köpük hissini güçlendirir.
	for z in [-9.0, -6.6, 6.0]:
		var foam := MeshInstance3D.new()
		foam.name = "RiverFoam"
		var foam_plane := PlaneMesh.new()
		foam_plane.size = Vector2(7.5, 0.16)
		foam.mesh = foam_plane
		foam.position = Vector3(0.0, -0.72, z)
		foam.material_override = make_emissive_material(Color(0.72, 0.94, 0.96, 0.48), 0.35, true)
		foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(foam)


func make_water_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.08, 0.66, 0.76, 1.0);
uniform vec4 deep_color : source_color = vec4(0.015, 0.24, 0.47, 1.0);
uniform vec4 foam_color : source_color = vec4(0.78, 0.96, 1.0, 1.0);

varying float wave_height;

void vertex() {
	float broad = sin(VERTEX.x * 0.68 + TIME * 1.25) * 0.055;
	float cross_wave = cos(VERTEX.z * 1.15 - TIME * 0.9) * 0.035;
	float ripple = sin((VERTEX.x + VERTEX.z) * 2.2 + TIME * 2.1) * 0.016;
	wave_height = broad + cross_wave + ripple;
	VERTEX.y += wave_height;
}

void fragment() {
	float flow_a = sin(UV.y * 92.0 - TIME * 3.3 + sin(UV.x * 25.0)) * 0.5 + 0.5;
	float flow_b = sin(UV.y * 47.0 - TIME * 2.15 - UV.x * 14.0) * 0.5 + 0.5;
	float foam = smoothstep(0.82, 0.98, flow_a * 0.62 + flow_b * 0.38);
	float shade = clamp(UV.y * 0.38 + 0.38 + wave_height * 1.8, 0.0, 1.0);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, shade);
	ALBEDO = mix(ALBEDO, foam_color.rgb, foam * 0.38);
	ROUGHNESS = 0.17;
	METALLIC = 0.08;
	SPECULAR = 0.92;
	EMISSION = shallow_color.rgb * 0.055 + foam_color.rgb * foam * 0.12;
	NORMAL = normalize(vec3(sin(UV.x * 36.0 + TIME) * 0.11, 1.0, cos(UV.y * 31.0 - TIME) * 0.11));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func build_distant_valley() -> void:
	# Uzak platolar, oynanış alanını çevreleyen geniş bir vadi silueti verir.
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		make_box(Vector3(side * 10.8, 0.0, -10.0), Vector3(12.0, 2.6, 6.5), Color("4f754c"), "FarPlateau")
		make_box(Vector3(side * 5.8, -0.8, -10.2), Vector3(2.6, 4.0, 6.2), Color("53645d"), "CanyonWall")
		for index in 8:
			var x: float = side * (6.3 + float(index) * 1.45)
			var height: float = 2.2 + float((index * 7) % 4) * 0.55
			make_low_poly_peak(Vector3(x, 2.0 + height * 0.35, -13.2 - float(index % 2) * 1.0), height, Color("628064"))

	# Uzak nehir ve şelale haritaya süreklilik kazandırır.
	make_box(Vector3(0.0, -0.7, -11.5), Vector3(8.8, 0.18, 7.5), Color("177f9e"), "FarRiver")
	var waterfall := MeshInstance3D.new()
	waterfall.name = "Waterfall"
	var sheet := QuadMesh.new()
	sheet.size = Vector2(2.8, 4.7)
	waterfall.mesh = sheet
	waterfall.position = Vector3(0.0, 1.45, -13.0)
	waterfall.material_override = make_waterfall_material()
	waterfall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(waterfall)
	for index in 7:
		var mist := MeshInstance3D.new()
		var mist_mesh := SphereMesh.new()
		mist_mesh.radius = 0.25 + float(index % 3) * 0.08
		mist_mesh.height = mist_mesh.radius * 1.45
		mist.mesh = mist_mesh
		mist.position = Vector3(-1.25 + index * 0.42, -0.55 + float(index % 2) * 0.12, -12.45)
		mist.material_override = make_emissive_material(Color(0.82, 0.95, 0.98, 0.38), 0.2, true)
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mist)


func make_waterfall_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;
void fragment() {
	float stream = sin(UV.x * 44.0 + sin(UV.y * 12.0) - TIME * 2.0) * 0.5 + 0.5;
	float streak = smoothstep(0.52, 0.96, stream);
	float edge = smoothstep(0.0, 0.12, UV.x) * smoothstep(0.0, 0.12, 1.0 - UV.x);
	ALBEDO = mix(vec3(0.16, 0.65, 0.82), vec3(0.88, 0.98, 1.0), streak);
	EMISSION = ALBEDO * (0.25 + streak * 0.25);
	ALPHA = edge * (0.72 + streak * 0.25);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func build_grass_fields() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 72831
	var transforms: Array[Transform3D] = []
	for index in 310:
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var x: float = side * rng.randf_range(6.0, 16.6)
		var z: float = rng.randf_range(-6.2, 6.2)
		if absf(z) < 3.75:
			z = signf(z if not is_zero_approx(z) else 1.0) * rng.randf_range(3.9, 6.2)
		var scale: float = rng.randf_range(0.62, 1.28)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale, scale, scale))
		transforms.append(Transform3D(basis, Vector3(x, 0.25, z)))
	add_grass_multimesh(transforms, 0.0)
	add_grass_multimesh(transforms, PI * 0.5)


func add_grass_multimesh(transforms: Array[Transform3D], rotation_offset: float) -> void:
	var grass_mesh := QuadMesh.new()
	grass_mesh.size = Vector2(0.34, 0.62)
	grass_mesh.orientation = PlaneMesh.FACE_Z
	grass_mesh.material = make_grass_material()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = grass_mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		var source := transforms[index]
		var rotated_basis := source.basis.rotated(Vector3.UP, rotation_offset)
		multimesh.set_instance_transform(index, Transform3D(rotated_basis, source.origin + Vector3.UP * 0.27))
	var instance := MultiMeshInstance3D.new()
	instance.name = "WindGrass"
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func make_grass_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
void vertex() {
	float tip = clamp(UV.y, 0.0, 1.0);
	VERTEX.x += sin(TIME * 1.35 + MODEL_MATRIX[3].x * 0.72 + MODEL_MATRIX[3].z * 0.51) * 0.075 * tip * tip;
}
void fragment() {
	float blade = smoothstep(0.5, 0.12, abs(UV.x - 0.5));
	float tip = smoothstep(1.0, 0.66, UV.y);
	ALPHA = blade * tip;
	ALPHA_SCISSOR_THRESHOLD = 0.15;
	ALBEDO = mix(vec3(0.12, 0.38, 0.09), vec3(0.46, 0.69, 0.18), UV.y);
	ROUGHNESS = 0.88;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func build_flower_beds() -> void:
	var flower_scene: PackedScene = load("res://assets/nature/Flower_1_Clump.fbx")
	var bush_scene: PackedScene = load("res://assets/nature/Bush_Flowers.fbx")
	if not flower_scene:
		return
	var positions := [
		Vector3(-15.0, 0.25, -4.3), Vector3(-13.6, 0.25, 4.1), Vector3(-10.2, 0.25, -4.7),
		Vector3(-7.2, 0.25, 4.35), Vector3(15.0, 0.25, 4.3), Vector3(13.6, 0.25, -4.1),
		Vector3(10.2, 0.25, 4.7), Vector3(7.2, 0.25, -4.35), Vector3(-8.5, 0.25, 5.5),
		Vector3(8.5, 0.25, -5.5), Vector3(-12.0, 0.25, -5.65), Vector3(12.0, 0.25, 5.65)
	]
	for index in positions.size():
		var scene := bush_scene if bush_scene and index % 4 == 0 else flower_scene
		var flower := scene.instantiate() as Node3D
		flower.position = positions[index]
		flower.rotation.y = float(index) * 1.73
		flower.scale = Vector3.ONE * (0.62 + float(index % 3) * 0.12)
		add_child(flower)


func build_animated_pennants() -> void:
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		var team_color := Color("278ee5") if side < 0.0 else Color("d9473f")
		for z in [-3.75, 3.75]:
			var flag := MeshInstance3D.new()
			flag.name = "WindPennant"
			var quad := QuadMesh.new()
			quad.size = Vector2(0.95, 0.55)
			flag.mesh = quad
			flag.position = Vector3(side * 11.0, 6.25, z)
			flag.rotation.y = -PI * 0.5 if side < 0.0 else PI * 0.5
			flag.material_override = make_flag_material(team_color)
			add_child(flag)


func make_flag_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 team_color : source_color;
void vertex() {
	float free_edge = UV.x;
	VERTEX.z += sin(TIME * 3.0 + UV.x * 6.0) * 0.09 * free_edge;
}
void fragment() {
	float weave = 0.88 + sin(UV.x * 26.0) * sin(UV.y * 19.0) * 0.04;
	ALBEDO = team_color.rgb * weave;
	ROUGHNESS = 0.72;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("team_color", color)
	return material


func build_birds() -> void:
	for index in 5:
		var bird := Node3D.new()
		bird.name = "DistantBird"
		bird.set_meta("radius", 3.8 + float(index) * 0.72)
		bird.set_meta("speed", 0.15 + float(index % 3) * 0.035)
		bird.set_meta("phase", float(index) * 1.23)
		bird.position = Vector3(0.0, 8.2 + float(index % 2) * 0.65, -14.0)
		for wing_sign in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var wing_mesh := BoxMesh.new()
			wing_mesh.size = Vector3(0.38, 0.025, 0.075)
			wing.mesh = wing_mesh
			wing.position.x = wing_sign * 0.17
			wing.rotation.z = wing_sign * 0.35
			wing.material_override = make_standard_material(Color("263c44"))
			wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			bird.add_child(wing)
		add_child(bird)
		birds.append(bird)


func _process(delta: float) -> void:
	bird_time += delta
	for index in birds.size():
		var bird := birds[index]
		if not is_instance_valid(bird):
			continue
		var phase: float = bird.get_meta("phase")
		var radius: float = bird.get_meta("radius")
		var angle := bird_time * float(bird.get_meta("speed")) + phase
		bird.position.x = cos(angle) * radius
		bird.position.z = -13.5 + sin(angle) * 1.6
		bird.position.y = 7.8 + sin(angle * 2.4) * 0.32 + float(index % 2) * 0.55
		bird.rotation.y = -angle
		for wing in bird.get_children():
			wing.rotation.z = signf(wing.position.x) * (0.25 + sin(bird_time * 5.0 + phase) * 0.23)


func make_low_poly_peak(pos: Vector3, height: float, color: Color) -> void:
	var peak := MeshInstance3D.new()
	peak.name = "DistantPeak"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.12
	cone.bottom_radius = height * 0.62
	cone.height = height
	cone.radial_segments = 7
	peak.mesh = cone
	peak.position = pos
	peak.material_override = make_standard_material(color)
	add_child(peak)


func make_box(pos: Vector3, size: Vector3, color: Color, node_name: String) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.position = pos
	instance.material_override = make_standard_material(color)
	add_child(instance)


func make_standard_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material


func make_emissive_material(color: Color, energy: float, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = energy
	material.roughness = 0.28
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
