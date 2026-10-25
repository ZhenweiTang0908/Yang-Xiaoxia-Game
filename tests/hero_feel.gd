extends SceneTree
# Sheep-spirit rates and multipliers, hold-to-charge, charge damage guard,
# hurt reaction timing and the boss-rush interstitial reward.
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func prepare(sheep):
 game.release_inputs();game.hitstop=0;game.combat.clear()
 var p=game.player;p.reset(Vector2(300,450),true);p.invincible=0;p.facing=1
 if sheep:p.sheep_time=10;p.set_form_art(true)
 var b=game.boss;b.active_battle=true;b.dead=false;b.phase_shift=0;b.hp=b.max_hp;b.position=p.position+Vector2(45,0)
 return p
func tick(p,seconds):
 var remaining=seconds
 while remaining>0:
  var dt=minf(.01,remaining);game.hitstop=0;p._physics_process(dt);remaining-=dt
func melee_damage(sheep,combo):
 var p=prepare(sheep);p.combo=combo;var b=game.boss;var before=b.hp
 game.combat.melee(p);return before-b.hp
func blast_damage(sheep):
 var p=prepare(sheep);var b=game.boss;var before=b.hp;p.rage=0
 game.combat.blast(p,.5);return before-b.hp
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new()
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.boss.set_physics_process(false)
 await process_frame
 for combo in [1,2,3]:
  var hero=melee_damage(false,combo);var sheep=melee_damage(true,combo)
  verify(is_equal_approx(sheep,hero*1.4),"sheep melee hit "+str(combo)+" deals 1.4x the hero ("+str(sheep)+" vs "+str(hero)+")")
 var hero_blast=blast_damage(false);var sheep_blast=blast_damage(true)
 verify(is_equal_approx(sheep_blast,hero_blast*1.5),"sheep charged blast deals 1.5x the hero")
 var p=prepare(true);game.combat.player_shot(p)
 verify(is_equal_approx(game.combat.shots[-1].damage,23*1.4),"sheep flame deals 1.4x the hero arrow")
 # Attack rate: the sheep reaches each timing 1.3x sooner.
 p=prepare(true);p.combo=0;p.combo_window=0;p.start_attack();tick(p,.1)
 verify(is_equal_approx(p.attack_elapsed,.13),"sheep slash timeline advances 1.3x faster")
 p=prepare(false);p.combo=0;p.combo_window=0;p.start_attack();tick(p,.1)
 verify(is_equal_approx(p.attack_elapsed,.1),"hero slash timeline stays at normal speed")
 # Ranged: cooldown only, never waiting for the previous flame to leave the screen.
 p=prepare(true);p.enqueue("bow");tick(p,.01)
 verify(is_equal_approx(p.bow_cd,.48/1.3),"sheep ranged cooldown is the hero's divided by 1.3")
 tick(p,.48/1.3+.05);p.enqueue("bow");tick(p,.12)
 var flames=game.combat.shots.filter(func(s):return s.kind=="flame")
 verify(flames.size()==2,"a second flame fires while the first is still in flight")
 # Hold attack to charge; the U key is no longer bound.
 verify(InputMap.action_get_events("charge").is_empty(),"charge has no dedicated key")
 p=prepare(false);Input.action_press("attack");p.enqueue("attack");tick(p,.05)
 verify(p.attack_elapsed>=0 and p.charge==0,"pressing attack slashes immediately")
 tick(p,.6)
 verify(p.charge>0,"keeping attack held starts a charge after the slash")
 Input.action_release("attack");var charged=p.charge;tick(p,.02)
 verify(p.charge==0 and (charged<.32 or p.blast_anim>0),"releasing attack ends the charge")
 p=prepare(false);p.charge=.5;var hp=p.health;p.take_damage(20,1.0)
 verify(is_equal_approx(hp-p.health,17),"damage taken while charging is reduced to 85%")
 p=prepare(true);p.charge=.5;hp=p.health;p.take_damage(20,1.0)
 verify(is_equal_approx(hp-p.health,17),"sheep charge guard also takes 85%")
 # Hurt reaction keeps easing out after control returns.
 p=prepare(false);p.take_damage(5,-1.0)
 verify(p.hurt_time==0 and p.hurt_push==-1.0,"a frontal hit knocks the hero back")
 p.invincible=0;tick(p,.3)
 verify(p.hurt_anim==0 and p.hurt_time>0 and p.hurt_weight()>0,"recovery pose outlasts the 0.22 s control lock")
 tick(p,.2);verify(p.hurt_time<0,"hurt recovery finishes")
 p=prepare(false);p.facing=1;p.take_damage(5,1.0);verify(p.hurt_push==1.0,"a hit from behind pitches the hero forward")
 # Awakening has no HUD gauge; the aura overlay lives on the hero.
 var aura=p.get_children().filter(func(c):return c.get_script()!=null and str(c.get_script().resource_path).ends_with("awaken_aura.gd"))
 verify(aura.size()==1,"awakening aura is attached to the hero")
 game.audio.stop_all();game.queue_free();await process_frame
 print("HERO_FEEL_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
