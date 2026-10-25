extends SceneTree
var failed=0
func check(ok,label):
 if ok:print("PASS ",label)
 else:failed+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.load_stage(2,0)
 var presence=game.terrain.presence;presence.set_physics_process(false)
 check(presence.wet_at(Vector2(2200,450)),"ferry stage puddle is a wet contact surface")
 check(not presence.wet_at(Vector2(2200,430)),"water response stays on the walking surface")
 presence.ripple(Vector2(2200,450),.55,1,"step")
 presence.ripple(Vector2(2210,450),1,-1,"landing")
 presence.ripple(Vector2(2220,455),.4,1,"wake")
 check(presence.ripples.size()==3,"step landing and ferry wake remain distinct events")
 check(presence.ripples[0].direction==1.0 and presence.ripples[1].direction==-1.0,"water arcs retain travel direction")
 check(presence.ripples[2].kind=="wake" and presence.ripples[2].strength<.5,"ferry wake is restrained")
 for i in 20:presence.ripple(Vector2(2300+i,450))
 check(presence.ripples.size()==14,"water effect count is capped")
 game.audio.stop_all();game.queue_free();await process_frame
 print("WATER_CONTACT failures=",failed);quit(failed)
