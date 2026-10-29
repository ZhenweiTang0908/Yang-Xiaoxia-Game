extends "res://scripts/actors/boss.gd"
# Shared scheduling only; authored moves retain distinct stone/sword/moon identities.
const DEFINITIONS=preload("res://scripts/actors/boss_reset/definitions.gd")
const TURN=preload("res://scripts/combat/combo_turn.gd")
var combo_turn=TURN.new()
var action_age=0.0
var action_duration=0.0
var turn_age=0.0
var effects=[]
var moon_clock=0.0
var moon_visible=0.0
var recall_age=-1.0
var defeat_complete=false
var moon_form_spoken=false
var audio_stages=[]
var swing_age=-1.0
var dart_chain=0
var foot_distance=0.0
var recall_line_pending=false
func cfg(key):return game.tuning.get_value(key)
func value(field):return cfg("reset_"+spec.id+"_"+str(move.id)+"_"+field)
func setup(world,id,x):
 super.setup(world,id,x)
 spec=spec.duplicate(true);spec.moves=DEFINITIONS.MOVES[id].duplicate(true)
 spec.title="守石兽" if id=="lantern" else spec.title
 max_hp=cfg("reset_"+id+"_health");hp=max_hp
func _ready():
 collision_layer=0;collision_mask=1;floor_snap_length=5
 var c=CollisionShape2D.new();var s=CapsuleShape2D.new();s.radius=23;s.height=body_height*.85;c.shape=s;c.position.y=-s.height*.5;add_child(c)
 art=preload("res://scripts/actors/boss_reset/visual.gd").new();art.actor=self;add_child(art);art.configure_reset(spec.id,body_height)
func desired_phase():
 var fraction=hp/maxf(1,max_hp)
 return 3 if spec.id=="priest" and fraction<=cfg("moon_threshold") else (2 if fraction<(.65 if spec.id=="priest" else .5) else 1)
func phase_title(value=phase):
 var names={"lantern":["守石","群岩应令"],"duelist":["试刃","渡影"],"priest":["迎月","月蚀初临","月亮形态"]}
 return names[spec.id][clampi(value-1,0,names[spec.id].size()-1)]
func cue(stage):
 audio_stages.append({"move":move.get("id",""),"stage":stage,"time":time})
 if audio_stages.size()>180:audio_stages.pop_front()
 var identity="reset_"+spec.id+":"+str(move.get("id",""))
 game.audio.enemy_cue(identity,stage)
func clear_attacks():
 events.clear();effects.clear();dash_left=0;leap_left=0;windup=0;strike=0;velocity=Vector2.ZERO;combo_turn.clear()
 game.combat.remove_owner(get_instance_id())
func begin_phase_shift(next_phase):
 clear_attacks();phase=next_phase;cycle.clear();cooldown=.65;position.y=450
 phase_shift=cfg("moon_transition") if spec.id=="priest" and phase==3 else 1.25
 game.scene_motion.reset(self)
 if phase==3:
  moon_clock=0;moon_form_spoken=false
 else:speak_event("phase_"+str(phase),true)
 game.audio.play("reset_moon_fall" if phase==3 else "boss_release",-8);cue("charge")
func start_next():
 if spec.id!="duelist":
  super.start_next();return
 var distance=absf(game.player.position.x-position.x)
 var candidates=[];var previous=str(move.get("id",""))
 for i in spec.moves.size():
  var id=spec.moves[i].id
  if i==move_index or (previous=="feint" and id=="triple") or (previous=="shadow" and id in ["shadow","feint"]):continue
  if dart_chain>=2 and id in ["fan","boomerang"]:continue
  if distance<110 and id in ["flash","leap"]:continue
  if distance>170 and id in ["triple","low_sweep","shadow"]:continue
  var weight=2 if id in ["flash","triple","low_sweep","feint","shadow"] else 1
  for _copy in weight:candidates.append(i)
 if candidates.is_empty():candidates.append(0)
 var selected=candidates[randi()%candidates.size()]
 dart_chain=dart_chain+1 if spec.moves[selected].id in ["fan","boomerang"] else 0
 start_move(selected)
