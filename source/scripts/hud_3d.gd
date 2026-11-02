extends Node2D
var game
const INK = Color("#18262c")
const GOLD = Color("#d8b57a")
const IVORY = Color("#f5ead4")
const MUTED = Color("#acbdb9")
func label_at(p: Vector2, s: String, size: int = 20, col: Color = IVORY):
	draw_string(ThemeDB.fallback_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
func centered(x: float, y: float, s: String, size: int = 20, col: Color = IVORY):
	var w = ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label_at(Vector2(x-w*.5,y),s,size,col)
func panel(r: Rect2, col: Color, outline: Color = Color.TRANSPARENT, width: float = 1.0):
	var style = StyleBoxFlat.new()
	style.bg_color = col
	style.border_color = outline
	style.set_border_width_all(int(width))
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0,0,0,.22)
	style.shadow_size = 5
	style.draw(get_canvas_item(),r)
func inventory_card(x: float, y: float, kind: int, has_item: bool, taken: bool):
	panel(Rect2(x,y,105,49),Color("#365e53") if has_item else Color(.075,.12,.14,.88),GOLD if has_item else Color(.4,.5,.5,.5))
	draw_circle(Vector2(x+16,y+18),5,Color(game.TRAP_COLORS[kind]) if not taken else MUTED)
	label_at(Vector2(x+29,y+22),game.TRAP_KINDS[kind],12)
	label_at(Vector2(x+12,y+40),"В РЮКЗАКЕ" if has_item else ("ГОТОВО" if taken else "НАЙТИ"),10,GOLD if has_item else MUTED)
