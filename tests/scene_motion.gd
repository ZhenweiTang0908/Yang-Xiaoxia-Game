extends SceneTree
var failed=0
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 var motion=game.scene_motion;motion.set_process(false);motion.set_physics_process(false)
 var p=game.player;p.set_physics_process(false)
 motion.reset(p);p.position.x+=12;motion._physics_process(1.0/60)
 game.state="paused";motion.held_fraction=.5
 var logical=p.position;motion._process(0)
 check(p.position==logical,"display interpolation never changes logical position")
 check(absf(motion.offset(p).x+6)<.001,"half step display is midway between physics positions")
 var offset=motion.offset(p);motion._process(.3)
 check(motion.offset(p)==offset,"paused interpolation is frozen")
 p.position.x+=40;motion.reset(p)
 check(motion.offset(p)==Vector2.ZERO,"short teleport reset prevents streaking")
 p.position.x+=300
 check(motion.offset(p)==Vector2.ZERO,"large unexpected teleport skips interpolation")
 game.state="playing";game.summon.reset(true);game.summon.request()
 var ally=game.summon.brother;ally.set_physics_process(false);p.attach_to(ally)
 motion.reset(ally);ally.position.x+=14;motion._physics_process(1.0/60)
 game.state="paused";motion.held_fraction=.4
 check(motion.offset(p)==motion.offset(ally),"rider and mount share the same displayed root offset")
 p.detach_from(Vector2(100,450));check(motion.offset(p)==Vector2.ZERO,"dismount resets previous position")
 game.load_stage(2,0)
 check(motion.tracks.size()==game.enemies.size()+1+3,"stage reload only keeps current actors and mechanisms")
 game.audio.stop_all();game.queue_free();await process_frame
 print("SCENE_MOTION failures=",failed);quit(failed)
