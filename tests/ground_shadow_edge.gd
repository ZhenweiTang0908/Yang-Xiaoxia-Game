extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 var player=game.player;player.set_physics_process(false);player.velocity=Vector2.ZERO
 var presence=game.terrain.presence;presence.set_physics_process(false)
 player.position=Vector2(12853,370)
 await physics_frame
 presence._physics_process(1.0/60)
 var edge=presence.shadows[0]
 check(edge.p.x-edge.w>=12849.8,"ledge shadow stays on the platform")
 check(edge.w<9 and edge.p.x>player.position.x,"ledge shadow narrows toward supported ground")
 player.position=Vector2(12940,370)
 presence._physics_process(1.0/60)
 var center=presence.shadows[0]
 check(absf(center.w-10)<.01 and absf(center.p.x-player.position.x)<.01,"open platform keeps the full centered shadow")
 player.position=Vector2(12853,370);presence._physics_process(1.0/60)
 game.camera.position=Vector2(12853,270);game.hint_time=0;game.subtitle_time=0
 if DisplayServer.get_name()!="headless":
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/ground-shadow-edge.png")
 game.audio.stop_all();game.queue_free();await process_frame
 print("GROUND_SHADOW_EDGE failures=",failures)
 quit(0 if failures.is_empty() else 1)
