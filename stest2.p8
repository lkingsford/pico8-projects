pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function _init()
	reset_game()
end

function _update()
	t+=1
	for e in all(entities) do
		for u in all(e.updates) do
			u(e)
		end
	end
end

function _draw()
	cls()
	for layer = LAYER_BACKGROUND, LAYER_PLAYER do
		for e in all(entities) do
			if e.layer == layer then
				frame=(flr((t+e.t_offset)/e.period))%#e.sprites+1
				spr(e.sprites[frame],e.x,e.y)
			end
		end
	end
end

function reset_game()
	t=0
	player=dupe(player_template)
	entities={player}
	-- test map
	test_e=dupe(entity_template)
	test_e.layer=LAYER_BACKGROUND
	test_e.x=32
	test_e.y=32
	test_e.updates={basic_shooter}
	test_e.params=merge({basic_shooter_param_template})
	add(entities,test_e)

	test_f=dupe(entity_template)
	test_f.layer=LAYER_BACKGROUND
	test_f.x=96
	test_f.y=64
	test_f.updates={circle_shooter}
	test_f.params=merge({circle_shooter_param_template, {shoot_d_theta=0.01,shoot_interval=2,shoot_amount=30}})
	add(entities,test_f)
end

function dupe(t)
	local new_t = {}
	for k,v in pairs(t) do
		new_t[k] = v
	end
	return new_t
end

function merge(ts)
	local new_t = {}
	for t in all(ts) do
		for k,v in pairs(t) do
			new_t[k] = v
		end
	end
	return new_t
end

function default_cleanup(e)
	w=din(e.w,0)
	h=din(e.h,0)
	if (e.parent and e.parent:cleanup()) then return true end
	x=real_x(self)
	y=real_y(self)
	return x < -w or y < -h or x > 128+w or y > 128+h
end

function player_update()
end

t=0
entities={}

LAYER_HIDDEN=0
LAYER_BACKGROUND=1
LAYER_ENEMY=2
LAYER_ENEMY_BULLET=3
LAYER_PLAYER_BULLET=4
LAYER_PLAYER=4

entity_template={
	layer=LAYER_HIDDEN,
	sprites={},
	x=0,
	y=0,
	w=8,
	h=8,
	updates={},
	cleanup=default_cleanup,
	activated=false,
	period=10,
	t_offset=0,
	parent=nil,
	dx=0,
	dy=0,
	params={},
}

player_template={
}

function should_shoot(e)
	return ((t+e.t_offset)/e.params.shoot_interval) % 1 == 0
end

function basic_shooter(e)
	if should_shoot(e) then
		local b = merge({e.params.bullet_template, {
			x=e.x,
			y=e.y,
		}})
		add(entities,b)
	end
end

function circle_shooter(e)
	if should_shoot(e) then
	 	local origin_theta = t * e.params.shoot_d_theta + e.params.shoot_initial_theta
		for i=1,e.params.shoot_amount do
			local theta = origin_theta + i/e.params.shoot_amount
			local sin_theta = sin(theta)
			local cos_theta = cos(theta)
			local b = merge({e.params.bullet_template, {
				x=cos_theta*e.params.shoot_radius+e.x,
				y=sin_theta*e.params.shoot_radius+e.y,
				dx=cos_theta*e.params.shoot_d,
				dy=sin_theta*e.params.shoot_d,
			}})
			add(entities,b)
		end
	end
end

function straight_move(e)
	e.x += e.dx
	e.y += e.dy
end

bullet_template = {dx=0, dy=1,sprites={16,17}, updates={straight_move}, period=4, layer=LAYER_ENEMY_BULLET}

basic_shooter_param_template={
	shoot_interval=10,
	bullet_template=merge({
		entity_template,
		bullet_template,
		{dy=1},
	})
}

circle_shooter_param_template={
	shoot_interval=10,
	shoot_d=5,
	shoot_amount=10,
	shoot_radius=0,
	shoot_d_theta=0,
	shoot_initial_theta=0,
	bullet_template=merge({entity_template,bullet_template})
}

function lim(a,b,c)
	local _min, _max, v
	if c==nil then
		_min = -a
		_max = a
		v = b
	else
		_min = min(a,b)
		_max = max(a,b)
		v = c
	end
	return max(min(_max,v),_min)
end

__gfx__
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
00088000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0087780000a77a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0087780000a77a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
