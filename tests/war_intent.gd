extends SceneTree
var game
var victim
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL "+label)
func prepare(amount,sheep=false):
 game.release_inputs();game.state="playing";game.hitstop=0;game.combat.clear();game.fx.clear()
 var p=game.player;p.reset(Vector2(500,450),true);p.facing=1;p.rage=amount;p.dash_victims.clear()
 if sheep:p.sheep_time=10;p.set_form_art(true)
 for e in game.enemies:e.dead=true
 victim.dead=false;victim.kind="imp";victim.hp=10000;victim.position=p.position+Vector2(28,0)
 return p
func damage(action,amount,sheep):
 var p=prepare(amount,sheep)
 match action:
  "melee":p.combo=1;game.combat.melee(p)
  "spin","rising":game.combat.command_attack(p,action)
  "blast":game.combat.blast(p,.6)
  "horn":game.combat.horn(p)
  "arrow":game.combat.player_shot(p)
  "wave":game.combat.command_attack(p,"wave")
  "finisher_wave":p.combo=3;game.combat.melee(p)
 if action in ["arrow","wave","finisher_wave"]:
  verify(not game.combat.shots.is_empty(),action+" emits projectile")
  if game.combat.shots.is_empty():return -1.0
  return game.combat.shots[0].damage
 return 10000-victim.hp
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 var candidates=game.enemies.filter(func(e):return e.kind!="boss")
 verify(not candidates.is_empty(),"has ordinary combat target")
 if candidates.is_empty():quit(1);return
 victim=candidates[0]
 for sheep in [false,true]:
  for action in ["melee","spin","rising","blast","horn","arrow","wave","finisher_wave"]:
   if action in ["horn","finisher_wave"] and not sheep:continue
   var base=damage(action,0,sheep)
   verify(base>0,action+" has base damage")
   for amount in [50,100]:
    var actual=damage(action,amount,sheep)
    verify(absf(actual-base*(1+.25*amount/100.0))<.002,action+" scales at "+str(amount)+" sheep="+str(sheep))
 var p=prepare(100);game.combat.player_shot(p);var shot=game.combat.shots[0];p.rage=0
 verify(is_equal_approx(shot.damage,23*1.25),"flying shot keeps release-time multiplier")
 var hp=victim.hp;game.combat._physics_process(.02)
 verify(absf(hp-victim.hp-23*1.25)<.002,"projectile impact uses snapshotted damage after intent falls")
 if candidates.size()>1:
  p=prepare(50);p.combo=1
  var second=candidates[1];second.dead=false;second.kind="imp";second.hp=10000;second.position=p.position+Vector2(32,0)
  game.combat.melee(p)
  verify(absf(victim.hp-second.hp)<.002 and absf(10000-victim.hp-27)<.002,"one swing uses the same multiplier for every target despite hit rewards")
 prepare(100);var hostile=game.combat.fire(Vector2.ZERO,Vector2.ZERO,20,"enemy")
 verify(hostile.damage==20,"enemy damage is unaffected")
 p=prepare(100);victim.dead=true;p.enqueue("sprint");p._physics_process(0)
 verify(p.sprinting and is_equal_approx(p.rage,90),"successful sprint spends ten percent of current intent")
 p.enqueue("sprint");p._physics_process(0);verify(is_equal_approx(p.rage,90),"cooldown-blocked sprint spends nothing")
 p.dash_cd=0;p.dash_time=0;p.enqueue("sprint");p._physics_process(0)
 verify(is_equal_approx(p.rage,81),"second sprint spends nine rather than ten points")
 p=prepare(80);victim.dead=true;p.enqueue("dash");p._physics_process(0)
 verify(not p.sprinting and p.rage==80,"roll does not spend intent")
 p=prepare(75);game.state="paused";p.enqueue("sprint");p._physics_process(0)
 verify(p.rage==75,"paused input spends nothing")
 game.state="playing";p.rage=50;p.form_transition=.4;p.enqueue("sprint");p._physics_process(0)
 verify(p.rage==50,"form-transition-blocked sprint spends nothing")
 game.summon.reset(true);game.summon.request();game.summon.phase="active"
 var ally=game.summon.brother
 verify(is_instance_valid(ally),"has mount for blocked sprint check")
 if not is_instance_valid(ally):quit(1);return
 ally.set_physics_process(false);ally.arrive();p.form_transition=0;p.rage=60;p.enqueue("sprint");p._physics_process(0)
 verify(p.is_carried() and p.rage==60,"mounted sprint input spends nothing")
 game.summon.reset(true)
 for symbol in ["血","量","战","意","月","露","×"]:
  verify(game.font.has_char(symbol.unicode_at(0)),"HUD font contains "+symbol)
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("WAR_INTENT_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
