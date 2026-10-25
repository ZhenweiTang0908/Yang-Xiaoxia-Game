extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(name):
 game.hud.canvas.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/bull-default-"+name+".png")
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();await shot("title")
 game.start_challenge(4,2);await process_frame;game.world.visible=true;game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 game.player.position=Vector2(450,450);game.summon.request();var b=game.summon.brother;b.set_physics_process(false)
 game.summon._physics_process(.55);b._physics_process(.01);await shot("entering")
 game.summon._physics_process(.65);b._physics_process(.5);game.player._process(0);await shot("mounted")
 game.summon.begin_leaving();game.summon._physics_process(.8);await shot("cooldown")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
