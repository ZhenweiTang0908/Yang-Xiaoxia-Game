extends SceneTree
const OUT="res://builds/qa/boss-reset/"
var game
func _initialize():root.unfocusable=true;call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new();root.size=Vector2i(960,540)
 for stage in [1,2,3]:
  game.jump_to_stage(stage);await process_frame
  game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
  game.stage_banner=-10;game.subtitle_time=0;game.hint_time=0;game.player.position=Vector2(180,450)
  var b=game.boss;b.active_battle=true;b.position=Vector2(660,450);b.facing=-1;b.art.pose("idle",0)
  var tex=load("res://assets/art/boss_frames/%02d.png"%((stage-1)*6))
  if tex==null:quit(1);return
  var bounds=tex.get_image().get_used_rect();var old=Sprite2D.new();old.texture=tex;old.centered=false;old.offset=Vector2(-bounds.get_center().x,-bounds.end.y);old.scale=Vector2.ONE*b.body_height/bounds.size.y;old.position=Vector2(380,450);game.world.add_child(old)
  for entry in [["改动前",Vector2(350,302)],["本次重制",Vector2(625,302)]]:
   var label=Label.new();label.text=entry[0];label.position=entry[1];label.add_theme_font_override("font",game.font);label.add_theme_font_size_override("font_size",16);game.world.add_child(label)
  await process_frame;await process_frame;RenderingServer.force_draw(false)
  var im=root.get_texture().get_image()
  if im==null or im.is_empty():quit(1);return
  im.save_png(OUT+"comparison-"+str(stage)+".png")
  if stage==3:
   for i in 8:
    b.art.pose("turn",float(i)/8);await process_frame;b.art.advance(.1);await process_frame;RenderingServer.force_draw(false)
    root.get_texture().get_image().save_png(OUT+"priest-turn-%02d.png"%i)
 game.audio.stop_all();game.queue_free();await process_frame;print("BOSS_RESET_COMPARE_RESULT frames=3");quit()
