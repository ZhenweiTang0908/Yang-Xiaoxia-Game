extends SceneTree
var game
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failures+=1;push_error(label)
 else:print("PASS ",label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false)
 var p=game.player;var effect=game.terrain.presence
 p.position=Vector2(2200,450);p.velocity=Vector2.ZERO
 for i in 5:await physics_frame
 check(not effect.shadows.is_empty(),"contact shadow finds collision surface")
 effect.splashes.clear() # Exclude the real player's initial landing from this event check.
 effect.step(p.position,true);check(effect.ripples.size()>0,"shallow puddle creates ripple")
 check(effect.splashes.size()==3,"wet landing creates three small droplets")
 var water_count=effect.splashes.size();effect.step(p.position)
 check(effect.splashes.size()==water_count,"ordinary wet step keeps only a ripple")
 for i in 12:effect.step(p.position,true)
 check(effect.splashes.size()==12,"water droplet cap is respected")
 effect.step(Vector2(200,450),true);check(effect.dust.size()==2,"dry landing emits two restrained dust puffs")
 var count=effect.dust.size();effect.step(Vector2(2200,350),true)
 check(effect.dust.size()==count,"no dust at unsupported airborne position")
 effect.step(Vector2(2384,322),true)
 check(effect.dust.size()==count+2 and absf(effect.dust.back().p.y-324)<.1,"raised platform dust snaps to collision surface")
 for i in 20:effect.step(Vector2(200,450),true)
 check(effect.dust.size()==18,"dust cap is respected exactly")
 var age=effect.dust[0].age;game.state="paused"
 var splash_age=effect.splashes[0].age
 for i in 10:await physics_frame
 check(effect.dust[0].age==age,"pause freezes ground effects")
 check(effect.splashes[0].age==splash_age,"pause freezes water droplets")
 game.state="playing";p.position=Vector2(2200,360);p.velocity=Vector2.ZERO
 await physics_frame;await physics_frame
 check(effect.shadows.any(func(s):return absf(s.p.y-450.8)<1 and s.alpha<.2),"airborne shadow remains on floor and fades")
 p.set_physics_process(false) # Do not generate a new landing during the expiry check.
 for i in 35:await physics_frame
 check(effect.splashes.is_empty(),"water droplets return to surface and expire")
 game.load_stage(3,0);await physics_frame
 check(not game.terrain.presence.wet_at(Vector2(2200,450)),"altar keeps dry stone surface")
 game.audio.stop_all();game.queue_free();await process_frame;print("GROUND_PRESENCE failures=",failures);quit(failures)
