extends SceneTree
var failures=[]
var checks=0
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="/private/tmp/yang-save-store-test.json"

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func cleanup():
	for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
		var path=PATH+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func run():
	cleanup()
	var first=STORE.defaults();first.level=2;first.music=.4
	verify(STORE.write_save(first,PATH),"initial save succeeds")
	verify(STORE.read_save(PATH).level==2,"initial save reads back")
	var second=STORE.defaults();second.level=3;second.checkpoint=2;second.screen_shake=false;second.journey_mode="relaxed";second.upgrades=["blade","spirit"];second.pending_upgrade={"level":3,"checkpoint":2};second.relics=["moon_1_roof"];second.records={"1":{"standard":{"completions":1,"best_seconds":90.0,"best_kills":20,"best_clears":3}}}
	verify(STORE.write_save(second,PATH),"replacement save succeeds")
	var replacement=STORE.read_save(PATH)
	verify(replacement.level==3 and not replacement.screen_shake and replacement.journey_mode=="relaxed","replacement and accessibility settings read back")
	verify(replacement.upgrades==["blade","spirit"] and replacement.pending_upgrade.checkpoint==2,"upgrade choices and pending decision read back")
	verify(replacement.relics==["moon_1_roof"],"permanent relic collection reads back")
	verify(replacement.records["1"].standard.best_seconds==90.0,"journey records read back")
	verify(STORE.read_save(PATH+STORE.BACKUP_SUFFIX).level==2,"previous valid save becomes backup")
	var corrupt=FileAccess.open(PATH,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close()
	var recovered=STORE.read_save(PATH)
	verify(recovered.level==2 and recovered.screen_shake and is_equal_approx(recovered.music,.4),"corrupt primary recovers backup and defaults")
	cleanup()
	var legacy=FileAccess.open(PATH,FileAccess.WRITE);legacy.store_string(JSON.stringify({"version":2,"hero_mesh":false}));legacy.close()
	verify(not STORE.read_save(PATH).hero_mesh and STORE.read_save(PATH).boss_voice=="ai","legacy save migrates once to 2D and AI")
	var preference=STORE.defaults();preference.hero_mesh=false
	verify(STORE.write_save(preference,PATH) and not STORE.read_save(PATH).hero_mesh,"later explicit legacy animation choice is preserved")
	cleanup()
	print("SAVE_STORE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
