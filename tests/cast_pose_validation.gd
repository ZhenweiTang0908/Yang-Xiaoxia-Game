extends SceneTree
var failed=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 var e=game.enemies[0];e.set_physics_process(false);e.art.set_process(false)
 e.windup=.1;e.strike=0;e.hurt=0;e.art._process(.1)
 check(e.art.lean>0 and e.art.sink>0,"enemy anticipation shifts weight back")
 var previous=e.art.lean;e.windup=0;e.strike=.4;e.art._process(.001)
 check(absf(e.art.lean-previous)<.01,"strike begins without rotational snap")
 e.art._process(.2);check(e.art.lean<0,"strike shifts weight forward")
 var feet=true
 for x in [-15,0,15]:feet=feet and e.art.deform(Vector2(x,0)).is_equal_approx(Vector2(x,0))
 check(feet,"support strip remains fixed")
 var a=Vector2(-4,-40);var b=Vector2(4,-40)
 check(absf(e.art.deform(a).distance_to(e.art.deform(b))-8)<.001,"upper silhouette preserves proportions")
 var before=e.art.lean;game.state="paused";e.art._process(.5)
 check(e.art.lean==before,"pause freezes pose motion")
 check(e.art.isolated.size()==48,"all eight enemy types have isolated poses")
 check(game.boss.art.isolated.size()==18,"boss isolation remains intact")
 game.audio.stop_all();game.queue_free();await process_frame;print("CAST_POSE failures=",failed);quit(failed)
