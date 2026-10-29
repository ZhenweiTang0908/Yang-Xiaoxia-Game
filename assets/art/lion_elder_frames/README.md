# Lion elder animation handoff — INCOMPLETE

48 extracted study cells (16 each: lion, backfall, sweep). **0 approved production poses / 272 planned distinct poses.** Extraction makes these files loadable for previews, not production-usable animation. The backfall ending contains near duplicates. Anatomical continuity, prop consistency and normal/half-speed mirrored playback remain unaccepted.

Rebuild without changing sources:

```sh
.agents/skills/godot-headless-test/run_test.sh tools/prepare_lion_frames.gd 120
.agents/skills/godot-headless-test/run_test.sh tests/lion_art.gd 120
```

Each bank's frames.json contains source rectangles, status, warnings, zero-based filenames, anchor (source-image x), baseline (source-image y), and reference_height. Current contact-strip estimates are explicitly provisional: lowest visible pixels can be hands, shoulders, cloth or feet. They must be replaced by reviewed anatomical support anchors for production. They map to local (0,0), not to an independently applied world displacement. A single scale per bank comes from frame 00; crouches and rolls retain their authored heights.

Parent integration:

```gdscript
var visual = preload("res://scripts/animation/lion_elder_visual.gd").new()
add_child(visual)
visual.setup(self)
# Per move; times are absolute seconds measured by actor.t, not normalized progress.
move = {"bank": "backfall", "poses": [0, 1, 3], "times": [0.0, 0.2, 0.5]}
visual.sync_pose(dt)
# Or explicit events:
move = {"bank": "sweep", "poses": [{"time": 0.0, "index": 2, "snap": true}]}
# Manual state overrides (hurt, phase shift, defeat, idle):
visual.pose("backfall", 0, true)
```

Call sync_pose once per animation tick, after choosing the move and advancing t. Parent owns pause/hitstop and state selection; an empty sequence holds the previous image. If overriding a timed move with pose(), do so after sync_pose or clear that move's sequence. Dead/hurt/phase state art is not fabricated from unrelated study frames. No world position, combat, timing or facing state is written by the visual. facing=-1 displays the left-facing source normally; facing=+1 mirrors it. Invalid requests return false, preserve display and set last_error. Distinct silhouettes use authored frame cuts in the existing actor_pose_art ArrayMesh; snap also resets lean/sink. Mesh deformation is intentionally identity to avoid bending rigid lion props and inventing transitions.

Replace the preview PNGs/manifests with production transparent art and reviewed anchors later; setup reloads bank metadata. The study extraction tool is only for the three existing 4x4 boards and will overwrite preview outputs when rerun. It is not a production-sheet importer. Keep status/counts honest when replacing art.

Headless tests verify loading, extraction bounds, coordinate anchors, timelines, facing and failure behavior. They do not verify anatomical foot planting, rendering quality or animation fluency.
