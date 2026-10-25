extends SceneTree
func _initialize():call_deferred("run")
func surface(parent,rect,one_way):
 var body=StaticBody2D.new();body.position=rect.position;parent.add_child(body)
 var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=rect.size;shape.shape=box;shape.position=rect.size*.5;shape.one_way_collision=one_way;body.add_child(shape)
 var art=Polygon2D.new();art.polygon=PackedVector2Array([Vector2.ZERO,Vector2(rect.size.x,0),rect.size,Vector2(0,rect.size.y)]);art.color=Color("516a68");body.add_child(art)
func run():
 root.size=Vector2i(960,540);root.content_scale_size=root.size
 Engine.max_fps=60
 # Offline capture: prevent image encoding stalls from skipping simulation frames.
 Engine.max_physics_steps_per_frame=1
 var world=Node2D.new();root.add_child(world)
 var bg=Polygon2D.new();bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(960,0),Vector2(960,540),Vector2(0,540)]);bg.color=Color("18262c");world.add_child(bg)
 surface(world,Rect2(0,450,960,90),false)
 surface(world,Rect2(300,355,220,12),true)
 var actor=load("res://tests/platform_motion_actor.gd").new();actor.position=Vector2(80,450);world.add_child(actor)
 DirAccess.make_dir_recursive_absolute("res://builds/qa/platform-motion")
 for i in 210:
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/platform-motion/%04d.png"%i)
 print("PLATFORM_MOTION landed=",actor.landed_count," reached_platform=",actor.reached_platform," air_ticks=",actor.airborne_ticks," air_locks=",actor.airborne_locks," foot_releases=",actor.rig.released_unreachable)
 quit(0 if actor.reached_platform and actor.airborne_locks==0 else 1)
