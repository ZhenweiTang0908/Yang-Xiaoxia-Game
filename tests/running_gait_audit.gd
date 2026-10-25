extends SceneTree
func _initialize():call_deferred("run")
func run():
 var atlas=load("res://scripts/actors/atlas_actor.gd").new();atlas.configure("res://assets/art/v2/hero.png",8,5,52.8)
 var rig=load("res://tests/hero_running_gait.gd").new();root.add_child(rig);rig.set_process(false);rig.game_scale=atlas.scale_unit
 var previous=[null,null];var drift=0.0;var ground_error=0.0;var inverted=0;var airborne=0;var elbow_error=0.0
 for i in 120:
  rig.age=i/120.0;var transforms=rig.pose_transforms();var phase=fposmod(rig.age/rig.cycle,1.0);var contacts=0
  for pair in [[9,7,Vector2(64,125)],[10,8,Vector2(124,127)]]:
   elbow_error=maxf(elbow_error,(transforms[pair[0]]*pair[2]).distance_to(transforms[pair[1]]*pair[2]))
  for leg in 2:
   var t=fposmod(phase+leg*.5,1.0)
   if t>=rig.support_fraction:previous[leg]=null;continue
   contacts+=1
   var foot=transforms[5+leg]*rig.joints[5+leg]
   var world=foot.x*rig.game_scale+225*rig.age
   if previous[leg]!=null:drift=maxf(drift,absf(world-previous[leg]))
   previous[leg]=world
   ground_error=maxf(ground_error,absf(foot.y+rig.soles[leg]-199))
  if contacts==0:airborne+=1
  rig.update_shorts(transforms)
  for index in [1,3]:
   var arrays=rig.parts[index].surface_get_arrays(0);var vertices=arrays[Mesh.ARRAY_VERTEX];var indices=arrays[Mesh.ARRAY_INDEX]
   for k in range(0,indices.size(),3):
    var a=vertices[indices[k]];var b=vertices[indices[k+1]];var c=vertices[indices[k+2]]
    if Vector2(b.x-a.x,b.y-a.y).cross(Vector2(c.x-a.x,c.y-a.y))<=0:inverted+=1
 print("RUNNING_AUDIT scale=",rig.game_scale," support_fraction=",rig.support_fraction," drift=",drift," ground_error=",ground_error," airborne_samples=",airborne," inverted_triangles=",inverted," elbow_error=",elbow_error)
 rig.queue_free();atlas.free();await process_frame;quit()
