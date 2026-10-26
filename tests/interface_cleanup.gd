extends SceneTree
const BOSS_DIALOGUE=preload("res://scripts/core/boss_dialogue.gd")
const KNIGHT_DIALOGUE=preload("res://scripts/core/knight_dialogue.gd")
const HUD=preload("res://scripts/ui/hud.gd")
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func redraw():
 game.hud.canvas.queue_redraw();await process_frame;await process_frame
func run():
 var translated=Transform2D(0,Vector2(100,50))
 var mapped_safe=HUD.safe_area_in_hud(Rect2i(160,50,840,450),translated.affine_inverse())
 var safe_shifts=HUD.touch_safe_shifts(mapped_safe)
 verify(mapped_safe.is_equal_approx(Rect2(60,0,840,450)),"display safe area maps through the HUD screen transform")
 verify(safe_shifts.is_equal_approx(Vector3(42,36,67)),"touch clusters shift clear of simulated side and home insets")
 var title_challenge_y=HUD.touch_menu_row_y(Rect2(60,24,840,476),442,44);var title_challenge_shift=442-title_challenge_y
 var title_challenge_panel=Rect2(70,413-title_challenge_shift,250,73)
 verify(title_challenge_y==440 and Rect2(76,40,808,444).encloses(Rect2(85,title_challenge_y,101,44)) and Rect2(76,40,808,444).encloses(Rect2(200,title_challenge_y,105,44)) and title_challenge_panel.end.y==484 and title_challenge_panel.position.y>=400,"title challenge card and actions stay above the gesture inset with their spacing intact")
 var title_safe=Rect2(100,24,800,476);var title_left=HUD.touch_title_left_x(title_safe);var title_column=[Rect2(title_left,239,250,46),Rect2(title_left,356,120,44),Rect2(title_left+130,356,120,44),Rect2(title_left,411,250,73)]
 var title_column_fit=title_left==116
 for rect in title_column:title_column_fit=title_column_fit and Rect2(116,40,768,444).encloses(rect)
 verify(title_column_fit,"touch title and primary actions move together inside a simulated left-side notch")
 var title_right_safe=Rect2(100,24,740,476);var footer_x=HUD.touch_title_footer_right(title_right_safe);var footer_widths=[110,90,90,110];var footer_fit=footer_x==824
 for i in range(footer_widths.size()-1,-1,-1):
  footer_x-=footer_widths[i];footer_fit=footer_fit and Rect2(116,40,708,444).encloses(Rect2(footer_x,440,footer_widths[i],44));footer_x-=10
 verify(footer_fit,"touch title footer actions, including the optional journal, stay inside a right-side notch")
 var developer_touch=HUD.touch_developer_button_rect(Rect2(100,40,760,460))
 verify(developer_touch==Rect2(722,56,122,44) and Rect2(116,56,728,428).encloses(developer_touch) and HUD.touch_developer_button_rect(Rect2(0,0,960,540))==Rect2(818,16,122,44),"touch developer shortcut avoids top and right display insets")
 var portrait_footer_y=HUD.touch_menu_row_y(Rect2(60,24,840,476),486,44);var portrait_feet=HUD.touch_title_portrait_feet(portrait_footer_y)
 verify(portrait_footer_y==440 and portrait_feet==432 and portrait_feet<=portrait_footer_y-8 and HUD.touch_title_portrait_feet(486)==453,"touch title portraits lift above the footer while retaining desktop composition")
 verify(HUD.touch_menu_row_y(mapped_safe,486,44)==390,"title touch actions stay above the mapped bottom safe area")
 var stage_safe=Rect2(60,24,840,476);var stage_back_y=HUD.touch_menu_row_y(stage_safe,473,44)
 verify(stage_back_y==440 and Rect2(76,40,808,444).encloses(Rect2(380,stage_back_y,200,44)) and not Rect2(600,375,200,44).intersects(Rect2(380,stage_back_y,200,44)),"stage selector return stays above the gesture inset without covering the last stage")
 var settings_back_y=HUD.touch_menu_row_y(stage_safe,465,44);var settings_back=Rect2(380,settings_back_y,200,44)
 verify(settings_back_y==440 and not settings_back.intersects(Rect2(100,381,145,44)) and not settings_back.intersects(Rect2(520,360,340,44)),"settings return stays clear of the voice and controls buttons")
 var notch_settings=Rect2(100,24,760,476);var settings_offset=HUD.touch_settings_left_offset(notch_settings);var settings_panel=Rect2(70+settings_offset,100,minf(390,490-(70+settings_offset)),325)
 var sound_targets=[Rect2(100+settings_offset,160,145,44),Rect2(265+settings_offset,160,160,44),Rect2(231+settings_offset,155,44,44),Rect2(386+settings_offset,155,44,44)]
 var sound_targets_fit=settings_offset==46 and settings_panel.position.x==116 and settings_panel.end.x==490 and Rect2(116,40,728,444).encloses(settings_panel)
 for rect in sound_targets:sound_targets_fit=sound_targets_fit and Rect2(116,40,728,444).encloses(rect)
 verify(sound_targets_fit,"touch sound settings shift fully inside a left notch while staying clear of travel controls")
 var settings_right_offset=HUD.touch_settings_right_offset(notch_settings);var travel_panel=Rect2(490,100,minf(400,notch_settings.end.x-16-490),325)
 var travel_targets=[Rect2(520+settings_right_offset,161,340,44),Rect2(520+settings_right_offset,214,340,44),Rect2(520+settings_right_offset,360,340,44),Rect2(700+settings_right_offset,303,160,44)]
 var travel_targets_fit=settings_right_offset==-16 and travel_panel.position.x==490 and travel_panel.end.x==844 and Rect2(116,40,728,444).encloses(travel_panel)
 for rect in travel_targets:travel_targets_fit=travel_targets_fit and Rect2(116,40,728,444).encloses(rect)
 verify(travel_targets_fit,"touch travel settings shrink and shift left to fit a right-side notch")
 var tight_settings_back=HUD.touch_settings_back_rect(Rect2(60,24,840,436))
 verify(tight_settings_back==Rect2(426,400,94,44) and not tight_settings_back.intersects(Rect2(100,381,325,44)) and not tight_settings_back.intersects(Rect2(520,360,340,44)) and HUD.touch_settings_back_rect(stage_safe)==Rect2(380,440,200,44),"touch settings return uses the center gutter only when the bottom inset forces a collision")
 var pause_toggle=Rect2(HUD.touch_menu_left_x(stage_safe,35),HUD.touch_menu_row_y(stage_safe,472,44),260,44)
 var challenge_utility_y=minf(398, pause_toggle.position.y-46);var challenge_utility=[Rect2(282,challenge_utility_y,125,44),Rect2(417,challenge_utility_y,125,44),Rect2(552,challenge_utility_y,125,44)]
 var pause_toggle_fit=Rect2(76,40,808,444).encloses(pause_toggle)
 for rect in challenge_utility:pause_toggle_fit=pause_toggle_fit and not pause_toggle.intersects(rect)
 verify(pause_toggle_fit,"touch pause animation toggle clears the gesture inset and challenge utilities")
 var stacked_shift=HUD.touch_overlay_shift(stage_safe,525);var stacked_rows=[]
 for i in 4:stacked_rows.append(Rect2(350,343+i*46-stacked_shift,260,44))
 var stacked_overlay_fit=stacked_shift==41 and Rect2(350,283-stacked_shift,260,45).position.y==242 and stacked_rows[0].position.y==302 and stacked_rows[3].end.y==484 and Rect2(76,40,808,444).encloses(stacked_rows[3])
 var challenge_overlay_shift=HUD.touch_overlay_shift(stage_safe,516)
 stacked_overlay_fit=stacked_overlay_fit and challenge_overlay_shift==32 and Rect2(282,398-challenge_overlay_shift,125,44).end.y==410 and Rect2(76,472-challenge_overlay_shift,260,44).end.y==484
 verify(stacked_overlay_fit,"touch pause and death overlays shift as a group when optional rows exceed the bottom safe area")
 var notch_safe=Rect2(100,24,800,476);var notch_shift=HUD.touch_overlay_shift(notch_safe,525);var notch_toggle_x=HUD.touch_overlay_toggle_x(notch_safe,343-notch_shift,46,4,44,472-notch_shift,44);var notch_toggle=Rect2(notch_toggle_x,472-notch_shift,260,44)
 verify(notch_toggle_x==624 and Rect2(116,40,768,444).encloses(notch_toggle) and not notch_toggle.intersects(Rect2(350,440,260,44)),"pause animation toggle switches sides to clear optional rows beside a wide display notch")
 var relic_back_y=HUD.touch_menu_row_y(stage_safe,468,44);var relic_back=Rect2(380,relic_back_y,200,44)
 verify(relic_back_y==440 and Rect2(76,40,808,444).encloses(relic_back) and not relic_back.intersects(Rect2(55,112,820,316)),"relic journal return avoids the gesture inset and record cards")
 var tight_relic_safe=Rect2(60,24,840,436);var tight_relic_back_y=HUD.touch_menu_row_y(tight_relic_safe,468,44);var tight_relic_cards=HUD.touch_relic_journal_rects(tight_relic_safe);var tight_relic_fit=tight_relic_back_y==400 and tight_relic_cards.size()==6
 for card in tight_relic_cards:tight_relic_fit=tight_relic_fit and card.size.y==84 and card.end.y<=tight_relic_back_y-12 and card.position.y>=112 and card.position.x>=76 and card.end.x<=884
 verify(tight_relic_fit,"touch relic journal compresses its card rows above the raised return action")
 var side_relic_cards=HUD.touch_relic_journal_rects(Rect2(100,24,760,436));var side_relic_fit=side_relic_cards.size()==6
 for i in side_relic_cards.size():
  side_relic_fit=side_relic_fit and is_equal_approx(side_relic_cards[i].size.x,354) and side_relic_cards[i].position.x>=116 and side_relic_cards[i].end.x<=844
  for j in range(i+1,side_relic_cards.size()):side_relic_fit=side_relic_fit and not side_relic_cards[i].intersects(side_relic_cards[j])
 verify(side_relic_fit,"touch relic journal columns narrow to remain inside bilateral notch insets")
 var records_back_y=HUD.touch_menu_row_y(stage_safe,466,44);var records_back=Rect2(380,records_back_y,200,44)
 verify(records_back_y==440 and Rect2(76,40,808,444).encloses(records_back) and not records_back.intersects(Rect2(40,151,880,273)),"journey-record return avoids the gesture inset and record cards")
 var narrow_record_cards=HUD.touch_journey_record_rects(Rect2(100,24,760,476));var narrow_records_fit=narrow_record_cards.size()==4
 for i in narrow_record_cards.size():
  narrow_records_fit=narrow_records_fit and is_equal_approx(narrow_record_cards[i].size.x,176) and Rect2(116,40,728,444).encloses(narrow_record_cards[i])
  for j in range(i+1,narrow_record_cards.size()):narrow_records_fit=narrow_records_fit and not narrow_record_cards[i].intersects(narrow_record_cards[j])
 verify(narrow_records_fit,"touch journey-record columns shrink to fit between bilateral notches")
 var story_action_y=HUD.touch_menu_row_y(stage_safe,459,44);var story_shift=459-story_action_y
 var story_panel=Rect2(155,340-story_shift,650,95);var story_actions_clear=Rect2(76,40,808,444).encloses(Rect2(590,story_action_y,215,44)) and Rect2(76,40,808,444).encloses(Rect2(155,story_action_y,145,44)) and story_panel.end.y+24==story_action_y
 verify(story_action_y==440 and story_actions_clear,"story dialogue and actions move together while preserving a 24px gap")
 var controls_action_y=HUD.touch_menu_row_y(stage_safe,455,44);var controls_row_fit=controls_action_y==440
 var tight_controls_help=HUD.touch_controls_help_ys(HUD.touch_menu_row_y(Rect2(60,24,840,436),455,44))
 verify(tight_controls_help==Vector2(348,376) and tight_controls_help.x>285+44 and tight_controls_help.y<400,"touch controller help lines stay between the last binding row and raised actions")
 var narrow_control_columns=HUD.touch_controls_columns(Rect2(100,24,760,476));var columns_fit=narrow_control_columns[0]==116 and narrow_control_columns[1]==488 and narrow_control_columns[2]==166
 var controller_buttons=[Rect2(narrow_control_columns[0]+190,111,narrow_control_columns[2],44),Rect2(narrow_control_columns[1]+190,111,narrow_control_columns[2],44)]
 for rect in controller_buttons:columns_fit=columns_fit and Rect2(116,40,728,444).encloses(rect)
 columns_fit=columns_fit and controller_buttons[0].end.x<narrow_control_columns[1] and controller_buttons[1].end.x==844
 verify(columns_fit,"touch binding columns and remap targets fit between bilateral notches")
 var controls_xs=HUD.touch_controls_row_xs(stage_safe)
 var controls_row=[Rect2(controls_xs[0],controls_action_y,260,44),Rect2(controls_xs[1],controls_action_y,220,44),Rect2(controls_xs[2],controls_action_y,235,44)]
 for i in controls_row.size():
  controls_row_fit=controls_row_fit and Rect2(76,40,808,444).encloses(controls_row[i]) and not controls_row[i].intersects(Rect2(200,404,560,12))
  for j in range(i+1,controls_row.size()):controls_row_fit=controls_row_fit and not controls_row[i].intersects(controls_row[j])
 verify(controls_row_fit,"touch control-settings actions shift together above the gesture inset and instructions")
 var result_action_y=HUD.touch_menu_row_y(stage_safe,459,44);var result_utility_y=minf(409,result_action_y-44-6);var result_primary_y=minf(350,result_utility_y-45)
 var result_buttons=[Rect2(350,result_primary_y,260,45),Rect2(282,result_utility_y,125,44),Rect2(417,result_utility_y,125,44),Rect2(552,result_utility_y,125,44),Rect2(350,result_action_y,260,44)]
 var result_rows_fit=result_action_y==440 and result_utility_y==390 and result_primary_y==345
 for i in result_buttons.size():
  result_rows_fit=result_rows_fit and Rect2(76,40,808,444).encloses(result_buttons[i])
  for j in range(i+1,result_buttons.size()):result_rows_fit=result_rows_fit and not result_buttons[i].intersects(result_buttons[j])
 verify(result_rows_fit,"touch journey-result buttons avoid the gesture inset without overlap")
 var challenge_safe=Rect2(60,24,840,456);var challenge_action_y=HUD.touch_menu_row_y(challenge_safe,439,44);var challenge_shift=439-challenge_action_y
 var challenge_result_buttons=[Rect2(350,330-challenge_shift,260,45),Rect2(282,389-challenge_shift,125,44),Rect2(417,389-challenge_shift,125,44),Rect2(552,389-challenge_shift,125,44),Rect2(350,challenge_action_y,260,44)]
 var challenge_result_fit=challenge_action_y==420 and 75-challenge_shift>=40
 for i in challenge_result_buttons.size():
  challenge_result_fit=challenge_result_fit and Rect2(76,40,808,424).encloses(challenge_result_buttons[i])
  for j in range(i+1,challenge_result_buttons.size()):challenge_result_fit=challenge_result_fit and not challenge_result_buttons[i].intersects(challenge_result_buttons[j])
 verify(challenge_result_fit,"touch challenge results move as a group above the gesture inset")
 var lab_y=HUD.touch_menu_row_y(stage_safe,451,44);var lab_xs=HUD.touch_animation_lab_xs(stage_safe);var lab_rects=[]
 var lab_widths=[110,125,110,235,130];var lab_targets_fit=lab_y==440
 for i in lab_xs.size():lab_rects.append(Rect2(lab_xs[i],lab_y,lab_widths[i],44))
 for i in lab_rects.size():
  lab_targets_fit=lab_targets_fit and Rect2(76,40,808,444).encloses(lab_rects[i])
  for j in range(i+1,lab_rects.size()):lab_targets_fit=lab_targets_fit and not lab_rects[i].intersects(lab_rects[j])
 verify(lab_targets_fit,"touch animation-lab controls meet 44px targets inside the safe area")
 var tight_lab=HUD.touch_animation_lab_layout(Rect2(60,24,840,436));var tight_lab_fit=tight_lab.control_y==400 and tight_lab.shift==51 and tight_lab.panel_bottom==349 and tight_lab.preview_y==321 and tight_lab.title_y==376 and tight_lab.footnote_y==104
 tight_lab_fit=tight_lab_fit and tight_lab.panel_bottom>115 and tight_lab.title_y<tight_lab.control_y and tight_lab.title_y>tight_lab.panel_bottom and tight_lab.footnote_y<115
 verify(tight_lab_fit,"touch animation-lab preview and labels reflow above controls in a tall bottom safe inset")
 var status_offset=HUD.touch_status_offset(mapped_safe)
 verify(status_offset==Vector2(58,1) and Rect2(76,16,808,418).encloses(Rect2(Vector2(18,15)+status_offset,Vector2(304,66))),"touch combat status stays inside simulated top-left safe insets")
 var soul_slow_rect=HUD.touch_soul_slow_rect(status_offset)
 verify(soul_slow_rect==Rect2(88,51,212,5) and Rect2(76,16,808,418).encloses(soul_slow_rect),"touch soul-slow meter follows the combat status clear of side and top insets")
 var quick_rects=HUD.touch_quick_action_rects(mapped_safe);var quick_actions_fit=true
 for i in quick_rects.size():
  quick_actions_fit=quick_actions_fit and Rect2(76,16,808,418).encloses(quick_rects[i])
  for j in range(i+1,quick_rects.size()):quick_actions_fit=quick_actions_fit and not quick_rects[i].intersects(quick_rects[j])
 verify(quick_actions_fit,"touch gameplay shortcuts avoid simulated top and side safe insets")
 var scaled=Transform2D(Vector2(2,0),Vector2(0,1.5),Vector2(100,50))
 var scaled_safe=HUD.safe_area_in_hud(Rect2i(220,50,1680,675),scaled.affine_inverse())
 verify(scaled_safe.is_equal_approx(mapped_safe),"safe-area mapping remains correct under content scaling")
 var inset_layout=HUD.touch_layout_for_safe_rect(mapped_safe)
 var inset_layout_fit=true
 for i in inset_layout.size():
  var rect=inset_layout[i].rect
  inset_layout_fit=inset_layout_fit and Rect2(60,0,840,450).encloses(rect)
  for j in range(i+1,inset_layout.size()):inset_layout_fit=inset_layout_fit and not rect.intersects(inset_layout[j].rect)
 verify(inset_layout_fit,"simulated safe-area touch controls stay inside bounds without overlap")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame
 var subtitles_fit=true
 for boss in BOSS_DIALOGUE.BOSSES.values():
  for line in boss.lines.values():subtitles_fit=subtitles_fit and game.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x<=540
 for line in KNIGHT_DIALOGUE.LINES.values():subtitles_fit=subtitles_fit and game.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x<=540
 verify(subtitles_fit,"all authored subtitles fit the 560px caption panel")
 for state in ["title","settings","controls","new_confirm","playing","paused","dead","stage_clear","win","stage_select","relic_journal","journey_records","story","upgrade","animation_lab"]:
  if state=="animation_lab":game.open_animation_lab()
  else:game.state=state
  await redraw()
  var entries=game.hud.buttons
  if state=="title":
   verify(not entries.any(func(entry):return entry.action=="continue") and entries.any(func(entry):return entry.action=="new"),"fresh title leads with a new journey")
  verify(not entries.is_empty(),state+" has actionable controls")
  var clear=true
  var labels_fit=true
  for i in entries.size():
   clear=clear and Rect2(0,0,960,540).encloses(entries[i].rect)
   var width=game.font.get_string_size(entries[i].label,HORIZONTAL_ALIGNMENT_LEFT,-1,entries[i].text_size).x
   labels_fit=labels_fit and width<=entries[i].rect.size.x-10
   for j in range(i+1,entries.size()):clear=clear and not entries[i].rect.intersects(entries[j].rect)
  verify(clear,state+" controls fit without overlap")
  verify(labels_fit,state+" button labels fit their targets")
  game.pad_mode=true;game.hud.pad_focus=0;game.hud.pad_move(Vector2.DOWN)
  verify(game.hud.pad_focus>=0 and game.hud.pad_focus<entries.size(),state+" controller focus stays valid")
  game.pad_mode=false
 game.progress.level=2;game.state="title";await redraw()
 verify(game.hud.buttons.any(func(entry):return entry.action=="continue") and game.hud.buttons.any(func(entry):return entry.action=="new"),"saved journey offers continue and new journey")
 game.state="playing";game.is_touch=true;await redraw()
 var quick=game.hud.buttons.filter(func(entry):return entry.action in ["stage_select","debug","settings","pause"])
 var touch_targets_fit=quick.size()==4
 for entry in quick:
  touch_targets_fit=touch_targets_fit and entry.rect.size.x>=44 and entry.rect.size.y>=44
  for other in game.hud.buttons:
   if not quick.has(other):touch_targets_fit=touch_targets_fit and not entry.rect.intersects(other.rect)
 verify(touch_targets_fit,"touch quick actions have 44px targets without HUD overlap")
 var tonic_targets=game.hud.buttons.filter(func(entry):return entry.action=="tonic")
 verify(tonic_targets.size()==1 and tonic_targets[0].rect.size==Vector2(58,44) and not tonic_targets[0].rect.intersects(Rect2(18,15,236,32)),"touch HUD tonic tap target reaches 44px without covering combat status")
 var gameplay_touch_edges_fit=true;var gameplay_touch=game.hud.touch_layout()
 for i in gameplay_touch.size():
  var rect=gameplay_touch[i].rect
  gameplay_touch_edges_fit=gameplay_touch_edges_fit and rect.position.x>=32 and rect.end.x<=928
  for j in range(i+1,gameplay_touch.size()):gameplay_touch_edges_fit=gameplay_touch_edges_fit and not rect.intersects(gameplay_touch[j].rect)
 verify(gameplay_touch_edges_fit,"touch combat controls keep an edge buffer without overlap")
 var message_safe=HUD.touch_combat_message_rect(stage_safe);var tight_message_safe=HUD.touch_combat_message_rect(Rect2(60,24,840,436));var messages_clear=message_safe==Rect2(200,323,560,30) and tight_message_safe==Rect2(200,283,560,30)
 for safe in [stage_safe,Rect2(60,24,840,436)]:
  var message=HUD.touch_combat_message_rect(safe)
  for control in HUD.touch_layout_for_safe_rect(safe):messages_clear=messages_clear and not message.intersects(control.rect)
 verify(messages_clear and HUD.touch_combat_message_rect(Rect2(0,0,960,540)).position.y==340,"touch subtitles and alerts stay above the shifted action clusters")
 var modal_targets_fit=true
 for state in ["paused","dead"]:
  game.state=state;await redraw()
  for i in game.hud.buttons.size():
   var rect=game.hud.buttons[i].rect
   modal_targets_fit=modal_targets_fit and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
   for j in range(i+1,game.hud.buttons.size()):modal_targets_fit=modal_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(modal_targets_fit,"touch pause/death actions have 44px targets without overlap")
 game.state="settings";await redraw()
 var settings_targets_fit=true
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  settings_targets_fit=settings_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):settings_targets_fit=settings_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(settings_targets_fit,"touch settings controls meet 44px targets without overlap")
 game.state="controls";await redraw()
 var control_targets_fit=true
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  control_targets_fit=control_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):control_targets_fit=control_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(control_targets_fit,"touch controller settings meet 44px targets without overlap")
 game.state="title";await redraw()
 var title_targets_fit=true
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  title_targets_fit=title_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):title_targets_fit=title_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(title_targets_fit,"touch title actions meet 44px targets without overlap")
 game.state="new_confirm";await redraw()
 var confirm_targets_fit=game.hud.buttons.size()==2
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  confirm_targets_fit=confirm_targets_fit and rect.size==Vector2(230,44) and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):confirm_targets_fit=confirm_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(confirm_targets_fit,"touch new-journey confirmation actions meet 44px targets without overlap")
 var challenge_heading_clear=430+game.font.get_descent(12)+4<=442
 verify(challenge_heading_clear,"touch title challenge heading stays clear of its buttons")
 var result_targets_fit=true
 for state in ["stage_clear","win"]:
  game.state=state;await redraw()
  for i in game.hud.buttons.size():
   var rect=game.hud.buttons[i].rect
   result_targets_fit=result_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
   for j in range(i+1,game.hud.buttons.size()):result_targets_fit=result_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(result_targets_fit,"touch journey result actions meet 44px targets without overlap")
 var rush_safe=Rect2(60,24,840,426);var rush_stage_back_y=HUD.touch_menu_row_y(rush_safe,395,44);var rush_final_back_y=HUD.touch_menu_row_y(rush_safe,385,44)
 var rush_back_fit=Rect2(350,rush_stage_back_y,260,44).end.y<=rush_safe.end.y-16 and Rect2(350,rush_final_back_y,260,44).end.y<=rush_safe.end.y-16 and not Rect2(350,rush_stage_back_y,260,44).intersects(Rect2(350,330,260,45)) and not Rect2(350,rush_final_back_y,260,44).intersects(Rect2(350,320,260,45))
 verify(rush_stage_back_y==390 and rush_final_back_y==385 and rush_back_fit,"touch boss-rush result actions stay above an unusually tall home-indicator inset")
 game.boss_rush=true
 var rush_targets_fit=true
 for state in ["stage_clear","win"]:
  game.state=state;await redraw()
  for i in game.hud.buttons.size():
   var rect=game.hud.buttons[i].rect
   rush_targets_fit=rush_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
   for j in range(i+1,game.hud.buttons.size()):rush_targets_fit=rush_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(rush_targets_fit,"touch boss-rush results meet 44px targets without overlap")
 game.boss_rush=false
 game.start_challenge();await process_frame
 game.state="stage_clear";await redraw()
 var challenge_targets_fit=true
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  challenge_targets_fit=challenge_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):challenge_targets_fit=challenge_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(game.is_challenge() and challenge_targets_fit,"touch independent challenge result meets 44px targets without overlap")
 game.state="story";game.story_page=0;await redraw()
 var story_targets_fit=game.hud.buttons.size()==2
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  story_targets_fit=story_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):story_targets_fit=story_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(story_targets_fit,"touch story actions meet 44px targets without overlap")
 game.state="stage_select";await redraw()
 var stage_targets_fit=true
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  stage_targets_fit=stage_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):stage_targets_fit=stage_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(stage_targets_fit,"touch stage-select actions meet 44px targets without overlap")
 var narrow_stage_safe=Rect2(60,24,700,476);var narrow_stage_x=HUD.touch_stage_select_button_x(narrow_stage_safe);var stage_labels_end=322.0
 for i in 4:
  var stage=load("res://data/arenas/boss_"+str(i+1)+".tres");var boss=load("res://data/bosses/"+stage.boss_id+".tres")
  stage_labels_end=maxf(stage_labels_end,322+game.font.get_string_size(str(i+1)+" · "+stage.title,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x)
  stage_labels_end=maxf(stage_labels_end,322+game.font.get_string_size(boss.title+"   · 已击破",HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)
 verify(narrow_stage_x==544 and narrow_stage_x+200==744 and stage_labels_end+16<=narrow_stage_x,"touch stage-select actions move left of long labels and inside a wide right notch")
 game.state="relic_journal";await redraw()
 var relic_page_fit=game.hud.buttons.size()==1 and game.hud.buttons[0].rect.size.y>=44 and Rect2(0,0,960,540).encloses(game.hud.buttons[0].rect)
 verify(relic_page_fit,"touch relic journal return action meets 44px target")
 game.state="journey_records";await redraw()
 var records_page_fit=game.hud.buttons.size()==3
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  records_page_fit=records_page_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):records_page_fit=records_page_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(records_page_fit,"touch journey-record controls meet 44px targets without overlap")
 game.state="upgrade";await redraw()
 var upgrade_targets_fit=game.hud.buttons.size()==3
 for i in game.hud.buttons.size():
  var rect=game.hud.buttons[i].rect
  upgrade_targets_fit=upgrade_targets_fit and rect.size.x>=44 and rect.size.y>=44 and Rect2(0,0,960,540).encloses(rect)
  for j in range(i+1,game.hud.buttons.size()):upgrade_targets_fit=upgrade_targets_fit and not rect.intersects(game.hud.buttons[j].rect)
 verify(upgrade_targets_fit,"touch upgrade actions meet 44px targets without overlap")
 var upgrade_safe=Rect2(60,24,840,436);var upgrade_shift=HUD.touch_upgrade_shift(upgrade_safe);var upgrade_card=Rect2(55,158-upgrade_shift,260,292);var upgrade_button=Rect2(85,394-upgrade_shift,200,44)
 verify(upgrade_shift==6 and upgrade_card.position.y==152 and upgrade_card.end.y==444 and upgrade_button.end.y==432 and upgrade_card.position.y>=40 and upgrade_card.end.y<=444 and upgrade_button.end.y<=444,"touch upgrade cards and actions move together above the bottom gesture inset")
 var narrow_upgrade_safe=Rect2(100,24,760,436);var responsive_cards=HUD.touch_upgrade_card_rects(narrow_upgrade_safe,152,292);var responsive_cards_fit=responsive_cards.size()==3
 for i in responsive_cards.size():
  var card=responsive_cards[i];var card_button=Rect2(card.position.x+30,388,card.size.x-60,44)
  responsive_cards_fit=responsive_cards_fit and card.size.x>=200 and Rect2(116,40,728,404).encloses(card) and card_button.size.x>=44 and Rect2(116,40,728,404).encloses(card_button)
  for j in range(i+1,responsive_cards.size()):responsive_cards_fit=responsive_cards_fit and not card.intersects(responsive_cards[j])
 verify(responsive_cards_fit,"touch upgrade cards and actions fit between simulated left and right notches")
 game.state="playing";game.player.health=100;game.hint_time=0;game.use_tonic()
 verify(game.hud.resource_feedback>0 and game.tonic_count()==2,"refused tonic has visual feedback without consuming inventory")
 for key in ["ui_focus","ui_back","ui_confirm","ui_error"]:
  verify(game.audio.bank.has(key) and game.audio.bank[key].get_length()>0,"sound available: "+key)
 game.fx.clear()
 for i in 20:game.fx.number(Vector2(100,100),2,Color.RED)
 verify(game.fx.labels.size()==1 and game.fx.labels[0].text=="40","rapid damage merges without losing total")
 for i in 20:game.fx.number(Vector2(i*100,100),1,Color.BLUE)
 verify(game.fx.labels.size()<=6,"floating numbers remain bounded")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("INTERFACE_CLEANUP checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
