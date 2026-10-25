extends SceneTree
# Renders the knight's readable tells into a contact folder for review.
# Usage: Godot --path . --script tests/knight_visual.gd -- <output folder>
var game
var folder="/private/tmp/yang-knight-visual/"
func _initialize():call_deferred("run")
func shot(name):
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(folder+name+".png")
func pose(knight,id,at,prep=-1.0):
	knight.action="";knight.dismount_t=-1
	knight.begin(id,knight.prep_for(id) if prep<0 else prep)
	knight.t=0
	var dt=1.0/60
	while knight.t<at-.0001:
		game.hitstop=0;knight._physics_process(dt)
		if knight.action!=id:break
func run():
	var args=OS.get_cmdline_user_args()
	if args.size()>0:folder=args[0]
	if not folder.ends_with("/"):folder+="/"
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(false);await process_frame
	game.start_challenge();await process_frame
	var knight=game.boss;knight.set_physics_process(false);knight.active_battle=true
	game.player.set_physics_process(false);game.player.position=Vector2(330,450);game.player.facing=1
	game.combat.set_physics_process(false)
	knight.position.x=640;knight.facing=-1
	await shot("m0_idle")
	pose(knight,"charge",.35);await shot("m1_charge_prep")
	pose(knight,"charge",.64);await shot("m2_charge_couched")
	pose(knight,"charge",.8);await shot("m3_charge_run")
	knight.position.x=640;pose(knight,"rear",.6);await shot("m4_rear")
	pose(knight,"rear",.7);await shot("m5_rear_slam")
	pose(knight,"kick",.45);await shot("m6_kick_prep")
	pose(knight,"kick",.53);await shot("m7_kick")
	pose(knight,"butt",.4);await shot("m8_butt_prep")
	pose(knight,"butt",.5);await shot("m9_butt")
	knight.action="";knight.begin_dismount()
	for i in 20:game.hitstop=0;knight._physics_process(1.0/60)
	await shot("d1_rise")
	for i in 22:game.hitstop=0;knight._physics_process(1.0/60)
	await shot("d2_leap")
	for i in 14:game.hitstop=0;knight._physics_process(1.0/60)
	await shot("d3_land_dust")
	game.state="playing"
	knight.dismount_t=-1;knight.phase_shift=0;knight.horse_away=-1;knight.dust_age=-1
	knight.position.x=600;knight.facing=-1
	await shot("f0_idle")
	pose(knight,"thrust",.4);await shot("f1_thrust_prep")
	pose(knight,"thrust",.5);await shot("f2_thrust")
	pose(knight,"butt_spin",.45);await shot("f3_buttspin_prep")
	pose(knight,"guard",.3);await shot("f4_guard")
	knight.wave_uses=0;pose(knight,"wave",.15);await shot("f5_wave_raise")
	pose(knight,"wave",.36);await shot("f6_wave_retract")
	pose(knight,"wave",.44);await shot("f7_wave_release")
	knight.weapon="bow";pose(knight,"bow",.6);await shot("f8_bow_draw")
	knight.weapon="sword";pose(knight,"draw_slash",.4);await shot("f9_sword_grip")
	pose(knight,"draw_slash",.5);await shot("fa_sword_slash")
	pose(knight,"drag",.5);await shot("fb_drag")
	pose(knight,"drag",1.1);await shot("fc_drag_raise")
	pose(knight,"drag",1.2);await shot("fd_drag_strike")
	knight.weapon="spear";knight.next_weapon="bow";knight.pending="bow";pose(knight,"switch",.25,.5);await shot("fe_switch")
	game.summon.seal(7);for i in 40:game.summon._physics_process(1.0/60)
	await shot("g1_sealed_hud")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
