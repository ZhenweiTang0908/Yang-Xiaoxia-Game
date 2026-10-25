extends SceneTree
var errors=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:errors.append(label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 game.player.health=100;game.progress.gourd=true;game.summon.reset(true);game.summon.request()
 for i in 85:await physics_frame
 var brother=game.summon.brother;brother.set_physics_process(false);game.combat.set_physics_process(false)
 var target=game.enemies[0];target.dead=false;game.player.current_target=target
 target.dead=true;brother.pending_skill="";brother.attack_anim=0
 brother.position=Vector2(100,450);brother.velocity=Vector2.ZERO
 game.player.position=Vector2(430,450)
 game.terrain.presence.dust.clear()
 brother.stride_frame=0
 var distance=0.0
 for i in 25:
  var before=brother.position.x
  brother._physics_process(1.0/60)
  if brother.is_on_floor():distance+=absf(brother.position.x-before)
 var expected=fposmod(distance/(200.0/11.0),6)
 check(absf(brother.stride_frame-expected)<.0001 and distance>20,"gait follows actual accelerated movement")
 check(game.terrain.presence.dust.size()==2,"one grounded half-stride creates two small dust puffs")
 game.terrain.presence.dust.clear()
 brother.position=Vector2(200,350);brother.velocity=Vector2(0,-100)
 brother._physics_process(1.0/60)
 check(not brother.is_on_floor() and game.terrain.presence.dust.is_empty(),"airborne travel emits no steps")
 brother.position=Vector2(200,449);brother.velocity=Vector2(200,100);brother.stride_frame=2.99
 brother._physics_process(1.0/60)
 check(brother.is_on_floor() and game.terrain.presence.dust.is_empty(),"landing does not duplicate the shared landing puff")
 brother.attack_anim=.4;brother.stride_frame=2.99
 brother._physics_process(1.0/60)
 check(game.terrain.presence.dust.is_empty(),"throwing pose does not emit a walking contact")
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame
 print("BROTHER_STRIDE failures=",errors)
 quit(0 if errors.is_empty() else 1)
