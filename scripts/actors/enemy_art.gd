extends "res://scripts/animation/actor_pose_art.gd"
func configure(path:String,cols:int,row_count:int,height:float):
 super.configure(path,cols,row_count,height)
 load_frames("res://assets/art/mob_frames",48)
func deform(p):
 var result=super.deform(p)
 if not is_instance_valid(actor) or actor.dead:return result
 if actor.kind=="spirit" and current>=6 and current<=9:
  var source=p/scale_unit+Vector2(anchors[current],bounds[current].end.y)
  var follow=smoothstep(88,146,source.y)
  # A delayed lateral wave follows the floating body. The head and shoulders
  # stay untouched, and no vertical scaling stretches the painted silhouette.
  return result+Vector2(sin(clock*3.6-(source.y-88)*.045)*5*follow*scale_unit,0)
 if actor.kind!="bat" or current<24 or current>27:return result
 # Keep face and body rigid; bend only the broad wing around its shoulder.
 var pixel=p/scale_unit+Vector2(anchors[current],bounds[current].end.y)
 var weight=smoothstep(75,104,pixel.x)*(1-smoothstep(88,113,pixel.y))
 var pivot=Vector2(94,104)
 var angle=sin(clock*TAU*3.5)*.22
 if actor.strike>0:angle=lerpf(angle,.28,.7)
 return result+((pixel-pivot).rotated(angle)-(pixel-pivot))*scale_unit*weight
