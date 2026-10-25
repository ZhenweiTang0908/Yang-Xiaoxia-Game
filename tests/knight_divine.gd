extends SceneTree
var game
var k
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func reset():
 game.state="playing";game.hitstop=0;game.progress.journey_mode="standard";game.combat.clear();game.summon.reset(true)
 k.soul.clear_attacks();k.soul.spend();k.end_box();k.ancient_pending=null;k.ancient_target=null;k.action="";k.pending="";k.t=0;k.phase=2;k.phase_shift=0;k.dismount_t=-1;k.dead=false;k.active_battle=true;k.hp=2400;k.max_hp=2400;k.weapon="spear";k.position=Vector2(250,450);k.facing=1;k.idle=100;k.speech_cooldown=100;k.recover_time=0
 game.player.position=Vector2(650,450);game.player.velocity=Vector2.ZERO;game.player.health=100;game.player.invincible=0;game.player.roll_guard=0;game.player.soul_slow=0
func ally_active():
 game.summon.request();game.summon.phase="active";game.summon.remaining=30
 var ally=game.summon.brother;ally.set_physics_process(false);ally.position=Vector2(500,450);ally.invincible=0
 return ally
func step(seconds):
 for i in int(round(seconds*120)):
  game.hitstop=0;k._physics_process(1.0/120);game.combat._physics_process(1.0/120)
