extends SceneTree
func _initialize():call_deferred("run")
func run():
 var art=load("res://scripts/actors/atlas_actor.gd").new();root.add_child(art);art.configure("res://assets/art/v3/niu_human.png",6,4,88)
 var rig=load("res://scripts/animation/brother_visual.gd").new();rig.preview=true;rig.source_art=art;root.add_child(rig);rig.set_process(false)
 var frames=[]
 for f in 24:
  rig.rebuild(f);var points=[];var uv=[];var pivots=[]
  for p in rig.rest:points.append([p.x,-p.y,0])
  for p in rig.uv:uv.append([p.x,1-p.y])
  for p in rig.pivots:pivots.append([p.x,-p.y,0])
  frames.append({"vertices":points,"uv":uv,"indices":Array(rig.triangles),"weights":rig.weights,"pivots":pivots})
 FileAccess.open("res://art_source/brother_mesh_source.json",FileAccess.WRITE).store_string(JSON.stringify(frames))
 rig.queue_free();art.queue_free();await process_frame;quit()
