extends SceneTree
func _initialize():
 var rig=load("res://scripts/animation/hero_visual.gd").new()
 var a={"base":Vector2.ZERO,"tip":Vector2(20,0),"attack":"slash1","facing":1}
 var b={"base":Vector2.ZERO,"tip":Vector2(0,-20),"attack":"slash1","facing":1}
 var sections=rig.trail_sections(a,b);var errors=0
 if sections.size()<8:errors+=1
 for s in sections:
  if absf(s[1].length()-20)>.001 or absf(s[0].length()-13.6)>.001:errors+=1
 b.facing=-1
 if not rig.trail_sections(a,b).is_empty():errors+=1
 b.facing=1;b.attack="slash2"
 if not rig.trail_sections(a,b).is_empty():errors+=1
 b.attack="slash1";b.tip=Vector2(-20,0)
 if not rig.trail_sections(a,b).is_empty():errors+=1
 print("BLADE_RIBBON sections=",sections.size()," errors=",errors)
 rig.free();quit(errors)
