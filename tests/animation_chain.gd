extends SceneTree
var game
var failed=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func frames(n):
 for i in n:await physics_frame
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.dead=true;enemy.set_physics_process(false)
 await frames(3)
 var p=game.player;p.enqueue("attack");await frames(3);p.enqueue("attack");await frames(15)
 check(p.combo==2,"queued second slash begins during recovery of first")
 p.enqueue("attack");await frames(19)
 check(p.combo==3,"queued third slash chains without idle gap")
 await frames(34);check(p.attack_elapsed<0,"last slash fully recovers")
 var M=load("res://scripts/animation/hero_motion.gd")
 check(M.sample("jump",.02).near_thigh.distance_to(M.sample("jump",.18).near_thigh)>.1,"jump legs evolve through ascent")
 check(M.sample("fall",.02).near_shin.distance_to(M.sample("fall",.25).near_shin)>.1,"fall extends legs before landing")
 check(M.sample("land",.035).offset.y<M.sample("land",0).offset.y-.05,"landing compresses before recovering")
 game.queue_free();await process_frame;quit(failed)
