extends RefCounted
static func circle_hit(previous,current,center,radius):
 var old_blade=previous.tip-previous.base;var new_blade=current.tip-current.base
 var turn=wrapf(new_blade.angle()-old_blade.angle(),-PI,PI)
 var travel=previous.base.distance_to(current.base)+absf(turn)*maxf(old_blade.length(),new_blade.length())
 var steps=maxi(1,int(ceil(travel/maxf(1,radius*.4))))
 for i in steps+1:
  var u=float(i)/steps
  var start=previous.base.lerp(current.base,u)
  var end=start+Vector2.from_angle(old_blade.angle()+turn*u)*lerpf(old_blade.length(),new_blade.length(),u)
  if Geometry2D.get_closest_point_to_segment(center,start,end).distance_to(center)<=radius:return true
 return false
