extends SceneTree
const LAB=preload("res://scripts/animation/animation_lab.gd")
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run():
 var lab=LAB.new()
 lab.cursor=6;lab.clock=0;lab.playing=true;lab.advance(.8)
 verify(lab.cursor==8 and is_equal_approx(lab.clock,.24),"long frame consumes every crossed preview segment")
 lab.playing=false;var paused_cursor=lab.cursor;var paused_clock=lab.clock;lab.advance(1.0)
 verify(lab.cursor==paused_cursor and is_equal_approx(lab.clock,paused_clock),"paused preview preserves its segment and timestamp")
 lab.cursor=7;lab.clock=.53;lab.playing=false;lab.advance(0)
 verify(lab.cursor==7 and is_equal_approx(lab.clock,.53),"pausing with carried frame time cannot advance the next segment")
 lab.free()
 print("ANIMATION_LAB_PAUSE_RESULT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
