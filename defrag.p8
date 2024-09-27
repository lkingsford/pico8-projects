pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
w=12
h=8

--used just for tline on the selector
mset(0,32,16)

function _init_game()
 aloc=w*h-30
 placed=0
	for i=2,15 do
		fw=flr(rnd(6))+4
		fh=flr(rnd(4))+1
		x0=flr(rnd(w-fw))
		y0=flr(rnd(h-fh))
		for x=x0,x0+fw do
			for y=y0,y0+fh do
			 if mget(x,y) == 0 then placed+=1;mset(x,y,i) end
			end
		end
	end
	while placed>aloc do
	 x=flr(rnd(w))+1
	 y=flr(rnd(h))+1
	 if mget(x,y)!=0 then
	  mset(x,y,0)
	  placed-=1
	 end
	end
	--add unmoveables
	for obs_i=0,1 do
		placed=false
		while not placed do
			x0=flr(rnd(w))-4
			w0=flr(rnd(6))+2
			y0=flr(rnd(h))
			x=x0
			y=y0
			problem=false
			for i=0,w0 do
				x+=1
				if (x>w) x=0;y+=1
				for x2=x-3,x+3 do for y2=y-3,y+3 do
					if (mget(x2,y2)==1) problem=true
				end end
	   if (problem) break
			end
			if not problem then
				for i=0,w0 do
					x+=1
					if (x>w) x=0;y+=1
					mset(x,y,1)
					placed=true
				end
			end
		end
	end
	--init score
	frag=calc_frag()
end


