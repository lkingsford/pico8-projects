pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- pillogrim's duel
-- lachlan kingsford

function _init()
	consts()
	_init_menu()
	menuitem(1, "menu", _init_menu)
end

function consts()
	MAP_COUNT = 4
	ITEMS = {lazgun, launcher, holy_hand_grenade}
	FIREY_PART_COLORS = {7,8,8,9,9,9,10,10,10,10}
	MODES = {{text="last pillow standing", init=init_lps, update=update_lps, draw=draw_lps},
			 {text="capture the teddybear", init=init_captureflag, update=update_captureflag, draw=draw_captureflag}}
	WIN_SCORE = 5
	LPS_HEALTH = 99
	CTF_TIME = 20
end

-->8
-- menu state

-- The menu sits on top of the game while running
function _draw_menu()
	_draw_game()
	center_print("pillogrim's duel", 64, 49, 10)
	center_print("by l. kingsford", 64, 55, 10)
	center_print("FOR WA AND SHORTY", 64, 96, 10)
	center_print("⬅️❎➡️",64,64,10)
	if player_selected == 0 then
		print("-1P-", 32, 64, 8)
		print(" 2P ",80, 64, 10)
	else
		print(" 1P ", 32, 64, 10)
		print("-2P-",80, 64, 8)
	end
end

function _init_menu()
	_init_round(0, {init=none, update=none, draw=none})
	_draw = _draw_menu
	_update = _update_menu
	player_selected = 0
	for i in all(actors) do i.player = 255 end
end

function _update_menu()
	_update_game()
	for p=0,1 do
		if btnp(0,p) and player_selected == 1 then
			player_selected = 0
		elseif btnp(1, p) and player_selected == 0 then
			player_selected = 1
		elseif btnp(5, p) or btnp(4,p) then
			sfx(8)
			start_game(p)
			return
		end
	end
end

function center_print(text, x, y, c)
	local w = 0
	for i = 1, #text do
		if ord(text, i) > 128 then
			w += 8
		else
			w += 4
		end
	end
	local calc_x = x - w/2
	print(text, calc_x, y, c)
end

-->8
-- game state

function _draw_game()
	-- Double negative... but means it can work for state as well as called
	cls()
	camera()
	clock_32 = (clock_32 + 1) % 32
	update_part()
	update_shake()
	draw_back()
	draw_map()
	draw_actors()
	draw_fore_parts()
	camera()
	draw_round()
	if round_ended then
		center_print(round_end_text,64,64,round_end_color)
	end
end

function draw_back()
	if flash then
		rectfill(0,0,127,127,1)
		flash = false
	end
	for p in all(back_part) do
		pset(p.x, p.y, p.c)
	end
end

function draw_actors()
	for a in all(actors) do
		if fget(a.sprite, 0) then -- x dependent animated
			base_sprite = flr(a.sprite / 2) * 2
			if a.knocked <= 0 then
				a.sprite = base_sprite + (a.x/4 + anim_f) % 2
			else
				a.sprite = base_sprite
			end
		end
		local y_adj = 0
		local flip = a.flip
		if a.held_by then
			y_adj = -(a.x/4 + anim_f) % 2
			flip = a.held_by.flip
		end
		local w = a.w or 1
		local h = a.h or 1
		spr(a.sprite, a.x + 1, a.y + 1 + y_adj,w,h,flip)
		-- Draw wraparound
		if (a.x > 120) then
			spr(a.sprite, a.x + 1- 127 + y_adj, 1 + a.y,w,h,flip)
		end
		if (a.y > 120) then
			spr(a.sprite, a.x + 1, 1 + a.y  + y_adj - 127,w,h,flip)
		end
		a.draw_logic(a)
		a.colx = false
		a.coly = false
		if a.knocked > 0 then
			spr(80 + (clock_32/4)%4, a.x, a.y + y_adj)
		end
	end
end

function draw_map()
	-- swap tiles for animations
	anim_t -= 1
	if anim_t == 0 then
		anim_t = 8
		anim_f = (anim_f + 1)%2
		for ix = 0,15 do
			for iy = 0,15 do
				local t = mget(ix,iy)
				if fget(t,7) then
					local b = t-t%2
					mset(ix,iy,t-t%2+anim_f)
				end
			end
		end
	end
	map()
end

function draw_fore_parts()
	for p in all(fore_parts) do
		p.update(p)
		p.draw(p)
		if p.x > 128 or p.y > 128 or p.x < 0 or p.y < 0 or p.t < 0 then del(fore_parts, p) end
	end
end

function new_jump_parts(a)
	for ix = a.x, a.x+8, 0.5 do
		p = {}
		p.draw = draw_basic_part
		p.update = update_basic_part
		p.x = ix
		p.y = a.y + 8
		p.t = 9999
		p.c = rnd({1,4,4,5,5,8,8,9,10})
		p.dx = rnd(2)-1
		p.dy = rnd(2)-1
		p.gravity = true
		add(fore_parts, p)
	end
end

function draw_basic_part(p)
	pset(p.x, p.y, p.c)
end

function update_basic_part(p)
	p.t -= 1
	p.x += p.dx
	p.y += p.dy
	if p.gravity then
		p.dy += 0.1
		p.dy = min(p.dy,3)
	end
end

function update_part()
	-- Actually done during draw
	for p in all(back_part) do
		p.x += p.dx
		p.dy += 0.005 --grav
		p.dy = min(p.dy,1)
		p.y += p.dy
		if max(p.x,p.y) > 128 then
			del(back_part,p)
			add(back_part,new_back_part(0))
		end
	end
end

function add_screen_shake(amount, diff)
	local s = {}
	s.amount = amount
	s.diff = diff
	add(shakes, s)
end

function update_shake()
	local x_offset = 0
	local y_offset = 0
	for shake in all(shakes) do
		theta = rnd()
		x_offset += shake.amount * sin(theta)
		y_offset += shake.amount * cos(theta)
		shake.amount = max(shake.amount - shake.diff, 0)
	end
	camera(x_offset, y_offset)
end

