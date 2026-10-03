@tool
extends Node3D
## Cosmetic actors never join BattleUnit, consume population or participate in combat.
var valley: Node3D
var residents: Array[Dictionary] = []
var flyers: Array[Dictionary] = []
var elapsed := 0.0
var rng := RandomNumberGenerator.new()
var bounds_cache: Dictionary = {}

func setup(world: Node3D,routes: Array[Dictionary]) -> void:
	name="VillageLife"
	valley=world
	rng.seed=43028
	for route in routes:
		for i in route.count:
			var human: bool = route.kind in ["villager","farmer"]
			var path: String = "res://assets/characters/Rogue_Clean.fbx" if human else "res://assets/animals/"+route.kind+".glb"
			var height: float = 1.25 if human else (0.60 if route.kind=="Dog" else (0.36 if route.kind=="Cat" else 0.25))
			var actor := make_actor(path,height)
			actor.name=route.kind+str(i)
			var points: Array[Vector3] = []
			for point in route.points: points.append(point)
			var index: int = i%points.size()
			actor.position=points[index]
			actor.position.y=valley.height_at(actor.position.x,actor.position.z)
			if route.kind=="farmer": add_straw_hat(actor,height)
			var animation := find_player(actor)
			var record := {"actor":actor,"points":points,"target":(index+1)%points.size(),"wait":rng.randf_range(0,2.0),"speed":0.85 if human else (0.8 if route.kind=="Dog" else 0.45),"player":animation,"kind":route.kind,"phase":rng.randf_range(0,TAU),"moving":false}
			residents.append(record)
			play(record,false)
	for i in 5:
		var eagle:=i<2
		var actor:=make_actor("res://assets/animals/Eagle.glb" if eagle else "res://assets/animals/Bird.glb",2.1 if eagle else 0.38,true)
		actor.name=("DistantEagle" if eagle else "GardenBird")+str(i)
		var player:=find_player(actor)
		if player:
			for clip in player.get_animation_list():
				if clip=="RESET": continue
				if clip.to_lower().contains("fly") or clip.to_lower().contains("action"):
					player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
					player.play(clip);player.seek(float(i)*0.3)
					break
		flyers.append({"actor":actor,"angle":float(i)*2.1,"radius":15.0 if eagle else 2.6,"altitude":17.0+i*3.0 if eagle else 4.0,"center_x":-15.0 if i%2==0 else 23.0,"center_z":-65.0-i*17.0 if eagle else 25.0,"speed":0.09 if i%2==0 else -0.12})
	set_meta("resident_count",residents.size())
	set_meta("bird_count",flyers.size())

func make_actor(path: String,height: float,wingspan: bool=false) -> Node3D:
	var actor := Node3D.new()
	add_child(actor)
	var pivot := Node3D.new()
	actor.add_child(pivot)
	var model: Node3D=load(path).instantiate()
	pivot.add_child(model)
	if not bounds_cache.has(path):
		var boxes: Array[AABB]=[]
		collect_bounds(model,Transform3D.IDENTITY,boxes)
		var box := boxes[0]
		for b in boxes: box=box.merge(b)
		bounds_cache[path]=box
	var box: AABB=bounds_cache[path]
	var extent:=maxf(box.size.x,box.size.z) if wingspan else box.size.y
	var s := height/maxf(extent,0.001)
	model.scale*=s
	model.position-=Vector3(box.get_center().x,box.position.y,box.get_center().z)*s
	# Original Quaternius quadrupeds/chick face +X; game actors face +Z.
	if path.get_file() in ["Cat.glb","Dog.glb","Chick.glb"]: pivot.rotation.y=-PI*0.5
	return actor

func collect_bounds(node: Node,t: Transform3D,boxes: Array[AABB]) -> void:
	var local := t
	if node is Node3D: local=t*node.transform
	if node is MeshInstance3D and node.mesh: boxes.append(local*node.mesh.get_aabb())
	for child in node.get_children(): collect_bounds(child,local,boxes)

func find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := find_player(child)
		if found: return found
	return null

func add_straw_hat(actor: Node3D,height: float) -> void:
	var hat := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius=0.26
	mesh.bottom_radius=0.28
	mesh.height=0.055
	hat.mesh=mesh
	hat.position.y=height*0.94
	hat.material_override=valley.solid(Color("ac8742"))
	actor.add_child(hat)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius=0.12
	crown_mesh.bottom_radius=0.18
	crown_mesh.height=0.14
	crown.mesh=crown_mesh
	crown.position.y=height*0.94+0.08
	crown.material_override=hat.material_override
	actor.add_child(crown)

func play(record: Dictionary,moving: bool) -> void:
	var player: AnimationPlayer=record.player
	if not player: return
	var choice := ""
	for clip in player.get_animation_list():
		if clip=="RESET": continue
		var lower := clip.to_lower()
		var idle_match := lower=="idle" or lower.ends_with("|idle")
		if record.kind=="farmer" and not moving: idle_match=lower.ends_with("|interact")
		if (moving and (lower.contains("walking_a") or lower=="walking")) or (not moving and idle_match):
			choice=clip
			break
	if choice.is_empty() and moving:
		for clip in player.get_animation_list():
			if clip!="RESET": choice=clip;break
	if choice.is_empty():
		player.pause()
	else:
		player.get_animation(choice).loop_mode=Animation.LOOP_LINEAR
		player.play(choice,0.15,0.7 if record.kind in ["villager","farmer"] else 1.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	elapsed+=delta
	for record in residents:
		var actor: Node3D=record.actor
		if record.wait>0:
			record.wait-=delta
			continue
		var target: Vector3=record.points[record.target]
		var direction := target-actor.position
		direction.y=0
		if direction.length()<0.07:
			record.target=(record.target+1)%record.points.size()
			record.wait=rng.randf_range(1.0,4.0) if record.kind!="farmer" else rng.randf_range(4.0,7.0)
			record.moving=false
			play(record,false)
			continue
		if not record.moving:
			record.moving=true
			play(record,true)
		actor.rotation.y=lerp_angle(actor.rotation.y,atan2(direction.x,direction.z),minf(1.0,delta*6.0))
		actor.position+=direction.normalized()*minf(record.speed*delta,direction.length())
		actor.position.y=valley.height_at(actor.position.x,actor.position.z)
	for bird in flyers:
		var angle: float=bird.angle+elapsed*bird.speed
		var actor: Node3D=bird.actor
		actor.position=Vector3(bird.center_x+cos(angle)*bird.radius,bird.altitude+sin(angle*2.0)*0.3,bird.center_z+sin(angle)*bird.radius*0.6)
		actor.rotation.y=atan2(-sin(angle)*bird.speed,cos(angle)*0.6*bird.speed)
		actor.rotation.z=sin(angle)*0.13
