class_name ArrowProjectile
extends Node3D

var battle: Node
var source: BattleUnit
var target: BattleUnit
var damage := 0.0
var speed := 8.5
var team := 0
var projectile_kind := "arrow"

func setup(p_battle: Node, p_source: BattleUnit, p_target: BattleUnit, p_damage: float, p_kind := "arrow") -> void:
	battle = p_battle
	source = p_source
	target = p_target
	damage = p_damage
	team = p_source.team
	projectile_kind = p_kind
	if projectile_kind == "stone": speed = 7.0
	build_visual()

func build_visual() -> void:
	if projectile_kind == "stone":
		var stone := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.19
		sphere.height = 0.38
		stone.mesh = sphere
		stone.material_override = BattleUnit.make_material(Color("55515a"))
		add_child(stone)
		return
	var shaft := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.025
	cylinder.bottom_radius = 0.025
	cylinder.height = 0.72
	shaft.mesh = cylinder
	shaft.rotation_degrees.x = 90.0
	shaft.material_override = BattleUnit.make_material(Color("7b4a24"))
	add_child(shaft)
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.105
	cone.height = 0.25
	head.mesh = cone
	head.position.z = 0.45
	head.rotation_degrees.x = 90.0
	head.material_override = BattleUnit.make_material(Color("d8dbe0"))
	add_child(head)

func _process(delta: float) -> void:
	if not battle or battle.match_over or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	var destination := target.global_position + Vector3.UP * (1.0 if target.is_base else 0.85)
	var offset := destination - global_position
	if offset.length() <= speed * delta + 0.18:
		target.take_damage(damage, source if is_instance_valid(source) else null)
		queue_free()
		return
	look_at(destination, Vector3.UP, true)
	global_position += offset.normalized() * speed * delta

