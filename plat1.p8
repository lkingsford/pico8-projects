pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- mr pillow
-- lachlan kingsford

function _draw()
	camera()
	cls()
	update_part()
	update_shake()
	draw_back()
	draw_map()
	draw_actors()
	draw_fore_parts()
end

function draw_back()
	for p in all(back_part) do
		pset(p.x, p.y, p.c)
	end
end

function draw_actors()
	for a in all(actors) do
		if fget(a.sprite, 0) then -- x dependent animated
			a.sprite = 2 + (a.x/4 + anim_f) % 2
		end
		local w = a.w or 1
		local h = a.h or 1
		spr(a.sprite, a.x, a.y,w,h,a.flip)
		-- Draw wraparound
		if (a.x > 120) then
			spr(a.sprite, a.x - 127, a.y,w,h,a.flip)
		end
		if (a.y > 120) then
			spr(a.sprite, a.x, a.y - 127,w,h,a.flip)
		end
		a.draw_logic(a)
		a.colx = false
		a.coly = false
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

function _update()
	update_actors()
end

function update_actors()
	for a in all(actors) do
		-- Gravity
		a.dy = min(4,a.dy+0.4)
		-- Move. Doing multiple per frame.
		if max(abs(a.dx), abs(a.dy)) > 0 then
			local steps = 5
			for i = 0, steps do
				if abs(a.dx) > 0 and check_collide(a.x + a.dx / steps, a.y-1) then
					if a.dx > 0 then
						a.y = flr(a.y)
					else
						a.y = ceil(a.y)
					end
					a.colx = true
					a.dx = 0
				end
				if abs(a.dy) > 0 and check_collide(a.x, a.y + a.dy / steps) then
					if a.dy > 1 then
						a.y = ceil(a.y/8) * 8
						a.on_floor = true
						a.jumps = 0
					else
						a.y = flr(a.y)
					end
					a.dy = 0
					a.coly = true
				end
				a.x += a.dx / steps
				a.y += a.dy / steps
			end
		end
		-- Friction
		if a.on_floor then
			a.dx *= 0.8
		end
		if abs(a.dy) > 0 then a.on_floor = false end
		a.logic(a)
		-- Wraparound (breaks collision)
		a.x = a.x % 128
		a.y = a.y % 128
	end
end

function player(actor)
	-- Logic for any player
	local p = actor.player
	local l = btn(0, p)
	local r = btn(1, p)
	--local u = btn(2, p)
	local d = btn(3, p)
	local o = btnp(4, p)
	local x = btnp(5, p)
	local accel = .75
	local max = 4
	if l then
		actor.dx -= accel
		actor.flip = true
	end
	if r then
		actor.dx += accel
		actor.flip = false
	end
	if x then
		jump(actor)
	end
	if o then
		bomb(actor, d)
	end
	--actor.dx = mid(-max,actor.dx,max)
end

function jump(actor)
	local jump = 4
	if actor.on_floor then
		actor.dy -= jump
		actor.on_floor = false
		actor.jumps = 1
	elseif actor.jumps == 0 or actor.jumps == 1 then
		actor.dy -= jump
		actor.jumps = 2
		add(fore_parts,new_jump_parts(actor))
	end
end

function bomb(actor, drop)
	local b = new_actor(66,bomb_update,bomb_draw)
	b.x = actor.x
	b.y = actor.y
	if drop then
		b.dx = actor.dx
		b.dy = actor.dy
	else
		b.dx = actor.dx + sgn(actor.dx) * 3
		b.dy = actor.dy - 4
		add_screen_shake(0.5,1)
	end
	b.wick = {{2,1},{3,1},{4,2},{4,3}}
	b.t = 60
	b.max_t = b.t
	b.t_per_wick = b.t/#b.wick
	b.t_next_wick = b.t_per_wick
	b.r = 1
	add(actors, b)
end
 
function distance(x1, y1, x2, y2)
	return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

function bomb_update(b)
	b.t -= 1
	b.t_next_wick -= 1
	if b.t_next_wick <= 0 then
		b.t_next_wick = b.t_per_wick
		del(b.wick, b.wick[1])
	end
	if b.t <= 0 then
		del(actors, b)
		explode(b)
	end
end

function remove_grass(ix, iy)
	if mget(ix, iy) != 9 then return end
	if mget(ix, iy - 1) == 10 or mget(ix, iy - 1) == 11 then
		mset(ix, iy - 1, 0)
	end
end

