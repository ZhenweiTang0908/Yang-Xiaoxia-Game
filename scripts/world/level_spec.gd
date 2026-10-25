extends Resource
@export var number: int = 1
@export var title: String = ""
@export var length: float = 16000.0
@export var tint: Color = Color.WHITE
@export var section_names: PackedStringArray
@export var platforms: Array = []
@export var spawns: Array = []
@export var pickups: Array = []
@export var checkpoints: PackedFloat32Array = PackedFloat32Array([100,8100,13700])
@export var boss_id: String = "lantern"
@export var boss_x: float = 14900.0

@export var features: Array = []
# Optional challenge-stage settings. Older levels keep the defaults.
@export var boss_script: String = ""
@export var single_boss: bool = false
@export var no_carry: bool = false
@export var art_stage: int = 0
@export var arena: Rect2 = Rect2()
func stage_art():return art_stage if art_stage>0 else number
@export var music_stage: int = 0
func stage_music():return music_stage if music_stage>0 else stage_art()