func arrow(kind="knight_arrow"):
 var shot=game.combat.fire(game.player.position-Vector2(25,21),Vector2(600,0),5,"enemy",kind,{"owner":k.get_instance_id()})
 shot.seal=3;shot.attack_sound="knight:bow"
 game.hitstop=0;game.combat._physics_process(.05)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_challenge(4,2);await process_frame
 k=game.boss;game.set_process(false);game.set_physics_process(false);k.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 reset();verify(k.cfg("knight_rage_release")==75,"default release probability is 75 percent")
 k.soul.absorb(96,.74);verify(k.soul.release_ready,"first completed cell releases at roll below 75 percent")
 k.begin("thrust",.45);verify(k.empowered and k.soul.rage==0,"one cell empowers next attack and consumes all rage")
 reset();k.soul.absorb(96,.75);verify(not k.soul.release_ready and k.soul.rage==1,"boundary roll holds the first cell")
 for i in 20:k.begin("thrust",.45)
 verify(not k.empowered and k.soul.rage==1,"starting attacks does not reroll a held cell")
 k.soul.absorb(96,.74);verify(k.soul.ready_cells()==2,"second completed cell can request a two-cell release")
 k.choose();verify(k.action=="soul_legion" and k.soul.rage==0,"two cells summon the ghost regiment")
 step(1.01)
 verify(k.action=="" and k.soul.legion.size()==7,"boss releases its summon action while seven soldiers remain")
 verify(k.soul.legion.filter(func(u):return u.kind=="archer").size()==3 and k.soul.legion.filter(func(u):return u.kind=="spear").size()==3 and k.soul.legion.filter(func(u):return u.kind=="blade").size()==1,"regiment has three archers, three spears and one blade")
 var archers=k.soul.legion.filter(func(u):return u.kind=="archer");var fixed_x=archers.map(func(u):return u.p.x)
 k.weapon="spear";k.begin("lunge",k.prep_for("lunge"));var before=k.position.x;step(.95)
 verify(k.position.x>before+40 and not k.soul.legion.is_empty(),"boss attacks and moves while soldiers execute independently")
 var spears=k.soul.legion.filter(func(u):return u.kind=="spear")
 verify(spears.all(func(u):return u.box==null or is_equal_approx(u.box.damage,12)),"spear ghosts deal the requested 12 damage")
 step(1.4)
 verify(archers.map(func(u):return u.p.x)==fixed_x,"three archers stay at their summoned horizontal positions")
 verify(spears.all(func(u):return absf(u.travel-k.arena.size.x/3)<.1 and u.hits==1),"three spears each travel one third arena and attack once")
 verify(game.combat.shots.any(func(s):return s.kind=="soul_arrow"),"stationary archers fire real projectiles")
 reset();game.player.invincible=0;k.soul.begin_legion()
 k.soul.legion=k.soul.legion.filter(func(u):return u.kind=="blade")
 k.soul.advance(1.10)
 var blade=k.soul.legion[0]
 verify(blade.locked and blade.p.x<game.player.position.x and blade.hits==0,"blade appears behind the hero before releasing its attack")
 k.soul.advance(.5);game.hitstop=0;game.combat._physics_process(.02)
 verify(game.player.health==88,"blade's actual hit causes twelve damage")
 game.hitstop=0;game.player.invincible=0;game.combat._physics_process(.02)
 verify(game.player.health==88,"blade's single swing cannot hit twice")
 reset();k.soul.absorb(96,.99);k.soul.absorb(96,.99);verify(not k.soul.release_ready,"two high rolls retain two cells")
 k.soul.absorb(96,.99);verify(k.soul.ready_cells()==3,"third cell always releases regardless of roll")
 k.weapon="spear";k.choose();verify(k.action=="soul_legion" and k.legion_strong and k.soul.rage==0,"three cells summon the reinforced regiment instead of the old eagle")
 var ally=ally_active();var hero_hp=game.player.health
 step(1.01)
 var strong=k.soul.legion
 verify(strong.size()==9 and strong.filter(func(u):return u.kind=="spear").size()==4 and strong.filter(func(u):return u.kind=="blade").size()==2,"reinforced regiment adds a fourth spear and a second blade")
 verify(strong.all(func(u):return u.strong and is_equal_approx(k.soul.unit_damage(u),14)),"reinforced units are empowered and strike for 14")
 verify(game.summon.phase=="active" and game.summon.brother==ally and game.player.health==hero_hp,"regiment arrival neither recalls the ally nor deals fixed arena damage")
 reset();game.player.facing=1;k.soul.begin_legion(true)
 k.soul.legion=k.soul.legion.filter(func(u):return u.kind=="blade")
 k.soul.advance(1.3);var first=k.soul.legion[0];var second=k.soul.legion[1]
 verify(first.locked and first.p.x<game.player.position.x and not second.locked,"first reinforced blade appears behind the hero")
 k.soul.advance(.6)
 verify(second.locked and second.p.x>game.player.position.x,"second blade arrives later in front of the hero")
 verify(not "soul_eagle_burst" in k.TITLES,"arena-wide eagle has been retired")
 reset();k.begin("lunge",k.prep_for("lunge"));verify(is_equal_approx(k.windup,k.cfg("knight_lunge_windup")),"dash wind-up keeps its original reaction window")
 step(k.prep_for("lunge")+.02)
 verify(k.hit_box!=null and is_equal_approx(k.hit_box.damage,k.cfg("knight_lunge_damage")*k.cfg("knight_damage_scale")*1.08),"dash strikes deal about eight percent more")
 reset();game.summon.reset(false);game.summon.force_cooldown()
 verify(game.summon.phase=="locked" and not game.summon.unlocked,"forced recall cannot unlock an unavailable gourd")
 reset();ally=ally_active();verify(k.on_ally_hit(ally,"knight:thrust",.149),"ancient weapon triggers below 15 percent")
 verify(not k.on_ally_hit(ally,"knight:thrust",0),"queued ancient weapon does not stack")
 k.choose();verify(k.action=="ancient_spear","accepted proc starts ancient weapon on next action")
 step(1.12);verify(ally.pinned_left==10 and ally.pending_skill=="","divine spear pins and cancels attacks for ten seconds")
 var anchor=ally.position;ally.velocity=Vector2(200,-400);ally._physics_process(.5)
 verify(ally.position==anchor and ally.velocity==Vector2.ZERO and is_equal_approx(ally.pinned_left,9.5),"pinned ally remains stationary while timer advances")
 game.player.health=10;verify(not ally.try_transform(0),"pinned ally cannot transform or start a rescue")
 ally._physics_process(9.5);verify(ally.pinned_left==0,"movement lock expires after exactly ten active seconds")
 reset();ally=ally_active();verify(not k.on_ally_hit(ally,"knight:thrust",.15),"15 percent boundary does not trigger")
 ally.invincible=2
 verify(not ally.take_damage(10,0,"knight:thrust",k.get_instance_id()) and k.ancient_pending==null,"invulnerable ally does not proc on a rejected hit")
 ally.invincible=0;seed(3)
 verify(ally.take_damage(1,0,"knight:thrust",k.get_instance_id()),"actual knight damage enters ally hit handling")
 reset();ally=ally_active();ally.pin(10);k.soul.clear_attacks();verify(ally.pinned_left==0,"cancelled boss attacks release the divine binding")
 reset();ally=ally_active();game.player.position.x=900;seed(251025)
 var procs=0
 for i in 300:
  game.hitstop=0;game.combat.clear();ally.invincible=0;ally.health=50;k.ancient_pending=null
  var h=game.combat.hazard(ally.hurt_rect(),0,.1,1,k.get_instance_id(),"knight_thrust");h.sounded=true;h.attack_sound="knight:thrust"
  game.combat._physics_process(.01)
  if k.ancient_pending==ally:procs+=1
 verify(procs>=28 and procs<=65,"real owned hazard hits trigger near fifteen percent ("+str(procs)+"/300)")
 k.ancient_pending=null;ally.invincible=0
 game.combat.clear();var other=game.combat.hazard(ally.hurt_rect(),0,.1,1,0,"zone");other.sounded=true
 game.combat._physics_process(.01)
 verify(k.ancient_pending==null,"unrelated damage cannot trigger the knight's divine weapon")
 reset();ally=ally_active();ally.pin(10);k.hp=1;k.take_hit(5,"brother",1)
 verify(ally.pinned_left==0 and k.dead,"boss death removes the active binding")
 reset();ally=ally_active();ally.pin(10);k.begin_dismount()
 verify(ally.pinned_left==0 and k.ancient_pending==null,"phase transition clears binding and queued followup")
 reset();ally=ally_active();arrow()
 verify(game.summon.phase=="active" and game.summon.brother==ally and game.summon.remaining==22,"hero arrow hit subtracts eight seconds without dismissing the ally")
 game.player.invincible=0;game.summon.remaining=4;arrow("soul_arrow")
 verify(game.summon.phase=="active" and game.summon.remaining==1,"soul arrow also drains assist but leaves a departure grace second")
 reset();arrow();verify(game.summon.is_sealed() and game.summon.sealed==2,"arrow seals an absent ally for two seconds")
 reset();game.summon.request();var entering=game.summon.brother;entering.set_physics_process(false);arrow()
 verify(game.summon.phase=="entering" and game.summon.entry_penalty==8,"arrow during entrance queues a time penalty without removing the ally")
 game.hitstop=0;game.summon._physics_process(1.2)
 verify(game.summon.phase=="active" and game.summon.remaining==22,"entrance penalty applies to real assist duration")
 reset();ally=ally_active();game.player.invincible=2;arrow()
 verify(game.summon.remaining==30 and game.summon.phase=="active","dodged arrow causes no assist penalty")
 reset();game.summon.seal(10);game.summon.arrow_hit();verify(game.summon.sealed==10,"arrow cannot shorten an existing dust seal")
 reset();ally=ally_active();ally.become_demon(true);ally.demon_controller.carrying=true;game.player.attach_to(ally);ally.pin(10)
 verify(not game.player.is_carried() and ally.pinned_left==10,"binding safely releases an existing rider")
 for identity in ["knight:soul_eagle_burst","knight:ancient_spear"]:
  for sound in game.audio.ENEMY_AUDIO.profiles()[identity].values():verify(game.audio.bank.has(sound) and game.audio.bank[sound]!=null,"sound asset loaded: "+sound)
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("KNIGHT_DIVINE checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
