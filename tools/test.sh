#!/bin/zsh
set -eu
cd "${0:A:h:h}"

engine_bin="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
temp_root="$(mktemp -d /private/tmp/yang-daxia-tests.XXXXXX)"
trap 'rm -rf "$temp_root"' EXIT

tests=(
	save_store
	upgrades
	section_clear
	stage_results
	relics
	relic_journal
	journey_mode
	death_guide
	journey_records
	new_journey_confirm
	moon_tonic
	boss_phase_shift
	hero_commands
	hero_sword_continuity
	sheep_form
	hero_commands_pad
	attack_readability
	combat_impact_audio
	combat_polish
	perfect_dodge
	release_ui
	interface_cleanup
	boss_dialogue
	level_identity
	integration
	movement
	gamepad
	stage_select
	knight_boss
	knight_painted
	knight_pressure
	knight_meteor
	knight_rage
	knight_legion
	knight_divine
	knight_arrow_balance
	knight_selection
	mount_rescue
	mount_rescue_trigger
	rider_alignment
	knight_fight_sim
	hero_feel
	rush_knight_foot
)

for test_name in $tests; do
	echo "==> $test_name"
	mkdir -p "$temp_root/$test_name"
	log="$temp_root/$test_name.log"
	set +e
	HOME="$temp_root/$test_name" "$engine_bin" --headless --path . --fixed-fps 60 --script "tests/$test_name.gd" 2>&1 | tee "$log"
	exit_code=${pipestatus[1]}
	set -e
	if (( exit_code != 0 )) || rg -q "SCRIPT ERROR:|Failed to load script" "$log"; then
		echo "Test failed: $test_name" >&2
		exit 1
	fi
done

echo "All core tests passed."
