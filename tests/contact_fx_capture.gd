extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,540);root.content_scale_size=root.size;Engine.max_fps=60;Engine.max_physics_steps_per_frame=1
 var lab=load("res://tests/interactive_motion_lab.gd").new();root.add_child(lab)
 await physics_frame;Input.action_press("right")
 var last=0;var air_checked=false;var errors=0
 for i in 155:
  if i==40:Input.action_press("jump")
  if i==80:Input.action_release("jump")
  if i==140:Input.action_release("right")
  await physics_frame;await RenderingServer.frame_post_draw
  var fx=lab.actor.contact_fx
  if not air_checked and not lab.actor.is_on_floor() and lab.actor.velocity.y< -100:
   var count=fx.landing_emissions;fx.landed(500)
   if fx.landing_emissions!=count:errors+=1
   air_checked=true
  if fx.landing_emissions>last:
   last=fx.landing_emissions
   root.get_texture().get_image().save_png("res://builds/qa/contact-landing-%d.png"%last)
 print("CONTACT_FX landings=",last," air_checked=",air_checked," errors=",errors)
 lab.actor.stop_sounds()
 await create_timer(.1).timeout
 lab.queue_free();await process_frame
 quit(0 if last>=2 and air_checked and errors==0 else 1)
