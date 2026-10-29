extends RefCounted
const PROFILES={
 "reset_lantern:pounce": {
  "warning": "reset_lantern_pounce_warning",
  "charge": "reset_lantern_pounce_charge",
  "release": "reset_lantern_pounce_release",
  "impact": "reset_lantern_pounce_impact",
  "landing": "reset_lantern_pounce_landing",
  "recover": "reset_lantern_pounce_recover"
 },
 "reset_lantern:sweep": {
  "warning": "reset_lantern_sweep_warning",
  "charge": "reset_lantern_sweep_charge",
  "release": "reset_lantern_sweep_release",
  "impact": "reset_lantern_sweep_impact",
  "landing": "reset_lantern_sweep_landing",
  "recover": "reset_lantern_sweep_recover"
 },
 "reset_lantern:ground_wave": {
  "warning": "reset_lantern_ground_wave_warning",
  "charge": "reset_lantern_ground_wave_charge",
  "release": "reset_lantern_ground_wave_release",
  "impact": "reset_lantern_ground_wave_impact",
  "landing": "reset_lantern_ground_wave_landing",
  "recover": "reset_lantern_ground_wave_recover"
 },
 "reset_lantern:stone_lift": {
  "warning": "reset_lantern_stone_lift_warning",
  "charge": "reset_lantern_stone_lift_charge",
  "release": "reset_lantern_stone_lift_release",
  "impact": "reset_lantern_stone_lift_impact",
  "landing": "reset_lantern_stone_lift_landing",
  "recover": "reset_lantern_stone_lift_recover"
 },
 "reset_lantern:stone_throw": {
  "warning": "reset_lantern_stone_throw_warning",
  "charge": "reset_lantern_stone_throw_charge",
  "release": "reset_lantern_stone_throw_release",
  "impact": "reset_lantern_stone_throw_impact",
  "landing": "reset_lantern_stone_throw_landing",
  "recover": "reset_lantern_stone_throw_recover"
 },
 "reset_lantern:stone_roll": {
  "warning": "reset_lantern_stone_roll_warning",
  "charge": "reset_lantern_stone_roll_charge",
  "release": "reset_lantern_stone_roll_release",
  "impact": "reset_lantern_stone_roll_impact",
  "landing": "reset_lantern_stone_roll_landing",
  "recover": "reset_lantern_stone_roll_recover"
 },
 "reset_lantern:stone_combo": {
  "warning": "reset_lantern_stone_combo_warning",
  "charge": "reset_lantern_stone_combo_charge",
  "release": "reset_lantern_stone_combo_release",
  "impact": "reset_lantern_stone_combo_impact",
  "landing": "reset_lantern_stone_combo_landing",
  "recover": "reset_lantern_stone_combo_recover"
 },
 "reset_duelist:flash": {
  "warning": "reset_duelist_flash_warning",
  "charge": "reset_duelist_flash_charge",
  "release": "reset_duelist_flash_release",
  "impact": "reset_duelist_flash_impact",
  "landing": "reset_duelist_flash_landing",
  "recover": "reset_duelist_flash_recover"
 },
 "reset_duelist:triple": {
  "warning": "reset_duelist_triple_warning",
  "charge": "reset_duelist_triple_charge",
  "release": "reset_duelist_triple_release",
  "impact": "reset_duelist_triple_impact",
  "landing": "reset_duelist_triple_landing",
  "recover": "reset_duelist_triple_recover"
 },
 "reset_duelist:low_sweep": {
  "warning": "reset_duelist_low_sweep_warning",
  "charge": "reset_duelist_low_sweep_charge",
  "release": "reset_duelist_low_sweep_release",
  "impact": "reset_duelist_low_sweep_impact",
  "landing": "reset_duelist_low_sweep_landing",
  "recover": "reset_duelist_low_sweep_recover"
 },
 "reset_duelist:leap": {
  "warning": "reset_duelist_leap_warning",
  "charge": "reset_duelist_leap_charge",
  "release": "reset_duelist_leap_release",
  "impact": "reset_duelist_leap_impact",
  "landing": "reset_duelist_leap_landing",
  "recover": "reset_duelist_leap_recover"
 },
 "reset_duelist:fan": {
  "warning": "reset_duelist_fan_warning",
  "charge": "reset_duelist_fan_charge",
  "release": "reset_duelist_fan_release",
  "impact": "reset_duelist_fan_impact",
  "landing": "reset_duelist_fan_landing",
  "recover": "reset_duelist_fan_recover"
 },
 "reset_duelist:boomerang": {
  "warning": "reset_duelist_boomerang_warning",
  "charge": "reset_duelist_boomerang_charge",
  "release": "reset_duelist_boomerang_release",
  "impact": "reset_duelist_boomerang_impact",
  "landing": "reset_duelist_boomerang_landing",
  "recover": "reset_duelist_boomerang_recover"
 },
 "reset_duelist:feint": {
  "warning": "reset_duelist_feint_warning",
  "charge": "reset_duelist_feint_charge",
  "release": "reset_duelist_feint_release",
  "impact": "reset_duelist_feint_impact",
  "landing": "reset_duelist_feint_landing",
  "recover": "reset_duelist_feint_recover"
 },
 "reset_duelist:shadow": {
  "warning": "reset_duelist_shadow_warning",
  "charge": "reset_duelist_shadow_charge",
  "release": "reset_duelist_shadow_release",
  "impact": "reset_duelist_shadow_impact",
  "landing": "reset_duelist_shadow_landing",
  "recover": "reset_duelist_shadow_recover"
 },
 "reset_priest:horn": {
  "warning": "reset_priest_horn_warning",
  "charge": "reset_priest_horn_charge",
  "release": "reset_priest_horn_release",
  "impact": "reset_priest_horn_impact",
  "landing": "reset_priest_horn_landing",
  "recover": "reset_priest_horn_recover"
 },
 "reset_priest:four_slash": {
  "warning": "reset_priest_four_slash_warning",
  "charge": "reset_priest_four_slash_charge",
  "release": "reset_priest_four_slash_release",
  "impact": "reset_priest_four_slash_impact",
  "landing": "reset_priest_four_slash_landing",
  "recover": "reset_priest_four_slash_recover"
 },
 "reset_priest:ground_wave": {
  "warning": "reset_priest_ground_wave_warning",
  "charge": "reset_priest_ground_wave_charge",
  "release": "reset_priest_ground_wave_release",
  "impact": "reset_priest_ground_wave_impact",
  "landing": "reset_priest_ground_wave_landing",
  "recover": "reset_priest_ground_wave_recover"
 },
 "reset_priest:moonfall": {
  "warning": "reset_priest_moonfall_warning",
  "charge": "reset_priest_moonfall_charge",
  "release": "reset_priest_moonfall_release",
  "impact": "reset_priest_moonfall_impact",
  "landing": "reset_priest_moonfall_landing",
  "recover": "reset_priest_moonfall_recover"
 },
 "reset_priest:ring": {
  "warning": "reset_priest_ring_warning",
  "charge": "reset_priest_ring_charge",
  "release": "reset_priest_ring_release",
  "impact": "reset_priest_ring_impact",
  "landing": "reset_priest_ring_landing",
  "recover": "reset_priest_ring_recover"
 },
 "reset_priest:homing": {
  "warning": "reset_priest_homing_warning",
  "charge": "reset_priest_homing_charge",
  "release": "reset_priest_homing_release",
  "impact": "reset_priest_homing_impact",
  "landing": "reset_priest_homing_landing",
  "recover": "reset_priest_homing_recover"
 },
 "reset_priest:beam": {
  "warning": "reset_priest_beam_warning",
  "charge": "reset_priest_beam_charge",
  "release": "reset_priest_beam_release",
  "impact": "reset_priest_beam_impact",
  "landing": "reset_priest_beam_landing",
  "recover": "reset_priest_beam_recover"
 },
 "reset_priest:rain": {
  "warning": "reset_priest_rain_warning",
  "charge": "reset_priest_rain_charge",
  "release": "reset_priest_rain_release",
  "impact": "reset_priest_rain_impact",
  "landing": "reset_priest_rain_landing",
  "recover": "reset_priest_rain_recover"
 },
 "reset_priest:rift": {
  "warning": "reset_priest_rift_warning",
  "charge": "reset_priest_rift_charge",
  "release": "reset_priest_rift_release",
  "impact": "reset_priest_rift_impact",
  "landing": "reset_priest_rift_landing",
  "recover": "reset_priest_rift_recover"
 },
 "reset_priest:ritual": {
  "warning": "reset_priest_ritual_warning",
  "charge": "reset_priest_ritual_charge",
  "release": "reset_priest_ritual_release",
  "impact": "reset_priest_ritual_impact",
  "landing": "reset_priest_ritual_landing",
  "recover": "reset_priest_ritual_recover"
 }
}
