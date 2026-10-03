@tool
extends Node3D
## Orbit and pan affect only the camera. The bridge remains the reset pivot.
const DEFAULT_SIZE := 48.0
const MIN_SIZE := 6.0
const MAX_SIZE := 68.0
const DEFAULT_YAW := 7.0
const DEFAULT_PITCH := 27.0
var view_tween: Tween
var lens: CameraAttributesPractical
var camera: Camera3D
var yaw := DEFAULT_YAW
var pitch := DEFAULT_PITCH
var zoom := DEFAULT_SIZE
var dragging := false
var pan_drag := false
var drag_origin := Vector2.ZERO
var focus := Vector3(0.0, 0.3, -3.8)
var trauma := 0.0
var shake_time := 0.0
var cinematic_follow := false
var follow_elapsed := 0.0

func setup() -> void:
	name = "BattleCamera"
	camera = Camera3D.new()
	camera.name = "OrbitCamera"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 44.0
	camera.near = 0.2
	camera.far = 320.0
	camera.current = true
	lens=CameraAttributesPractical.new()
	var dof_supported := RenderingServer.get_current_rendering_method() != "gl_compatibility"
	lens.dof_blur_far_enabled=dof_supported
	lens.dof_blur_near_enabled=false
	lens.dof_blur_amount=0.055 if dof_supported else 0.0
	camera.attributes=lens
	add_child(camera)
	reset_view()

func reset_view() -> void:
	finish_drag()
	if view_tween and view_tween.is_valid():view_tween.kill()
	yaw = DEFAULT_YAW
	pitch = DEFAULT_PITCH
	zoom = DEFAULT_SIZE
	focus = Vector3(0.0, 0.3, -3.8)
	apply_view()

func apply_view() -> void:
	if not is_instance_valid(camera): return
	var azimuth := deg_to_rad(yaw)
	var elevation := deg_to_rad(pitch)
	var offset := Vector3(sin(azimuth)*cos(elevation), sin(elevation), cos(azimuth)*cos(elevation)) * (zoom/(2.0*tan(deg_to_rad(camera.fov*0.5))))
	camera.position = focus + offset
	camera.look_at_from_position(camera.global_position, to_global(focus), Vector3.UP)
	camera.size = zoom
	var distance:=offset.length()
	lens.dof_blur_far_distance=distance+maxf(6.0,zoom*0.50)
	lens.dof_blur_far_transition=maxf(6.0,zoom*0.45)
	lens.dof_blur_near_distance=maxf(0.6,distance-maxf(4.0,zoom*0.46))
	lens.dof_blur_near_transition=maxf(2.0,zoom*0.17)

func orbit(relative: Vector2) -> void:
	cinematic_follow=false
	if view_tween and view_tween.is_valid():view_tween.kill()
	yaw = clampf(yaw - relative.x*0.23, -32.0, 32.0)
	pitch = clampf(pitch + relative.y*0.18, 22.0, 48.0)
	apply_view()

func pan_pixels(relative: Vector2) -> void:
	cinematic_follow=false
	if view_tween and view_tween.is_valid():view_tween.kill()
	var screen_height := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	var right := camera.global_basis.x
	var forward := Vector3(camera.global_basis.z.x, 0.0, camera.global_basis.z.z).normalized()
	focus += (-right*relative.x - forward*relative.y) * zoom/screen_height
	clamp_focus()
	apply_view()

func clamp_focus() -> void:
	focus.x = clampf(focus.x, -35.0, 35.0)
	focus.z = clampf(focus.z, -24.0, 21.0)
	focus.y = 0.3