func start_move(index):
 if spec.id=="priest" and phase==3 and spec.moves[index].id in ["rain","ritual"] and (effects.any(func(e):return e.type=="moon_column" and e.age<e.delay+e.life) or events.any(func(e):return e.payload.get("independent",false))):index=1
 move_index=index;move=spec.moves[index].duplicate();windup=value("windup");move.windup=windup;move.damage=value("damage");move.recovery=value("recovery")
 action_age=0;strike=0;target=game.player.position;breath_face=facing;shown_moves[move.id]=true
 # A single draw for the whole combo; never draw again for each strike.
 combo_turn.begin(cfg("reset_"+spec.id+"_turn_chance")/100.0)
 speak_event(move.id);cue("warning")
 safe_x=clampf(target.x+(180 if target.x<arena.get_center().x else -180),arena.position.x+100,arena.end.x-100)
func _physics_process(dt):
 if game.state=="paused" or game.state=="debug":return
 if recall_age>=0:
  if game.state=="boss_cinematic":advance_recall(dt)
  return
 if not game.active() or game.hitstop>0:
  if game.state in ["dead","title"]:clear_attacks()
  return
 time+=dt;speech_cooldown=maxf(0,speech_cooldown-dt);hurt=maxf(0,hurt-dt)
 if dead:
  dead_time+=dt;art.tint.a=maxf(0,1-dead_time/1.4);art.pose("death",minf(1,dead_time/1.2));art.advance(dt);return
 if not active_battle:
  if game.player.position.x<=arena.position.x+15:return
  active_battle=true;game.audio.change_music(game.level.number,true);speak_event("intro",true)
 game.player.position.x=clampf(game.player.position.x,arena.position.x+10,arena.end.x-10)
 if desired_phase()>phase:begin_phase_shift(desired_phase())
 if phase_shift>0:
  if phase==3 and not moon_form_spoken:
   # Companion speech owns the channel until it finishes.
   if not game.audio.voice_player.playing:moon_form_spoken=speak_story("moon_form")
   if not moon_form_spoken:return
  phase_shift=maxf(0,phase_shift-dt)
  if phase==3:moon_visible=clampf(1-phase_shift/cfg("moon_transition"),0,1);art.pose("transform",moon_visible)
  else:art.pose("stagger",1-phase_shift/1.25)
  art.advance(dt);queue_redraw();return
 advance_effects(dt)
 if phase==3:
  moon_visible=move_toward(moon_visible,1,dt);moon_clock-=dt
  if moon_clock<=0:
   moon_clock+=cfg("moon_cycle")
   for i in 3:later(i*cfg("moon_gap"),"moonfall",{"damage":cfg("moon_damage"),"independent":true})
 if combo_turn.remaining>0:
  for e in events:
   if e.payload.get("independent",false):
    e.delay-=dt
    if e.delay<=0 and not e.done:e.done=true;execute_event(e.type,e.payload)
  events=events.filter(func(e):return not e.done)
  facing=combo_turn.advance(dt);turn_age+=dt;art.pose("turn",turn_age/maxf(.01,combo_turn.duration));art.facing=combo_turn.from_face;art.advance(dt);queue_redraw();return
 # Segment turns are deliberate footwork, and suspend the scheduled next strike.
 if events.any(func(e):return e.type=="melee" and e.delay>0 and e.delay<.18) and action_age>.12 and dash_left<=0 and not effects.any(func(e):return e.type=="weapon" and e.age<e.delay+e.life):
  if combo_turn.request(position,game.player.position,facing,cfg("reset_"+spec.id+"_turn_time")):
   turn_age=0;cue("recover");return
 for e in events:
  e.delay-=dt
  if e.delay<=0 and not e.done:e.done=true;execute_event(e.type,e.payload)
 events=events.filter(func(e):return not e.done)
 if leap_left>0:
  leap_left=maxf(0,leap_left-dt);var u=1-leap_left/.55
  position=leap_start.lerp(leap_end,u)+Vector2(0,-sin(u*PI)*115)
 elif dash_left>0:
  dash_left=maxf(0,dash_left-dt);velocity=Vector2(dash_velocity,0);move_and_collide(velocity*dt)
  if spec.id=="priest" and move.id=="rift":game.fx.trail(position-Vector2(0,body_height*.48),Color("a89acb"),facing)
  if dash_left<=0:cue("landing")
 else:
  velocity=Vector2(0,1080*dt);move_and_collide(velocity*dt)
 position.x=clampf(position.x,arena.position.x+35,arena.end.x-35)
 if windup>0:
  var before=windup;windup=maxf(0,windup-dt)
  if before>move.windup*.5 and windup<=move.windup*.5:cue("charge")
  art.pose(str(move.id),.30*(1-windup/maxf(.01,move.windup)))
  if windup<=0:release_move()
 elif strike>0:
  cooldown-=dt;action_age+=dt;swing_age+=dt if swing_age>=0 else 0;strike=maxf(0,strike-dt)
  art.pose(str(move.id),.30+.70*clampf((swing_age if swing_age>=0 else action_age)/(.34 if swing_age>=0 else maxf(.01,action_duration)),0,1))
  if dash_left>0 and move.id in ["flash","horn","rift","shadow","feint"]:art.pose(str(move.id),.32+.16*clampf(action_age/maxf(.01,action_duration-.25),0,1))
  if move.id=="beam":art.pose("beam",.30+.70*clampf(action_age/.65,0,1))
  if strike<=0:cue("recover")
 else:
  cooldown-=dt
  if absf(game.player.position.x-position.x)>3:facing=signf(game.player.position.x-position.x)
  var distance=game.player.position.x-position.x
  if spec.id=="priest" and move.get("id","")=="ritual" and events.any(func(e):return e.type=="ritual_ring"):
   art.pose("ritual",1.0)
  elif spec.id=="duelist" and absf(distance)>180 and cooldown>.15:
   var previous_x=position.x
   velocity=Vector2(facing*100,0);move_and_collide(velocity*dt);art.pose("walk",fposmod(time*1.8,1))
   foot_distance+=absf(position.x-previous_x)
   if foot_distance>=36:foot_distance-=36;cue("landing")
  else:art.pose("idle",fmod(time*.55,1))
  if cooldown<=0 and events.filter(func(e):return not e.payload.get("independent",false)).is_empty():start_next()
 art.facing=facing;art.tint=preload("res://scripts/combat/hit_feedback.gd").tint(hurt,.12)
 art.advance(dt);queue_redraw()
