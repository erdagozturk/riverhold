class_name VillagePlan
extends RefCounted
## Shared authored coordinates: visuals, recruitment and objective use one plan.
const ALTAR_X := 24.0
const BARRACKS_X := 29.0
const EXIT_Z := -7.6
const DEFENSE_X := 15.0
const SURFACE_Y := 0.35

static func side(team: int) -> float:
	return -1.0 if team==0 else 1.0

static func altar(team: int) -> Vector3:
	return Vector3(side(team)*ALTAR_X,SURFACE_Y,0)

static func recruit_position(team: int,lane: float,row: int) -> Vector3:
	return Vector3(side(team)*(BARRACKS_X+lane),SURFACE_Y,EXIT_Z-float(row)*0.72)

static func recruit_route(team: int,lane: float) -> Array[Vector3]:
	return [Vector3(side(team)*(BARRACKS_X+lane),SURFACE_Y,-5.2+lane),Vector3(side(team)*20.0,SURFACE_Y,-5.2+lane),Vector3(side(team)*20.0,SURFACE_Y,lane)]

static func buildings(team: int=-1) -> Array[Dictionary]:
	var plots: Array[Dictionary] = [
		{"kind":"castle","pos":Vector2(20,-17),"size":Vector2(10,9),"door":Vector2(21,-11)},
		{"kind":"barracks","pos":Vector2(29,-13),"size":Vector2(7.2,5),"door":Vector2(29,-7.6)},
		{"kind":"guildhall","pos":Vector2(37,-16),"size":Vector2(6.0,5.0),"door":Vector2(34,-15)},
		{"kind":"blacksmith","pos":Vector2(44,-14),"size":Vector2(4.2,4.0),"door":Vector2(41.5,-14)},
		{"kind":"townhouse","pos":Vector2(38,-8),"size":Vector2(4.3,3.7),"door":Vector2(35.8,-8)},
		{"kind":"home","pos":Vector2(44,-8),"size":Vector2(3.5,3.2),"door":Vector2(41.8,-8)},
		{"kind":"town_center","pos":Vector2(37,0),"size":Vector2(7.2,5.8),"door":Vector2(33.4,0)},
		{"kind":"market","pos":Vector2(19,6.3),"size":Vector2(3,2.4),"door":Vector2(19,4.5)},
		{"kind":"market","pos":Vector2(23,6.3),"size":Vector2(3,2.4),"door":Vector2(23,4.5)},
		{"kind":"inn","pos":Vector2(30,6),"size":Vector2(5.0,4.0),"door":Vector2(27.5,6)},
		{"kind":"home","pos":Vector2(31,11),"size":Vector2(3.2,3),"door":Vector2(28.8,11)},
		{"kind":"townhouse","pos":Vector2(38,7),"size":Vector2(4.2,3.6),"door":Vector2(35.7,7)},
		{"kind":"home","pos":Vector2(44,7),"size":Vector2(3.5,3.2),"door":Vector2(41.8,7)},
		{"kind":"home","pos":Vector2(45,1.5),"size":Vector2(3.3,3.0),"door":Vector2(42.8,1.5)},
		{"kind":"farmhouse","pos":Vector2(24,15.2),"size":Vector2(3.5,3),"door":Vector2(24,12.8)},
		{"kind":"windmill","pos":Vector2(33.5,15),"size":Vector2(5.0,5.0),"door":Vector2(31,12.8)},
		{"kind":"warehouse","pos":Vector2(15,14),"size":Vector2(3.6,3),"door":Vector2(17.3,14)},
		{"kind":"home","pos":Vector2(40,14.5),"size":Vector2(3.6,3.2),"door":Vector2(38,12.8)},
		{"kind":"hut","pos":Vector2(45.5,14.5),"size":Vector2(3.2,3.2),"door":Vector2(43,12.8)},
		{"kind":"hut","pos":Vector2(45,-3.5),"size":Vector2(3.2,3.0),"door":Vector2(42.8,-3.5)}
	]
	for i in plots.size():
		if team==1:
			# Tiny cosmetic offsets preserve identical travel distances and footprints.
			plots[i]=plots[i].duplicate()
			plots[i].pos+=Vector2(0.10 if i%2==0 else -0.10,0.18 if i%3==0 else -0.12)
			plots[i].door+=Vector2(0,0.10 if i%2==0 else -0.08)
	return plots

