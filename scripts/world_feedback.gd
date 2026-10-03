extends Node3D
## Bounded reusable world-space labels; visual events never change combat state.
const LIMIT=32
var pool: Array[Dictionary]=[]
func _ready() -> void:
	for i in LIMIT:
		var label:=Label3D.new()
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=40;label.outline_size=9;label.pixel_size=0.008
		label.no_depth_test=false;label.shaded=false
		add_child(label);label.hide()
		pool.append({"node":label,"life":0.0,"origin":Vector3.ZERO})

func damage(point: Vector3,amount: float,team: int) -> void:
	var camera:=get_viewport().get_camera_3d()
	if not camera or camera.is_position_behind(point):return
	# At tactical zoom numbers would create noise: show only when approaching combat.
	if camera.global_position.distance_to(point)>42.0:return
	for entry in pool:
		if entry.life>0.0:continue
		entry.life=0.75;entry.origin=point
		var label:Label3D=entry.node
		label.text=str(roundi(amount));label.modulate=Color("ffe2a0") if team==1 else Color("ff9c91")
		label.global_position=point;label.show()
		return

func _process(delta: float) -> void:
	var camera:=get_viewport().get_camera_3d()
	if not camera:return
	for entry in pool:
		if entry.life<=0.0:continue
		entry.life=maxf(0.0,entry.life-delta)
		var label:Label3D=entry.node
		if entry.life<=0.0:label.hide();continue
		label.global_position=entry.origin+Vector3.UP*(0.75-entry.life)*0.85
		label.modulate.a=minf(1.0,entry.life/0.2)
		label.scale=Vector3.ONE*clampf(camera.global_position.distance_to(label.global_position)/18.0,0.65,1.6)
