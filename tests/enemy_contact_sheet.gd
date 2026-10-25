extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1000,1200);root.content_scale_size=Vector2i(1000,1200)
 var bg=ColorRect.new();bg.color=Color("1b2b34");bg.size=Vector2(1000,1200);root.add_child(bg)
 var names=["Stone imp","Wisp","Stone guard","Pouncer","Night bat","Dart thrower","Shield guard","Rune caller"]
 for row in 8:
  var label=Label.new();label.text=names[row];label.position=Vector2(12,row*150+8);root.add_child(label)
  for col in 4:
   var art=load("res://scripts/actors/enemy_art.gd").new();root.add_child(art);art.configure("res://assets/art/v2/mobs.png",6,8,75)
   art.scale_unit=75.0/art.bounds[row*6].size.y;art.body_height=75
   art.frame=row*6+[0,2,3,4][col];art.position=Vector2(160+col*230,row*150+138)
   art.lean=[0,.04,-.045,.025][col];art.sink=[0,1.2,.35,.3][col]
 await create_timer(.2).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/enemy-pose-sheet.png");quit()
