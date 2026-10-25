extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 game.player.set_physics_process(false);game.player.position=Vector2(600,450)
 for e in game.enemies:e.set_physics_process(false)
 var actor=game.enemies[0];var failed=false
 for slow in [0.0,10.0]:
  actor.position=Vector2(200,450);actor.velocity=Vector2.ZERO;actor.gait_phase=0;actor.cooldown=99;actor.slow=slow;actor.strike=0;actor.windup=0
  await physics_frame
  var distance=0.0
  for i in 20:
   await physics_frame
   var before=actor.position.x
   actor._physics_process(1.0/60)
   distance+=absf(actor.position.x-before)
  var error=absf(actor.gait_phase-fposmod(distance/30.0,1.0))
  print("GAIT_DISTANCE slow=",slow," distance=",distance," phase_error=",error)
  failed=failed or error>.001 or distance<=0
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.1).timeout
 quit(1 if failed else 0)
