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
	frag=calc_frag()
end


function calc_frag()
	--get files with any segments
	files=0
	for i=0,15 do
		for p=0,w*h do if mget(p%w,p\w)==i then files += 1; break end end
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
cursor={0,0}
--0: selecting x/y
--1: selecting w/h
--2: placing
mode=0
dim={1,1}

function _update(dt)
 l,r,u,d,x,o=btnp(⬅️),btnp(➡️),btnp(⬆️),btnp(⬇️),btnp(❎),btnp(🅾️)
 if not(l or r or u or d or x or o) then return end
	if mode==0 then
		if (l) cursor[1]-=1
		if (r) cursor[1]+=1
		if (u) cursor[2]-=1
		if (d) cursor[2]+=1
		cursor[1]=min(max(0, cursor[1]), w-1)
		cursor[2]=min(max(0, cursor[2]), h-1)
		if (x) mode = 1
	elseif mode==1 then
	 if (l) dim[1]-=1
		if (r) dim[1]+=1
		if (u) dim[2]-=1
		if (d) dim[2]+=1
		dim[1]=min(max(1, dim[1]), w-cursor[1])
		dim[2]=min(max(1, dim[2]), h-cursor[2])
		if (x) mode = 2
	elseif mode==2 then
	end
	frag = calc_frag()
end

draw_frame=0

function _draw()
 draw_frame+=1
	cls()
	camera(-64+(w*4),-10)
	map(0,0,0,0,w,h)
	rect(-1,-1,w*8,h*8,7)
	--selection palette
	pal(({{[1]=0,[2]=0,[3]=5,[4]=7},
						 {[1]=7,[2]=0,[3]=0,[4]=5},
						 {[1]=5,[2]=7,[3]=0,[4]=0},
						 {[1]=0,[2]=5,[3]=7,[4]=0},
							})[draw_frame\4%4+1])
	--draw selector
	if mode==0 then
		spr(16, cursor[1]*8, cursor[2]*8)
	elseif mode==1 then
	 for x=cursor[1],cursor[1]+dim[1]-1 do
			tline(x*8,cursor[2]*8,(x+1)*8,cursor[2]*8,0,32)
			tline(x*8,(cursor[2]+dim[2])*8-1,(x+1)*8,(cursor[2]+dim[2])*8-1,0,32.875)
		end
		for y=cursor[2],cursor[2]+dim[2]-1 do
		 tline((cursor[1])*8,y*8,(cursor[1])*8,(y+1)*8,0,32.875)
		 tline((cursor[1]+dim[1])*8-1,y*8,(cursor[1]+dim[1])*8-1,(y+1)*8,0,32)
		end

	elseif mode==2 then
	end
	pal()
	--score
	print(tostr(frag) .. "% fragmented", 0, h*8 + 2)
	camera()
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
41234123000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14321432000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
