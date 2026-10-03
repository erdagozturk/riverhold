extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var shell=load("res://scripts/game_shell.gd").new()
 shell.name="GameShell";game.add_child(shell);shell.setup(game)
 assert(paused and shell.page=="menu")
 shell.show_briefing();assert(paused)
 shell.resume_battle();assert(not paused)
 shell.show_pause();assert(paused)
 var t:float=game.game_time
 await create_timer(0.1,true).timeout
 assert(game.game_time==t)
 shell.show_settings();assert(paused and shell.page=="settings")
 shell.resume_battle();assert(not paused)
 game.open_card_choice();assert(paused)
 var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true
 shell._input(event);assert(paused and game.card_overlay.visible)
 game.choose_card(0);assert(not paused)
 if "--capture" in OS.get_cmdline_user_args():
  await create_timer(1.0).timeout
  root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/director-play.png")
  shell.show_pause()
  await create_timer(0.2,true).timeout
  root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/director-pause.png")
 paused=false
 game.queue_free()
 await process_frame
 print("SHELL_TEST_PASSED: menu, briefing, pause, settings, frozen battle, mandatory card choice")
 quit()