func release_move():
 if move.id in ["flash","horn","pounce","leap","triple","four_slash","sweep","stone_combo"]:game.audio.exertion(spec.id)
 cue("release");action_age=0;swing_age=-1;action_duration=.65;strike=action_duration;cooldown=move.recovery+maxf(.55,1.25-phase*.18)
 if spec.id=="duelist":cooldown*=cfg("reset_duelist_recovery_scale")
 var damage=float(move.damage);var id=str(move.id);var travel=value("travel")
 match id:
  "flash","horn","rift","shadow":
   # A visible committed dash replaces unexplained teleports.
   dash_velocity=facing*value("speed");dash_left=travel/maxf(1,value("speed"));strike=maxf(strike,dash_left+.25);action_duration=strike
   later(.04,"melee",{"damage":damage,"dash":true})
  "triple","four_slash","stone_combo":
   var count=4 if id=="four_slash" else (2 if id=="stone_combo" else 3)
   for i in count:later(i*value("gap"),"melee",{"damage":24.0 if id=="four_slash" and i==3 else (16.0 if id=="stone_combo" and i==1 else damage),"step":i})
   strike=(count-1)*value("gap")+.45;action_duration=strike
  "sweep","low_sweep","stone_lift":later(.03,"melee",{"damage":damage})
  "pounce","leap":
   leap_start=position;leap_end=Vector2(clampf(position.x+clampf(target.x-position.x,-travel,travel),arena.position.x+45,arena.end.x-45),450);leap_left=.55
   later(.53,"land",{"p":leap_end,"damage":damage})
  "ground_wave":
   for dir in [-1,1]:
    for i in 8:later(i*value("gap"),"wave",{"p":Vector2(position.x+dir*i*48,450),"damage":damage})
  "stone_throw","stone_roll":
   add_effect("boulder",position-Vector2(0,44),Vector2(facing*value("speed"),-120 if id=="stone_throw" else 0),damage,travel/maxf(1,value("speed")),0,Vector2(32,32))
  "fan":
   for angle in [-.42,0,.42]:add_effect("dart",position-Vector2(0,48),Vector2(facing*value("speed"),0).rotated(angle),damage,1.65,0,Vector2(20,8))
  "boomerang":add_effect("return_dart",position-Vector2(0,42),Vector2(facing*value("speed"),0),damage,1.5,0,Vector2(20,8))
  "feint":
   add_effect("dart",position-Vector2(0,44),Vector2(facing*320,0),16,1.5,0,Vector2(20,8));later(value("gap"),"feint_thrust",{"damage":damage})
   strike=value("gap")+.45;action_duration=strike
  "moonfall":
   if phase<3:
    for i in 3:later(i*value("gap"),"moonfall",{"damage":damage})
  "ring":
   for i in 14:
    var a=i*TAU/14
    if a>1.7 and a<2.8:continue
    add_effect("crescent",position-Vector2(0,75),Vector2.from_angle(a)*value("speed"),damage,3,0,Vector2(14,14))
  "homing":
   for i in 3:later(i*value("gap"),"moon_orb",{"damage":damage})
  "beam":
   art.pose("beam",.35)
   add_effect("beam",art.weapon_segment()[1],Vector2.ZERO,damage,.65,0,Vector2(travel,22))
  "rain":
   for x in range(int(arena.position.x)+30,int(arena.end.x),60):
    if absf(x-safe_x)>90:add_effect("moon_shard",Vector2(x,100),Vector2(0,value("speed")),damage,1.3,.30,Vector2(12,24))
  "ritual":
   # Travelling crescents leave a wide exit rather than sealing the whole floor.
   for i in 2:later(i*value("gap"),"ritual_ring",{"damage":damage,"step":i})
