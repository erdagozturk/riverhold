extends Node
## Owns static render quality. DayNight owns time-dependent sun values.
## Renderer-specific features are deliberately gated; Mobile must never inherit Forward+ settings.

var environment: Environment
var rendering_method := ""
var forward_plus := false
var compatibility := false

func setup(world: Node3D) -> void:
	name = "RenderDirector"
	rendering_method = RenderingServer.get_current_rendering_method()
	forward_plus = rendering_method == "forward_plus"
	compatibility = rendering_method == "gl_compatibility"
	environment = world.get_node("ValleyDaylight").environment
	configure_environment()
	configure_sun(world.get_node_or_null("AfternoonSun"))
	if forward_plus:
		add_river_mist(world)
	add_depth_outline(world)
	world.set_meta("rendering_method", rendering_method)
	world.set_meta("forward_plus_features", forward_plus)
	print("RENDER_PROFILE method=", rendering_method, " ssr=", environment.ssr_enabled,
		" ssao=", environment.ssao_enabled, " volumetric_fog=", environment.volumetric_fog_enabled)

func configure_environment() -> void:
	# AgX preserves hue in bright cartoon colors and rolls highlights off more gently than Linear.
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.03
	environment.tonemap_agx_white = 6.0
	environment.tonemap_agx_contrast = 1.06
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.04
	environment.adjustment_saturation = 1.03

	# The sky supplies coherent ambient/reflected light. Toon shading stays readable because its
	# contribution is controlled rather than replaced with unrelated fill lights.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.ambient_light_color = Color("8fa8c4")
	environment.ambient_light_sky_contribution = 0.58
	environment.ambient_light_energy = 0.38

	# Available in every renderer. High threshold confines glow to fire, lightning and magic.
	environment.glow_enabled = true
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.55
	environment.glow_intensity = 0.30

	# Forward+ only: screen-space reflections, indirect light and volumetric fog.
	environment.ssr_enabled = forward_plus
	environment.ssil_enabled = forward_plus
	if forward_plus:
		environment.ssr_max_steps = 48
		environment.ssil_radius = 2.2
		environment.ssil_intensity = 0.55
		environment.ssil_sharpness = 0.88
	environment.volumetric_fog_enabled = forward_plus
	if forward_plus:
		environment.volumetric_fog_density = 0.00032
		environment.volumetric_fog_length = 160.0
		environment.volumetric_fog_albedo = Color("b8ccdf")
		environment.volumetric_fog_anisotropy = 0.35
		environment.volumetric_fog_ambient_inject = 0.15
		environment.volumetric_fog_sky_affect = 0.25

	# SSAO is available in Forward+ and Compatibility, but not Mobile.
	environment.ssao_enabled = forward_plus or compatibility
	if environment.ssao_enabled:
		environment.ssao_radius = 1.05
		environment.ssao_intensity = 1.12
		environment.ssao_power = 1.25
		environment.ssao_light_affect = 0.12

	# Depth fog remains the inexpensive atmospheric-depth fallback on every renderer.
	environment.fog_enabled = true
	environment.fog_light_color = Color("9ebdca")
	environment.fog_density = 0.00105 if forward_plus else 0.00135
	environment.fog_sky_affect = 0.10
	environment.fog_aerial_perspective = 0.24

func configure_sun(sun: DirectionalLight3D) -> void:
	if not sun:
		return
	sun.light_color = Color("ffe7c7")
	sun.light_energy = 1.12
	sun.light_specular = 0.72
	sun.shadow_enabled = true
	sun.shadow_blur = 1.35
	sun.light_angular_distance = 1.1
	sun.directional_shadow_max_distance = 105.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if forward_plus else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits = forward_plus
	sun.directional_shadow_split_1 = 0.08
	sun.directional_shadow_split_2 = 0.24
	sun.directional_shadow_split_3 = 0.52

func add_river_mist(world: Node3D) -> void:
	var mist := FogVolume.new()
	mist.name = "RiverMist"
	mist.position = Vector3(0, -6.5, -15)
	mist.size = Vector3(22, 7, 140)
	var material := FogMaterial.new()
	material.density = 0.010
	material.albedo = Color("99bed1")
	material.edge_fade = 0.25
	mist.material = material
	world.add_child(mist)

func add_depth_outline(world: Node3D) -> void:
	var outline := MeshInstance3D.new()
	outline.name = "MobileDepthOutline"
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	outline.mesh = quad
	outline.extra_cull_margin = 16384.0
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var outline_material := ShaderMaterial.new()
	outline_material.shader = load("res://shaders/mobile_depth_outline.gdshader")
	outline.material_override = outline_material
	world.add_child(outline)

