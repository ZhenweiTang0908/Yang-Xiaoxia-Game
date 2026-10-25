extends SceneTree
func _initialize():call_deferred("run")
func run():
 var c=load("res://scripts/combat/combat.gd").new();root.add_child(c)
 var h=c.hazard(Rect2(100,200,235,140),0,1,10,0,"fire");h.age=.13
 var ok=not c.hazard_hits(h,Rect2(100,205,230,35))
 ok=ok and c.hazard_hits(h,Rect2(130,320,12,20))
 for i in 5:
  var column=c.fire_column(h,i,5)
  ok=ok and column.end.y==340 and column.size.y<=95
 print("FIRE_VISIBLE_BOUNDS ","PASS" if ok else "FAIL")
 c.queue_free();await process_frame;quit(0 if ok else 1)