function _update_game()
	update_actors()
	update_sounds()
	update_spawn()
	if not round_ended then
		update_round()
	else
		round_ended_time += 1
		if round_ended_time > 90 then
			_init_roundend(check_gameover())
		end
		-- Making a bunch of explosions until round end
		local non_null = {}
		if round_ended_time > 30 then
			for ix = 0, 15 do for iy = 0, 15 do
				if mget(ix, iy) != 0 then add(non_null,{x=ix,y=iy}) end
			end end
			if #non_null > 0 then
				local b = bomb()
				local p = rnd(non_null)
				del(non_null, p)
				b.t = 1
				b.x = p.x * 8
				b.y = p.y * 8
				b.nuke = true
				add(actors,b)
			end
		end
	end
end

function near_int(x)
	if sgn(x % 1 - 0.5) > 0 then return ceil(x) end
	return flr(x)
end

function update_sounds()
	local walkers = 0
	for i in all(actors) do
		if i.walking_sound == true then
			walkers += 1
		end
	end
	if last_walkers != walkers then
		if walkers == 1 then
			sfx(3, 1)
			sfx(4, -2)
		elseif walkers > 1 then
			sfx(4, 1)
			sfx(3, -2)
		else
			sfx(4, -2)
			sfx(3, -2)
		end
	end
	last_walkers = walkers
end

function update_actors()
	for a in all(actors) do
		init_x = a.x
		init_y = a.y
		if a.held_by then
			a.x = a.held_by.x + sgn(a.held_by.dx) * 3
			a.y = a.held_by.y - 3
		else
			-- Move. Doing multiple per frame.
			if max(abs(a.dx), abs(a.dy)) > 0 then
				local steps = 5
				for i = 0, steps do
					if not a.colx and abs(a.dy) > 0 and check_collide(a.x, a.y + a.dy / steps) then
						a.coly = true
						if a.dy >= 0 then
							a.on_floor = true
							a.jumps = 0
						end
						a.dy = 0
					else
						a.y += a.dy / steps
					end
					if abs(a.dx) > 0 and check_collide(a.x + a.dx / steps, a.y) then
						a.colx = true
						a.dx = 0
					else
						a.x += a.dx / steps
					end
				end
			end
			if (a.colx or a.coly) and a.collide then
				a.collide(a)
			end
			if check_collide(a.x, a.y) then
				-- Hack to deal with getting stuck
				-- ... not happy that I need it
				a.x = init_x
				a.y = init_y
				a.dy = 0
				a.dx = 0
				a.on_floor = true
			end
			if a.recent_thrower != nil then
				a.throw_time -= 1
				if a.throw_time == 0 then a.recent_thrower = nil end
			end
			-- Check if hit another actor that can be knocked out
			for i in all(actors) do
				if i != a and a.knocked != 0 then
					local speed = distance(a.dx, a.dy)
					if distance(i.x, i.y, a.x, a.y) < 8 and speed > 0 and a.recent_thrower != i then
						a.collide(a)
						i.dx = (a.dx * a.weight + i.dx * i.weight) / 2
						i.dy = (a.dy * a.weight + i.dy * i.weight) / 2
						if i.knocked >= 0 then
							i.knocked += 20
							sfx(5)
						end
						a.dx = 0
						a.dy = 0
						a.recent_thrower = i
						a.throw_time = 45
						i.hp -= a.hit_damage
					end
				end
			end
			-- Friction
			if a.on_floor then
				a.dx *= 0.8
			end
			if abs(a.dy) > 0.1 then a.on_floor = false end
			-- Wraparound (breaks collision)
			a.x = a.x % 128
			a.y = a.y % 128
			-- Gravity
			if a.gravity then
				a.dy = min(4,a.dy+0.3)
			end
		end
		a.logic(a)
	end
end

function player(actor)
	-- Logic for any player
	if actor.knocked > 0 then
		actor.knocked = max(actor.knocked - 1, 0)
		if actor.holding then drop_item(actor) end
		return
	end
	local p = actor.player
	local l = btn(0, p)
	local r = btn(1, p)
	local u = btn(2, p)
	local d = btn(3, p)
	local o = btnp(4, p)
	local x = btnp(5, p)
	local accel = .75
	local max = 3
	if l then
		actor.dx -= accel
		actor.flip = true
	end
	if r then
		actor.dx += accel
		actor.flip = false
	end
	actor.dx = min(abs(actor.dx), max) * sgn(actor.dx)
	if x then
		jump(actor)
	end
	if o then
		local ground_item = check_ground(actor)
		if actor.holding then
			if actor.holding.action then
				actor.holding.action(actor.holding, u, d)
			elseif d then
				drop_item(actor)
			else
				throw_item(actor, actor.holding, u)
			end
		elseif ground_item and d then
			pick_item(actor, ground_item)
		else
			player_bomb(actor, d, u)
		end
	end
	if abs(actor.dx) > 0.5 and actor.on_floor then
		actor.walking_sound = true
	else
		actor.walking_sound = false
	end
end

function check_ground(actor)
	local i = 0
	for a in all(actors) do
		i += 1
		if actor != a and distance(a.dx,a.dy) < 1 and distance(a.x, a.y, actor.x, actor.y) < 4 and not a.held_by then
			return a
		end
	end
end

function drop_item(a)
	local item = a.holding
	a.holding.held_by = nil
	a.holding = nil
	item.dx = sgn(a.dx) * .5
	item.dy = 0
	item.recent_thrower = a
	item.throw_time = 0.5
	if check_collide(item.x, item.y) then
		item.x = a.x
		item.y = a.y
	end
end

function pick_item(a, item)
	item.held_by = a
	a.holding = item
end

function throw_item(a, b, up)
	b = b or a.holding
	b.held_by = nil
	a.holding = nil
	b.dx = a.dx + sgn(a.dx) * 3
	b.dy = a.dy - 3
	b.recent_thrower = a
	b.throw_time = 0.5
	if up then
		b.dy -= 3
	end
end

