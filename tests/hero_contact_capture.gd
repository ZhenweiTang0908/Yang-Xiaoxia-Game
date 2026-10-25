extends SceneTree
class Ground:
 extends Node2D
 var offset=0.0
 func _draw():
  draw_rect(Rect2(650,558,550,42),Color("243941"))
  draw_line(Vector2(650,558),Vector2(1200,558),Color("6b817f"),1)
  for i in 11:
   var x=650+i*64-fposmod(offset,64)
   if x>=650 and x<1200:draw_line(Vector2(x,560),Vector2(x,572),Color("59716f"),2)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1200,600);root.content_scale_size=Vector2i(1200,600)
 var background=ColorRect.new();background.color=Color("18262c");background.size=Vector2(1200,600);root.add_child(background)
 var ground=Ground.new();root.add_child(ground)
 var original=Sprite2D.new();original.texture=load("res://assets/art/hero_2d/hero/00.png");original.centered=false;original.position=Vector2(70,80);original.scale=Vector2.ONE*2.4;root.add_child(original)
 var rig=load("res://tests/hero_running_gait.gd").new();rig.position=Vector2(650,80);rig.scale=Vector2.ONE*2.4;root.add_child(rig)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/contact-rest.png")
 rig.contact_enabled=true;rig.posing=true;rig.age=.16;rig.set_process(false);rig.travel_x+=225*rig.motion_amount/60.0;rig.queue_redraw()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/contact-bend.png")
 DirAccess.make_dir_recursive_absolute("res://builds/qa/contact-frames")
 rig.planted=[null,null];rig.travel_x=0
 var timeline=load("res://tests/locomotion_timeline.gd").new(rig)
 for i in 180:
  timeline.advance_to(i/60.0)
  ground.offset=rig.travel_x/rig.game_scale*2.4;ground.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/contact-frames/%04d.png"%i)
 quit()
