extends SceneTree
var game
var k
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func reset(id="spear_chain",x=370.0,y=450.0,rage=0.0):
 game.release_inputs();game.state="playing";game.hitstop=0;game.audio.stop_all();game.combat.clear();game.fx.clear();game.summon.reset(true)
 game.player.reset(Vector2(x,y),true);game.player.invincible=0
 k.end_box();k.soul.clear_attacks();k.soul.rage=rage;k.soul.release_ready=rage>=1;k.empowered=false;k.phase=2;k.max_hp=2400;k.hp=2400;k.dead=false;k.dismount_t=-1;k.phase_shift=0;k.active_battle=true;k.position=Vector2(250,450);k.facing=1;k.weapon="spear";k.idle=100;k.speech_cooldown=100;k.history=[];k.damage_log.clear();k.strike_fx.clear();k.visual.held_action=""
 k.begin(id,k.prep_for(id))
func step(seconds,ignore_guard=false,rate=120):
 for i in int(round(seconds*rate)):
  game.hitstop=0
  game.player.invincible=0 if ignore_guard else maxf(0,game.player.invincible-1.0/rate)
  k._physics_process(1.0/rate);game.combat._physics_process(1.0/rate)
func run():
 seed(1729)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame;game.start_challenge(4,2);await process_frame
 game.tuning.reset();game.tuning.values.knight_rage_release=100;game.set_physics_process(false);game.set_process(false)
 k=game.boss;k.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for id in k.SPEAR.MOVES:
  reset(id)
  var prep=k.prep_for(id);step(prep-.025)
  verify(game.player.health==100 and game.combat.hazards.is_empty(),id+" has a damage-free raised-arm windup")
  verify(k.visual.selected==k.visual.foot or k.visual.selected==k.visual.pressure,id+" uses original painted 2D poses")
  var beats=k.spear.times(id);step(.06)
  verify(k.fired.has("beat0") and game.combat.hazards.size()==1,id+" releases exactly one first-beat hitbox")
  verify(game.combat.hazards[0].attack_sound=="knight:"+id and game.combat.hazards[0].invisible,id+" carries matching impact audio without a warning rectangle")
  step(beats[-1]-k.t+.26)
  verify(k.action=="" and k.hit_box==null and game.combat.hazards.is_empty(),id+" completes and clears contact damage")
 reset();var beats=k.spear.times("spear_chain");step(beats[-1]+.12,true)
 verify(is_equal_approx(game.player.health,100-20*(.68+.78+1.0)*.9),"three chain contacts each settle once even with hurt immunity disabled")
 reset();step(.29);var before=k.position.x;step(.3)
 verify(k.position.x>before and k.position.x<game.player.position.x,"chain steps into range without crossing through the target")
 reset();step(.34);game.player.position.x=100;step(.30)
 verify(k.facing==1 and k.lock_dir==1,"first thrust cannot reverse during its committed tell")
 step(.26)
 verify(k.facing==-1 and k.lock_dir==-1,"next chain beat reacquires before its own tell")
 reset("dragon_sweep",370,400);step(.76)
 verify(game.player.health==100,"jump clears the first low sweep")
 step(.86);verify(game.player.health<100,"high return catches a player who stays airborne")
 reset("dragon_sweep");step(1.68,true)
 verify(is_equal_approx(game.player.health,100-20*.85*.9),"grounded hero is safe under the high return")
 reset("dragon_rise",370,350);step(2.45)
 verify(game.player.health<100,"final rising spear reaches an airborne hero")
 reset("dragon_break",900);step(2.60)
 verify(game.player.health==100 and k.visual.selected_frame in [1,2],"dragon king holds a visible raised-arm beat before its distant release")
 step(.10);verify(is_equal_approx(game.player.health,81.1) and k.damage_log.size()==1,"dragon king sends one 0.9-scaled low strike across the arena")
 step(.10);verify(k.damage_log.size()==1,"dragon king residue never hits twice")
 reset("dragon_break",900,420);step(2.82)
 verify(game.player.health==100 and k.damage_log.is_empty(),"jump alone clears the dragon king full-width strike")
 reset("dragon_break",900);game.player.invincible=10;step(2.82)
 verify(game.player.health<100,"grounded invulnerability cannot replace jumping over the low wave")
 for id in k.SPEAR.MOVES:
  reset(id,370,450,1)
  verify(k.empowered and k.soul.rage==0,id+" consumes exactly one stored rage cell")
  var strong=k.span(8,146,48,10)
  verify(strong.size.x>150,id+" extends the actual reinforced spear reach")
  step(k.spear.times(id)[-1]+.30)
  verify(not k.empowered,id+" reinforcement ends with recovery")
 reset();k.t=k.prep_for("spear_chain")+.02;k.visual.sync_pose(0)
 var art=k.visual.foot;var first_tip=Vector2(9,55);var rear=Vector2(350,86)
 var actual=art.source_socket(5,first_tip).distance_to(art.source_socket(5,rear))
 verify(absf(actual-first_tip.distance_to(rear)*art.scale_unit)<.02,"lowered spear remains rigid from its metal tip to the rear grip")
 var axis=preload("res://scripts/animation/knight/meteor_effects.gd").weapon_axis(k)
 verify(axis[1].y>=-48 and axis[1].y<=-10,"actual painted thrust tip is at the authored contact height")
 reset("dragon_sweep");k.t=k.spear.times("dragon_sweep")[1]+.02;k.visual.sync_pose(0)
 axis=preload("res://scripts/animation/knight/meteor_effects.gd").weapon_axis(k)
 verify(axis[1].y<=-48 and axis[1].y>=-138,"high return's painted spear sits inside its airborne contact band")
 var seen={};var far_valid=true
 for distance in [50,120,240,650]:
  for i in 100:
   reset("thrust",250+distance);k.history=[];k.choose();var id=k.pending if k.action=="switch" else k.action;seen[id]=true
   if distance==650:far_valid=far_valid and id not in ["spear_chain","dragon_sweep","dragon_rise","thrust","guard","kick_thrust"]
 for id in k.SPEAR.MOVES:verify(seen.has(id),id+" is reachable through normal distance-based AI")
 verify(far_valid,"AI never wastes a local spear technique at long range")
 reset();k.history=["dragon_break"];k.choose();verify(not k.action in k.LONG_COMBOS,"long spear routines do not chain directly into another long routine")
 reset("dragon_rise");step(.9);k.hp=1;k.take_hit(99,"player",1)
 verify(game.combat.hazards.is_empty() and game.combat.shots.is_empty(),"death removes all live spear contacts")
 reset("dragon_break");step(1);k.begin_dismount()
 verify(game.combat.hazards.is_empty() and k.action=="","transition cancels the unfinished dragon release")
 reset();k.speech_cooldown=0;k.speech_history.clear()
 verify(k.speak_event("spear_chain") and game.audio.voice_player.playing,"new spear line plays real Mandarin speech")
 var first=k.speech_history[-1];k.speech_cooldown=0
 verify(k.speak_event("spear_chain") and k.speech_history[-1]!=first,"repeated technique rotates its spoken line")
 verify(not k.speak_event("dragon_break"),"extra lines respect the existing dialogue cooldown")
 var second=k.speech_history[-1];k.speech_cooldown=0;k.speak_event("counter");k.speech_cooldown=0;k.speak_event("spear_chain")
 verify(k.speech_history[-1]!=second,"technique dialogue alternates even when another line plays between uses")
 game.audio.stop_all();game.say_line("唐牛牛在此，谁敢放肆！","niu_demon");k.speech_cooldown=0
 verify(not k.speak_event("dragon_break",true),"new spear lines preserve brother speech priority")
 for event in k.DIALOGUE.GROUPS:
  for id in k.DIALOGUE.GROUPS[event]:verify(k.DIALOGUE.LINES.has(id),"dialogue group links a real line: "+id)
 var voices_valid=true
 for id in k.DIALOGUE.LINES:
  var voice=load("res://assets/voice/knight_"+id+".wav")
  voices_valid=voices_valid and voice!=null and voice.get_length()>.5 and voice.data.size()>20000
 verify(voices_valid and k.DIALOGUE.LINES.size()==36,"all 36 knight lines have actual nonempty Mandarin PCM")
 var cue_keys=[]
 for id in k.SPEAR.MOVES:
  var profile=game.audio.ENEMY_AUDIO.profiles()["knight:"+id]
  for stage in ["warning","release","impact"]:
   var key=profile[stage];cue_keys.append(key)
   verify(game.audio.bank.has(key) and game.audio.bank[key].get_length()>.1,id+" has a distinct "+stage+" sound")
 verify(cue_keys.size()==12 and cue_keys.all(func(key):return cue_keys.count(key)==1),"all twelve spear cues have distinct asset identities")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
 print("KNIGHT_METEOR checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