function jump(actor)
	local jump = 4
	if actor.held_by then
		actor.dy = -jump
		actor.jumps = 2
		actor.held_by.holding = nil
		actor.held_by = nil
		sfx(1)
	elseif actor.on_floor then
		actor.dy = -jump
		actor.on_floor = false
		actor.jumps = 1
		sfx(1)
	elseif actor.jumps == 0 or actor.jumps == 1 then
		actor.dy = -jump
		actor.jumps = 2
		add(fore_parts,new_jump_parts(actor))
		sfx(1)
	end
end

function player_bomb(actor, drop, up)
	local b = bomb(actor)
	b.x = actor.x
	b.y = actor.y
	if drop then
		pick_item(actor, b)
		drop_item(actor)
	else
		throw_item(actor, b, up)
		add_screen_shake(0.5,1)
	end

	add(actors, b)
	sfx(2)
end

function distance(x1, y1, x2, y2)
	x2 = x2 or 0
	y2 = y2 or 0
	return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

function none(actor)
	-- Do nothing
end

function exploded(actor, exploded_by)
	actor.hp -= exploded_by.explosion_damage
end

function check_collide_p(x,y)
	return fget(mget(x%128/8, y%128/8), 0)
end

function check_collide(x, y, w, h)
	local collide = false
	w = w or 8
	h = h or 8
	x = (x+1) % 128
	y = (y+1) % 128

	a = check_collide_p(x+1,y+1)
	b = check_collide_p(x+w-1,y+1)
	c = check_collide_p(x+1,y+h-1)
	d = check_collide_p(x+w-1,y+h-1)
	if a or b or c or d then return true else return false end
end

function update_spawn()
	-- Spawn crates
	next_spawn -= 1
	if next_spawn <= 0 then
		spawn = {}
		spawn.loc = rnd(crate_spawns)
		spawn.time = rnd(60)+30
		add(spawns, spawn)
		next_spawn = 150+rnd(150) -- 5-10 seconds before next one
	end
	for s in all(spawns) do
		s.time -= 1
		if s.time <= 0 then
			del(spawns, s)
			if not to_spawn then
				local a = new_actor(68, crate_logic)
				a.x = s.loc.x * 8
				a.y = s.loc.y * 8
				a.exploded = crate_exploded
				a.action = crate_action
				add(actors, a)
			else
				local a = to_spawn()
				a.x = s.loc.x * 8
				a.y = s.loc.y * 8
				add(actors, a)
				to_spawn = nil
			end
		end
		if flr(s.time) == 15 then
			sfx(8)
		end
		-- Draw more particles as getting closer
		local to_draw = 2 + max(0, 60-s.time) / 5
		for a = 0, to_draw do
			p = {}
			p.draw = draw_basic_part
			p.update = update_basic_part
			p.x = s.loc.x*8 + rnd(8)
			p.y = s.loc.y*8 + rnd(8)
			p.dx = rnd(2)-1
			p.dy = rnd(2)-1
			p.c = rnd({4,5,9,10,7})
			p.gravity = true
			p.t = 20
			add(fore_parts, p)
		end
	end
end

function init_back()
	back_part={}
	for i = 0,50 do
		add(back_part,new_back_part())
	end
end

function new_back_part(x)
 x = x or rnd(128)
	return part(x,rnd(128),rnd(2), rnd(.05)-.025, rnd({1,1,1,1,5,5,5,5,6,6,7}))
end

function part(x,y,dx,dy,c)
	local p = {}
	p.x=x
	p.y=y
	p.dx=dx
	p.dy=dy
	p.c=c
	return p
end

function new_actor(sprite, logic, draw_logic)
	logic = logic or none
	draw_logic = draw_logic or none
	local a = {}
	a.sprite = sprite
	a.sprite_0 = sprite
	a.logic = logic
	a.draw_logic = draw_logic
	a.collide = none
	a.x = 0
	a.y = 0
	a.dx = 0
	a.dy = 0
	a.extra_hit_dx = 0
	a.extra_hit_dy = 0
	a.knocked = -1 -- -1 means never knocked out
	a.weight = 1
	a.jumps = 0
	a.gravity = true
	a.hp = 0
	a.exploded = exploded
	a.explosion_damage = 10
	a.hit_damage = 1
	a.capture_time = -1
	return a
end

function load_map(map_id)
	-- Copy map_id from rom into map in ram
	-- Left top corner
	crate_spawns = {}
	local map_x = (map_id % 8) * 16
	local map_y = flr(map_id / 8) * 16
	for iy = map_y, map_y+16 do
		reload(dest,16)
	end
	for iy = map_y, map_y+16 do
		local src = 0x2000+iy*128+map_x
		local dest = 0x2000+iy*128
		memcpy(dest, src, 16)
	end
	for iy = 0, 15 do for ix = 0, 15 do
		-- Player starting locations
		if mget(ix, iy) == 2 then
			mset(ix, iy, 0)
			p0.x = ix * 8
			p0.y = iy * 8 - 1
		elseif mget(ix, iy) == 18 then
			mset(ix, iy, 0)
			p1.x = ix * 8
			p1.y = iy * 8 - 1
		elseif mget(ix, iy) == 68 then
			-- crate
			mset(ix, iy, 0)
			local s = {}
			s.x = ix
			s.y = iy
			add(crate_spawns, s)
		end
	end end
end

function start_game(p)
	if player_selected == 0 then
		-- 1p
		-- Player who pushed start is the player
		p0_player = p
		p1_player = -1
	else
		-- 2p
		p0_player = 0
		p1_player = 1
	end
	_init_game()
	_init_roundend()
end

function _init_game()
	p0_score = 0
	p1_score = 0
	_init_roundend()
end

function _init_round(map, mode, take_state)
	p0 = new_actor(2, player)
	p0.knocked = 0
	p0.player = p0_player

	p1 = new_actor(18, player)
	p1.knocked = 0
	p1.player = p1_player

	actors={p0,p1}

	to_spawn = nil -- Set, because set by some modes

	anim_t = 8
	anim_f = 0
	init_back()
	-- Update rnd for new map
	load_map(map or flr(rnd(MAP_COUNT)))
	fore_parts = {}
	shakes = {}

	clock_32 = 0
	last_walkers = 0
	next_spawn = 90 -- Wait a few seconds before spawning any items
	spawns = {}

	mode.init()
	update_round = mode.update
	draw_round = mode.draw

	round_ended = false

	if take_state then
		_update = _update_game
		_draw = _draw_game
	end
