extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(name):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/yang-demon-"+name+".png")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.tuning.reset();game.start_new(false)
 game.player.position=Vector2(530,450);game.player.health=29
 for e in game.enemies:e.set_physics_process(false);e.visible=false;e.dead=true
 game.summon.reset(true);game.summon.request()
 await create_timer(1.35).timeout
 await capture("normal")
 var b=game.summon.brother;b.become_demon()
 await create_timer(1.3).timeout
 await capture("carry")
 game.player.sheep_time=10;game.player.set_form_art(true)
 await create_timer(.25).timeout
 await capture("sheep-rider")
 game.player.sheep_time=0;game.player.set_form_art(false)
 await create_timer(6.7).timeout
 var e=game.enemies[0];e.dead=false;e.visible=true;e.hp=10000;e.position=Vector2(740,450);e.offscreen=false
 b.demon_controller.begin_lock(e)
 await create_timer(.2).timeout
 await capture("lock")
 await create_timer(.8).timeout
 await capture("strike")
 game.debug_panel.toggle()
 await create_timer(.2).timeout
 await capture("debug")
 game.audio.stop_all();await create_timer(.1).timeout
 quit()
