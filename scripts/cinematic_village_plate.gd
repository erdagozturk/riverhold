extends CanvasLayer
## Hybrid presentation: authored 2.5D environment below live 3D units and VFX.

const PLATE_PATH := "res://assets/environment/plates/fetih_valley_cinematic_v1.png"
const DESIGN_BRIDGE_ANCHOR := Vector2(0.5,0.505)
var battlefield: Node3D
var camera_rig: Node3D
var old_backdrop: Node3D
var environment: Environment
var plate: TextureRect
var plate_enabled := true

func setup(p_battlefield: Node3D,p_camera_rig: Node3D,p_old_backdrop: Node3D) -> void:
	name="CinematicVillagePlate"
	layer=-100
	process_mode=Node.PROCESS_MODE_ALWAYS
	battlefield=p_battlefield
	camera_rig=p_camera_rig
	old_backdrop=p_old_backdrop
	plate=TextureRect.new()
	plate.name="VillageAndValley"
	plate.texture=load(PLATE_PATH)
	plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	environment=battlefield.get_node("ValleyDaylight").environment
	apply_mode(true)
	set_meta("presentation","2.5d_hybrid")
	set_meta("live_3d_layers",["units","projectiles","combat_vfx","world_ui"])

func apply_mode(enabled: bool) -> void:
	plate_enabled=enabled
	plate.visible=enabled
	set_geometry_hidden(battlefield,enabled)
	if is_instance_valid(old_backdrop): old_backdrop.visible=not enabled
	if is_instance_valid(camera_rig): camera_rig.plate_mode=enabled
	if is_instance_valid(camera_rig) and is_instance_valid(camera_rig.lens):
		# Screen-space art must stay crisp; depth is already painted into the plate.
		camera_rig.lens.dof_blur_far_enabled=not enabled
		camera_rig.lens.dof_blur_near_enabled=false
	if environment:
		environment.background_mode=Environment.BG_CANVAS if enabled else Environment.BG_SKY
		environment.background_canvas_max_layer=-50
	call_deferred("sync_landmarks")
	call_deferred("sync_diorama")

func sync_diorama() -> void:
	var game:=get_parent()
	var diorama: Variant=game.get("cinematic_diorama")
	if is_instance_valid(diorama): diorama.visible=plate_enabled

func sync_landmarks() -> void:
	var game:=get_parent()
	for property_name in ["blue_base","red_base"]:
		var landmark: Variant=game.get(property_name)
		if is_instance_valid(landmark): landmark.visible=not plate_enabled

func set_geometry_hidden(root: Node,hidden: bool) -> void:
	for child in root.get_children():
		if child is GeometryInstance3D:
			child.visible=not hidden
		set_geometry_hidden(child,hidden)

func _process(_delta: float) -> void:
	if not plate_enabled or not is_instance_valid(camera_rig) or not is_instance_valid(camera_rig.camera): return
	var viewport_size:=get_viewport().get_visible_rect().size
	if viewport_size.x<2.0 or viewport_size.y<2.0:return
	var scale_factor:=clampf(camera_rig.DEFAULT_SIZE/maxf(camera_rig.zoom,1.0),0.78,2.5)
	plate.size=viewport_size
	plate.scale=Vector2.ONE*scale_factor
	# World origin is the combat center; keep the generated bridge locked to it while zooming and panning.
	var combat_screen: Vector2=camera_rig.camera.unproject_position(Vector3(0.0,0.3,0.0))
	plate.position=combat_screen-DESIGN_BRIDGE_ANCHOR*viewport_size*scale_factor

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_V:
		apply_mode(not plate_enabled)
		get_viewport().set_input_as_handled()
