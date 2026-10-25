# Current painted motion verification

The production adapter uses `painted_rig/combo.gd` for locomotion, landing and
three melee attacks. `tests/landing_blade_clearance.gd` exercises the older
preview renderer, so it is not sufficient evidence for production landing.

Added `tests/painted_blade_clearance.gd`: samples the production landing squash
curve and transformed sword-tip socket. Maximum tip is 26.002 source pixels
above the floor. This checks the tip, not all weapon pixels or all attacks.

Re-ran current contact transitions at 30, 60 and 120 samples per second. Maximum
world contact error is below 0.000002; there are no unreachable contact releases.
These are deterministic geometry samples, not measured rendering frame rates.
Nine upper-body transitions have maximum joint/socket discrepancy below 0.000025.

Remaining: browser interaction is unavailable while the Mac is locked; the full
combat experience and the remaining character animation states are not proven
complete by these tests. No production art or gameplay was changed in this audit.
