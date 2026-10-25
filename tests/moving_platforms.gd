extends SceneTree
var game
var failed=0
func _initialize():call_deferred("run")
func frames(n):
 for i in n:await physics_frame
 await process_frame
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.dead=true;enemy.set_physics_process(false)
 var feature
 for child in game.terrain.get_children():
  if child.get_script() and child.get_script().resource_path.ends_with("room_features.gd"):feature=child
 var ferry=feature.items.filter(func(x):return x.kind=="ferry")[0];var p=game.player
 p.position=ferry.body.position+Vector2(ferry.w*.5,-2);p.velocity=Vector2.ZERO;await frames(10)
 var start=p.position;await frames(60)
 check(p.is_on_floor() and absf(p.position.y-ferry.body.position.y)<3 and p.position.x>start.x+5,"ferry carries player horizontally")
 var lift=feature.items.filter(func(x):return x.kind=="lift")[0]
 p.position=lift.body.position+Vector2(lift.w*.5,-2);p.velocity=Vector2.ZERO;await frames(10);start=p.position;await frames(40)
 check(p.is_on_floor() and absf(p.position.y-lift.body.position.y)<3 and p.position.y<start.y-5,"lift carries player vertically")
 game.audio.stop_all();game.queue_free();await process_frame;print("MOVING_PLATFORMS failures=",failed);quit(failed)
