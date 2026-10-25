# Painted knight asset prompts

Generated with the built-in imagegen tool. Style reference for all three: `builds/qa/boss-clean-sheet.png`. Original tool outputs are preserved under the Codex generated_images task directory; the selected PNGs are copied here.

Shared prompt: Production 2D side-scrolling game boss sprite sheet. Match the reference EXACTLY: hand-painted small sprites, thin dark outlines, restrained flat painted 3-tone shading, muted burgundy reds, charcoal shadows, slightly textured brush edges. No 3D, glossy metal, plastic render, text, labels, grid, scenery, ground or shadows. Transparent background. All sprites face left; full figures and full weapons inside each cell, generous margins. Original medieval armored physical warrior, closed silver sallet visor, weathered articulated old silver plate armor, broad shoulders, dark burgundy short cape and split tabard, small antique brass accents. No shield or magical ornaments. Warhorse: dark bay coat, black mane/tail, realistic shoulder/neck/haunch masses, saddle/stirrups/bridle, leather straps, burgundy horse cloth and brass edging.

## foot-atlas.png — 4 columns × 3 rows
Row 1: neutral spear upright; high raised spear arm; shoulder-back spear preparation; low forward spear lunge, tip near ground.
Row 2: waist-level spear draw-back; forward ordinary spear thrust toward knee height; fully drawn bow with stowed spear; released bow without arrow.
Row 3: hand on sheathed sword; longsword held overhead in two hands; completed heavy downward lunge with blade at ground; horizontal spear guard.

## mounted-atlas.png — 4 columns × 3 rows
Row 1: mounted idle upright lance; pawing/pressing lance down; couched lance; collected gallop.
Row 2: extended gallop; landing gallop; push-off gallop; rearing on hind legs.
Row 3: rear-kick preparation; rear double kick; high lance-arm shaft-strike preparation; completed downward shaft strike.

## extra-atlas.png — 4 columns × 3 rows
Row 1: empty-saddle horse idle; horse collected gallop; horse extended gallop; horse landing gallop.
Row 2: empty-saddle horse push-off; empty-saddle horse rear; knight airborne dismount knees folded; knight landing crouch.
Row 3: knight walking with sword dragged behind; spear walking left boot forward; spear walking opposite legs; defeated knight kneeling head bowed.

## Arsenal expansion, 2026-10-25
Built-in imagegen; references foot-atlas.png and mounted-atlas.png. Output arsenal-atlas.png, transparent 4×3 hand-painted sprite sheet. Preserve the original burgundy/silver medieval knight, left-facing, painterly PNG style. Row 1: mounted hoof raised, hoof down, withdrawn spear, rising spear. Row 2: braced spear, lunging spear, raised knee, straight boot kick. Row 3: backward bow draw, high sword grip, horizontal cut, diagonal return cut. No UI, spell effects, 3D rendering or added characters. Isolated using the existing Godot 2D mesh pipeline.

## Pressure expansion 2026-10-25
Built-in imagegen, foot-atlas reference; output pressure-atlas.png. Same left-facing burgundy/silver hand-painted knight, transparent 4×3 separate full-body foot poses, consistent ~225px head-to-feet. No swords or effects. Rows: spinning spear preparation / low forward spear lunge / up-left spinning spear / horizontal spear; down-left spin / javelin windup / empty-handed throw release / empty-handed receiving stance; catch spear / high bow draw / low bow draw / overhead SPEAR sweep. Copied into project, isolated using existing 2D mesh pipeline.

## Soul combat expansion 2026-10-25
Built-in imagegen, foot-atlas character reference. Output soul-atlas.png, transparent 4×3 matte hand-painted violet spirit sprites matching silver/burgundy knight. Row1 four armored upper-body archers, smoky lower halves with no legs, draw/release and downward draw/release. Rows2/3 single-use sword/spear phantom strikes, long spectral spear, and one purple eagle. No persistent new enemies, background, UI or 3D. Copied to project and isolated in Godot.