function explode(b)
	local x = b.x / 8
	local y = b.y / 8
	for ix = x - b.r, x + b.r do
	for iy = y - b.r, y + b.r do
		if flr(distance(x,y,ix,iy)) <= b.r then
			if fget(mget(ix,iy),1) then
				remove_grass(ix, iy)
				mset(ix, iy, 0)
			end
		end
	end
	end

	-- These are for the boom boom effects
	local high = 12
	local low = 0
	for i = high, low, -0.25 do
		local p = {}
		p.draw = draw_explode_part
		p.update = update_basic_part
		p.x = b.x + rnd(i/2) - (i/4)
		p.y = b.y + rnd(i/2) - (i/4)
		p.x2 = rnd(1) - .5
		p.y2 = rnd(1) - .5
		p.r = rnd(high - i) / 2
		p.c = rnd({7,8,8,9,9,9,10,10,10,10})
		p.c2 = rnd({7,8,8,9,9,9,10,10,10,10})
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
		p.c = rnd({7,8,8,9,9,9,10,10,10,10})
		theta = rnd()
		p.dx = i * sin(theta)
		p.dy = i * cos(theta)
		p.t = 999
		p.gravity = true
		add(fore_parts, p)
	end
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
		b.sprite = 66 + (b.t / 5) % 2
	elseif b.t > 10 and b.t < b.max_t / 3 then
		b.sprite = 66 + (b.t / 2) % 2
	elseif b.t < 10 then
		b.sprite = 67
	end
end

function none(actor)
	-- Do nothing
end

function check_collide(x, y, w, h)
	local collide = false
	w = w or 8
	h = h or 8
	x = x % 128
	y = y % 128

 	for i = x, x+w, w do
		if fget(mget(i/8,y/8),0) or fget(mget(i/8,(y+h)%128/8),0) then
			collide = true
		end
	end

	for i = y, y+h, h do
		if fget(mget(x/8,i/8),0) or fget(mget((x+w)%128/8,i/8),0) then
			collide = true
		end
	end
	return collide
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

function init_map()
	ox=0
	oy=0
end

function new_actor(sprite, logic, draw_logic)
	logic = logic or none
	draw_logic = draw_logic or none
	local a = {}
	a.sprite = sprite
	a.logic = logic
	a.draw_logic = draw_logic
	a.x = 0
	a.y = 0
	a.dx = 0
	a.dy = 0
	return a
end

