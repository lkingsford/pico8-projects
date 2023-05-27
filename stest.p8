pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function _init()
	cls()
	cur_state=game:C()
	cur_state:start()
end


function _update()
	cur_state:update()
end

function _draw()
	cur_state:draw()
end

game={
	C=function(self)
		o={
			entities={}
		}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		for e in all(self.entities) do
			if (e.update) then e:update() end
			if (e.cleanup and e:cleanup()) then del(self.entities, e) end
		end	
	end,
	draw=function(self)
		cls()
	 	for l=0,2 do
			for e in all(self.entities) do
			 	if e.draw then
					if e.l==l then e:draw() end
				end
			end	
		end
	end,
	start=function(self)
		add(self.entities,player:C(self))
	end
}

function entity_update(self)
end

function entity_draw(self)
	spr(self.s, self.x-self.w/2, self.y-self.h/2, self.w/8, self.h/8)
	print(self.x,0,0)
	print(self.y,0,8)
	print(self.dx,0,16)
	print(self.dy,0,24)
end

player={
	C=function(self,game)
		o={
			-- x/y are at the middle of the sprite
			x=10,
			y=10,
			w=8, -- in pixels
			h=8,
			s=1,
			l=2,
			dx=0,
			dy=0,
			game=game,
			accel=1,
			max_d=4,
		}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		if(btn(0)) then self.dx = lim(0,-self.max_d,self.dx-self.accel) end
		if(btn(1)) then self.dx = lim(0,self.max_d,self.dx+self.accel) end
		if(btn(2)) then self.dy = lim(0,-self.max_d,self.dy-self.accel) end
		if(btn(3)) then self.dy = lim(0,self.max_d,self.dy+self.accel) end
		if(btn(0) == btn(1)) then self.dx = lim(0, self.dx, self.dx-self.accel*sgn(self.dx)) end
		if(btn(2) == btn(3)) then self.dy = lim(0, self.dy, self.dy-self.accel*sgn(self.dy)) end
		self.x += self.dx
		self.y += self.dy

		if(btnp(4)) then self:fire() end
	end,
	draw=entity_draw,
	fire=function(self)
		add(self.game.entities,player_shot:C(self.x, self.y, self.game))
	end
}

player_shot={
	C=function(self,x,y,game)
		o={x=x,y=y,dy=-3,ddy=-1,dymax=-12,l=1,c=({7,10,14})[flr(rnd(3))+1],game=game}
		setmetatable(o, {__index=self})
		return o
	end,
	update = function(self)
		self.dy=lim(0, self.dymax,self.dy+self.ddy)
		self.y+=self.dy
		add(self.game.entities,trail_shot:C(self.x,self.y,self.y-self.dy,self.c))
	end,
	draw = function(self)
		line(self.x,self.y,self.x,self.y+self.dy,self.c)
	end,
	cleanup = function(self)
		return self.y < -8 
	end
}

trail_shot={
	C=function(self,x,y1,y2,start_c)
		o={x=x,y1=y1,y2=y2,c=start_c,t=10,l=0}
		setmetatable(o,{__index=self})
		return o
	end,
	update = function(self)
		self.c = ({0,0,0,0,0,5,6,0,4,9,0,0,1,13,0})[self.c]
	end,
	draw = function(self)
		line(self.x, self.y1,self.x,self.y2,self.c)
	end,
	cleanup = function(self)
		return self.c==0
	end
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
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
