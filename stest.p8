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
			entities={},
			t=0
		}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		for e in all(self.entities) do
			if (e.update) then e:update() end
			if (e.cleanup and e:cleanup()) then del(self.entities, e) end
		end	
		self.t+=1
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
		--add(self.entities,straight_shooter:C(self,32, 32, 1.5, 0, 15))
		--add(self.entities,circle_shooter:C(self, 32, 64, 1, 10, 15))
		add(self.entities,circle_shooter:C(self, 96, 64, 2, 3, 2, 0,.1))
	end
}

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
	spr(s, self.x-w/2, self.y-h/2, w/8, h/8)
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

function enemy_cleanup(self)
	return false
end

function bullet_cleanup(self)
	return self.x < -16 or self.y < -16 or self.x > 144 or self.y > 144
end

straight_shooter = {
	C=function(self,game,x,y,target_dx,target_dy,interval)
		o={game=game,x=x,y=y,target_dx=target_dx,target_dy=target_dy,interval=interval,t=0,l=1,s=2,w=8,h=8}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		self.t+=1
		if self.t>self.interval then
			add(self.game.entities, basic_bullet:C(self.game,self.x, self.y, self.target_dx, self.target_dy, {17,18}))
			self.t=0
		end
	end,
	draw=entity_draw,
	cleanup=enemy_cleanup(self)
}

circle_shooter = {
	C=function(self,game,x,y,target_d,amount,interval,initial_radius,dtheta)
		local o={game=game,x=x,y=y,target_d=target_d,amount=amount,initial_radius=initial_radius,interval=interval,t=0,l=1,s=3,dtheta=dtheta,theta=0}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		local r=din(self.initial_radius,0)
		self.t+=1
		self.theta+=din(self.dtheta,0)
		print(self.theta,100,100)
		if self.t>self.interval then
			for i=1,self.amount do
				local t = i/self.amount+self.theta
				local st = sin(t)
				local ct = cos(t)
				add(self.game.entities, basic_bullet:C(self.game,self.x+ct*r,self.y+st*r,self.target_d*ct,self.target_d*st,{17,18}))
			end
			self.t=0
		end
	end,
	draw=entity_draw
}

basic_bullet={
	C=function(self,game,x,y,dx,dy,s)
		local o={x=x,y=y,dx=dx,dy=dy,s=s,l=1,t=0,game=game}
		setmetatable(o,{__index=self})
		return o
	end,
	update=function(self)
		self.x+=self.dx
		self.y+=self.dy
		self.t+=1
	end,
	draw=entity_draw,
	cleanup=bullet_cleanup,
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

__gfx__
00000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000999999000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000900009009000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000070000900009090000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000777000900009009000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007777700900009000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777770999999000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090000900499994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900000094900009400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900880094908809400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900880094908809400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900000094900009400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090000900499994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