func keyboard_pan(delta: float) -> void:
	if dragging: return
	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): movement.y += 1.0
	if movement.length_squared() > 0.0:
		cinematic_follow=false
		var right := camera.global_basis.x
		var forward := Vector3(camera.global_basis.z.x,0,camera.global_basis.z.z).normalized()
		focus += (right*movement.normalized().x + forward*movement.normalized().y)*delta*maxf(2.0,zoom*0.22)
		clamp_focus()
		apply_view()

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	keyboard_pan(delta)
	if cinematic_follow and not dragging:
		follow_elapsed+=delta
		var target_focus:=battle_focus()
		focus=focus.lerp(target_focus,1.0-exp(-delta*2.8))
		yaw=lerpf(yaw,7.0+sin(follow_elapsed*0.22)*2.4,1.0-exp(-delta*0.8))
		zoom=lerpf(zoom,12.0,1.0-exp(-delta*2.0))
		pitch=lerpf(pitch,24.0,1.0-exp(-delta*2.0))
		apply_view()
	if trauma > 0.001:
		shake_time += delta
		trauma = maxf(0.0, trauma-delta*2.8)
		apply_view()
		var strength:=trauma*trauma
		camera.position += camera.basis.x*sin(shake_time*61.0)*0.075*strength
		camera.position += camera.basis.y*sin(shake_time*47.0+1.7)*0.045*strength

func add_impact(point: Vector3, heavy: bool) -> void:
	if not is_instance_valid(camera) or camera.is_position_behind(point): return
	var distance:=camera.global_position.distance_to(point)
	var falloff:=clampf(1.0-distance/95.0,0.15,1.0)
	trauma=clampf(trauma+(0.30 if heavy else 0.10)*falloff,0.0,0.72)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or get_tree().paused: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			dragging = true
			pan_drag = event.shift_pressed
			drag_origin = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			cinematic_follow=false
			if view_tween and view_tween.is_valid():view_tween.kill()
			var origin := camera.project_ray_origin(event.position)
			var direction := camera.project_ray_normal(event.position)
			var anchor: Variant = Plane(Vector3.UP,focus.y).intersects_ray(origin,direction)
			var previous := zoom
			zoom = clampf(zoom*(0.86 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.16), MIN_SIZE, MAX_SIZE)
			if anchor is Vector3:
				focus += (anchor-focus)*(1.0-zoom/previous)
				clamp_focus()
			apply_view()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		reset_view()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not dragging: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		finish_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		finish_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if pan_drag: pan_pixels(event.relative)
		else: orbit(event.relative)
		get_viewport().set_input_as_handled()

func finish_drag() -> void:
	if not dragging: return
	dragging = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_inside_tree(): get_viewport().warp_mouse(drag_origin)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_PAUSED]: finish_drag()

func _exit_tree() -> void:
	finish_drag()

func watch_battle() -> void:
	finish_drag()
	cinematic_follow=true
	follow_elapsed=0.0
	if view_tween and view_tween.is_valid():view_tween.kill()
	var target_focus:=Vector3(0,0.3,0)
	var battle=get_parent()
	if battle and "units" in battle:
		for unit in battle.units:
			if is_instance_valid(unit) and not unit.dead and not unit.is_base and unit.attacking:
				target_focus=unit.global_position;break
	var start_focus:=focus
	var start_zoom:=zoom
	var start_pitch:=pitch
	var target_zoom:=12.0
	view_tween=create_tween()
	view_tween.tween_method(func(t: float):
		focus=start_focus.lerp(target_focus,t)
		zoom=lerpf(start_zoom,target_zoom,t)
		pitch=lerpf(start_pitch,24.0,t)
		apply_view(),0.0,1.0,0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func battle_focus() -> Vector3:
	var battle=get_parent()
	var sum:=Vector3.ZERO
	var count:=0
	if battle and "units" in battle:
		for unit in battle.units:
			if not is_instance_valid(unit) or unit.dead or unit.is_base or not unit.attacking: continue
			sum+=unit.global_position
			count+=1
			if count>=8: break
	if count==0: return focus
	var center:=sum/float(count)
	center.y=0.3
	center.x=clampf(center.x,-10.0,10.0)
	center.z=clampf(center.z,-1.4,1.4)
	return center
