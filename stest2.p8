pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function _init()
	reset_game()
end

function _update()
	t+=1
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
	test_e=dupe(entity_template)
	test_e.layer=LAYER_BACKGROUND
	test_e.sprites={1,2,3}
	test_e.x=32
	add(entities,test_e)
	test_f=dupe(entity_template)
	test_f.layer=LAYER_BACKGROUND
	test_f.sprites={1,2,3}
	test_f.x=64
	test_f.t_offset=3
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
	for t in ts do
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
	layer=0,
	sprites=nil,
	x=0,
	y=0,
	w=8,
	h=8,
	update=nil,
	cleanup=default_cleanup,
	activated=false,
	period=5,
	t_offset=0,
	parent=nil,
	dx=0,
	dy=0,
	params={},
}

shoot_param_template={

}
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000087780000a77a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000087780000a77a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
