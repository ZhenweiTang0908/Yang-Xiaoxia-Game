extends Node2D
# Ground effects are anchored to actual collision surfaces, not the actor's feet in mid-air.
var game
var shadows=[]
var dust=[]
var ripples=[]
var splashes=[]
var time=0.0
var wake_clock=0.0
var landing_tracks={}
const PUDDLES=[Vector2(2180,150),Vector2(8440,115)]
func wet_at(p):
 if game.level.stage_art()==3 or absf(p.y-450)>6:return false
 for pool in PUDDLES:
  if p.x>=pool.x and p.x<=pool.x+pool.y:return true
 return false
func step(p,landing=false):
 var query=PhysicsRayQueryParameters2D.create(p-Vector2(0,3),p+Vector2(0,8),5)
 var hit=get_world_2d().direct_space_state.intersect_ray(query)
 if hit.is_empty() or hit.normal.y>-.7:return
 p=hit.position
 if wet_at(p):
  var direction=0.0
  if is_instance_valid(game.player) and game.player.position.distance_to(p)<70:direction=signf(game.player.velocity.x)
  ripple(p,1.0 if landing else .55,direction,"landing" if landing else "step")
  if landing and splashes.size()+3<=12:
   for side in [-1,0,1]:
    splashes.append({"p":p+Vector2(side*9,0),"v":Vector2(side*16,-27 if side==0 else -22),"age":0.0})
  return
 if dust.size()+2>18:return
 var color=[Color("8d9788"),Color("7d918a"),Color("8f8699")][game.level.stage_art()-1]
 for side in [-1,1]:
  dust.append({"p":p+Vector2(side*3,-1),"v":Vector2(side*(24 if landing else 12),-8 if landing else -3),"age":0.0,"life":.38 if landing else .22,"size":3.2 if landing else 1.6,"color":color})
func ripple(p,strength=.6,direction=0.0,kind="step"):
 if ripples.size()<14:ripples.append({"p":p,"age":0.0,"strength":strength,"direction":direction,"kind":kind})
func splash_offset(drop):
 return drop.v*drop.age+Vector2(0,60*drop.age*drop.age)
func surface_extent(space,feet,surface_y,side,desired):
 # Keep the ellipse on the visible top face when an actor reaches a ledge.
 # A neighbouring collider at the same height still counts as continuous ground.
 var supported=func(distance):
  var x=feet.x+side*distance
  var query=PhysicsRayQueryParameters2D.create(Vector2(x,feet.y-1),Vector2(x,feet.y+145),5)
  var sample=space.intersect_ray(query)
  return not sample.is_empty() and sample.normal.y<=-.7 and absf(sample.position.y-surface_y)<=2
 if supported.call(desired):return desired
 var low=0.0;var high=desired
 for i in 5:
  var middle=(low+high)*.5
  if supported.call(middle):low=middle
  else:high=middle
 return low
