extends Node
## Six-minute visual cycle; equal lighting for both armies, no combat modifiers.
var elapsed := 0.0
var sun: DirectionalLight3D
var environment: Environment
var lamps: Array[OmniLight3D]=[]
func setup(world: Node) -> void:
	sun=world.get_node_or_null("AfternoonSun")
	var holder=world.get_node_or_null("ValleyDaylight")
	if holder:environment=holder.environment
	for light in world.find_children("*","OmniLight3D",true,false):lamps.append(light)

func _process(delta: float) -> void:
	if not sun or not environment:return
	elapsed+=delta
	var phase:=fposmod(elapsed/360.0+0.35,1.0)
	var daylight:=smoothstep(-0.12,0.35,sin(phase*TAU))
	var twilight:=1.0-absf(daylight*2.0-1.0)
	sun.rotation_degrees=Vector3(lerpf(-16,-36,daylight),-35+sin(phase*TAU)*12,0)
	sun.light_energy=lerpf(0.28,1.18,daylight)
	sun.light_color=Color("829fd9").lerp(Color("ffe1b4"),daylight).lerp(Color("ffae70"),twilight*0.5)
	environment.ambient_light_energy=lerpf(0.22,0.38,daylight)
	environment.fog_light_color=Color("263d64").lerp(Color("94b6bb"),daylight)
	var sky=environment.sky.sky_material
	if sky is ShaderMaterial:
		sky.set_shader_parameter("daylight",daylight)
		sky.set_shader_parameter("twilight",twilight)
	for i in lamps.size():
		if is_instance_valid(lamps[i]):lamps[i].light_energy=lerpf(1.9,0.45,daylight)*(1.0+sin(elapsed*9+i*2.4)*0.08)
