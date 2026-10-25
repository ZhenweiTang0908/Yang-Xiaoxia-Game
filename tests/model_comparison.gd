extends SceneTree
func _initialize():call_deferred("run")
func run():
 await process_frame
 root.size=Vector2i(960,540);root.content_scale_size=Vector2i(960,540)
 var background=ColorRect.new();background.color=Color("182a36");background.size=Vector2(960,540);root.add_child(background)
 var font=load("res://assets/art/ui_font.ttf")
 for row in [[Vector2(100,40),"之前"],[Vector2(575,40),"调整后 · 羊小侠"]]:
  var label=Label.new();label.position=row[0];label.text=row[1];label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",24);root.add_child(label)
 var rigs=[]
 for i in 2:
  var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;rig.position=Vector2(240+i*470,390);rig.scale=Vector2.ONE*4;root.add_child(rig)
  if i==0:
   var holder=rig.model.get_parent();rig.model.queue_free();rig.model=load("res://builds/qa/model/hero_model_before.gd").new();holder.add_child(rig.model)
  rigs.append(rig)
 await create_timer(.4).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/model/comparison-idle.png")
 for rig in rigs:rig.preview_state="slash1";rig.preview_time=.15
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/model/comparison-slash.png")
 quit()