func _physics_process(dt):
 if not is_instance_valid(game.player):return
 if not game.active() or game.hitstop>0:return
 time+=dt;shadows.clear()
 var actors=[game.player]
 for e in game.enemies:
  if not e.dead and absf(e.position.x-game.player.position.x)<650:actors.append(e)
 if is_instance_valid(game.summon) and is_instance_valid(game.summon.brother):actors.append(game.summon.brother)
 var space=get_world_2d().direct_space_state
 var next_tracks={}
 for actor in actors:
  if not actor.visible:continue
  if actor==game.player and actor.is_carried():continue
  var feet=actor.position
  # Player footsteps already follow animation contacts. Other actors also need
  # one grounded landing event, without dust on spawn or teleport arrival.
  if actor!=game.player and actor is CharacterBody2D:
   var id=actor.get_instance_id()
   var previous=landing_tracks.get(id,{})
   var grounded=actor.is_on_floor()
   if not previous.is_empty() and previous.p.distance_to(feet)<80:
    if grounded and not previous.grounded and previous.fell:step(feet,true)
   var fell=not grounded and (actor.velocity.y>40 or (not previous.is_empty() and previous.fell))
   next_tracks[id]={"p":feet,"grounded":grounded,"fell":fell}
  var query=PhysicsRayQueryParameters2D.create(feet-Vector2(0,1),feet+Vector2(0,145),5)
  var hit=space.intersect_ray(query)
  if hit.is_empty() or hit.normal.y>-.7:continue
  var height=maxf(0,hit.position.y-feet.y)
  var width=10.0 if actor==game.player else clampf(actor.get("body_height")*.20 if actor.get("body_height")!=null else 16,8,26)
  width*=1+height/220
  var left=surface_extent(space,feet,hit.position.y,-1,width)
  var right=surface_extent(space,feet,hit.position.y,1,width)
  var center_shift=(right-left)*.5
  shadows.append({"p":hit.position+Vector2(center_shift,.8),"w":(left+right)*.5,"alpha":.27*(1-height/155),"actor":weakref(actor),"surface":weakref(hit.collider)})
 landing_tracks=next_tracks
 for e in dust:e.age+=dt;e.p+=e.v*dt;e.v.y+=25*dt
 dust=dust.filter(func(e):return e.age<e.life)
 for e in ripples:e.age+=dt
 ripples=ripples.filter(func(e):return e.age<.85)
 for drop in splashes:drop.age+=dt
 # Remove droplets when they meet the water again, never below the surface.
 splashes=splashes.filter(func(drop):return splash_offset(drop).y<=0 and drop.age<.5)
 wake_clock+=dt
 if wake_clock>.32:
  wake_clock=0
  for f in game.terrain.mechanisms.items:
   if game.level.stage_art()!=3 and f.kind=="ferry" and absf(f.body.position.x-game.player.position.x)<700:
    var direction=signf(sin(time*f.speed))
    ripple(Vector2(f.body.position.x+f.w*.5-direction*f.w*.42,455),.4,direction,"wake")
 queue_redraw()
func _draw():
 if not is_instance_valid(game.player):return
 if game.level.stage_art()!=3:
  for pool in PUDDLES:
   if absf(pool.x-game.player.position.x)>1000:continue
   draw_set_transform(Vector2(pool.x+pool.y*.5,450.5),0,Vector2(pool.y*.5,1.6))
   draw_circle(Vector2.ZERO,1,Color("2b444c"));draw_set_transform(Vector2.ZERO)
   draw_line(Vector2(pool.x+pool.y*.2,450),Vector2(pool.x+pool.y*.75,450),Color("69858a"),.7)
 for s in shadows:
  var offset=game.scene_motion.offset(s.actor.get_ref())
  var surface_offset=game.scene_motion.offset(s.surface.get_ref())
  var at=s.p+Vector2(offset.x,surface_offset.y)
  draw_set_transform(at,0,Vector2(s.w,2.4));draw_circle(Vector2.ZERO,1,Color(.035,.055,.08,s.alpha))
  draw_set_transform(at,0,Vector2(s.w*.62,1.15));draw_circle(Vector2.ZERO,1,Color(.025,.04,.055,s.alpha*.65))
 draw_set_transform(Vector2.ZERO)
 for e in dust:
  var fade=1-e.age/e.life
  draw_set_transform(e.p,0,Vector2(1.8,1));draw_circle(Vector2.ZERO,e.size*(1+e.age),Color(e.color,fade*.32))
 draw_set_transform(Vector2.ZERO)
 for e in ripples:
  var r=3+e.age*25*e.strength
  var direction=float(e.get("direction",0.0));var kind=e.get("kind","step")
  var fade=(1-e.age/.85)
  draw_set_transform(e.p,0,Vector2(1,.16))
  # Broken directional arcs read as displaced water instead of a magic ring.
  var sweep=.72 if kind=="wake" else 1.05
  var heading=0.0 if direction>=0 else PI
  draw_arc(Vector2(direction*r*.16,0),r,heading-sweep,heading+sweep,10,Color(.48,.68,.70,fade*(.22 if kind=="wake" else .42)),.8)
  draw_arc(Vector2(-direction*r*.08,0),r*.82,heading+PI-sweep*.82,heading+PI+sweep*.82,8,Color(.42,.61,.65,fade*.25),.7)
  if e.strength>.7 and e.age>.08:
   var inner=maxf(0,r-3)
   draw_arc(Vector2.ZERO,inner,.25,PI-.25,12,Color(.60,.75,.75,fade*.18),.65)
 draw_set_transform(Vector2.ZERO)
 for drop in splashes:
  var p=drop.p+splash_offset(drop)
  var fade=1-smoothstep(.25,.48,drop.age)
  # A short vertical glint reads as water at native pixel scale.
  draw_line(p,p+Vector2(0,-1.4),Color(.58,.76,.78,.6*fade),.8)
