extends SceneTree
var game
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failures+=1;push_error(label)
 else:print("PASS ",label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 var p=game.player;p.combo=1;p.position=Vector2(500,450);p.facing=1
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 var audio=game.audio
 check(audio.melee_players.size()==4,"dedicated melee voices cannot be starved by ambient combat")
 audio.melee_history.clear();game.combat.melee(p);check(audio.melee_history.is_empty(),"whiff produces no contact sound")
 var previous="";var unique=true
 for i in 12:
  audio.melee_swing(1);var current=audio.melee_history.back();unique=unique and current!=previous;previous=current
 check(unique,"same swing recording never repeats consecutively")
 var targets=game.enemies.slice(0,3)
 for e in targets:e.dead=false;e.kind="pouncer";e.hp=1000;e.position=p.position+Vector2(20,0)
 audio.melee_history.clear();game.combat.melee(p)
 check(audio.melee_history.size()==1 and audio.melee_history[0].begins_with("melee_soft1_"),"three enemies yield one body impact")
 for e in targets:e.dead=true
 var shield=targets[0];shield.dead=false;shield.kind="shield";shield.facing=-1;shield.hp=1000
 audio.melee_history.clear();game.combat.melee(p)
 check(audio.melee_history.size()==1 and audio.melee_history[0].begins_with("melee_block1_"),"frontal shield produces block without extra flesh impact")
 shield.kind="guardian";p.combo=3;audio.melee_history.clear();game.combat.melee(p)
 check(audio.melee_history.size()==1 and audio.melee_history[0].begins_with("melee_stone3_"),"finisher selects heavy stone contact")
 var all_valid=true
 for family in ["swing","soft","stone","boss","block"]:
  for combo in range(1,4):
   for variant in 3:
    var sound=audio.bank["melee_"+family+str(combo)+"_"+str(variant)]
    all_valid=all_valid and sound.get_length()>.05 and sound.get_length()<.3
 check(all_valid,"all 45 edited clips imported with short tails")
 game.state="paused";audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("MELEE_AUDIO_RESULT failures=",failures);quit(failures)
