# 雷电淡出与方向

共享 vfx_shapes.bolt 的辉光与白色内芯原先覆盖传入 alpha，导致技能消散时仍有固定亮度线条。现在三层共同继承透明度，alpha 为零及零长度时不绘制。锯齿沿雷电方向的法线偏移，短雷电的摆幅按长度限制，端点保持锁定。

tests/bolt_lifecycle.gd 覆盖横向、纵向、斜向的四档透明度及零长度，共 13 种情况，错误 0。tests/bolt_visual.gd 实际渲染 builds/qa/bolt-fade.png，检查内外层同步淡出。未改变伤害、判定或预兆时长。
