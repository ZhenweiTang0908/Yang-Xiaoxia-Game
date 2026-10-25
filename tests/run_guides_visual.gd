extends SceneTree
class Sheet extends Node2D:
 var pictures=[]
 func _ready():
  for frame in range(10,16):pictures.append(load("res://assets/art/hero_2d/hero/%02d.png"%frame))
 func _draw():
  var font=ThemeDB.fallback_font
  var guides=load("res://scripts/animation/hero_2d_pose.gd")
  draw_rect(Rect2(0,0,1500,900),Color("18252b"))
  for index in 6:
   var frame=index+10;var at=Vector2(30+index%3*480,45+index/3*410)
   draw_set_transform(at,0,Vector2.ONE*2)
   draw_texture(pictures[index],Vector2.ZERO)
   for i in 6:
    var p=guides.guides(frame)[i];var q=Vector2(p[0]+28,p[1])
    draw_circle(q,2,Color.YELLOW)
    draw_string(font,q+Vector2(3,-3),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.YELLOW)
   draw_set_transform(Vector2.ZERO)
   draw_string(font,at-Vector2(0,10),str(frame),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1500,900);root.content_scale_size=Vector2i(1500,900);root.add_child(Sheet.new())
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/run-guides.png");quit()
