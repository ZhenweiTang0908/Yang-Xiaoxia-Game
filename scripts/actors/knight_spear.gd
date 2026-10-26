extends RefCounted
# Meteor-style spear grammar adapted to the side-view arena: thrust / advance /
# lift, low sweep / return, spiral / lift, then dance / committed low release.
const MOVES=["spear_chain","dragon_sweep","dragon_rise","dragon_break"]
var actor
func times(id):
 var prep=actor.prep_for(id)
 match id:
  "spear_chain":return [prep,prep+.56,prep+1.34]
  "dragon_sweep":return [prep,prep+.86]
  "dragon_rise":return [prep,prep+.64,prep+1.48]
  "dragon_break":return [prep,prep+.66,prep+1.76]
 return []
func advance(dt):
 var k=actor;var beats=times(k.action)
 for i in beats.size():
  var at=beats[i];var first=i==0
  # Each follow-up has its own body tell. Tracking stops before the strike,
  # never while the spear is already crossing the hero.
  var ready=0.0 if first else beats[i-1]+.18
  if k.t>=ready and k.t<at-.30:k.face_target();k.lock_dir=k.facing
  if not first and k.once("ready"+str(i),maxf(ready,at-.48)):
   k.windup=minf(.48,at-ready);k.move_sound("warning",-5)
  var speed=420.0 if k.action=="dragon_sweep" else 620.0
  var distance=76.0 if k.action=="dragon_sweep" else 96.0
  # The dragon-king release holds its stance for a full raised-arm beat.
  if not (k.action=="dragon_break" and i==2):
   k.approach_interval(dt,at-.24,at,speed,k.lock_dir,distance)
  if k.once("beat"+str(i),at):release(i)
 var recovery=.95 if k.action=="dragon_break" else (.80 if k.action=="dragon_rise" else .65)
 if k.t>=beats[-1]+.22:k.finish(recovery)
func release(index):
 var k=actor;var damage=k.cfg("knight_"+k.action+"_damage")
 var source="knight_"+k.action
 var rect=Rect2();var effect="spear_point"
 match k.action:
  "spear_chain":
   rect=k.span(8,146 if index<2 else 155,48 if index<2 else 142,10 if index<2 else 6,k.lock_dir)
   damage*=([.68,.78,1.0][index]);effect="spear_lift" if index==2 else "spear_point"
  "dragon_sweep":
   rect=k.span(-18,170,35 if index==0 else 138,1 if index==0 else 48,k.lock_dir)
   damage*=.85 if index==0 else 1.0;effect="spear_low" if index==0 else "spear_high"
  "dragon_rise":
   rect=k.span(-45,125 if index<2 else 158,94 if index<2 else 152,4,k.lock_dir)
   damage*=.55 if index<2 else 1.0;effect="spear_spiral" if index<2 else "spear_lift"
  "dragon_break":
   if index==2:
    k.fire_wave("knight:dragon_break",damage);k.move_sound("release",-1);k.pressure_flash("dragon_release",.38)
    return
   rect=k.span(-26,135,86,5,k.lock_dir);damage*=.55;effect="spear_spiral"
 # One short, invisible contact per beat, including when a large dt crosses it.
 k.strike(rect,.11,damage,source)
 if k.action=="dragon_break":k.game.audio.enemy_cue("knight:dragon_rise","release",-4)
 else:k.move_sound("release",-2 if index<2 else 0)
 k.pressure_flash(effect,.26)
 k.game.fx.burst(k.position+Vector2(k.lock_dir*65,-4),4,Color("b7a888"),45)
 if k.empowered and index==beats_last() and k.action!="dragon_break":
  k.game.fx.burst(k.position+Vector2(k.lock_dir*110,-38),6,Color("acdce6"),65)
  k.soul.queue_soldiers()
func beats_last():return times(actor.action).size()-1
func pose(id,at):
 var beats=times(id);var index=0
 for i in beats.size():
  if at>=beats[i]-.44:index=i
 var delta=at-beats[index]
 var bank="foot";var frame=4;var contact=delta>=0 and delta<.20
 match id:
  "spear_chain":
   if index<2:frame=5 if contact else 4
   else:bank="pressure";frame=11 if contact else 4
  "dragon_sweep":bank="pressure";frame=(4 if index==0 else 3) if contact else (2 if index==0 else 4)
  "dragon_rise":bank="pressure";frame=([3,4,11][index] if contact else [2,3,4][index])
  "dragon_break":
   if index<2:bank="pressure";frame=([3,4][index] if contact else [2,3][index])
   else:frame=3 if contact else (1 if delta<-.22 else 2)
 return {"bank":bank,"frame":frame,"contact":contact,"delta":delta}
