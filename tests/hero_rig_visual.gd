extends SceneTree
var scene
func _initialize():call_deferred("run")
func run():
 var layer=Node2D.new();root.add_child(layer)
 var background=ColorRect.new();background.color=Color("263c4b");background.size=Vector2(1200,720);layer.add_child(background)
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;rig.preview_state="idle";rig.position=Vector2(480,450);rig.scale=Vector2.ONE*4;layer.add_child(rig)
 await create_timer(.7).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/yang-rig-idle.png")
 rig.preview_state="run";await create_timer(.8).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/yang-rig-run.png")
 rig.preview_state="slash1";rig.preview_time=.15;await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/yang-rig-slash.png")
 layer.queue_free();await process_frame;quit()
