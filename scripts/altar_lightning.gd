class_name AltarLightning
extends Node3D

var source: BattleUnit
var target: BattleUnit
var damage:=0.0
var elapsed:=0.0
var duration:=0.28
var delivered:=false
var bolt: MeshInstance3D

func setup(p_source: BattleUnit,p_target: BattleUnit,p_damage: float) -> void:
	source=p_source;target=p_target;damage=p_damage
	bolt=MeshInstance3D.new()
	bolt.name="AltarLightningBolt"
	var quad:=QuadMesh.new();quad.size=Vector2(1.25,1.0);quad.orientation=PlaneMesh.FACE_Z
	bolt.mesh=quad
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/altar_lightning.gdshader")
	var team_color:=Color("73d8ff") if source.team==0 else Color("ff7b62")
	material.set_shader_parameter("main_color",team_color.lightened(0.45))
	material.set_shader_parameter("effect_color",team_color)
	material.set_shader_parameter("seed",randf()*100.0)
	bolt.material_override=material
	bolt.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bolt)
	update_bolt()

func _process(delta: float) -> void:
	elapsed+=delta
	if not is_instance_valid(target) or target.dead:
		queue_free();return
	update_bolt()
	if not delivered and elapsed>=duration*0.62:
		delivered=true
		target.take_damage(damage,source)
	if elapsed>=duration: queue_free()

func update_bolt() -> void:
	var a:=source.global_position+Vector3.UP*1.65 if is_instance_valid(source) else global_position
	var b:=target.global_position+Vector3.UP*0.9
	var direction:=b-a
	var length:=direction.length()
	if length<0.01:return
	bolt.global_position=(a+b)*0.5
	var y:=direction/length
	var camera:=get_viewport().get_camera_3d()
	var toward_camera:=(camera.global_position-bolt.global_position).normalized() if camera else Vector3.FORWARD
	var x:=y.cross(toward_camera).normalized()
	if x.length_squared()<0.01:x=Vector3.RIGHT
	var z:=x.cross(y).normalized()
	bolt.global_basis=Basis(x,y,z).scaled(Vector3(1.0,length,1.0))
