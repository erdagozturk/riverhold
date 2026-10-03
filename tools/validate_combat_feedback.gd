extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scripts/main.gd").new()
	root.add_child(game)
	game.set_process(false)
	for unit in game.units: unit.set_process(false)
	var victim = game.units.back()
	var gold: int = game.player_gold
	victim.take_damage(99999, game.units[2])
	victim.take_damage(99999, game.units[2])
	assert(game.player_gold == gold + 15, "Death reward must occur once")
	assert(game.combat_feedback.reward_count == 1)
	assert(game.combat_feedback.hit_count == 1)
	game.combat_feedback.impact(Vector3.ZERO, true)
	game.combat_feedback.impact(Vector3.ONE, false)
	var a = game.combat_feedback.HIT.instantiate()
	var b = game.combat_feedback.HIT.instantiate()
	assert(a.get_node("Glow").material_override != b.get_node("Glow").material_override, "Concurrent effects must not share animated material")
	a.free(); b.free()
	await create_timer(2.5).timeout
	assert(game.combat_feedback.get_child_count() == 10, "Effects must clean up, leaving only bounded audio pool")
	print("COMBAT_FEEDBACK_PASS reward_once material_isolation cleanup hit_events")
	game.queue_free()
	await process_frame
	quit()