function _init()
	anim_t = 8
	anim_f = 0
	init_back()
	init_map()
	fore_parts = {}
	local p0 = new_actor(18, player)
	p0.x = 10
	p0.y = 40
	p0.player = 0
	p0.jumps = 0
	actors={p0}
	shakes = {}
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000777777054545454000000000000000000000000000000000000000000000000
00000000000000000006670000055500000000000000000000000000000000005666666745454545000000000000000000000000000000000000000000000000
00700700000000000066667000566700000000000000000000000000000000005666666754545454000000000000000000000000000000000000000000000000
00077000000000000561617000666670000000000000000000000000000000005666666745454545000000000000000000000000000000000000000000000000
00077000000000000566666005616160000000000000000000000000000000005666666754545454000000000000000000000000000000000000000000000000
007007000000000005d6dd5005d66650000000000000000000000000000000005666666745454545b0b0b0b00b0b0b0b00000000000000000000000000000000
000000000000000000d5d000005dd500000000000000000000000000000000005666666754545454303030303030303000000000000000000000000000000000
0000000000000000000dcc00000ccd00000000000000000000000000000000000555555045454545333333333333333300000000000000000000000000000000
00000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006870000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000056667000068700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000057878000566670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000056666000578780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e000e00060006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28e028e01c601c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88828880ccc1ccc000055600000e7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088888000ccccc00005555600088ee70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0288820001ccc1000015556000288870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00288000001cc00000155550002888e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000000100000001150000022e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000077777700777777007777770077777700777777007777770077777700777777000000000000000000000000000000000
00000000000000000000000000000000566666675666666756666667566666675666666756666667566666675666666700000000000000000000000000000000
00000000000000000000000000000000566666675666666756666667566666675666666756666667566666675666666700000000000000000000000000000000
00000000000000000000000000000000566666675666666756666667566666675666666756666667566666675666666700000000000000000000000000000000
00000000000000000000005000000000566666675666666756666667566666675666666756666667566666675666666700000000000000000000000000000000
00000000000000000000000000000000566666675666666756666667566666675666666756666667566666675666666700000000000000000000000000000000
00000000000000000000000000000000566666675666666756666667566666675666666756666667566666675666666700000000000000000000000000000000
00000000000000000000000000000000055555500555555005555550055555500555555005555550055555500555555000000000000000000000000000000000
07777770077777700777777007777770077777700777777007777770000000000000000007777770077777700777777007777770077777700777777007777770
56666667566666675666666756666667566666675666666756666667000000000000000056666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667000000000000000056666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667000000000000000056666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667000000000000000056666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667000000000000000056666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667000000000000000056666667566666675666666756666667566666675666666756666667
05555550055555500555555005555550055555500555555005555550000000000000000005555550055555500555555005555550055555500555555005555550
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000005555550
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555550
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000005555550
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000056666667
56666667000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000006670000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000000000000000000000000000066667000000000000000000000000000000000000000000000000005555550
00000000000000000000000007000000000000000000000000000000000000000561617000000000000000000000000000000000000000000000000000000000
00500000000000000000000000000000000000000000000000000000000000000566666000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000005d6dd5000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000d5d00000000000000000000000000000000000000000000000000000000000
0000000000000005000000000000000000000000000000000000000000000000000dcc0000000000000000000000000000000000000000000000000000000000
00000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000
00000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
5666666700000000000000000b0b0b0b0b0b0b0b0b0b0b5b000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b0b000000000000000056666667
56666667000000000000000030303030303030303030303000000000000000000000000000000000303030303030303030303030000000000000000056666667
05555550000000000000000033333333333333333333333300000000000000000000000000000000333333333333333333333333000000000000000005555550
07777770000000000000000054545454545454545454545400000000000000000000000000000000545454545454545454545454000000000000000007777770
56666667000000000000000045454545454545454545454500000000000000000000000000000000454545454545454545454545000000000000000056666667
56666667000000000000000054545454545454545454545400000000000000000000000000000000545454545454545454545454000000000000000056666667
56666667000000000000000045454545454545454545454500000000000000000000000000000000454545454545454545454545000000000000000056666667
56666667000000000000000054545454545454545454545400000000000000000000000000000000545454545454545454545454007000000000000056666667
56666667000000000000000045454545454545454545454500000000000000000000000000000000454545454545454545454545000000000000010056666667
56666667000000000000000054545454545454545454545400000000000000000000000000000000545454545454545454545454000000000000000056666667
05555550000000000000000045454545454545454545454500000000000000000000000000000000454545454545454545454545000000000000000005555550
07777770000000000000000054545454545454545454545400000001400000000000000000000000545454545454545454545454000000000000000007777770
56666667000000000000000045454545454545454545454500000000100000000000000000000000454545454545454545454545000000000000000056666667
56666667000000000000000054545454545454545454545400000000000000900000000000000000545454545454545454545454000000000000000056666667
56666667000000000000000045454545454545454545454500000000000000000100000000000000454545454545454545454545000000000000000056666667
56666667000000000000000054545454545454545454545400000000080000000000000000000000545454545454545454545454000000000000000056666667
56666667000000000000000045454545454545454545454500000000000000000000000000000000454545454545454545454545000000000000000056666667
56666667000000000000000054545454545454545454545400000000000000000000000000000000545454545454545454545454000000000000000056666667
055555500000000000000000454545454545454545454545000000000080050a0000000000000000454545454545454545454545000000000000000005555550
07777770000000000000000000000000000000000777777007777770000000004000000107777770077777700000000000000000000000000000000007777770
56666667000000000000000000000000000000005666666756866667000000000000a00056666667566666670000000000000000000000000000000056666667
56666667000060000000000000000000000000005666666756666667000000000000000056666667566666670000000000000000000000000000000056666667
56666667000000000000000000000000000000005666666756666667000000090000000056666667566666670000000000000000000000000000000056666667
56666667000000000000000000000000000000005666666756666667000500000000000056666667566666670000000000000000000000000000000056666667
56666667000000000000000000000000000000005666666756666667000000800000000556666667566666670000000000000000000000000000000056666667
56666667000000000000000000000000000000005666666756666667000000000000040056666667566666670000000000000000000000000000000056666667
05555550001000000000000000000000000000000555555005555550000000000000000005555550055555500000000000000000000000000000000005555550
07777770000000000000000000000000000000000000000000000000005000050000000000000000000000000000000000000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555550
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000056666667
56666667000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555550
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
56666667000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
56666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666667
566666670000000000000000000000000000000000000000000000000b0b0b0b0b0b0b0b00000000000000000000000000000005000000000000000056666667
56666667000000000000000000000000000000000000000000000000303030303030303000000000000000000000000000000000000000000000000056666667
05555550000000000000000000000000000000000000000000000000333333333333333300000000000000000000000000000000000000000000000005555550
07777770077777700777777007777770077777700777777007777770545454545454545407777770077777700777777007777771077777700777777007777770
56666667566666675666666756666667566666675666666756666667454545454545454556666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667545454545454545456666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667454545454545454556666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667545454545454545456666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667454545454545454556666667566666675666666756666667566666675666666756666667
56666667566666675666666756666667566666675666666756666667545454545454545456666667566666675666666756666667566666675666666756666667
05555550055555500555555005555550055555500555555005555550454545454545454505555550055555500555555005555550055555500555555005555550

__gff__
0001010100000000010380800000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000008080800000808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080800000808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000707070707070707070707070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000a0a0a000000000a0a0a00000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000909090000000009090900000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000909090000000009090900000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000080800000808000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080000000000000a0a0000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080809090808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
