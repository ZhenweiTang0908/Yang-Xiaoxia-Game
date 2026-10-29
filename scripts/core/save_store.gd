extends RefCounted
const PATH = "user://progress_v2.json"
const TEMP_SUFFIX = ".tmp"
const BACKUP_SUFFIX = ".bak"

static func defaults():
	return {"version":2,"rush_stage":1,"rush_clears":[],"rush_completed":false,"rush_knight_foot":false,"level":1,"checkpoint":0,"entry_section":0,"bow":false,"gourd":false,"story_seen":false,"completed":false,"upgrades":[],"pending_upgrade":{},"tonic":2,"relics":[],"records":{},"music":.72,"sfx":.85,"ambience":.45,"muted":false,"screen_shake":true,"hero_mesh":false,"hero_animation_revision":2,"boss_voice":"ai","boss_voice_revision":1,"journey_mode":"standard"}

static func read_save(path=PATH):
	var parsed=_read_valid(path)
	if parsed==null:parsed=_read_valid(path+BACKUP_SUFFIX)
	var data=defaults()
	if parsed is Dictionary:
		for key in data:
			if parsed.has(key):
				if typeof(data[key])==TYPE_INT and (parsed[key] is int or parsed[key] is float):data[key]=int(parsed[key])
				elif typeof(parsed[key])==typeof(data[key]):data[key]=parsed[key]
	# Apply the requested defaults once, then preserve every later explicit choice.
	if parsed is Dictionary:
		if int(data.hero_animation_revision)<2 or not parsed.has("hero_animation_revision"):data.hero_mesh=false
		if not parsed.has("boss_voice_revision"):data.boss_voice="ai"
	data.hero_animation_revision=2;data.boss_voice_revision=1
	data.rush_stage=clampi(int(data.rush_stage),1,5)
	# JSON stores numbers as floats; keep each cleared stage once as an int.
	var clears=[]
	for n in data.rush_clears:
		if (n is int or n is float) and int(n)>=1 and int(n)<=5 and int(n) not in clears:clears.append(int(n))
	data.rush_clears=clears
	# Version 2 remains readable; the former four-battle ending now opens the fifth.
	if data.rush_completed and 5 not in clears:
		data.rush_stage=5;data.rush_completed=false;data.rush_knight_foot=false
	data.level=clampi(int(data.level),1,3)
	data.entry_section=2 if data.entry_section in [2,6] else 0
	data.checkpoint=clampi(int(data.checkpoint),0,2)
	data.tonic=clampi(int(data.tonic),0,2)
	for key in ["music","sfx","ambience"]: data[key]=clampf(float(data[key]),0,1)
	if data.journey_mode not in ["standard","relaxed"]:data.journey_mode="standard"
	if data.boss_voice not in ["ai","classic"]:data.boss_voice="ai"
	data.records=_sanitize_records(data.records)
	return data

static func _sanitize_records(raw):
	var clean={}
	if not (raw is Dictionary):return clean
	for stage in ["1","2","3","4","5"]:
		var source=raw.get(stage,{})
		if not (source is Dictionary):continue
		var stage_records={}
		for mode in ["standard","relaxed"]:
			var record=source.get(mode,{})
			if not (record is Dictionary):continue
			var completions=record.get("completions",0)
			var seconds=record.get("best_seconds",0.0)
			var kills=record.get("best_kills",0)
			var clears=record.get("best_clears",0)
			completions=clampi(int(completions),0,9999) if completions is int or completions is float else 0
			seconds=clampf(float(seconds),0,86400) if seconds is int or seconds is float else 0.0
			kills=clampi(int(kills),0,999) if kills is int or kills is float else 0
			clears=clampi(int(clears),0,4) if clears is int or clears is float else 0
			if completions>0:stage_records[mode]={"completions":completions,"best_seconds":seconds,"best_kills":kills,"best_clears":clears}
		if not stage_records.is_empty():clean[stage]=stage_records
	return clean

static func write_save(data,path=PATH):
	var temp_path=path+TEMP_SUFFIX
	var backup_path=path+BACKUP_SUFFIX
	var file=FileAccess.open(temp_path,FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error=file.get_error()
	file.close()
	if write_error!=OK or _read_valid(temp_path)==null:
		_remove_if_present(temp_path)
		return false

	var primary_valid=_read_valid(path)!=null
	if primary_valid:
		_remove_if_present(backup_path)
		if DirAccess.rename_absolute(_absolute(path),_absolute(backup_path))!=OK:
			_remove_if_present(temp_path)
			return false
	elif FileAccess.file_exists(path):
		_remove_if_present(path)

	if DirAccess.rename_absolute(_absolute(temp_path),_absolute(path))==OK:return true
	if primary_valid and FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(_absolute(backup_path),_absolute(path))
	_remove_if_present(temp_path)
	return false

static func _read_valid(path):
	if not FileAccess.file_exists(path):return null
	var json=JSON.new()
	if json.parse(FileAccess.get_file_as_string(path))!=OK:return null
	var parsed=json.data
	if parsed is Dictionary and parsed.get("version",0)==2:return parsed
	return null

static func _remove_if_present(path):
	if FileAccess.file_exists(path):DirAccess.remove_absolute(_absolute(path))

static func _absolute(path):
	return ProjectSettings.globalize_path(path)
