extends SceneTree
# Every authored lion line group must be reachable from shipping code. A recorded
# line nobody triggers is dead content, not coverage.
const DIALOGUE="res://data/voice/boss_dialogue.json"
const SOURCES=["res://scripts/actors/lion_moves.gd","res://scripts/actors/lion_elder.gd","res://scripts/game.gd","res://scripts/core/lion_audio.gd"]
var checks=0
var failures=[]
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);print("FAIL ",label)
func _initialize():
	var data=JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE))
	if not data is Dictionary or not data.get("bosses",{}).has("lion"):
		print("FAIL dialogue json");quit(1);return
	var lion=data.bosses.lion
	var groups=lion.groups
	verify(groups.size()==34,"34 lion dialogue groups, got "+str(groups.size()))
	var text=""
	for path in SOURCES:text+=FileAccess.get_file_as_string(path)
	var missing=[]
	for group in groups:
		var variants=groups[group]
		for variant in variants:
			verify(lion.lines.has(variant),"line file "+variant)
		# A dictionary key that merely names the event is not a trigger: require
		# the call site that actually speaks or staggers with it.
		var move_literal='"voice": "'+group+'"'
		var speak_literal='speak_event("'+group+'"'
		var stagger_literal='stagger("'+group+'"'
		# Break windows pick their stagger kind from a move-to-event map, so the
		# event also counts when it is written as a mapping value.
		var value_literal=':"'+group+'"'
		if not (text.contains(move_literal) or text.contains(speak_literal) or text.contains(stagger_literal) or text.contains(value_literal)):missing.append(group)
	verify(missing.is_empty(),"every group reached by a real call site, missing="+str(missing))
	# Two variants per event keep repeats from sounding identical.
	for group in groups:verify(groups[group].size()>=2,"two variants for "+group)
	print("LION_DIALOGUE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
