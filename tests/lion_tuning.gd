extends SceneTree
const BALANCE=preload("res://scripts/core/balance.gd")
const PATH="res://builds/qa/lion-tuning-test.json"
var checks=0
var failures=[]
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var tuning=BALANCE.new();tuning.reset()
	tuning.apply({"lion_phase_fraction":.2,"lion_finale_fraction":.5,"lion_M20_0_time":4.9,"lion_M20_1_time":.4,"lion_M20_2_time":.4,"lion_M14_range_min":180,"lion_M14_range_max":60,"lion_M13_0_low":150,"lion_M13_0_high":10,"lion_M15_0_near":100,"lion_M15_0_far":-100})
	verify(tuning.get_value("lion_finale_fraction")<=tuning.get_value("lion_phase_fraction"),"finale follows uncovered phase")
	verify(tuning.get_value("lion_M20_1_time")>=tuning.get_value("lion_M20_0_time")+.399,"second contact follows first window")
	verify(tuning.get_value("lion_M20_2_time")>=tuning.get_value("lion_M20_1_time")+.399,"third contact follows second window")
	verify(tuning.get_value("lion_M14_range_max")>=tuning.get_value("lion_M14_range_min"),"selection range ordered")
	verify(tuning.get_value("lion_M13_0_high")>tuning.get_value("lion_M13_0_low"),"height cap has area")
	verify(tuning.get_value("lion_M15_0_far")>tuning.get_value("lion_M15_0_near"),"horizontal cap has area")
	DirAccess.make_dir_recursive_absolute("res://builds/qa")
	verify(tuning.save_settings(PATH),"write isolated tuning file")
	var restored=BALANCE.new();restored.reset();restored.load_settings(PATH)
	for key in tuning.values:
		if key.begins_with("lion_"):verify(is_equal_approx(restored.get_value(key),tuning.get_value(key)),"persist "+key)
	DirAccess.remove_absolute(PATH)
	print("LION_TUNING_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
