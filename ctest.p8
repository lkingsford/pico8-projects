pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

function kv_to_ikv(t)
	local out = {}
	for k,v in pairs(t) do
		add(out, {k,v})
	end
	return out
end

function sort(t, c)
	if c == nil then c = function(a,b) return a > b end end
	for i=1,#t do
		local j = i
		while j > 1 and c(t[j-1], t[j]) do
			t[j],t[j-1] = t[j-1],t[j]
			j = j - 1
		end
	end
end

function str_to_bytes(s)
	local out = {}
	for i=1,#s do add(out, ord(s[i])) end
	return out
end

function bytes_to_str(b)
	local out = ""
	for i in all(b) do out ..= chr(i) end
	return out
end

stream = {
	c = function(self, stream)
		if stream == nil then stream = {} end
		local o = {
			data = stream,
			cursor = {1, 1}
		}
		setmetatable(o, {__index=self})
		return o
	end,
	bit_read = function(self)
		v = shr(band(self.data[self.cursor[1]], shl(1,self.cursor[2]-1)), self.cursor[2]-1)
		self:next()
		return v
	end,
	byte_read = function(self)
		local v = 0
		for i = 0,7 do
			v += shl(self:bit_read(), i)
		end
		return v
	end,
	bit_push = function(self, v)
		if self.cursor[1] > #self.data then add(self.data, 0) end
		if v > 0 then self.data[self.cursor[1]] += shl(1, self.cursor[2] - 1) end
		self:next()
	end,
	byte_push = function(self, v)
		for i = 0,7 do
			self:bit_push(shr(band(v, shl(1, i))), i)
		end
	end,
	next = function(self)
		self.cursor[2] += 1
		if self.cursor[2] == 9 then self.cursor[1] += 1 self.cursor[2] = 1 end
	end,
	p = function(self)
		local s = ""
		for v in all(self.data) do
			s ..= v .. " "
		end
		print(s)
	end,
	eof = function(self)
		return self.cursor[1] > #self.data
	end
}

function merge(t1, t2)
	local o = {}
	for i in all(t1) do add(o, i) end
	for i in all(t2) do add(o, i) end
	return o
end

function generate_huff_tree(data)
	local freq_table = {}
	for i in all(data) do
		if freq_table[i] == nil then
			freq_table[i] = 1
		else 
			freq_table[i] += 1 
		end
	end
	sorted_table = kv_to_ikv(freq_table)
	sort(sorted_table, function(a,b) return a[2] > b[2] end)
	nodes = {}
	for i in all(sorted_table) do add(nodes, {c={i[1]},p=i[2]}) end
	while #nodes > 1 do
		sort(nodes, function(a,b) return a.p > b.p end)
		new_node = {c=merge(nodes[1].c, nodes[2].c), p=nodes[1].p+nodes[2].p, l=nodes[1],r=nodes[2]}
		add(nodes, new_node)
		del(nodes, nodes[1])
		del(nodes, nodes[1])
	end
	return nodes[1], #sorted_table
end

function huff_enc_node(node, stream)
	if node.l == nil then
		stream:bit_push(1)
		stream:byte_push(node.c[1])
	else
		stream:bit_push(0)
		huff_enc_node(node.l, stream)
		huff_enc_node(node.r, stream)
	end
end

function huff_enc(data)
	local nodes, node_count = generate_huff_tree(data)

	-- Encode huffman tree - 
	-- Encoded as byte N, followed by a series of a bit 'b', then optionally byte 'B'. 
	-- N is total number of nodes
	-- b is if current node is leaf (1) or branch (0)
	-- B is (if leaf) the value of the leaf
	local output = stream:c()
	output:byte_push(node_count)
	huff_enc_node(nodes, output)
	return output.data
end

function huff_dec(data)
	local input = stream:c(data)
	print("data # is " .. #data .. " [1] is " .. data[1])
	local node_count = input:byte_read()
	print("node count = " .. node_count)
	local root = {}
	stack = {root}
	leafs = {}
	-- Decode huffman tree
	while #leafs < node_count do
		if input:bit_read() == 1 then
			print("leaf")
			-- leaf
			local byte = input:byte_read()
			local leaf = {c={byte}, p=stack[#stack]}
			add(leafs, leaf)
			local n = leaf.p
			while n do 
				add(n.c,leaf.c[0]) 
				n = n.p
			end
			if stack[#stack].l == nil then stack[#stack].l = leaf print('set l') else stack[#stack].r = leaf print('set r') end
			while #stack > 1 and n != nil and n.l != nil and n.r != nil do n=stack[#stack] del(stack, n) end
			print("after while")
		else
			print("branch")
			-- branch
			add(stack, {c={},p=stack[#stack]})
		end
		print(#leafs)
	end
	return root
end

function draw_tree(node, x, y, layer)
	layer = layer or 1
	if node.x then
		w = #node.c*4
	else
		w = 10
	end
	ovalfill(x-max(5, w/2), y-5, x+max(5,w/2), y+5, 7)
	if node.l then
		local lx = x - 64 / layer
		local rx = x + 64 / layer
		local ny = y + 20
		line(x, y, lx, ny, 6)
		line(x, y, rx, ny, 6)
		draw_tree(node.l, lx, ny, layer + 1)
		draw_tree(node.r, rx, ny, layer + 1)
	end
	local c = ""	
	if node.c then 
		for i in all(node.c) do c ..= chr(i) end
	print(c,x-#node.c*2,y-1,8) end
end

--mmg_song = "I am the very model of a modern Major-General I've information vegetable, animal, and mineral I know the kings of England, and I quote the fights Historical From Marathon to Waterloo, in order categorical I'm very well acquainted, too, with matters Mathematical I understand equations, both the simple and quadratical About binomial theorem I'm teeming with a lot o' news With many cheerful facts about the square of the Hypotenuse With many cheerful facts about the square of the Hypotenuse With many cheerful facts about the square of the Hypotenuse With many cheerful facts about the square of the Hypotepotenuse I'm very good at integral and differential calculus I know the scientific names of beings animalculous In short, in matters vegetable, animal, and mineral I am the very model of a modern Major-General In short, in matters vegetable, animal, and mineral He is the very model of a modern Major-General"
-- print("uncompressed length: ".. #mmg_song)
mmg_song = chr(1) .. chr(1) .. chr(2) .. chr(3) .. chr(4) .. chr(5)
compressed = huff_enc(str_to_bytes(mmg_song))

cls()

print("compressed length:" .. #compressed)
decompressed = huff_dec(compressed)
if compressed == decompressed then print("decompressed matches") else print("decompressed does not match") end

--tree = generate_huff_tree(str_to_bytes(mmg_song))
print(decompressed.l)
print(decompressed.r)

cx=64
cy=10
function _update()
	if btnp(⬅️) then cls() cx+=20 end
	if btnp(➡️) then cls() cx-=20 end
	if btnp(⬆️) then cls() cy+=20 end
	if btnp(⬇️) then cls() cy-=20 end
end
-- 
function _draw()
	draw_tree(stack[2], cx, cy)
end