end

function round_end(winner)
	round_ended_time = 0
	if winner == -1 then
		round_ended = true
		round_end_text = "mutual destruction"
		round_end_color = 7
		del(actors, p0)
		del(actors, p1)
	elseif winner == 0 then
		round_ended = true
		round_end_text = "point to the pillowgrim"
		round_end_color = 12
		p0_score += 1
		del(actors, p0)
	else
		round_ended = true
		round_end_text = "point to the punk"
		round_end_color = 8
		p1_score += 1
		del(actors, p1)
	end
end

function check_gameover()
	if p0_score >= WIN_SCORE and p1_score <= WIN_SCORE then
		return true
	elseif p0_score >= WIN_SCORE then
		return true
	elseif p1_score >= WIN_SCORE then
		return true
	else
		return false
	end
end

-->8
-- types of round

-- last pillow standing

function init_lps()
	p0.hp = LPS_HEALTH
	p1.hp = LPS_HEALTH
end

function update_lps()
	if p0.hp <= 0 and p1.hp <= 0 then
		round_end(-1)
	elseif p0.hp <= 0 then
		round_end(1)
	elseif p1.hp <= 0 then
		round_end(0)
	end
end

function hp_color(hp)
	if hp > 30 then return 7
	elseif hp > 20 then return 10
	elseif hp > 10 then return 9
	else return 8 end
end

