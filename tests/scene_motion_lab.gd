extends SceneTree
class MockGame extends Node:
 var player=null
 var hitstop=0.0
 func active():return true
class Walker extends Node2D:
 var row=0.0
 var age=0.0
 func _physics_process(dt):
  age+=dt;position=Vector2(90+age*130,row)
func _initialize():call_deferred("run")
func run():
 set_physics_interpolation_enabled(false);Engine.physics_ticks_per_second=10
 var mock=MockGame.new();root.add_child(mock)
 var smoother=load("res://scripts/animation/scene_motion.gd").new();smoother.game=mock;root.add_child(smoother)
 var bg=ColorRect.new();bg.size=Vector2(960,540);bg.color=Color("11212b");root.add_child(bg)
 var walkers=[]
 for i in 2:
  var label=Label.new();label.text="10 TPS / direct position" if i==0 else "10 TPS / rendered interpolation";label.position=Vector2(50,40+i*240);root.add_child(label)
  var walker=Walker.new();walker.row=200+i*240;walker.position=Vector2(90,walker.row)
  walker.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF if i==0 else Node.PHYSICS_INTERPOLATION_MODE_ON
  root.add_child(walker);walker.reset_physics_interpolation();walkers.append(walker)
  if i==1:smoother.register(walker)
  var hero=load("res://scripts/animation/hero_visual.gd").new();hero.preview=true;hero.preview_state="run";hero.scale=Vector2.ONE*2;walker.add_child(hero)
  var marker=ColorRect.new();marker.position=Vector2(-2,8);marker.size=Vector2(4,4);marker.color=Color.RED if i==0 else Color.GREEN;walker.add_child(marker)
 DirAccess.make_dir_recursive_absolute("res://builds/qa/scene-motion/frames")
 var samples=[[],[]]
 for frame in 180:
  await RenderingServer.frame_post_draw
  var picture=root.get_texture().get_image()
  picture.save_png("res://builds/qa/scene-motion/frames/%04d.png"%frame)
  var sx=float(picture.get_width())/960;var sy=float(picture.get_height())/540
  for i in 2:
   var row=int((210+i*240)*sy);var sum=0.0;var count=0
   for x in picture.get_width():
    var c=picture.get_pixel(x,row)
    if (c.r>.9 and c.g<.1 and c.b<.1) if i==0 else (c.g>.9 and c.r<.1 and c.b<.1):sum+=x;count+=1
   if count>0:samples[i].append(sum/count/sx)
 var summary={}
 for i in 2:
  var held=0;var maximum=0.0
  for j in range(1,samples[i].size()):
   var delta=absf(samples[i][j]-samples[i][j-1]);maximum=maxf(maximum,delta)
   if delta<.1:held+=1
  summary["direct" if i==0 else "interpolated"]={"frames":samples[i].size(),"held_frames":held,"maximum_step":maximum}
 var out=FileAccess.open("res://builds/qa/scene-motion/result.json",FileAccess.WRITE);out.store_string(JSON.stringify(summary," "));out.close()
 print("SCENE_MOTION_LAB ",JSON.stringify(summary));quit()
