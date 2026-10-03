extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 await process_frame
 await create_timer(1.0).timeout
 root.get_texture().get_image().save_png("C:/Users/lenov/Documents/Codex/2026-09-28/c-users-lenov-onedrive-desktop-workspace/work/new-assets/cinematic-village-clean.png")
 quit()
