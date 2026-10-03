extends SceneTree
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
	print("CHECK ",label," ",ok)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for u in game.units:u.set_process(false)
	for tier in 3:
		for iteration in 100:
			for book in game.augments:
				var offer=book.roll(tier)
				assert(offer.size()==3)
				var ids: Array=[]
				for c in offer:
					assert(c.rarity==tier and not ids.has(c.id));ids.append(c.id)
	check(true,"600 offers: three unique cards of shared rarity")
	for book in game.augments:
		for card in book.CARDS:book.stacks[card.id]=card.max
		for tier in 3:
			var cards=book.roll(tier)
			check(cards.size()==3,"capped pool fallback team %d tier %d" % [book.team,tier])
		book.stacks.clear()
	for team in 2:
		var book=game.augments[team]
		book.offered=[book.CARDS[0]]
		var target=game.units.filter(func(u):return u.team==team and not u.is_base)[0]
		var before: float=target.damage
		book.choose(game,0)
		check(is_equal_approx(target.damage,before*1.15),"existing units receive team buff %d"%team)
		game.spawn_unit(team,0,false)
		var newest=game.units.back()
		newest.set_process(false)
		check(is_equal_approx(newest.damage,18*1.15),"new units receive team buff %d"%team)
	game.spawn_unit(0,1,false);var archer=game.units.back();archer.set_process(false)
	game.spawn_unit(1,2,false);var tank=game.units.back();tank.set_process(false)
	var hp:float=tank.health
	tank.take_damage(20,archer)
	check(is_equal_approx(hp-tank.health,11),"tank blocks 45 percent arrow damage")
	check(is_instance_valid(archer.bow_socket),"archer carries bow in left hand")
	archer.play_animation("attack")
	check(archer.anim_player.current_animation=="Ranged_Bow_Draw","archer uses bow animation")
	game.open_card_choice()
	var tier:int=game.card_tier
	check(game.augments[0].offered.all(func(c):return c.rarity==tier) and game.augments[1].offered.all(func(c):return c.rarity==tier),"live round uses one shared rarity")
	game.choose_card(0)
	check(not paused and not game.card_overlay.visible,"selection resumes battle")
	game.player_gold=500
	var previous_gold:int=game.player_gold
	var previous_army:int=game.population(0)
	var cost:int=ceili(game.role_cost(2)*game.augments[0].cost_multiplier())
	check(game.request_recruit(2),"mouse recruitment accepts order")
	check(game.player_gold==previous_gold-cost and game.population(0)==previous_army,"queue reserves gold without instant spawn")
	game.process_recruits(3.0)
	check(game.population(0)==previous_army+1 and game.player_gold==previous_gold-cost and game.recruit_queue.is_empty(),"training produces once without double charge")
	if "--capture" in OS.get_cmdline_user_args():
		game.update_ui()
		await create_timer(2).timeout
		root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/play.png")
		game.open_card_choice()
		await create_timer(0.3,true).timeout
		root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/cards.png")
		paused=false
		game.card_overlay.visible=false
		for child in game.get_children():
			if child.get_script()==load("res://scripts/day_night.gd"):
				child.elapsed=144.0
				child._process(0)
		await create_timer(0.5).timeout
		root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/night.png")
	paused=false
	print("AUGMENT_TEST_RESULT ",failures)
	quit(0 if failures.is_empty() else 1)
