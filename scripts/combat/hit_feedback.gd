extends RefCounted
# Brief material flash; attack anticipation and release poses remain intact.
static func tint(remaining:float,duration:float)->Color:
 var elapsed=maxf(0,duration-remaining)
 var strength=1-smoothstep(.02,.13,elapsed)
 if remaining<=0:strength=0
 return Color.WHITE.lerp(Color(1.65,1.40,1.18),strength)
static func recoil(remaining,duration,direction):
 var elapsed=maxf(0,duration-remaining)
 var strength=0.0 if remaining<=0 else 1-smoothstep(0,.14,elapsed)
 return Vector2(direction*4,-1)*strength
static func apply(art,remaining,duration,direction,weight=1.0):
 art.tint=tint(remaining,duration);art.hit_direction=direction;art.hit_weight=weight
 art.position=recoil(remaining,duration,direction)*weight
 art.queue_redraw()
