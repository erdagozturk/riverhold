extends Node3D
## Cosmetic only: rewards remain exclusively in main.on_unit_died.
const HIT = preload("res://assets/BinbunVFX_Vol2/StylizedHitFX/effects/hit/vfx_hit_01.tscn")
const HEAVY = preload("res://assets/BinbunVFX_Vol2/StylizedHitFX/effects/impact/vfx_impact_01.tscn")
const LOOT = preload("res://assets/BinbunVFX/loot_effects/effects/ground/ground_loot_vfx_legendary.tscn")
const SLICE = preload("res://assets/audio/combat/knifeSlice.ogg")
const SLICE_ALT = preload("res://assets/audio/combat/knifeSlice2.ogg")
const CHOP = preload("res://assets/audio/combat/chop.ogg")
const COINS = preload("res://assets/audio/combat/handleCoins2.ogg")
var voices: Array[AudioStreamPlayer3D] = []
var hit_count := 0
var reward_count := 0
var coin_mesh: CylinderMesh
var coin_material: StandardMaterial3D
var camera_rig: Node

func setup(p_camera_rig: Node) -> void:
	camera_rig=p_camera_rig

func _ready() -> void:
	for i in 10:
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size=18.0
		voice.max_distance=120.0
		voice.attenuation_filter_cutoff_hz=12000.0
		add_child(voice)
		voices.append(voice)
	coin_mesh = CylinderMesh.new()
	coin_mesh.top_radius = 0.24
	coin_mesh.bottom_radius = 0.24
	coin_mesh.height = 0.07
	coin_mesh.radial_segments = 12
	coin_material = StandardMaterial3D.new()
	coin_material.albedo_color = Color("ffc340")
	coin_material.metallic = 0.65
	coin_material.roughness = 0.25
	coin_material.emission_enabled = true
	coin_material.emission = Color("d79520")
	coin_material.emission_energy_multiplier = 0.4

func sound(stream: AudioStream, point: Vector3, volume: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera and camera.is_position_behind(point): return
	for voice in voices:
		if voice.playing: continue
		voice.global_position = point
		voice.stream = stream
		voice.volume_db = volume
		voice.pitch_scale = randf_range(0.94, 1.06)
		voice.play()
		return

func impact(point: Vector3, heavy: bool = false) -> void:
	hit_count += 1
	if get_child_count() > 65: return
	var fx: Node3D = (HEAVY if heavy else HIT).instantiate()
	fx.autoplay = false
	fx.one_shot = true
	add_child(fx)
	fx.global_position = point
	fx.scale = Vector3.ONE * (0.46 if heavy else 0.27)
	fx.primary_color = Color("ffe6a0")
	fx.secondary_color = Color("ed931e")
	fx.light_energy = 0.75 if heavy else 0.42
	fx.speed_scale = 2.65
	fx.play()
	if is_instance_valid(camera_rig) and camera_rig.has_method("add_impact"):
		camera_rig.add_impact(point,heavy)
	var cleanup := create_tween()
	cleanup.tween_interval(1.1)
	cleanup.tween_callback(fx.queue_free)
	sound(CHOP if heavy else (SLICE if hit_count%2==0 else SLICE_ALT), point, -12.0 if heavy else -17.0)

func reward(point: Vector3, player_reward: bool) -> void:
	reward_count += 1
	if get_child_count() > 65: return
	var group := Node3D.new()
	add_child(group)
	group.global_position = point
	var glow: Node3D = LOOT.instantiate()
	group.add_child(glow)
	glow.scale = Vector3.ONE * 0.23
	glow.primary_color = Color("ffc541")
	glow.secondary_color = Color("ed921e")
	glow.light_energy = 0.2
	for i in 5:
		var coin := MeshInstance3D.new()
		coin.mesh = coin_mesh
		coin.material_override = coin_material
		group.add_child(coin)
		coin.position.y = 0.65
		coin.rotation.x = PI * 0.5
		var angle := TAU * float(i) / 5.0
		var landing := Vector3(cos(angle), 0.07, sin(angle)) * randf_range(0.35, 0.7)
		landing.y = 0.07
		var tween := coin.create_tween()
		tween.tween_property(coin, "position", landing + Vector3.UP * 0.85, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "position", landing, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(coin, "position:y", 0.25, 0.10)
		tween.tween_property(coin, "position:y", 0.07, 0.12)
		tween.tween_interval(0.30 + i * 0.04)
		tween.tween_property(coin, "scale", Vector3.ZERO, 0.20)
	var cleanup := group.create_tween()
	cleanup.tween_interval(1.5)
	cleanup.tween_callback(group.queue_free)
	if player_reward: sound(COINS, point, -16.0)
