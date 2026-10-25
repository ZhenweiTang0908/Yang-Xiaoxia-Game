extends SceneTree
func _initialize():call_deferred("run")
func shot(name):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/hero-sword-"+name+".png")
func run():
 root.size=Vector2i(1280,720);root.content_scale_size=root.size
 var canvas=Node2D.new();root.add_child(canvas)
 var background=ColorRect.new();background.color=Color("1b2930");background.size=Vector2(1280,720);canvas.add_child(background)
 for index in 3:
  var move=load("res://scripts/animation/hero_motion.gd").ATTACKS[index]
  var times=[0.0,move.hit*.55,move.hit-.03,move.hit,move.hit+.045,move.duration*.78,move.duration]
  for j in times.size():
   var rig=load("res://scripts/animation/painted_rig/combo.gd").new();canvas.add_child(rig);rig.set_process(false);rig.posing=true;rig.grounded_override=true;rig.contact_enabled=false;rig.scale=Vector2.ONE*.64
   var anchor=Vector2(105+j*180,210+index*220);rig.position=anchor-Vector2(96,199)*.64;rig.sample_attack(index,times[j],0)
   var label=Label.new();label.text=str(index+1)+" / "+str(snappedf(times[j],.001))+"s";label.position=anchor+Vector2(-35,12);canvas.add_child(label)
 await shot("sequence");canvas.queue_free();await process_frame
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 var p=game.player;p.position=Vector2(400,450);p.invincible=0;p.hurt_anim=0;p.combo=1;p.attack_elapsed=.15;p.attack_duration=.38
 game.camera.position=Vector2(400,410);game.camera.zoom=Vector2(2,2);game.camera.reset_smoothing();game.hint_time=0
 game.set_hero_animation(true);await shot("modern")
 game.set_hero_animation(false);await shot("legacy")
 game.state="settings";await shot("settings")
 game.state="paused";await shot("pause")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
