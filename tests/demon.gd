extends SceneTree
var game
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error("FAIL "+label)
func frames(count):
 for i in count:await physics_frame
 await process_frame
func summon_now():
 game.summon.reset(true);game.summon.request();game.summon.phase="active";game.summon.remaining=30
 return game.summon.brother
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.tuning.reset();game.start_new(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 await frames(5)
 var p=game.player;var tune=game.tuning
 verify(tune.probability(80)==0,"80 HP never transforms")
 verify(is_equal_approx(tune.probability(79),.05),"79 HP uses 5 percent")
 verify(is_equal_approx(tune.probability(30),.05),"30 HP still uses 5 percent")
 verify(is_equal_approx(tune.probability(29),.30),"29 HP uses 30 percent")
 var b=summon_now();b.set_physics_process(false)
 verify(b.health==50 and not b.demon,"normal summon has 50 HP")
 p.health=79;verify(not b.try_transform(.051),"roll above 5 percent fails")
 verify(b.try_transform(.049),"roll below 5 percent transforms")
 verify(b.demon and b.demon_controller.rig.art.columns==4 and b.body_height==52,"quadruped bull sprite and low body collider")
 verify(game.summon.remaining==60,"adds exactly 30 seconds once")
 verify(not b.become_demon() and game.summon.remaining==60,"cannot extend twice")
 verify(p.is_carried() and p.collision_mask==0,"carried hero detached from terrain physics")
 var dc=b.demon_controller;dc.set_process(false)
 verify(game.subtitle=="唐牛牛在此，谁敢放肆！" and game.audio.voice_player.playing,"transformation subtitle and offline voice")
 var saved=game.summon.remaining;game.state="paused";await frames(20)
 verify(game.summon.remaining==saved and dc.carry_age==0,"pause freezes carry and lifetime")
 game.state="playing";p.health=29;dc.transform_left=0
 for i in 300:dc.tick(1.0/60)
 # Floating accumulation may land just below the fifth tick; one small step makes the boundary explicit.
 dc.tick(.001)
 verify(p.health==44 and dc.heal_ticks==5,"five healing ticks restore 15 total")
 verify(p.is_carried(),"hero still carried after five seconds")
 for i in 121:dc.tick(1.0/60)
 verify(not p.is_carried() and p.collision_mask==5,"hero safely released at seven seconds")
 verify(p.health==44,"healing stops after five ticks")
 b.invincible=0;b.health=50;b.take_damage(10)
 verify(is_equal_approx(b.health,43.5),"demon takes damage with configured reduction")
 b.take_damage(10);verify(is_equal_approx(b.health,43.5),"ally invulnerability prevents repeated damage")
 b.heal_on_hit();verify(is_equal_approx(b.health,44.5),"demon hit restores one health")
 b.health=50;b.heal_on_hit();verify(b.health==50,"self-heal respects 50 maximum")
 # Exactly three local targets hit; distant mobs remain untouched.
 b.position=Vector2(200,450);b.facing=1;b.health=40;dc.rush_hits.clear()
 var near=[]
 for i in 5:
  var e=game.enemies[i];e.dead=false;e.hp=200;e.position=Vector2(230+i*12,450);near.append(e)
 var distant=game.enemies[5];distant.dead=false;distant.hp=200;distant.position=Vector2(500,450)
 dc.strike(b.position)
 verify(near.filter(func(e):return e.hp<200).size()==3,"single strike limited to three enemies")
 verify(distant.hp==200,"strike does not clear distant enemies")
 verify(b.health==43,"one self-heal per actual target hit")
 dc.strike(b.position)
 verify(b.health==43,"one rush cannot hit or self-heal twice on same enemy")
 verify(game.combat.shots.is_empty(),"bull has no trident or magical card attacks")
 game.combat.clear();dc.carrying=false;var old=b.position
 dc.begin_lock(near[0]);verify(dc.lock_left>=.74 and b.position==old,"blink locks before moving")
 dc.lock_left=0;var before_hit=near[0].hp;dc.complete_blink();verify(b.position.x>near[0].position.x,"blink arrives behind facing-left enemy")
 verify(near[0].hp==before_hit and dc.rush_left>0,"blink starts physical charge without instant damage")
 old=b.position
 var health_before=near.map(func(e):return e.hp)
 for i in 15:dc.tick(1.0/60)
 var charge_hit=false
 for i in near.size():charge_hit=charge_hit or near[i].hp<health_before[i]
 verify(b.position.x<old.x and charge_hit,"charge travels and hits enemies through body contact")
 verify(not dc.landing_clear(Vector2(100,470)),"blink rejects landing inside solid ground")
 dc.begin_lock(near[0]);near[0].dead=true;old=b.position;dc.complete_blink()
 verify(b.position==old,"dead lock target cancels teleport")
 for e in game.enemies:e.dead=true
 # Entry/exit never revert a demon early; the next summon starts normal.
 game.summon.begin_leaving();verify(b.demon,"demon remains demon during exit")
 await frames(51);verify(game.summon.phase=="cooldown" and game.summon.remaining>99,"cooldown begins only after exit")
 b=summon_now();b.set_physics_process(false);verify(not b.demon and b.health==50,"next summon returns to full-health normal form")
 # Enemy projectiles and hazards can injure the ally, independently of the player.
 b.position=Vector2(240,450);p.position=Vector2(420,450);b.invincible=0
 game.combat.fire(Vector2(180,410),Vector2(900,0),10,"enemy")
 await frames(6)
 verify(b.health==40,"enemy projectile damages normal ally")
 b.invincible=0;game.combat.hazard(Rect2(220,395,45,55),0,.1,8)
 await frames(2)
 verify(b.health==32,"enemy ground attack damages ally")
 game.combat.clear()
 var victim=game.enemies[0];victim.dead=false;victim.hp=999;victim.position=Vector2(350,450)
 p.health=79;game.tuning.apply({"proc_chance":0})
 var count=b.roll_count;b.queue_cast("fan",victim);b._physics_process(.15)
 verify(b.roll_count==count+1 and not b.demon,"three-card cast makes only one transformation roll")
 game.combat.clear();victim.dead=true;game.tuning.reset()
 b.health=40;b.heal_on_hit();verify(b.health==40,"normal form does not gain demon lifesteal")
 b.invincible=0;b.take_damage(10);verify(b.health==30,"normal form takes full damage")
 p.health=29;b.become_demon();b.invincible=0;b.take_damage(1000)
 verify(b.dead and game.summon.phase=="leaving" and not p.is_carried(),"ally death drops hero and starts exit")
 b=summon_now();b.set_physics_process(false);b.become_demon();game.summon.reset(true)
 verify(not p.is_carried() and game.summon.phase=="ready","reset clears riding attachment")
 b=summon_now();b.become_demon();game.load_stage(2,0)
 verify(not game.player.is_carried() and game.summon.brother==null,"stage change clears demon and carried state")
 game.debug_panel.toggle();verify(game.state=="debug" and game.debug_panel.spins.has("rush_speed") and game.debug_panel.spins.has("rush_windup"),"debug window exposes charge speed and anticipation")
 game.debug_panel.spins.proc_chance.get_line_edit().text="100";game.debug_panel.apply_values()
 verify(game.tuning.probability(79)==1,"debug probability applies")
 game.debug_panel.defaults();game.debug_panel.apply_values();game.debug_panel.close()
 verify(game.state=="playing" and is_equal_approx(game.tuning.probability(79),.05),"debug defaults and resume")
 verify(game.audio.voice_player.stream.get_length()>2,"voice is nonempty playable PCM")
 game.state="paused";game.audio.stop_all();game.free();await process_frame;await process_frame
 OS.delay_msec(200)
 print("DEMON_RESULT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
