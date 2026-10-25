extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 var combat=game.combat;combat.set_physics_process(false);combat.clear()
 var h=combat.hazard(Rect2(600,200,20,250),0,.01,0,987,"rain");h.age=.2
 combat._physics_process(.02)
 var ok=combat.hazards.is_empty() and combat.remnants.size()==1
 if not combat.remnants.is_empty():ok=ok and combat.remnants[0].rect.end.y==450
 print("RAIN_FINISH harmless_remnant=",ok)
 combat._physics_process(.21);ok=ok and combat.remnants.is_empty()
 print("RAIN_FINISH expired=",combat.remnants.is_empty())
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.1).timeout;quit(0 if ok else 1)
