extends SceneTree
var game
var records=[]
var baseline=false
func _initialize():call_deferred("run")
func freeze(node):
 node.set_process(false);node.set_physics_process(false)
 for child in node.get_children():freeze(child)
func run():
 baseline="--baseline" in OS.get_cmdline_user_args()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.set_process(false);game.set_physics_process(false)
 for sample in 24:
  seed(510+sample);game.jump_to_stage(2,0);game.set_process(false);game.set_physics_process(false)
  var b=game.boss
  if baseline:
   game.enemies.erase(b);b.free();b=load("res://scripts/actors/boss.gd").new();b.setup(game,"duelist",700);b.spec=load("res://tests/fixtures/duelist_before_reset.tres");game.world.add_child(b);game.enemies.append(b);game.boss=b
  var p=game.player;p.set_physics_process(false);b.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
  freeze(game)
  b.active_battle=true;b.cooldown=1;p.position=Vector2(430,450);p.health=100;game.progress.tonic=2
  await physics_frame;await process_frame
  var t=0.0;var dealt=0.0;var received=0.0;var moves=0;var last_move=-1;var mode=sample%3;var attack_left=0.0;var bow_left=0.0;var roll_left=0.0;var healed=0
  for frame in 7200:
   await physics_frame
   var dt=1.0/60;t+=dt;game.hitstop=0
   p.invincible=maxf(0,p.invincible-dt);p.roll_guard=maxf(0,p.roll_guard-dt);p.rage=maxf(0,p.rage-3.5*dt)
   attack_left-=dt;bow_left-=dt;roll_left-=dt
   var side=1.0 if int(t/(2.3+mode*.4))%2==0 else -1.0
   var distance=42.0 if mode==0 else (92.0 if b.windup>0 and mode==1 else (190.0 if mode==2 else 46.0))
   p.position.x=move_toward(p.position.x,clampf(b.position.x+side*distance,30,930),225*dt)
   var jump=fposmod(t+sample*.2,2.2+mode*.25)
   p.position.y=450-maxf(0,520*jump-540*jump*jump) if jump<.963 else 450
   p.facing=1 if b.position.x>=p.position.x else -1
   if mode==1 and b.windup>0 and b.windup<.18 and roll_left<=0:p.invincible=.23;p.roll_guard=.23;roll_left=.7
   var before=b.hp
   if attack_left<=0 and absf(p.position.x-b.position.x)<68:
    p.combo=1+int(t*2.4)%3;game.combat.melee(p);attack_left=.42 if mode==0 else .58
   if bow_left<=0 and mode!=0:game.combat.player_shot(p);bow_left=.48 if mode==2 else 1.1
   dealt+=maxf(0,before-b.hp)
   if p.health<40 and game.tonic_count()>0:game.use_tonic();healed+=1
   var health=p.health
   b._physics_process(dt);game.hitstop=0;game.combat._physics_process(dt)
   received+=maxf(0,health-p.health)
   if b.move_index!=last_move:last_move=b.move_index;moves+=1
   if b.dead or p.health<=0:break
   if frame%60==0:await process_frame
  print("BALANCE_SAMPLE ",sample," elapsed=",t)
  records.append({"seed":510+sample,"mode":mode,"seconds":snappedf(t,.01),"won":b.dead,"lost":p.health<=0,"damage_received":snappedf(received,.01),"boss_hp":snappedf(b.hp,.01),"moves":moves,"potions":healed})
 DirAccess.make_dir_recursive_absolute("res://builds/qa")
 var path="res://builds/qa/boss-reset-duelist-"+("baseline" if baseline else "after")+".json"
 var file=FileAccess.open(path,FileAccess.WRITE)
 if file==null:push_error("cannot save balance evidence");quit(1);return
 file.store_string(JSON.stringify({"harness":1,"runs":records},"  "));file.close()
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("BOSS_RESET_BALANCE_RESULT baseline=",baseline," runs=",records);quit()
