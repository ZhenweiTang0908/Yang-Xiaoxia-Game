extends SceneTree
var game
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL "+label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_challenge(4,2);await process_frame
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 verify(game.tuning.get_value("summon_cooldown")==20,"default summon cooldown is twenty seconds")
 for hp in [100,80,79,29]:
  game.state="playing";game.hitstop=0;game.player.health=hp;game.summon.reset(true)
  verify(game.summon.request(),"summon is available at health "+str(hp))
  var b=game.summon.brother;b.set_physics_process(false)
  verify(b.demon and b.art.texture.resource_path.ends_with("/bull.png") and b.demon_controller.transform_left==0,"entry starts as a bull without human or transformation")
  verify(not game.player.is_carried(),"riding waits for entrance to finish")
  game.summon._physics_process(1.2)
  verify(b.arrived and game.player.carried_by==b and is_equal_approx(game.summon.remaining,200.0/3.0),"arrival carries at every health with stamina-based lifetime")
  verify(not b.try_transform(0) and not b.become_demon() and is_equal_approx(game.summon.remaining,200.0/3.0),"old transformation calls cannot reroll or extend assistance")
  verify(game.audio.voice_identity!="niu_demon" and not game.subtitle.contains("唐牛牛"),"arrival has no old spoken introduction")
  verify(game.audio.bank.has("bull_moo") and game.audio.bank.bull_moo.get_length()>1,"bull call is a real nonempty sound asset")
  b._physics_process(.016)
  verify(is_equal_approx(game.summon.remaining,200.0/3.0),"ordinary bull update does not add an old transformation extension")
 game.summon.seal(2);var saved=game.summon.seal_resume.remaining
 game.hitstop=0;game.summon._physics_process(2);game.summon._physics_process(.4)
 verify(game.summon.phase=="active" and game.summon.brother.demon and game.summon.brother.arrived,"seal restoration always restores a bull")
 verify(game.summon.remaining==saved and not game.player.is_carried(),"seal restoration neither repeats riding nor adds duration")
 game.summon.begin_leaving();game.summon._physics_process(.8)
 verify(game.summon.phase=="cooldown" and game.summon.remaining==20,"natural departure enters twenty second cooldown")
 game.summon._physics_process(19);verify(game.summon.phase=="cooldown","cooldown is still active before twenty seconds")
 game.summon.force_cooldown();verify(game.summon.remaining==20,"eagle refreshes the full twenty second cooldown")
 game.summon._physics_process(20);verify(game.summon.phase=="ready","cooldown completes normally")
 game.summon.request();var b=game.summon.brother;b.set_physics_process(false)
 game.state="paused";game.summon._physics_process(2);verify(not b.arrived and not game.player.is_carried(),"pause cannot complete a summon")
 game.state="playing";game.hitstop=.1;game.summon._physics_process(2);verify(not b.arrived,"hitstop cannot complete a summon")
 game.hitstop=0;game.summon.reset(true);verify(not game.player.is_carried() and game.player.collision_mask==5,"cleanup leaves no orphan attachment")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("BULL_DEFAULT_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
