extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(name):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/mixed-"+name+".png")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.load_stage(3,2)
 game.player.position=Vector2(14710,450);game.player.health=29;game.player.invincible=999
 for e in game.enemies:e.set_physics_process(false);e.dead=true;e.visible=false
 var boss=game.boss;boss.dead=false;boss.visible=true;boss.active_battle=true;boss.hp=10000;boss.cooldown=100;boss.set_physics_process(true);boss.position=Vector2(14910,450)
 game.camera.position=Vector2(14800,270)
 game.summon.reset(true);game.summon.request()
 await create_timer(1.4).timeout
 var ally=game.summon.brother;ally.become_demon()
 await create_timer(1.1).timeout
 boss.start_move(6)
 await create_timer(.25).timeout
 await capture("carry-warning")
 await create_timer(1.05).timeout
 await capture("carry-fire")
 await create_timer(6.0).timeout
 ally.demon_controller.begin_lock(boss)
 await create_timer(.2).timeout
 await capture("lock")
 await create_timer(.8).timeout
 await capture("rush")
 game.combat.clear();game.fx.clear();game.summon.reset(true)
 await create_timer(.4).timeout
 print("MIXED_CLEANUP shots=",game.combat.shots.size()," folds=",game.fx.folds.size()," contacts=",game.fx.melee_contacts.size()," carried=",game.player.is_carried())
 await capture("cleared")
 game.load_stage(2,2)
 game.player.position=Vector2(14700,450);game.player.health=100;game.player.invincible=999
 for e in game.enemies:e.set_physics_process(false);e.dead=true;e.visible=false
 boss=game.boss;boss.dead=false;boss.visible=true;boss.active_battle=true;boss.hp=10000;boss.position=Vector2(15050,450);boss.facing=-1;boss.cooldown=100;boss.set_physics_process(true)
 game.summon.reset(true);game.summon.request()
 await create_timer(1.4).timeout
 ally=game.summon.brother;ally.position=Vector2(14750,450);ally.facing=1
 game.combat.clear();boss.start_move(4);boss.release_move();boss.windup=0;ally.release_fan(boss)
 await create_timer(.24).timeout
 var friendly=0;var hostile=0
 for shot in game.combat.shots:
  if shot.faction=="brother":friendly+=1
  elif shot.faction=="enemy":hostile+=1
 print("MIXED_PROJECTILES friendly=",friendly," hostile=",hostile)
 await capture("cards-blades")
 game.audio.stop_all();game.queue_free();await process_frame;quit()