func execute_event(type,payload):
 match type:
  "melee":
   swing_age=0;art.pose(str(move.id),.35);cue("release")
   if not payload.get("dash",false):
    var distance=value("travel") if move.id not in ["stone_combo","four_slash","triple"] else minf(value("travel"),35)
    dash_velocity=facing*minf(distance,45)/.16;dash_left=.16
    cue("landing")
   add_effect("weapon",position-Vector2(0,body_height*.48),Vector2.ZERO,payload.damage,dash_left+.08 if payload.get("dash",false) else .18,0,Vector2(100 if spec.id!="lantern" else 76,58))
   effects.back().body_contact=payload.get("dash",false)
   if move.id=="stone_lift":add_effect("stone_wave",position+Vector2(facing*65,-15),Vector2.ZERO,payload.damage,.28,0,Vector2(40,30))
  "land":cue("landing");add_effect("impact",payload.p-Vector2(0,22),Vector2.ZERO,payload.damage,.22,0,Vector2(96,44));game.fx.burst(payload.p,10,Color("a8a7a0") if spec.id=="lantern" else game.GOLD,90)
  "wave":
   add_effect("stone_wave" if spec.id=="lantern" else "moon_wave",payload.p-Vector2(0,15),Vector2.ZERO,payload.damage,.28,0,Vector2(44,30))
   if spec.id=="priest":effects.back().face=signf(payload.p.x-position.x)
  "moonfall":
   # Lock only the hero at warning start. Every column is independent of future movement.
   add_effect("moon_column",Vector2(game.player.position.x,130),Vector2.ZERO,payload.damage,cfg("moon_core"),cfg("moon_warning"),Vector2(cfg("moon_width"),320))
  "moon_orb":add_effect("moon_orb",position-Vector2(0,65),Vector2(facing*130,-25),payload.damage,3.2,0,Vector2(14,14))
  "feint_thrust":dash_velocity=facing*value("speed");dash_left=value("travel")/maxf(1,value("speed"));add_effect("weapon",position-Vector2(0,48),Vector2.ZERO,payload.damage,dash_left+.08,0,Vector2(100,48));effects.back().body_contact=true
  "ritual_ring":
   for i in 10:
    var a=i*TAU/10+.12*payload.step
    if a>1.6 and a<2.9:continue
    add_effect("crescent",position-Vector2(0,75),Vector2.from_angle(a)*180,payload.damage,1.8,.20,Vector2(16,16))
