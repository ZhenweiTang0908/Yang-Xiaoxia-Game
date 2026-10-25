extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1440,810);root.content_scale_size=Vector2i(1440,810)
 var bg=ColorRect.new();bg.color=Color("26343b");bg.size=Vector2(1440,810);root.add_child(bg)
 for i in 18:
  var art=load("res://scripts/actors/boss_art.gd").new();root.add_child(art);art.configure("res://assets/art/v2/bosses.png",6,3,130)
  art.scale_unit=130.0/art.bounds[(i/6)*6].size.y;art.frame=i;art.position=Vector2(120+(i%6)*235,230+(i/6)*260)
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/boss-clean-sheet.png");quit()
