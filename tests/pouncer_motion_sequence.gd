extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1050,250);root.content_scale_size=Vector2i(1050,250)
 var bg=ColorRect.new();bg.color=Color("172833");bg.size=Vector2(1050,250);root.add_child(bg)
 var title=Label.new();title.text="扑击山魈：蓄势 → 单网格扑出（无叠图）";title.position=Vector2(22,16);root.add_child(title)
 for index in 7:
  var art=load("res://scripts/actors/enemy_art.gd").new();root.add_child(art)
  art.configure("res://assets/art/v2/mobs.png",6,8,75);art.scale_unit=75.0/art.bounds[18].size.y;art.body_height=75
  art.frame=20;art.update_pose_mesh();art.frame=21;art.update_pose_mesh()
  var progress=float(index)/6.0;art.bridge_left=art.bridge_duration*(1-progress)
  art.position=Vector2(95+index*145,205);art.queue_redraw()
  var label=Label.new();label.text="%d%%"%roundi(progress*100);label.position=Vector2(72+index*145,218);root.add_child(label)
 await process_frame;await process_frame
 root.get_texture().get_image().save_png("res://builds/qa/pouncer-motion-sequence.png");quit()