function draw_lps()
	if round_ended then return end
	print(p0.hp,9,0,hp_color(p0.hp))
	print(p1.hp,119-#tostring(p1.hp)*4,0,hp_color(p1.hp))
	spr(65,0,0)
	spr(64,120,0)
end


-- capture the teddybear (flag)

function init_captureflag()
	to_spawn = teddybear
	p0.capture_time = CTF_TIME
	p1.capture_time = CTF_TIME
end

function update_captureflag()
	if p0.capture_time <= 0 then
		p0.capture_time = 0
		round_end(0)
	elseif p1.capture_time <= 0 then
		round_end(1)
	end
end

function format_capture_time(time)
	if time > 10 then
		return tostring(flr(time))
	else
		local z = tostring(time)
		return sub(z,1,3)
	end
end

function capture_time_color(time)
	if time > 10 then return 7
	elseif time > 5 then return 10
	elseif time > 3 then return 9
	else return 8 end
end

function draw_captureflag()
	if round_ended then return end
	print(format_capture_time(p0.capture_time),9,0,capture_time_color(p0.capture_time))
	local p1_time = format_capture_time(p1.capture_time)
	print(p1_time,119-#p1_time*4,0,capture_time_color(p1.capture_time))
end

-->8
--between rounds
function draw_score()
	-- h is 12 for all
	-- y is 52 for all
	local number_sprites = {{x=54,w=7},{x=61,w=6},{x=67,w=7},{x=74,w=7},{x=81,w=7},{x=88,w=7}, {x=96,w=7}, {x=103,w=7}, {x=110,w=7}}
	local colon = {x=124,w=4}
	score_str = tostring(p0_score) .. ":" .. tostring(p1_score)
	to_draw = {}
	for i = 1, #score_str do
		if sub(score_str, i, i) == ":" then
			add(to_draw, colon)
		else
			add(to_draw, number_sprites[ord(score_str, i)-47])
		end
	end
	local w = 0
	for i in all(to_draw) do
		w += i.w + 1
	end
	local x = 64 - w / 2
	for i in all(to_draw) do
		-- 58 is 64 - h/2
		sspr(i.x, 52, i.w, 12, x, 58)
		x += i.w + 1
	end
end

function _update_roundend()
	for p = 0,1 do
		if btnp(5,p) or btnp(4,p) then
			if not game_over then
				_init_round(nil, next_round, true)
			else
				_init_menu()
			end
			return
		end
	end
end

function _draw_roundend()
	cls()
	draw_score()
	if game_over then
		if p0_score > p1_score then
			center_print("pillogrim wins", 64, 72, 12)
		elseif p1_score > p0_score then
			center_print("the punk wins", 64, 72, 8)
		else
			center_print("draw?!?", 64, 72, 7)
		end
		return
	end

	center_print(next_round.text, 64, 72, 10)
	center_print("❎ to start",64,90,7)
end

function _init_roundend(_game_over)
	_update = _update_roundend
	_draw = _draw_roundend
	game_over = _game_over
	if not game_over then
		next_round = rnd(MODES)
	end
end

-->8
--items
function bomb()
	b = new_actor(66,bomb_update,bomb_draw)
	b.wick = wick()
	b.t = 60
	b.max_t = b.t
	b.t_per_wick = b.t/#b.wick
	b.t_next_wick = b.t_per_wick
	b.r = 2.5
	b.explosion_damage = 10
	b.weight=1
	b.exploded = bomb_exploded
	b.nuke = false
	return b
end

function wick()
	return {{2,1},{3,1},{4,2},{4,3}}
end

function bomb_update(b)
	b.t -= 1
	b.t_next_wick -= 1
	if b.t_next_wick <= 0 then
		b.t_next_wick = b.t_per_wick
		del(b.wick, b.wick[1])
	end
	if b.t <= 0 then
		explode(b)
	end
end

function bomb_exploded(actor)
	if actor.held_by then
		drop_item(actor.held_by)
	end
	-- Make bomb explode just a frame after the one next to it doees
	actor.dy += rnd(0.5)
	actor.dx += rnd(0.5)
	actor.t = 3
end

function explode(b)
	del(actors, b)
	local x = b.x / 8
	local y = b.y / 8
	for ix = x - b.r, x + b.r do
	for iy = y - b.r, y + b.r do
		if ceil(distance(x+0.5,y+0.5,ix,iy)) <= b.r then
			if not fget(mget(ix,iy),1) or b.nuke then
				remove_grass(ix, iy)
				mset(ix, iy, 0)
			end
		end
	end
	end

	-- Throw actors around
	b.y  += 2-- Make sure it's a little down to push actor up
	for a in all(actors) do
	if b != a then
		if distance(a.x, a.y, b.x, b.y) <= (b.r * 8 + 4) then
			btheta = atan2(a.x-b.x, a.y-b.y)
			local v = 10
			a.dx += cos(btheta) * v + b.extra_hit_dx
			a.dy += sin(btheta) * v + b.extra_hit_dy
			if a.exploded then
				a.exploded(a, b)
			end
			if a.knocked >= 0 then
				a.knocked = 30 -- Knocked out if boomed
			end
		end
	end end

	-- These are for the boom boom effects
	local high = b.r * 4
	local low = 0
	local theta = 0
	for i = high, low, -0.5 do
		local p = {}
		p.draw = draw_explode_part
		p.update = update_basic_part
		p.x = b.x + rnd(b.r * 2) - (b.r)
		p.y = b.y + rnd(b.r * 2) - (b.r)
		p.x2 = rnd(1) - .5
		p.y2 = rnd(1) - .5
		p.r = i
		p.c = rnd(FIREY_PART_COLORS)
		p.c2 = rnd(FIREY_PART_COLORS)
		theta = atan2(b.x-p.x, b.y-p.y)
		p.dx = i * sin(theta)
		p.dy = i * cos(theta)
		p.t = rnd(high-i) * 2
		p.gravity = true
		add(fore_parts, p)
	end
	for i = 0, 20 do
		local p = {}
		p.draw = draw_basic_part
		p.update = update_basic_part
		p.x = b.x
		p.y = b.y
		p.c = rnd(FIREY_PART_COLORS)
		theta = rnd()
		p.dx = i * sin(theta)
		p.dy = i * cos(theta)
		p.t = 999
		p.gravity = true
		add(fore_parts, p)
	end

	-- Sound
	sfx(0)

	flash = true
	add_screen_shake(4, 1)
end

function draw_explode_part(p)
	circfill(p.x, p.y, p.r, p.c)
	circfill(p.x + p.x2, p.y + p.y2, p.r * .8, p.c2)
end

function bomb_draw(b)
	if #b.wick == 0 then return end
	for p in all(b.wick) do
		pset(b.x + p[1], b.y + p[2], 4)
	end

	-- Spark
	for i = 0,3 do
		p={}
		p.draw = draw_basic_part
		p.update = update_basic_part
		p.x = b.wick[1][1] + b.x
		p.y = b.wick[1][2] + b.y
		p.t = 2
		p.c = rnd({10,10,7})
		p.dx = rnd(1)-.5
		p.dy = rnd(1)-.5
		p.gravity = true
		add(fore_parts, p)
	end

	-- Flashing bomb
	if b.t > b.max_t/3 and b.t < (b.max_t / 3) * 2 then
		b.sprite = b.sprite_0 + (b.t / 5) % 2
	elseif b.t > 10 and b.t < b.max_t / 3 then
		b.sprite = b.sprite_0 + (b.t / 2) % 2
	elseif b.t < 10 then
		b.sprite = b.sprite_0
	end
end

function remove_grass(ix, iy)
	if mget(ix, iy) != 9 then return end
	if mget(ix, iy - 1) == 10 or mget(ix, iy - 1) == 11 then
		mset(ix, iy - 1, 0)
	end
	if mget(ix, iy + 1) == 25 then
		mset(ix, iy + 1, 0)
	end
end


function crate_exploded(crate)
	open_crate(crate)
end

function crate_action(crate, d)
	open_crate(crate)
end

function open_crate(crate)
	del(actors, crate)

	-- Create spawned item
	local item = rnd(ITEMS)()
	item.x = crate.x
	item.y = crate.y
	if crate.held_by then
		crate.held_by.holding = nil
		item.held_by = crate.held_by
		item.held_by.holding = item
	end
	add(actors, item)
end

function holy_hand_grenade()
	local i = bomb()
	i.sprite = 69
	i.sprite_0 = 69
	i.logic = none
	i.draw_logic = none
	i.action = holy_hand_grenade_action
	i.r = 4
	i.weight = 2
	return i
end

function holy_hand_grenade_action(b, up, down)
	b.logic = bomb_update
	b.draw_logic = bomb_draw
	b.t = 60
	b.max_t = b.t
	if not down then
		throw_item(b.held_by, b, up)
	else
		drop_item(b.held_by, b, down)
	end
	sfx(6)
end

function launcher()
	local i = new_actor(85)
	i.action = launcher_action
	return i
end

function launcher_action(b, up, down)
	if down then
		drop_item(b.held_by, b)
		return
	end
	local i = new_actor(86)
	i.direction = sgn(b.held_by.dx)
	i.flip = i.direction < 0
	i.dx = sgn(b.held_by.dx)
	i.x = b.x + i.dx * 8
	i.y = b.y + 1
	i.r = 2.5
	i.logic = missile_update
	i.gravity = false
	i.collide = explode
	i.explosion_damage = 10
	add(actors, i)
end

function missile_update(m)
	m.dx = m.direction * abs(mid(1, abs(m.dx) + .5, 12))
	-- Particles
	-- (should probable function this)
	for a = 0, 4 do
		p = {}
		p.draw = draw_basic_part
		p.update = update_basic_part
		p.x = m.x - m.direction*3
		p.y = m.y + 4
		p.dx = rnd(2)-1
		p.dy = rnd(2)-1
		p.c = rnd({7,8,9})
		p.gravity = false
		p.t = 10
		add(fore_parts, p)
	end
end

function lazgun()
	local i = new_actor(87)
	i.action = lazgun_action
	return i
end

function lazgun_action(lazgun, up, down)
	if down then
		drop_item(lazgun.held_by)
		return
	end

	local still_going = true
	local direction = sgn(lazgun.held_by.dx)
	local ix = lazgun.x
	while  still_going do
		local i = new_actor(88)
		ix += direction * 8
		i.x = ix
		i.dx = 0
		i.extra_hit_dx = direction * 6
		i.x = ix
		i.y = lazgun.y + 1
		i.r = 0.5
		i.logic = laser_logic
		i.gravity = false
		i.t = 5
		i.explosion_damage = 15
		add(actors, i)
		still_going = ix < 128 and ix > 0 and not fget(mget(flr(ix/8),flr(i.y)/8),1)
	end
	sfx(7)
end

function laser_logic(laser)
	laser.t -= 1
	if laser.t <= 0 then
		explode(laser)
	end
end

function teddybear()
	teddy = new_actor(96)
	teddy.logic = teddy_logic
	teddy.t = 15
	teddy.r = 8
	teddy.last_beep = 0
	return teddy
end

function teddy_beep(ted)
	sfx(9)
	ted.last_beep = 0
end

function teddy_logic(ted)
	if ted.held_by then
		ted.held_by.capture_time -= .033 -- .033 is 1/30th of a second
		if ted.held_by.capture_time <= 0 then
			ted.t -= 1
			if ted.t == 0 then explode(ted) end
			return
		end
		teddy.last_beep += 1
		if teddy.last_beep >= 60 then teddy_beep(ted) end
		if teddy.last_beep >= 30 and ted.held_by.capture_time < 10 then teddy_beep(ted) end
		if teddy.last_beep >= 7 and ted.held_by.capture_time < 5 then teddy_beep(ted) end
		if teddy.last_beep >= 5 and ted.held_by.capture_time < 1 then teddy_beep(ted) end
	else
		teddy.last_beep = 0
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000777777011144141000000000000000000000000000000000000000000000000
00000000000000000006670000055500000000000000000000000000000000005666666744124149000000000000000000000000000000000000000000000000
00700700000000000066667000566700000000000000000000000000000000005666666744111111000000000000000000000000000000000000000000000000
00077000000000000561617000666670000000000000000000000000000000005666666721442491000000000000000000000000000000000000000000000000
00077000000000000566666005616160000000000000000000000000000000005666666711414411000000000000000000000000000000000000000000000000
007007000000000005d6dd5005d66650000000000000000000000000000000005666666719111112b000b000000b000b00000000000000000000000000000000
000000000000000000d5d000005dd500000000000000000000000000000000005666666744149414330030303030333000000000000000000000000000000000
0000000000000000000dcc00000ccd00000000000000000000000000000000000555555042124114344941423449414200000000000000000000000000000000
00000000000000000000800000000000000000000000000000000000000000000000000091149144000000000000000000000000000000000000000000000000
00000000000000000006870000008000000000000000000000000000000000000000000012111141000000000000000000000000000000000000000000000000
00000000000000000056667000068700000000000000000000000000000000000000000042152115000000000000000000000000000000000000000000000000
00000000000000000057878000566670000000000000000000000000000000000000000025105050000000000000000000000000000000000000000000000000
00000000000000000056666000578780000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000
00000000000000000028688000566660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000002880000082800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000002080000008200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008e08e000c70c700000000000000000000000000000900000008000000000000000000000000000000000000000000000000000000000000000000000000000
0088288000cc1cc00000000000000000064999460009990000088800000000000000000000000000000000000000000000000000000000000000000000000000
00288880001cccc00000000000000000045444540000900000008000000000000000000000000000000000000000000000000000000000000000000000000000
000288000001cc0000055600000e77000949494900049600000e8700000000000000000000000000000000000000000000000000000000000000000000000000
000080000000c000005555600088ee7009449449004444600088ee70000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000015556000288870095949590014446000288870000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000155550002888e00494449400144440002888e0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001150000022e00065555560001140000022e00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007c07000c07c000007c0000007c070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c070000c000c0c00000c0c00c000000000000000000000000000000000bb0000300000000000000000000000000000000000000000000000000000000
00c00c000000007007c00c70007000000000000000010000600000000000b0b0b00b003000000000000000000000000000000000000000000000000000000000
007007c00c700c0000c700c00000c700000000007676767886565ee000aa3a378388888b00000000000000000000000000000000000000000000000000000000
00000c000000000000c000000000000000000000565656568555588e003630300030b30b00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000110000852528800001000000033bb000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000110000020000000001000000000000000000000000000000000000000000000000000000000000000000000
44000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f444f40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044f4400000000000000000000000000000000000000000000000000444000044000044400004440000004400044444000044400444440004440000444000000
55444550000000000000000000000000000000000000000000000004997400497400499740049974000049740499997404999444999974049974004997400440
ff4f4ff0000000000000000000000000000000000000000000000049999744997404999974499997400499940499999449999744999994499997449999744974
f4fff4f0000000000000000000000000000000000000000000000049929944999404994994499299404999940494222449929940444994499299449929744994
00000000000000000000000000000000000000000000000000000049949940299400444994042499449999940494440049944400004994499499449949940220
00000000000000000000000000000000000000000000000000000049949940499400049940004994049929940499974049999400049940029994049949940000
00000000000000000000000000000000000000000000000000000049949940499400049940004974049449940499997449929740049940049974004999940000
00000000000000000000000000000000000000000000000000000049949940499400499400044297449999940022299449949740049940499297404429940440
00000000000000000000000000000000000000000000000000000049979940499400499440499499447999940044499449949940499200499499449949944974
00000000000000000000000000000000000000000000000000000029999944999744999774499999002229940499999449999940499400499999449999944994
00000000000000000000000000000000000000000000000000000002999402999942999994029992000049940499994004999400499400029992044999400220
00000000000000000000000000000000000000000000000000000000224000222200222220002200000002200022220000222000022000002200004222000000
__label__
00c71c711777177711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111777177711118e18e1
00cc1cc1171717171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111171717171111882881
001cccc1177717771111111111111111511111111111111111111111111111111111111111111111111111111111111111111111111111177717771111288881
0001cc11111711171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711171111128811
0000c111111711171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711171111118111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111191111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111155511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111566711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111666671111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111115
00001111111111111111115616161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111115
00001111111111111111115d6665111b111b111b111b111b111b111111111111111111111111111111111111111111111111111b111b111b111b111b111b1115
000011111111111111113135dd513131333131313331313133311111111111111111511111111111111111111111111111113131333131313331313133313131
000011111111111111113449ccd23449414234494142344941421111111111111111111111111111111111111111111111113449414234494142344941423449
00001111111111111111177777711114414111144141111441411115111111111111111111111111111111111111111111111114414111144141111441411777
00001111111111111111566666674412414944124149441241491111111111111111111111111111111111111111111111114412414944124149441241495666
00001111111111111111566666674411111144111111441111111111111111111111111111111111111111111111111111114411111144111111441111115666
00001111111111111111566666672144249121442491214424911111111111111111111111111111111111111111111111112144249121442491214424915666
00001111111111111111566666671141441111414411114144111111111111111111111111111111111111117111111111111141441111414411114144115666
00001117111111111111566666671911111219111112191111121111111111111111111111111111111111111111111111111911111219111112191111125666
00001111111111111111566666674414941444149414441494141111111111111111111111111111111111111111111111114414941444149414441494145666
00001111111111111111155555514212411442124114421241141111111111111111111111111111111111111111111111114212411442124114421241141555
000011111111111111119114914a9114914491149144911491441111111111111111111111111111111111111111111111119114914491149144911491449114
000011111111111111111211114112111141121111411211114111111111111111111111a1111111111111111111111111111211114112111141121111411211
00001111111111111111421521154215211542152115421521151111111111111111111111111111111111111111111111114215211542152115421521154215
00001111111111111111251151512511515125115151251151511111111111111111111111111111111111111111111111112511515125115151251151512511
00001111111111111111511111115111111151111111511111111111111111111111111111111111111111111111111111115111111151111111511111115111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111191111111111111111111111
00001111111111111111111111111111111111111111111191111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111511111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111116111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
a00011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a11111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a11111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111aa1111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111aa1111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
0000111111111111111111111111111111111111111111111111111b111b111b111b111b111b1111111111111111111aa11111111a1111111111111111111111
00001111111111111111111111111111111111111111111111113131333131313331313133311111111111111111111556111111111111111111111111111111
00001111111111111111111111111111111111111111111111113449414234494142344941421111111111111111115555611111111111111111111111111111
00001111111111111111111111111111111111111111111111111777777111144141111441411111111111111111111555611111111111111111111111111111
00001111111111111111111111111111111111111111111111115666666744124149441241491111111111111111111555511111111111111111111111111111
00001111111111111111111111111111111111111111111111115666666744111111441111111111111111111111111115aaaaaaa11111111111111111111111
000011111111111111111111111111111111111111111111111156666667214424912144249111111111111111111111aaaaaaaaaaa111111111111111111111
00001111111111111111111111111111111111111111111111115666666711414411114144111111111111111111111aaaaaaaaaaaaa11111117111111111111
0000111111111111111111111111111111111111111111111111566666671911111219111112111111111111188888aaaaaaaaaaaaaaa1111111111111111111
00001111111111111111111111111111111111111111111111115666666744149414441494141111111111188888888899999aaaaaaaaa111111111111111111
0000111111111111111111111111111111111111111111111111155555514212411442124114111111111188777778999999999aaaaaaaa11111111111111111
00001111111111111111111111111111111111111111111111119114914491149144911491441111111118877777799999999999aaaaaaa11111111111111111
00001111111111111111111111111111111111111111111111111211114112111141121111411111111118777aaaaa99999a99999aaaaaaa1111111111111111
0000111111111111111111111111111111111111111111111111421521154215211542152115111111118777aaaaaaa9999999999aaaaaaa1111111111111111
000011111111111111111111111111111111111111111111111125115151251151512511515111111111877aaaaaaaaa9999999999aaaaaa1111111111111111
0000111111111111111111111111111111111111111111111111511111115111111151111111111111118aaaaaaaaaaaa999999999aaaaaa1111111111111111
0000111111111111111111111111111111111111111111111111111111111111111111111111111111118aaaaaaaaaaaaa99999999aaaaaa1111111b111b1111
000011111111111111111111111711111111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaa99999999aaaaaa1111313133311111
000011111111111111111151111111111111111111111111111111111111111111111111111119119999aaaaaaaaaaaaaa99999999aaaaaa1111344941421111
000011111111111111111111111111111111117111111111111115111111111111111111111111999997aaaaaaa9a888aa999999999aaaa11111177777711111
0000111111111111111111111111111111111111111111111111111111111111111111111111999999aaaaaaaa9a9888899999999a9aaaa11111566666671111
000011111111111111111111111111111111111111111111111111111111111111111111111999999aaaaa888aa999988a999999aa99aa111111566666671111
000011111111111111111111111111111111111111111111111111111a1111117111111111199999aaaa88aaa9a989998a999999aaa9a1111111566666671111
00001111111111111111111111111111111111111111111111111111111111111111111111999999aaaa8aaa97999999a9999999aaa911111111566666671111
0000111111111111111111111111111111111111111111111111111111111111111111111199999aaaa8aaaa99a99999a9999999a8a911111111566666671111
0000111111111111111111111111111111111111111111111111111111111111111111111999999aaaa8aaaa9998999a99999999aaa911111111566666671111
0000111111111111111111111111111111111111111111111111111111111111111111111999999aaaa8aaaaa999aaaa99999999aaa111191111155555511111
0000611111111111111111111111111111111111111111111111111111111111111111111999999aaaaa8aaaaa89999a9999999aaa9111111111911491441111
00001111111111649994611111111111111111111111111111111111111111111111111119999999aaaa88aaa889999a999999aaaa1111111111121111411111
00001111111111454445411111111111111111111111111111111111111aaa1111111111199999999aaaaa88899999a999999aaaa11111111111421521151111
000011111111119494949111111111111111111111111111111111111aa999aa111111111199999999aaaaaaaa999aa99999aaaa111111111111251151511111
000011111111119449449111111111111111111111111111111111111a99999a1111111111999999999aaaaa99aaa1aaaaaaaaa1111111111111511111111111
00001111111111959495911b111b111b111b111b111b199999111111a9999999a1111111111999999999999999111111aaaaa111111111111111111111111111
00001111111131494449413133313131333131313331988888911111a9999999a111111111199999999999999911111111111111111111111111111111111111
00001111111134655555644941423449414234494149888888891111a9999999a111111111119999999999999111111111111111111111111111111111111111
000011111111177777711114414111144141111441988888888891111a99999a1111111111111199999999911111111999111111111111111111111111111111
000011111111566666674412414944124149441249888888888889111aa999aa1111111111111111999991111111119999911111111111111111111111111111
00001111111556666667441111114411111144111988888888888911111aaa111111111111111111111111111111119999911a11111111111111111111111111
00001111111156666667214424912144249121442988888888888911111111111111111111111111111111111111119a99911119111111111111111111111111
00001111111156666667114144111141441111414988888888888911111111111111111111111111111111111111181999111111111111111111111111111111
00001111111156666667191111121911111219111988888888888911111111111111111111111111111111111111111111111111111111111111111111111111
00001111111156666667441494144414941444149498888888889111111111111111111111111111111888111111111111111111111111111111111111111111
000011111111155555514212411442124114421241198888888911111111111111111111111111111188aaa11111111111111111111111111111111111111111
00001111111191149144911491449114914411111111988888911111111111111111111111111111188aaaaa1111111111111111111111111111111111111111
00001111111112111141121111411211114111111111199999111111111111111111111111111111188aaaaa1111111181111111111111111111111111111111
00001111111142152115421521154215211511111111111111111111111111111111111111111111188aaaaa1111111111111111111111111111111111911111
000011111111251151512511515125115151111111111111111111111111111111111111111111111188aaa11111111111111111111111111111111111111111
00001111111151111111511111115111111111119111111111111111111111111111111111111111111888111111111111111111111111111111111111111111
00001111111111111111111111161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111191111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
0000111111111111111111111111111111111111115111111111111111111111111111111111111111111111111111111111111111111a111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
0000111b111b111b111b111b111b111b111b111b111b111b111b111b111b111b111b111b111b1111111111111111111111111111111111111111111b111b111b
00003131333131313331313133313131333131313331313133313131333131313331313133311111111111111111111111111111111111111111313133313131
00003449414234494142344941423449414234494142344941423449414234494142344941421111111111111111111111111111111111111911344941423449
00001114414111144141111441411114414111144141111441411777777117777771177777711777777111111111111111111111111111144141111441411114
00004412414944124149441241494412414944124149441241495666666756666667566666675666666711111111111111111111111144124149441241494412
00004411111144111111441111114411111144111111441111115666666756666667566666675666666711111111111111111111111144111111441111114411
00002144249121442491214424912144249121442491214424915666666756666667566666675666666711111111111111111111111121442491214424912144
00001141441111414411114144111141441111414411114144115666666756666667566666675666666711111111111111111111111111414411114144111141
00001911111219111112191111121911111219111112191111125666666756666667566666675666666711111111111111111111111119111112191111121911
00004414941444149414441494144414941444149414441494145666666756666667566666675666666711111111111111111111111144149414441494144414
00004212411442124114421241144212411442124114421241141555555155555551155555511555555111111111111111111111111142124114421241144212

__gff__
0000010100000000030580800000000000010101000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000b0b0b0b08080809090808080a0a0a0a000000000808080000080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808090908080808080808080808080808080000080808080808080000020000000000000000000000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000000000044090944000000070708080000070707440909440707070707080800004407440744440744074407070800000a0a0a0a0000000000000a0a0a0a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000a09090a000000000008080200000a0a0a09090b0b0b00001208080000000000000000000000000000080000080909090000000000000909090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000200000909090900001200000808080000090909090909090900000808080000000000000000000000000000080000191919190000000000001919191900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000808080808080808080800000808000000090909090909090900000008080000000200000000000012000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000801000000000000010800000808000000190909090909091900000008000000000000000000000000000000000000000000000000000000000000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800070801000000000000010800000808000000000909090909090000000008000000000000000000000000000000000000000000000a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080000080100000000000001080000080800000a0a0909090909090b0b0000080800000a0a0a000000000a0a0a0000080000000000000809090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000a0a08080808080808080a0a000808440009090908080808090909004408080000090909000000000909090000080000000000001919190000000a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080909090909090909090909090808080a0a090909090909090909090b0b08080000090909000000000909090000080044000000004400004400000909080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
081919191919191919191919191919080809090909090909090909090909090808000019190808000008081919000008000a0a0a0a000000000000001919190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0844000a0a0a0a0a0a0a0a0a0a00440808090909090909090909090909090908080000000000000000000000000000080008090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000909090909090909090900000808191919191919090919191919191908080000000000000000000000000000080019191900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800001919191919191919191900000808000000000000090900000000000008080000000000000a0a000000000000080a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808090908080808080808080808080808080909080808080808080909090909090808080809090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200001f650276502565025650246500d650000500e650000500d650000500a6500865007650056500365002650016500362004620046200362001620016200262006620076100661003610026100260004600
000100000d0300c0300c0300b0300b0400b0400c0400e040100401104014050160501b0501d050141001a100241001a1001f10026100291002b20000000000000000000000000000000000000000000000000000
00010000391502f15020150171500e150056500565003650006500065000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500071763000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500051d630000000e6301c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000b15005600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
411000002417224172241721f100211001f17221100211721f1001f1721f1721f1721f1721f172000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
580200002325015350232503815023250153502325038150232501435023250381502325014350232503815000000000000000000000000000000000000000000000000000000000000000000000000000000000
7904000018055000051c0550c0051f0550c1552305510155240551315528055171552b055181552405518155180102401018010240102b000241002f0002810030000281002b0002f10030000301003000030100
000400002f02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 06074344