func add_effect(type,p,v,damage,life,delay=0.0,size=Vector2(20,20)):
 effects.append({"type":type,"p":p,"v":v,"damage":damage,"life":life,"delay":delay,"age":0.0,"size":size,"face":facing,"hit":{},"sound":false,"released":false,"origin":p,"broken":false,"gravity":type=="boulder" and move.get("id","")=="stone_throw","identity":"reset_"+spec.id+":"+str(move.get("id",""))})
 if type=="moon_orb":effects.back()["trail"]=PackedVector2Array([p])
 if type=="moon_column":effects.back().identity="reset_priest:moonfall"
func effect_rect(e):
 if e.type=="moon_column":return Rect2(e.p-Vector2(e.size.x*.5,0),e.size)
 if e.type=="beam":return Rect2(e.p+Vector2(0 if e.face>0 else -e.size.x,-e.size.y*.5),e.size)
 if e.type=="weapon" and spec.id!="lantern":
  var segment=art.weapon_segment()
  var rect=Rect2(segment[0],Vector2.ZERO).expand(segment[1]).grow(9)
  return rect.merge(Rect2(position-Vector2(radius,body_height*.7),Vector2(radius*2,body_height*.7))) if e.get("body_contact",false) and dash_left>0 else rect
 if e.type=="weapon":return Rect2(e.p+Vector2(0 if e.face>0 else -e.size.x,-e.size.y*.5),e.size)
 return Rect2(e.p-e.size*.5,e.size)
func advance_effects(dt):
 for e in effects:
  if e.broken:continue
  e.age+=dt
  if e.age<e.delay:continue
  var live=e.age-e.delay
  if live>e.life:continue
  if not e.released:
   e.released=true
   if e.type=="moon_column":game.audio.play("reset_moon_fall",-6)
  if e.type=="weapon":e.p=position-Vector2(0,body_height*.48)
  if e.type=="beam":e.p=art.weapon_segment()[1]
  if e.type=="moon_orb" and live<1.15:
   e.v=e.v.lerp((game.player.position-Vector2(0,22)-e.p).normalized()*130,1-exp(-dt*1.3))
  if e.type=="return_dart" and live>.65 and not e.get("returned",false):e.returned=true;e.hit.clear()
  if e.type=="return_dart" and live>.65:e.v=e.v.lerp((position-Vector2(0,45)-e.p).normalized()*300,1-exp(-dt*10))
  if e.type=="boulder" and e.gravity:e.v.y+=420*dt
  e.p+=e.v*dt
  if e.type=="boulder":e.p.y=minf(e.p.y,434)
  if e.type=="moon_orb":
   var trail:PackedVector2Array=e.get("trail",PackedVector2Array())
   trail.append(e.p)
   if trail.size()>16:trail.remove_at(0)
   e["trail"]=trail
  var rect=effect_rect(e)
  var targets=[game.player]
  if game.summon.phase=="active" and is_instance_valid(game.summon.brother):targets.append(game.summon.brother)
  for victim in targets:
   if e.hit.has(victim.get_instance_id()):continue
   var hurt_box=Rect2(victim.position-Vector2(8,38),Vector2(16,38)) if victim==game.player else victim.hurt_rect()
   if not rect.intersects(hurt_box):continue
   if e.type=="weapon" and spec.id!="lantern" and not weapon_intersects(hurt_box):
    if not (e.get("body_contact",false) and dash_left>0 and Rect2(position-Vector2(radius,body_height*.7),Vector2(radius*2,body_height*.7)).intersects(hurt_box)):continue
   if victim==game.player and victim.is_carried():continue
   var hit=false
   var direction=signf(e.v.x) if absf(e.v.x)>1 else e.face
   if victim==game.player:hit=victim.take_damage(e.damage,direction,"moonlight" if spec.id=="priest" else e.type,e.identity)
   else:victim.take_damage(e.damage,direction,e.identity,get_instance_id());hit=true
   e.hit[victim.get_instance_id()]=true
   if hit:
    audio_stages.append({"move":e.identity,"stage":"impact","time":time})
    var hit_color=Color("e4dcf5") if spec.id=="priest" else (Color("b8d7cd") if spec.id=="duelist" else game.GOLD)
    game.fx.hit_mark(hurt_box.get_center(),direction,hit_color,1.0);game.shake=maxf(game.shake,2.0)
    if spec.id=="priest" and e.type in ["moon_orb","moon_shard","crescent"]:
     game.fx.impact(hurt_box.get_center(),"moon_orb",direction,Color("d7cff4"))
    elif spec.id=="duelist" and e.type in ["dart","return_dart"]:
     var impact_kind="return_card" if e.type=="return_dart" else "card"
     game.fx.impact(hurt_box.get_center(),impact_kind,direction,Color("b8d7cd"))
 effects=effects.filter(func(e):return not e.broken and e.age<e.delay+e.life+(cfg("moon_afterglow") if e.type=="moon_column" else .16))
