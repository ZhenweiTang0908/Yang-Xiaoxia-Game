extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false)
 var source=rig.body_source[Mesh.ARRAY_VERTEX];var indices=rig.body_source[Mesh.ARRAY_INDEX]
 var protected_error=0.0;var max_move=0.0;var inverted=0;var changed=0
 for offset in [Vector2(1.2,0),Vector2(-1.2,0),Vector2(0,1.2),Vector2(0,-1.2)]:
  rig.secondary.cloth=offset;rig.secondary.hair=offset.normalized()*.3
  var moved=PackedVector2Array()
  for vertex in source:
   var p=Vector2(vertex.x,vertex.y);var q=rig.secondary.deform(p);moved.append(q)
   var displacement=p.distance_to(q);max_move=maxf(max_move,displacement)
   if p.y>=38 and p.y<=118:protected_error=maxf(protected_error,displacement)
   if displacement>.001:changed+=1
  for i in range(0,indices.size(),3):
   var a=indices[i];var b=indices[i+1];var c=indices[i+2]
   if (moved[b]-moved[a]).cross(moved[c]-moved[a])<=0:inverted+=1
 rig.secondary.reset()
 rig.secondary.step(Transform2D.IDENTITY,1.0/60)
 rig.secondary.step(Transform2D(0,Vector2(3,5)),1.0/60)
 var driven=rig.secondary.cloth.length()
 for i in 120:rig.secondary.step(Transform2D(0,Vector2(3,5)),1.0/60)
 var settled=rig.secondary.cloth.length()+rig.secondary.hair.length()
 print("SECONDARY_MOTION protected_error=",protected_error," max_source_move=",max_move," inverted=",inverted," changed_vertices=",changed," driven=",driven," settled=",settled)
 rig.queue_free();await process_frame
 quit(0 if protected_error==0 and max_move<1.201 and inverted==0 and changed>0 and driven>0 and settled<.001 else 1)
