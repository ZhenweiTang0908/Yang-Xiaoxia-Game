extends RefCounted
var cloth_anchor=Vector2.INF
var hair_anchor=Vector2.INF
var cloth=Vector2.ZERO
var hair=Vector2.ZERO
func reset():
 cloth_anchor=Vector2.INF;hair_anchor=Vector2.INF;cloth=Vector2.ZERO;hair=Vector2.ZERO
func step(body,dt):
 var chest=body*Vector2(96,128)
 var crown=body*Vector2(96,28)
 if not cloth_anchor.is_finite():cloth_anchor=chest
 if not hair_anchor.is_finite():hair_anchor=crown
 cloth_anchor=cloth_anchor.lerp(chest,1-exp(-22*dt))
 hair_anchor=hair_anchor.lerp(crown,1-exp(-30*dt))
 # Offsets are source pixels: under 0.31 and 0.08 game pixels respectively.
 cloth=((cloth_anchor-chest)*.35).limit_length(1.2)
 hair=((hair_anchor-crown)*.12).limit_length(.3)
func deform(point):
 var hem=smoothstep(118,141,point.y) if point.y<=142 and point.x>=70 and point.x<=121 else 0.0
 var tip=1-smoothstep(19,38,point.y) if point.y<38 else 0.0
 return point+cloth*hem+hair*tip
