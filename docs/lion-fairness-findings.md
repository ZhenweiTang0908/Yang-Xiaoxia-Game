# Independent lion fairness regression findings

Contract: approved `docs/lion-elder-design.md`, including its one-based contact-pose directory. Test ownership is limited to `tests/lion_fairness.gd` and this report. No production edits, builds, deployment, windows, or saves.

Final wrapper result: **4,662 checks, 10 failures, exit 1**, no script errors or timeout. All 56 beat/facing reach searches found at least one damaging position; none is proven wholly unreachable. The ten failures are six contact-frame mismatches, two M01 onset misses, and two fixed positive-reach misses. The post-run process check found no remaining headless Godot processes.

Reproduce with:

```sh
.agents/skills/godot-headless-test/run_test.sh tests/lion_fairness.gd 120
```

The fixture runs the real elder actor and visual helper with default schema values held in memory. It never instantiates the main scene, SaveStore or a tuning persistence object. `game.qa_mode=true`. Target spies record actual `take_damage` calls and health deductions; they deliberately have no invulnerability to expose repeated contacts. Audio and unrelated world services are spies. This does not test real player/ally damage reductions, dodge invulnerability, audio playback, or manually playable difficulty.

## Findings

- **M07 uses the study bank at contact despite its authored draft bank being available.** With F2 windup increased by .19s, both directions display `lion/9` (zero-based) at t=1.57001. Design requires M07 frame 08, zero-based 7. `lion_pose_timelines.gd` has no M07 entry, so `begin()` takes the provisional fallback branch. This is a missing authored timeline, not an unimported image.
- **M13 damages on authored frame 08 instead of design contact frame 09.** Both directions select `M13/7` at the tuned beat t=1.44001, expected zero-based 8. The timeline places index 7 at the nominal 1.25s contact; index 8 starts at 1.42s.
- **M14 damages on authored frame 07 instead of design contact frame 09.** Both directions select `M14/6` at tuned t=1.17001, expected zero-based 8. The timeline places index 6 at nominal .98s contact; index 8 starts at 1.30s. Negative retreat and initial-facing kick direction pass; those do not repair the pose mismatch.
- **M01 onset has no damage at the independently selected visible-cap probe.** First sample t=.781 produces no damage for either target in either direction. Subsequent probes during the same beat eventually produce one hit at .949. Separate 4px spatial-grid probes first find an actual damaging target at the .70-window sample, t=.948, after earlier .001/.20/.45-window samples found none. This is evidence of delayed painted reach during the active window, not evidence the entire beat is unreachable. Keep this failure for review of the contact pose/cap/mask; do not restore damage at the parent's known out-of-painted-reach x=620 target to make it pass. Spatial probes are discrete and do not prove absence of every possible subpixel contact.
- **The parent's fixed M01 positive example does not reproduce at 240Hz.** Starting at x=400, a stationary grounded target at x=600 takes no damage through t=1.1; the mirrored x=200 target also takes none. Fixed negative targets x=620 and x=180 remain unharmed as intended. These tests keep all positions fixed throughout the action. The fine-step result may differ from a coarse swept rectangle that is subsequently intersected with the current sprite; investigate timestep dependence rather than moving the positive targets inward.

## Coverage and boundaries

- 1,200 normal weighted selections across both legal phases and five distances. All 20 moves selected; no consecutive same move or adjacent long combinations. Completed actions include their full recovery before the next choice. Teaching/rest randomness and exhaustive arbitrary F2 parameter combinations are not established by this coverage.
- Every one of 28 beats, both facings: pre-contact safety, actual damage to two separate targets, no second damage with invulnerability absent, and no damage after the active window.
- Separate actual-sprite reach probes search legal attack regions at five active-window instants on a 4px grid, keeping target feet at or above the floor. These probes do not replace or suppress the stricter onset assertions. Fixed M01 targets at offsets 200 and 220 test the parent's positive/negative painted-reach examples without relocating them.
- Every move interrupted at .05, .55 and 1.01 times its first beat: pause/hitstop freeze clock, root, pose and events; player death, actual boss defeat and phase shift clear pending action, beats, fired keys and victim keys, with no subsequent damage.
- Nonuniform in-memory F2 beat changes test authored contact-frame selection; both directions verify original `source_dir` mirror. M20 reverses at final-beat time minus .35s while preserving that original artwork mirror.

All 20 draft banks load through the visual helper without running an importer. Current production is **258 drafted poses, 0 visually approved**. Headless pose indices and alpha-mask contacts do not prove anatomical correctness, support anchors, fluent motion, final visual contact quality, or manual balance. No renderer preview was requested or launched.

Production sources are being edited concurrently by the parent. The results apply to the inspected snapshot; rerun after changes. Snapshot SHA-256:

```text
0aaa466d9c29e437a2f013000e733081222262209f4848fb1f5996cc95210126 scripts/actors/lion_elder.gd
1c85e4401d709a8024ad16e5a6796014f2dfc7672a2c52a51281f136bd1dda02 scripts/actors/lion_moves.gd
9a7f695704e9df7e59e58519994b67874bd5da4bf4163bf818e0e4d11787d130 scripts/animation/lion_pose_timelines.gd
3a01a4b4849b05d80d5a4e12774263bf3e5be3bc25fd9d4b6f8a6b89e2d94628 scripts/animation/lion_elder_visual.gd
```