func _draw():
	if not is_instance_valid(game):return
	var lv:int=game.level
	var st:int=game.state
	panel(Rect2(16,12,293,43),Color(.06,.105,.12,.93),Color(.55,.48,.34,.6))
	label_at(Vector2(29,40),"ПАКОСТИ",23,GOLD)
	label_at(Vector2(151,39),"ПО СОСЕДСТВУ",14)
	panel(Rect2(636,12,308,43),Color(.06,.105,.12,.93),Color(.55,.48,.34,.6))
	label_at(Vector2(651,38),"%02d / 04"%(lv+1),17,GOLD)
	label_at(Vector2(748,38),"%d / %d"%[game.score,game.traps.size()],17)
	label_at(Vector2(831,38),"%d:%02d"%[int(game.episode_time/60),int(game.episode_time)%60],17,MUTED)
	if st==1:
		panel(Rect2(330,12,236,43),Color(.06,.105,.12,.90),Color(.4,.48,.47,.6))
		centered(448,38,"КАЧЕСТВО • ПЛАВНО" if game.performance_mode else "КАЧЕСТВО • ДЕТАЛИ",13,MUTED)
		panel(Rect2(17,68,281,53),Color(.06,.105,.12,.84))
		label_at(Vector2(30,89),game.TITLE[lv],14,GOLD)
		label_at(Vector2(30,108),"Собери предметы • Подстрой ловушки",12,MUTED)
		for j in range(game.lives):
			draw_circle(Vector2(922-j*19,73),5,Color("#dc8c78"))
		# Virtual stick is for touchscreens; PC shows a point-and-click hint.
		if OS.has_feature("mobile"):
			var c:Vector2=game.STICK_CENTER
			draw_circle(c,58,Color(.045,.09,.105,.76))
			draw_arc(c,55,0,TAU,64,Color(.8,.71,.52,.65),2)
			for a in [0,PI/2,PI,PI*1.5]:
				var q=c+Vector2(cos(a),sin(a))*42
				draw_circle(q,2,Color(.8,.8,.7,.4))
			var nub=c+game.joystick_vector()*34
			draw_circle(nub+Vector2(0,3),23,Color(0,0,0,.3))
			draw_circle(nub,22,Color("#c6aa78"))
			draw_circle(nub+Vector2(-5,-6),6,Color(.95,.87,.69,.5))
		else:
			panel(Rect2(17,466,228,60),Color(.055,.10,.12,.91),GOLD,1)
			label_at(Vector2(30,490),"ЛЕВАЯ КНОПКА МЫШИ",13,GOLD)
			label_at(Vector2(30,511),"ИДТИ  •  ВЗЯТЬ  •  ЛОВУШКА",11,MUTED)
		for i in range(game.traps.size()):
			var t=game.traps[i]
			inventory_card(262+i*115,476,i,game.inventory[i],t["used"] or t["armed"])
		var hint:String=game.action_hint()
		panel(game.ACTION_ZONE,Color("#957047") if hint!="" else Color(.085,.13,.15,.90),GOLD if hint!="" else Color(.4,.48,.47,.6),1)
		centered(849,487,"ДЕЙСТВИЕ",18)
		centered(849,509,"ЩЁЛКНИ" if not OS.has_feature("mobile") else "КОСНИСЬ",10,GOLD)
		if game.message_timer>0:
			var msg:String=game.message
			if msg.length()>65:msg=msg.left(62)+"…"
			panel(Rect2(222,422,516,35),Color(.06,.105,.12,.92),Color(.55,.48,.34,.65))
			centered(480,445,msg,13)
		elif hint!="":
			panel(Rect2(277,429,406,29),Color(.06,.105,.12,.85))
			centered(480,449,hint,12,GOLD)
		if game.combo>1 and game.combo_timer>0:
			panel(Rect2(413,68,134,35),Color("#8b613c"),GOLD)
			centered(480,92,"КОМБО ×%d"%game.combo,17)
		for e in game.enemies:
			if e["mode"]=="chase" and e["stun"]<=0:
				panel(Rect2(686,98,258,32),Color("#8a3b37"))
				centered(815,120,"СОСЕД ТЕБЯ ЗАМЕТИЛ!",15)
				break
		return
	# Main menu and results share the established touch targets.
	panel(Rect2(144,85,672,331),Color(.055,.095,.11,.94),GOLD)
	label_at(Vector2(180,119),"TEMBUR GAMES  /  КВАРТИРА № 13",12,GOLD)
	if st==0:
		centered(480,170,"ПАКОСТИ ПО СОСЕДСТВУ",31)
		centered(480,204,"Четыре вечера. Один план. Очень сердитый сосед.",16,MUTED)
		for j in range(4):
			var can_play:bool=j<=game.unlocked
			var r=Rect2(196+j*145,239,130,63)
			panel(r,Color("#325449") if can_play else Color("#24363a"),GOLD if can_play else Color("#415154"))
			centered(r.position.x+65,265,"ЭПИЗОД %02d"%(j+1),15)
			centered(r.position.x+65,285,"ИГРАТЬ" if can_play else "ЗАКРЫТ",11,MUTED)
		panel(game.MENU_PLAY,Color("#a17b49"),GOLD)
		centered(480,371,"НАЧАТЬ ПАКОСТИ",22)
	elif st==2 or st==4:
		centered(480,173,"МИССИЯ ВЫПОЛНЕНА!",31,GOLD)
		centered(480,213,"Очки: %d   /   Замечен: %d"%[game.prank_points,game.caught_count],18)
		var stars=3 if game.caught_count==0 else (2 if game.caught_count==1 else 1)
		for j in range(3):centered(417+j*63,283,"★",40,GOLD if j<stars else Color("#52615d"))
		panel(game.MENU_PLAY,Color("#325449"),GOLD)
		centered(480,371,"ДАЛЬШЕ" if st==2 else "В МЕНЮ",22)
	else:
		centered(480,173,"СОСЕД ТЕБЯ ПОЙМАЛ!",30,Color("#e79d88"))
		centered(480,232,"Прячься в шкафу и обходи соседа со спины.",17,MUTED)
		panel(game.MENU_PLAY,Color("#814a3e"),GOLD)
		centered(480,371,"ЕЩЁ ОДНА ПОПЫТКА",21)