func break_rocks(rect,_damage):
 var broken=false
 for e in effects:
  if e.type=="boulder" and not e.broken and effect_rect(e).intersects(rect):
   broken=true;e.broken=true;game.fx.burst(e.p,9,Color("b3b0a5"),90);game.audio.play("hit_stone",-3)
 return broken
func take_hit(amount,faction,direction,breaking=false,with_sound=true,with_debris=true):
 if dead or recall_age>=0:return
 if spec.id!="priest":
  super.take_hit(amount,faction,direction,breaking,with_sound,with_debris)
  if dead:clear_attacks();defeat_complete=true
  return
 if not active_battle or phase_shift>0:return
 # Run normal hit rewards without letting the generic death path settle early.
 var lethal=amount>=hp
 if lethal:
  var old_hp=hp;hp=amount+1
  super.take_hit(amount,faction,direction,breaking,with_sound,with_debris)
  hp=old_hp-amount
  if faction=="player":game.player.gain_spirit(6);game.player.health=minf(100,game.player.health+1)
  begin_recall()
 else:super.take_hit(amount,faction,direction,breaking,with_sound,with_debris)
func begin_recall():
 clear_attacks();dead=true;recall_age=0;moon_visible=1;position.y=450
 game.state="boss_cinematic";game.release_inputs();game.challenge_finish=-1;game.hitstop=0
 game.combat.clear();game.fx.clear()
 recall_line_pending=true;cue("recover")
func advance_recall(dt):
 if recall_age>=.7 and recall_line_pending:
  if game.audio.voice_player.playing and not game.audio.is_boss_voice(game.audio.voice_identity):return
  speak_story("moon_recall");recall_line_pending=false
 recall_age+=dt;time+=dt;moon_visible=1-clampf((recall_age-(cfg("moon_recall_time")-.6))/.6,0,1)
 art.pose("death" if recall_age<1.3 else "recall",clampf(recall_age/1.3 if recall_age<1.3 else (recall_age-1.3)/3.4,0,1))
 art.tint.a=1.0-clampf((recall_age-2.8)/2,0,1);art.advance(dt)
 if recall_age>=cfg("moon_recall_time") and not defeat_complete:
  defeat_complete=true;game.kills+=1;game.boss_defeated();game.state="playing";game.challenge_finish=.01;visible=false
 queue_redraw()
func warning_hint():return ""
func _draw():
 preload("res://scripts/actors/boss_reset/effect_draw.gd").paint(self)

func speak_story(event):
 var bank=DIALOGUE.BOSSES.get(spec.id,{})
 var key="reset_"+event+"_01"
 if game.say_line(spec.title+"："+str(bank.lines.get(key,"")),spec.id+"_"+key):return true
 game.subtitle=spec.title+"："+str(bank.lines.get(key,""));game.subtitle_time=4
 return true

func weapon_intersects(rect):
 var points=art.weapon_segment();var delta=points[1]-points[0]
 var width=delta.normalized().orthogonal()*9
 var blade=PackedVector2Array([points[0]+width,points[1]+width,points[1]-width,points[0]-width])
 var target_box=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
 return not Geometry2D.intersect_polygons(blade,target_box).is_empty()
