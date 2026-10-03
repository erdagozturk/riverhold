extends SceneTree
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
 print("CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func click(control:Control)->void:
 var point=control.get_global_rect().get_center()
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new()
  event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
  root.push_input(event,true)
  await process_frame
func run()->void:
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.open_card_choice()
 var hud=game.card_overlay.get_parent().get_parent()
 check(hud.confirm.disabled,"confirmation initially disabled")
 await click(game.augment_buttons[1])
 check(paused and game.card_overlay.visible and hud.selected==1,"mouse marks card without applying")
 check(game.augment_buttons[1].get_node("Selection").text=="SEÇİLDİ","selected card has explicit text state")
 await click(hud.confirm)
 check(not paused and not game.card_overlay.visible,"confirm applies and resumes")
 game.camera_rig.watch_battle()
 await create_timer(0.9).timeout
 check(is_equal_approx(game.camera_rig.zoom,12.0),"close combat camera")
 game.camera_rig.reset_view()
 game.open_card_choice()
 check(hud.selected==-1 and hud.confirm.disabled,"next offer clears selection")
 game.player_gold=0;hud._process(0.0)
 check(hud.recruit_buttons[0].disabled and "altın eksik" in hud.recruit_buttons[0].get_node("Availability").text,"disabled recruit explains affordability")
 game.player_gold=2000;hud._process(0.0)
 check(hud.attack.button_pressed and not hud.defend.button_pressed,"active army order is persistent")
 await click(game.augment_buttons[0])
 if "--capture" in OS.get_cmdline_user_args():
  await create_timer(0.1,true).timeout
  root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/redesign-selected.png")
 await click(hud.confirm)
 for i in 6:
  game.spawn_unit(0,i%3,false);game.spawn_unit(1,i%3,false)
 var lanes:Dictionary={}
 for unit in game.units:
  if not unit.is_base:lanes[unit.lane_z]=true
 check(lanes.size()==2,"two file battle formation")
 check(game.battlefield.get_meta("bridge_width")==3.2,"narrow bridge geometry")
 game.card_elapsed=-120
 if "--capture" in OS.get_cmdline_user_args():
  await create_timer(6.0).timeout
  root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/redesign-battle.png")
 print("REDESIGN_TEST ",failures)
 game.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)

