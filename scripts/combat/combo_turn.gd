extends RefCounted
# One draw and at most one deliberate turn per complete melee action.
var allowed=false
var used=false
var draws=0
var remaining=0.0
var duration=0.0
var from_face=1.0
var to_face=1.0
func begin(probability,forced_roll=-1.0):
 allowed=(randf() if forced_roll<0 else forced_roll)<clampf(probability,0,1)
 used=false;remaining=0;draws+=1
func request(origin,target,face,seconds):
 if not allowed or used or remaining>0 or (target.x-origin.x)*face>=-4:return false
 used=true;duration=maxf(.01,seconds);remaining=duration;from_face=face;to_face=-face
 return true
func advance(dt):
 remaining=maxf(0,remaining-dt)
 return to_face if remaining<=duration*.5 else from_face
func clear():allowed=false;used=false;remaining=0
