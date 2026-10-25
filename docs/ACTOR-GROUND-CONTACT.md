# Shared landing contact

Ground presence now tracks visible non-player CharacterBody2D actors near the
player. A falling-to-grounded transition emits the existing restrained terrain
effect: two dust puffs on dry surfaces, a ripple and three droplets in puddles.
Player effects remain driven by their existing animation contact events.

Tracking is rebuilt each physics tick, so removed actors leave no retained actor
references. Initial placement, stationary contact, and movement over 80 pixels
between samples do not trigger a landing. Pause and hit stop freeze tracking.

Validation: `tests/actor_landing_presence.gd` drops an actual enemy onto collision
geometry, counts exactly two dust puffs across 60 ticks, and checks quiet teleport
arrival. `tests/ground_presence.gd` passes existing surface, water, pause and cap
checks; that older test still reports resource cleanup warnings on exit.

This change does not complete the wider character animation or scene art work.
