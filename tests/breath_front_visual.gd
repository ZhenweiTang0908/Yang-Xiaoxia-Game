extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.jump_to_stage(3,2)
 game.set_process(false);game.combat.set_physics_process(false)
 for enemy in game.enemies:
  enemy.set_physics_process(false)
  if enemy!=game.boss:enemy.hide()
 var boss=game.boss;boss.set_physics_process(false);boss.position=Vector2(14900,450);boss.facing=-1;boss.active_battle=true
 game.player.set_physics_process(false);game.player.position=Vector2(14530,450);game.player.invincible=0
 game.camera.position=Vector2(14770,315);game.hint_time=0
 for face in [-1.0,1.0]:
  game.combat.clear();boss.facing=face;boss.start_move(6);boss.windup=0;boss.release_move()
  boss.show();boss.art.facing=-boss.facing;boss.art.frame=15
  var h=game.combat.hazards.back()
  for i in 4:
   h.age=[.025,.065,.20,.79][i];h.duration=h.total-h.age
   game.combat.visual_clock=h.age;game.combat.queue_redraw()
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://builds/qa/breath-front-%s-%d.png"%["left" if face<0 else "right",i])
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame;quit()
