extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(label):
 game.state="playing";game.hud.canvas.queue_redraw()
 for i in 4:
  game.state="playing";await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/combat-hud-"+label+".png")
func run():
 root.unfocusable=true;root.size=Vector2i(960,540);root.content_scale_size=root.size;root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
 DirAccess.make_dir_recursive_absolute("res://builds/qa")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_challenge(4,2)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 game.stage_banner=-100;game.hint_time=0;game.subtitle_time=0;game.player.position=Vector2(380,450);game.boss.position=Vector2(640,450);game.boss.active_battle=true
 game.camera.position=Vector2(480,270);game.camera.reset_smoothing()
 game.player.health=72;game.player.rage=50;game.challenge_tonic=2;game.hud.player_lag=.72;game.boss.hp=game.boss.max_hp*.63;game.hud.boss_lag=.78
 await shot("desktop")
 game.player.health=18;game.player.rage=100;game.challenge_tonic=0;game.hud.player_lag=.36
 await shot("danger")
 game.is_touch=true;game.player.health=63;game.player.rage=80;game.challenge_tonic=1
 await shot("touch")
 game.is_touch=false;game.summon.reset(true);game.summon.request()
 var ally=game.summon.brother;ally.set_physics_process(false);game.summon._physics_process(1.2);ally.demon_controller.carry_age=1;game.player._process(0)
 await shot("ally")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("COMBAT_HUD_CAPTURE_RESULT frames=4");quit()
