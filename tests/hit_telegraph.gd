extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 game.player.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 var failed=false
 for actor in [game.enemies[0],game.boss]:
  if actor.kind=="boss":actor.active_battle=true
  game.player.position=actor.position+Vector2(160,0)
  for state in ["windup","strike","hurt"]:
   actor.windup=.5 if state=="windup" else 0.0
   actor.strike=.3 if state=="strike" else 0.0
   actor.hurt=.1;actor.cooldown=99
   actor._physics_process(1.0/60)
   var expected=2 if state=="windup" else (3 if state=="strike" else 4)
   var ok=actor.art.frame%6==expected
   print("HIT_TELEGRAPH kind=",actor.kind," state=",state," preserved=",ok)
   failed=failed or not ok
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.1).timeout;quit(1 if failed else 0)
