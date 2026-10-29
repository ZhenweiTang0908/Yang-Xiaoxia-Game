extends CanvasLayer
var game
var root:Control
var spins={}
var status:Label
var previous="playing"
var pending=""
var pad_controls=[]
var pad_index=0
func _ready():
 layer=30
 root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
 var theme=Theme.new();theme.default_font=game.font;theme.default_font_size=14;root.theme=theme
 var shade=ColorRect.new();shade.color=Color(.015,.025,.04,.92);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(shade)
 var panel=PanelContainer.new();panel.position=Vector2(130,20);panel.size=Vector2(700,500);root.add_child(panel)
 var margin=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 panel.add_child(margin)
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",9);margin.add_child(column)
 var heading=Label.new();heading.text="战斗参数调试 · 牛大侠 / 枪骑 / 狮叟   F2 / Esc 关闭";heading.add_theme_font_size_override("font_size",20);column.add_child(heading)
 var note=Label.new();note.text="打开时暂停战斗。牛大侠直接以牛形登场；修改后点击保存。";column.add_child(note)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(660,275);column.add_child(scroll)
 var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",20);scroll.add_child(grid)
 for key in game.tuning.SCHEMA:
  if key in ["assist_duration","lifesteal","proc_threshold","critical_threshold","proc_chance","critical_chance","extension","normal_incoming","card_damage","fan_damage","return_damage","rune_damage"]:continue
  var spec=game.tuning.SCHEMA[key];var label=Label.new();label.text=spec[0];label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(label)
  var spin=SpinBox.new();spin.min_value=spec[2];spin.max_value=spec[3];spin.step=spec[4];spin.custom_minimum_size.x=140;grid.add_child(spin);spins[key]=spin;pad_controls.append(spin)
 var actions=HBoxContainer.new();column.add_child(actions)
 add_button(actions,"应用并保存",apply_values);add_button(actions,"默认值（待保存）",defaults);add_button(actions,"返回游戏",close)
 var tests=HBoxContainer.new();column.add_child(tests)
 add_button(tests,"生命 79",func():set_health(79));add_button(tests,"生命 29",func():set_health(29));add_button(tests,"生命 100",func():set_health(100))
 add_button(tests,"召唤就绪",func():pending="ready";status.text="关闭窗口后恢复召唤就绪（不改变剧情存档）。")
 add_button(tests,"召唤牛大侠",func():pending="demon";status.text="关闭窗口后测试牛大侠，未保存的参数不会生效。")
 status=Label.new();status.text="测试按钮用于当前试玩；不写入关卡进度。";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size=Vector2(650,32);column.add_child(status)
 root.hide()
func add_button(parent,label,callback):
 var button=Button.new();button.text=label;button.pressed.connect(callback);parent.add_child(button);pad_controls.append(button)
func refresh():
 for key in spins:
  spins[key].value=game.tuning.get_value(key)
  spins[key].get_line_edit().text=str(spins[key].value)
func toggle():
 if root.visible:close();return
 previous=game.state;game.release_inputs();game.state="debug";pending="";refresh();root.show();pad_index=0
 if game.pad_mode:pad_controls[0].get_line_edit().grab_focus()
 status.text="牛形召唤，无需概率变身。"
func apply_values():
 var values={}
 for key in spins:
  spins[key].apply()
  values[key]=spins[key].value
 game.tuning.apply(values);refresh()
 var saved=game.qa_mode or game.tuning.save_settings()
 if is_instance_valid(game.summon) and is_instance_valid(game.summon.brother):
  var ally=game.summon.brother;ally.max_health=game.tuning.get_value("ally_hp");ally.health=minf(ally.health,ally.max_health)
 status.text="参数已应用并保存。持续时间在下次召唤时读取。" if saved else "参数已应用，但本地保存失败。"
func defaults():
 for key in spins:
  spins[key].value=game.tuning.SCHEMA[key][1]
  spins[key].get_line_edit().text=str(spins[key].value)
 status.text="默认值已填入；点击应用并保存后生效。"
func set_health(value):
 if not is_instance_valid(game.player):status.text="请先开始游戏，再使用战斗测试。";return
 game.player.health=value;status.text="主角生命已设为 "+str(value)+"。关闭窗口后继续。"
func close():
 root.hide();game.state=previous;game.release_inputs()
 if pending!="" and is_instance_valid(game.player) and previous=="playing":
  if pending=="ready":game.summon.reset(true)
  else:
   if game.summon.phase!="active" or not is_instance_valid(game.summon.brother):
    game.summon.reset(true);game.summon.request();game.summon.phase="active";game.summon.remaining=game.summon.brother.health/game.summon.brother.STAMINA_DRAIN
   game.summon.brother.arrive()
 pending=""

func pad_move(direction):
 var item=pad_controls[pad_index]
 if direction.x!=0 and item is SpinBox:
  item.value+=direction.x*item.step
  return
 pad_index=posmod(pad_index+(1 if direction.x+direction.y>0 else -1),pad_controls.size())
 item=pad_controls[pad_index]
 if item is SpinBox:item.get_line_edit().grab_focus()
 else:item.grab_focus()
func pad_activate():
 var item=pad_controls[pad_index]
 if item is Button:item.pressed.emit()
