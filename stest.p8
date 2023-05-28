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

PLAYER_LAYER = 4
PLAYER_BULLET_LAYER = 3
ENEMY_BULLET_LAYER = 3
ENEMY_LAYER = 2
BACKGROUND_LAYER = 1

game={
	C=function(self)
		o={
			entities={},
			t=0
		}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		for e in all(self.entities) do
			print(e)			if (e.update) then e:update() end
			if (e:cleanup()) then del(self.entities, e) end
		end	
		self.t+=1
	end,
	draw=function(self)
		cls()
	 	for l=0,4 do
			for e in all(self.entities) do
			 	if e.draw then
					if e.l==l then e:draw() end
				end
			end	
		end
	end,
	start=function(self)
		add(self.entities,player:C(self))
		--add(self.entities,circle_shooter:C(self, 32, 64, 1, 10, 15))
		-- add(self.entities,circle_shooter:C(
		-- 	self, --game
		-- 	0, --x
		-- 	0, --y
		-- 	0, --dx
		-- 	0, --dy
		-- 	2, --target_d
		-- 	2, --amount
		-- 	0.5, --interval
		-- 	0, --inital_radius
		-- 	0.03, --dtheta
		-- 	0, --t_offset
		-- 	0, --theta
		-- 	nil) --parent
		-- )

		ship = ship:C(
			self,
			50,
			0,
			0,
			.5,
			32,
			16,
			4
		)
		add(self.entities,ship)
		add(self.entities,straight_shooter:C(self,-13, 0, 0, 0, nil, 0, 3, 15, 0, ship))
		add(self.entities,straight_shooter:C(self,13, 0, 0, 0, nil, 0, 3, 15, 7, ship))
	end
}

function always_false()
	return false
end

function entity_update(self)
end

function entity_draw(self)
	w = din(self.w,8)
	h = din(self.h,8)
	if type(self.s) == "table" then
		period = din(self.speriod,5)
		t = din(self.t,self.game.t)
		s = self.s[flr(t / period) % #self.s + 1]
	else
		s = self.s
	end
	spr(s, real_x(self)-w/2, real_y(self)-h/2, w/8, h/8)
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
			l=PLAYER_LAYER,
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
		add(self.game.entities,player_shot:C(real_x(self), real_y(self), self.game))
	end,
	cleanup=always_false
}

player_shot={
	C=function(self,x,y,game)
		o={x=x,y=y,dy=-3,ddy=-1,dymax=-12,l=PLAYER_BULLET_LAYER,c=({7,10,14})[flr(rnd(3))+1],game=game}
		setmetatable(o, {__index=self})
		return o
	end,
	update = function(self)
		self.dy=lim(0, self.dymax,self.dy+self.ddy)
		self.y+=self.dy
		add(self.game.entities,trail_shot:C(real_x(self),real_y(self),real_y(self)-self.dy,self.c))
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
		o={x=x,y1=y1,y2=y2,c=start_c,t=10,l=ENEMY_BULLET_LAYER}
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

function default_cleanup(self)
	w=din(self.w,0)
	h=din(self.h,0)
	if (self.parent and self.parent:cleanup()) then return true end
	x=real_x(self)
	y=real_y(self)
	return x < -w or y < -h or x > 128+w or y > 128+h
end

straight_shooter = {
	C=function(self,game,x,y,dx,dy,s,target_dx,target_dy,interval,t_offset,parent)
		o={game=game,x=din(x,0),y=din(y,0),dx=din(dx,0),dy=din(dy,0),target_dx=target_dx,target_dy=target_dy,interval=interval,t=din(t_offset,0),l=ENEMY_LAYER,s=s,w=8,h=8,parent=parent}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		self.t+=1
		if self.t>self.interval then
			add(self.game.entities, basic_bullet:C(self.game,real_x(self), real_y(self), self.target_dx, self.target_dy, {17,18}))
			self.t=0
		end
	end,
	draw=entity_draw,
	cleanup=default_cleanup
}

circle_shooter = {
	C=function(self,game,x,y,dx,dy,target_d,amount,interval,initial_radius,dtheta,t_offset,theta,parent)
		local o={game=game,x=din(x,0),y=din(y,0),dx=din(dx,0),dy=din(dy,0),target_d=target_d,amount=amount,initial_radius=initial_radius,interval=interval,t=0,l=ENEMY_LAYER,s=3,dtheta=din(dtheta,0),theta=din(theta,0),t_offset=din(t_offset,0),parent=parent}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		local r=din(self.initial_radius,0)
		self.t+=1+self.t_offset
		self.theta+=self.dtheta
		self.x+=self.dx
		self.y+=self.dy
		if self.t>self.interval then
			for i=1,self.amount do
				local t = i/self.amount+self.theta
				local st = sin(t)
				local ct = cos(t)
				add(self.game.entities, basic_bullet:C(self.game,real_x(self)+ct*r,real_y(self)+st*r,self.target_d*ct,self.target_d*st,{17,18}))
			end
			self.t=0
		end
	end,
	draw=entity_draw,
	cleanup=default_cleanup,
}

basic_bullet={
	C=function(self,game,x,y,dx,dy,s)
		local o={x=x,y=y,dx=dx,dy=dy,s=s,l=ENEMY_BULLET_LAYER,t=0,game=game}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		self.x+=self.dx
		self.y+=self.dy
		self.t+=1
	end,
	draw=entity_draw,
	cleanup=default_cleanup,
}

ship={
	C=function(self,game,x,y,dx,dy,w,h,s)
		local o={x=x,y=y,dx=dx,dy=dy,w=w,h=h,s=s,l=ENEMY_LAYER}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		self.x+=self.dx
		self.y+=self.dy
	end,
	draw=entity_draw,
	cleanup=default_cleanup,
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

-- Default if nill
function din(v,default)
	if v == nil then return default end
	return v
end

function real_x(e)
	if e.parent then return e.x + e.parent.x else return e.x end
end

function real_y(e)
	if e.parent then return e.y + e.parent.y else return e.y end
end

__gfx__
00000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000999999000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000900009009000900100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000
00000000000070000900009090000090111000000000000000000000000001110000000000000000000000000000000000000000000000000000000000000000
00000000000777000900009009000900155110000000000000000000000115510000000000000000000000000000000000000000000000000000000000000000
00000000007777700900009000909000555551100000000000000000011555550000000000000000000000000000000000000000000000000000000000000000
00000000077777770999999000090000155555511000001111000001155555510000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555551111115555111111555555550000000000000000000000000000000000000000000000000000000000000000
00000000009999000044440000000000155885555111155555511115555885510000000000000000000000000000000000000000000000000000000000000000
000000000900009004999940000000006558e5555555555555555555555e85560000000000000000000000000000000000000000000000000000000000000000
00000000900000094900009400888800065555555555555555555555555555600000000000000000000000000000000000000000000000000000000000000000
000000009008800949088094008ee800006666555555556666555555556666000000000000000000000000000000000000000000000000000000000000000000
000000009008800949088094008ee800000000666666550770556666660000000000000000000000000000000000000000000000000000000000000000000000
00000000900000094900009400888800000000000000650770560000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090000900499994000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