static func roads() -> Array[Dictionary]:
	return [
		{"a":Vector2(38.6,-19),"b":Vector2(38.6,16),"width":2.0,"name":"outer_neighborhood_street"},
		{"a":Vector2(43,-19),"b":Vector2(43,16),"width":1.5,"name":"courtyard_alley"},
		{"a":Vector2(35,-5.2),"b":Vector2(43,-5.2),"width":1.7,"name":"workshop_connection"},
		{"a":Vector2(36,12.8),"b":Vector2(43,12.8),"width":1.7,"name":"residential_connection"},
		{"a":Vector2(34,0),"b":Vector2(43,0),"width":2.2,"name":"outer_square"},
		{"a":Vector2(33,0),"b":Vector2(33,12.8),"width":1.7,"name":"residential_lane"},
		{"a":Vector2(28,0),"b":Vector2(34,0),"width":3.0,"name":"west_avenue"},
		{"a":Vector2(35,-15.5),"b":Vector2(35,-5.2),"width":1.8,"name":"craftsmen_lane"},
		{"a":Vector2(35,-5.2),"b":Vector2(29,-5.2),"width":1.8,"name":"craftsmen_join"},
		{"a":Vector2(10,0),"b":Vector2(28,0),"width":3.2,"name":"army_avenue"},
		{"a":Vector2(29,-8),"b":Vector2(29,-5.2),"width":6.3,"name":"barracks_exit"},
		{"a":Vector2(29,-5.2),"b":Vector2(20,-5.2),"width":6.3,"name":"muster_road"},
		{"a":Vector2(20,-5.2),"b":Vector2(20,0),"width":6.3,"name":"muster_join"},
		{"a":Vector2(21,-11),"b":Vector2(21,-5),"width":2.8,"name":"castle_steps"},
		{"a":Vector2(21,-5),"b":Vector2(24,0),"width":2.8,"name":"castle_avenue"},
		{"a":Vector2(19,0),"b":Vector2(19,4.5),"width":2.0,"name":"market_entrance"},
		{"a":Vector2(17,4.5),"b":Vector2(27.8,4.5),"width":2.2,"name":"market_street"},
		{"a":Vector2(27.8,0),"b":Vector2(27.8,12.8),"width":1.9,"name":"homes_street"},
		{"a":Vector2(27.8,12.8),"b":Vector2(18,12.8),"width":1.9,"name":"farm_street"},
		{"a":Vector2(18,4.5),"b":Vector2(18,15.8),"width":1.6,"name":"dock_street"},
		{"a":Vector2(27.8,12.8),"b":Vector2(36,12.8),"width":1.6,"name":"orchard_walk"},
		{"a":Vector2(18,14),"b":Vector2(17.3,14),"width":1.6,"name":"warehouse_entry"}
	]

static var _path_segments: Array[Dictionary] = []

static func path_segments() -> Array[Dictionary]:
	if not _path_segments.is_empty():return _path_segments
	var main_roads := roads()
	_path_segments.assign(main_roads)
	# Entrance connections are authored geometry: compute once, not per grass blade.
	for team in 2:
		for spec in buildings(team):
			var closest: Vector2=spec.door
			var best:=INF
			for road in main_roads:
				var q:=Geometry2D.get_closest_point_to_segment(spec.door,road.a,road.b)
				if q.distance_to(spec.door)<best:best=q.distance_to(spec.door);closest=q
			_path_segments.append({"a":spec.pos.lerp(spec.door,0.7),"b":closest,"width":1.35})
	return _path_segments

static func path_distance(p: Vector2) -> float:
	var result := INF
	for segment in path_segments():
		var point:=Geometry2D.get_closest_point_to_segment(p,segment.a,segment.b)
		result=minf(result,p.distance_to(point)-segment.width*0.5)
	return result

static func occupied(p: Vector2,padding: float) -> bool:
	if path_distance(p)<padding: return true
	if p.distance_to(Vector2(24,0))<4.5+padding: return true
	if Rect2(20,8,6,4).grow(padding).has_point(p): return true
	for building in buildings():
		var rect:=Rect2(building.pos-building.size*0.5,building.size)
		if rect.grow(padding+0.7).has_point(p): return true
	return false