function calc_frag()
	--get files with any segments
	files=0
	for i=0,15 do
	 --exclude unmoveable
		if i!= 1 then for p=0,w*h do if mget(p%w,p\w)==i then files += 1; break end end end
	end
	u={}
	seg_count=0
	for p=0,w*h do
		if not u[p] do 
			visited={}
			to_visit={p}
			file=mget(p%w,p\w)
			seg_count+=1
			while #to_visit > 0 do
				checking=to_visit[#to_visit]
				x=checking%w
				y=checking\w
				deli(to_visit)
				if not u[checking] and not visited[checking] and x>=0 and x<=w and y>=0 and y<=h then
					if mget(x,y)==file then
						u[checking]=true
						add(to_visit,x-1+y*w)
						add(to_visit,x+1+y*w)
						add(to_visit,x+(y-1)*w)
						add(to_visit,x+(y+1)*w)
					end
					visited[p]=true
				end
			end
		end
	end
	return 100-flr(files*100/seg_count)
end

frag = 100
init_xr_csr={0,0}
xy_csr={0,0}
--0: selecting x/y
--1: selecting w/h
--2: placing
mode=0
wh_csr={1,1}
mv_csr={0,0}
mv_rot=0
fail_flash=0
pass_flash=0

function _update(dt)
	camera(-64+(w*4),-10)
 l,r,u,d,x,o=btnp(⬅️),btnp(➡️),btnp(⬆️),btnp(⬇️),btnp(❎),btnp(🅾️)
 if not(l or r or u or d or x or o) then return end
	if mode==0 then
	 local new_x=xy_csr[1]
		local new_y=xy_csr[2]
		if (l) new_x-=1
		if (r) new_x+=1
		if (u) new_y-=1
		if (d) new_y+=1
		if mget(new_x,new_y) == 1 or new_x<0 or new_x>=w or new_y<0 or new_y>=h then
		 sfx(4)
			return
		end
		xy_csr[1]=new_x
		xy_csr[2]=new_y
		xy_corner_1={xy_csr[1],xy_csr[2]}
		xy_corner_2={xy_csr[1],xy_csr[2]}
		if (x) mode = 1
	elseif mode==1 then
	 local new_x=xy_corner_2[1]
		local new_y=xy_corner_2[2]
	 new_x+=(r and 1 or l and -1 or 0)
	 new_y+=(d and 1 or u and -1 or 0)
		new_xy_csr={min(xy_corner_1[1], new_x), min(xy_corner_1[2], new_y)}
		new_wh_csr={abs(xy_corner_1[1]-new_x)+1, abs(xy_corner_1[2]-new_y)+1}
		for ix=new_xy_csr[1],new_xy_csr[1]+new_wh_csr[1]-1 do
			for iy=new_xy_csr[2],new_xy_csr[2]+new_wh_csr[2]-1 do
				if mget(ix,iy) == 1 then
					sfx(4)
					return
				end
			end
		end
		if new_xy_csr[1]<0 or
					new_xy_csr[1]+new_wh_csr[1]>w or
					new_xy_csr[2]<0 or
					new_xy_csr[2]+new_wh_csr[2]>h then
			sfx(4)
			return
		end
		xy_csr=new_xy_csr
		wh_csr=new_wh_csr
		xy_corner_2={new_x, new_y}
		if x then
		 mode = 2
			mv_csr={xy_csr[1],xy_csr[2]}
			mv_rot=0
			for row=0,wh_csr[2]-1 do
				memset(0x2020+row*128,0,32)
				memcpy(0x2020+row*128,0x2000+(xy_csr[2]+row)*128+xy_csr[1],wh_csr[1])
			end
			for row=wh_csr[2],h do
				memset(0x2020+row*128,0,32)
			end
		end
	elseif mode==2 then
	 if (l) mv_csr[1]-=1
	 if (r) mv_csr[1]+=1
	 if (u) mv_csr[2]-=1
	 if (d) mv_csr[2]+=1
	 local d = wh_csr
		if (mv_rot % 2 == 1) d = {wh_csr[2], wh_csr[1]}
		if o then
			--rotate
			if d[1]>h or d[2]>w then
				sfx(0)
				fail_flash=1
				fail_flash_rect={mv_csr[1]*8,mv_csr[2]*8,mv_csr[1]*8+d[1]*8,mv_csr[2]*8+d[2]*8}
				return
			end
			mv_rot += 1
			mv_rot %= 4
		 sfx(3)
			for _y=0,h do
			 --stop abusing map memory, maybe one day you won't have any left
				memset(0x2040+y*128,0,32)
			end
			cls()
			for _x=0,d[1]-1 do for _y=0,d[2]-1 do
			 mset(_y+64,_x,mget(d[1]-_x+31,_y))
			end end
			for _y=0,h do
				memset(0x2020+y*128,0,32)
			end
			for _y=0,h do
				memcpy(0x2020+_y*128,0x2040+_y*128,d[2])
			end
		end
		if x then
		 if mv_rot==0 and mv_csr[1]==xy_csr[1] and mv_csr[2]==xy_csr[2] then
				--aborted
				sfx(1)
				wh_csr={1,1}
				mode=0
				return
			end
			fits = true
			for _x=0,d[1]-1 do for _y=0,d[2]-1 do
				if (mget(_x+mv_csr[1],_y+mv_csr[2])!=0 and mget(_x+32,_y)!=0) fits=false
			end end
			if not fits then
				fail_flash=1
				fail_flash_rect={mv_csr[1]*8,mv_csr[2]*8,mv_csr[1]*8+d[1]*8-1,mv_csr[2]*8+d[2]*8-1}
				sfx(0)
				return
			end
			sfx(2) --todo: make better sound on better move
			for _x=0,wh_csr[1]-1 do for _y=0,wh_csr[2]-1 do
				mset(xy_csr[1]+_x,xy_csr[2]+_y,0)
			end end
			for _x=0,d[1]-1 do for _y=0,d[2]-1 do
				m=mget(_x+32,_y)
				if m!=0 then
					mset(mv_csr[1]+_x,mv_csr[2]+_y,mget(_x+32,_y))
				end
			end end
			pass_flash=1
			pass_flash_rect={mv_csr[1]*8,mv_csr[2]*8,mv_csr[1]*8+d[1]*8-1,mv_csr[2]*8+d[2]*8-1}
			wh_csr={1,1}
			xy_csr=mv_csr
			mode = 0
		end
		d = wh_csr
		if (mv_rot % 2 == 1) d = {wh_csr[2], wh_csr[1]}
	 mv_csr[1]=min(max(0, mv_csr[1]), w-d[1])
	 mv_csr[2]=min(max(0, mv_csr[2]), h-d[2])
	end
	frag = calc_frag()
end

draw_frame=0

function fbtn(x0,y0,x1,y1,s,t)
	line(x0+1,y0,x1-1,y0,7)
	line(x0,y0+1,x0,y1-1,7)
	line(x0+1,y1,x1-1,y1,5)
	line(x1,y0+1,x1,y1-1,5)
	spr(s,x0+1,y0+1)
	print(t,x0+11,y0+2,0)
end

function pad(i,z)
 s = tostr(i)
	for _=0,z-#s-1 do s="0"..s end
	return s
end

function _draw()
 draw_frame+=1
	cls(3)
	--unnecessary background
	camera()
	spr(32,5,5,2,2)
	print("computer", 1,19,0)
	line(0,117,127,117,5)
	rectfill(0,118,127,127,6)
	fbtn(0,118,30,127,34,"play")
	fbtn(32,118,70,127,35,"defrag")
	rectfill(108,118,127,127,5)
	line(108,127,127,127,7)
	line(108,118,108,127,0)
	line(108,118,127,118,0)
	t()
	print(pad(stat(93),2)..":"..pad(stat(94),2), 109,120,0)
	--unnecessary window aesthetics
	camera(-64+(w*4),-10)
	rect(-1,-9,w*8+1,h*9+1,5)
	rectfill(-2,-9,w*8,h*9,7)
	rectfill(-2,-9,w*8,-1,1)
	rect(-2,-9,w*8,h*9,6)
	map(0,0,0,0,w,h)
	rectfill(-2,h*8,w*8,h*9,6)
	rect(-1,-1,w*8-1,h*8-1,5)
	print("defrag",9,-7,7)
	spr(50, -1, -8)
	--selection palette
	pal(({{[0]=0,0,0,5,7,1,12,7,0},{[0]=0,7,0,0,5,1,12,7,0},{[0]=0,5,7,0,0,1,12,7,0},{[0]=0,0,5,7,0,1,12,7,0}})[draw_frame\4%4+1])
	if mode==0 then
		spr(16, xy_csr[1]*8, xy_csr[2]*8)
	elseif mode==1 then
		for x=xy_csr[1],xy_csr[1]+wh_csr[1]-1 do for y=xy_csr[2],xy_csr[2]+wh_csr[2]-1 do spr(17+draw_frame\4%4,x*8,y*8) end end
	 for x=xy_csr[1],xy_csr[1]+wh_csr[1]-1 do
			tline(x*8,xy_csr[2]*8,(x+1)*8,xy_csr[2]*8,0,32)
			tline(x*8,(xy_csr[2]+wh_csr[2])*8-1,(x+1)*8,(xy_csr[2]+wh_csr[2])*8-1,0,32.875)
		end
		for y=xy_csr[2],xy_csr[2]+wh_csr[2]-1 do
		 tline((xy_csr[1])*8,y*8,(xy_csr[1])*8,(y+1)*8,0,32.875)
		 tline((xy_csr[1]+wh_csr[1])*8-1,y*8,(xy_csr[1]+wh_csr[1])*8-1,(y+1)*8,0,32)
		end
	elseif mode==2 then
		for x=xy_csr[1],xy_csr[1]+wh_csr[1]-1 do for y=xy_csr[2],xy_csr[2]+wh_csr[2]-1 do spr(21,x*8,y*8) end end
		rect(xy_csr[1]*8, xy_csr[2]*8, xy_csr[1]*8+wh_csr[1]*8-1, xy_csr[2]*8+wh_csr[2]*8-1, 8)
	end
	palt()
	pal()
	--active chunk
	if mode==2 then
	 local d = wh_csr
		if (mv_rot % 2 == 1) d = {wh_csr[2], wh_csr[1]}
		map(32,0,mv_csr[1]*8,mv_csr[2]*8,d[1],d[2])
		camera(-64+(w*4),-10)
		rect(mv_csr[1]*8,mv_csr[2]*8,mv_csr[1]*8+d[1]*8,mv_csr[2]*8+d[2]*8,0)
		rect(mv_csr[1]*8,mv_csr[2]*8,mv_csr[1]*8+d[1]*8-1,mv_csr[2]*8+d[2]*8-1,8)
		if not(mv_rot==0 and mv_csr[1]==xy_csr[1] and mv_csr[2]==xy_csr[2])then
			for x=0,d[1]-1 do for y=0,d[2]-1 do
				if (mget(x+mv_csr[1],y+mv_csr[2])!=0 and mget(x+32,y)!=0) spr(21,(x+mv_csr[1])*8,(y+mv_csr[2])*8)
			end end	
		end
	end
	--animations
	if fail_flash > 0 then
		fail_flash -= 0.125
		if (fail_flash >= .325) c = 8
		if (fail_flash >= .5) c = 9
		if (fail_flash >= .75) c = 10
		rect(fail_flash_rect[1],fail_flash_rect[2],fail_flash_rect[3],fail_flash_rect[4],c)
	end
	if pass_flash >0 then
		pass_flash -= 0.0625
		if (pass_flash >= .125) c = 1
		if (pass_flash >= .5) c = 3
		if (pass_flash >= .75) c = 11
		rect(pass_flash_rect[1],pass_flash_rect[2],pass_flash_rect[3],pass_flash_rect[4],c)
	end
	--score
	print(tostr(frag).."% fragmented",0,h*8+1,0)
end

_init_game()
__gfx__
00000000888888825555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
0000000088888828566666655dd1111556666665599999955aaaaaa55bb33bb55dd66dd55cccccc5599999955aaaaaa552222445599ff9955111111552222225
0000000088888288566666655dd1111556666665599999955adddda55bb33bb55dd66dd55ccccce55999999559aaaaa55222244559ffff955111111552222225
0000000088882888566663355111111556666665599dd9955adaada55bb33bb55dddddd55ccccee559999995599aaaa5522222255ffffff55dddddd55aa22225
0000000088828888566663355111111556666665599dd9955adaada55bb33bb55dddddd55ccceee55dddddd55999aaa5522222255ffffff55dddddd55aa22225
00000000882888885663366551111dd554466665599999955adddda55bb33bb55dd66dd55cceeee55dddddd559999aa55442222559ffff955111111552222225
00000000828888885663366551111dd554466665599999955aaaaaa55bb33bb55dd66dd55ceeeee55dddddd5599999a554422225599ff9955111111552222225
00000000288888885555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
41234123600560055600560005600560005600560808080800000000000000000000000000000000000000000000000000000000000000000000000000000000
30000004000000000000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000001056005600056005660056005560056000808080800000000000000000000000000000000000000000000000000000000000000000000000000000000
10000002000000000000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000003600560055600560005600560005600560808080800000000000000000000000000000000000000000000000000000000000000000000000000000000
30000004000000000000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000001056005600056005660056005560056000808080800000000000000000000000000000000000000000000000000000000000000000000000000000000
14321432000000000000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000666666650000000900000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000077777776500000111000000b003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007333333376500015551008aaab00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000736331137650001d1d1008cc1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000733336637650001d1d1008cc1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007333366376500011111008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007333333376500011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00057666666676550011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00667777777766650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0076bb75557607650666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00766666677777650666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777650677776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000655556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300000000005460084500845000450004300042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000000000180201f0301e75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000000000000137501375018750187401875018740187500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000000000000001c7402171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000032004300003000430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
