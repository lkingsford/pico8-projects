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
	short_read = function(self)
		return self:byte_read() + shl(self:byte_read(),8)
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
	short_push = function(self, v)
		self:byte_push(band(v, 255))
		self:byte_push(shr(band(v, 65280), 8))
	end,
	byte_insert = function(self, v, l)
	 	local new_data = {}
		for i, cv in ipairs(self.data) do
			if i == l then add(new_data, v) end
			add(new_data, cv)
		end
		self.data = new_data
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
	end,
	push_to_end = function(self)
	-- pushes to a new byte at end
		self.cursor[1] = #self.data + 1
		self.cursor[2] = 1
	end,
	next_actual_byte = function(self)
		self.cursor[1] += 1
		self.cursor[2] = 1
	end,
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

function contains(table, v)
	for c in all(table.c) do
		if c == v then return true end
	end	
	return false
end

function huff_enc_char(output, v, tree)
	if #tree.c <= 1 then return end
	if contains(tree.l, v) then
		output:bit_push(0) 	
		huff_enc_char(output, v, tree.l)
	elseif contains(tree.r, v) then
		output:bit_push(1)
		huff_enc_char(output, v, tree.r)
	else
		print("character "..v.. " not found in tree")
	end
end

function huff_enc(data)
	local nodes, node_count = generate_huff_tree(data)

	-- Encode huffman tree - 
	-- Encoded as byte N, followed by a series of a bit 'b', then optionally byte 'B'. 
	-- N is the size of the tree in bytes
	-- b is if current node is leaf (1) or branch (0)
	-- B is (if leaf) the value of the leaf
	local output = stream:c()
	huff_enc_node(nodes, output)
	output:byte_insert(#output.data,1)
	output:push_to_end()
	output:short_push(#data)

	for v in all(data) do
		huff_enc_char(output, v, nodes)
	end
	return output.data
end

function huff_dec_node(input, last_byte)
	if input.cursor[1] > last_byte then return {c={}} end
	if input:bit_read() == 0 then
		-- branch
		local l = huff_dec_node(input, last_byte)
		local r = huff_dec_node(input, last_byte)
		local c = {}
		for i in all(l.c) do add(c, i) end
		for i in all(r.c) do add(c, i) end
		return {c=c, l=l, r=r}
	else
		-- leaf
		return {c={input:byte_read()}}
	end
end

function huff_dec(data)
	local input = stream:c(data)
	print("data # is " .. #data .. " [1] is " .. data[1])
	local byte_count = input:byte_read()
	local leafs = {}
	-- Decode huffman tree
	root=huff_dec_node(input, byte_count + 1)
	-- File size
	input:next_actual_byte()
	output_size=input:short_read()
	print("listed output_size is ".. output_size)
	output = {}
	node = root
	while #output < output_size do
		if input:bit_read() == 0 then
			node = node.l
		else
			node = node.r
		end
		if not(node.l) then
			add(output,node.c[1])
			node = root
		end
	end
	return output
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
		for i in all(node.c) do c ..= i end
	print(c,x-#node.c*2,y-1,8) end
end

mmg_song = "I am the very model of a modern Major-General I've information vegetable, animal, and mineral I know the kings of England, and I quote the fights Historical From Marathon to Waterloo, in order categorical I'm very well acquainted, too, with matters Mathematical I understand equations, both the simple and quadratical About binomial theorem I'm teeming with a lot o' news With many cheerful facts about the square of the Hypotenuse With many cheerful facts about the square of the Hypotenuse With many cheerful facts about the square of the Hypotenuse With many cheerful facts about the square of the Hypotepotenuse I'm very good at integral and differential calculus I know the scientific names of beings animalculous In short, in matters vegetable, animal, and mineral I am the very model of a modern Major-General In short, in matters vegetable, animal, and mineral He is the very model of a modern Major-General"
compressed = huff_enc(str_to_bytes(mmg_song))
decompressed = bytes_to_str(huff_dec(compressed))

print("mmg:" .. #decompressed .. "->" .. #compressed)
--stop()
if mmg_song == decompressed then print("decompressed matches") else print("decompressed does not match") end

stop()
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
	draw_tree(decompressed, cx, cy)
end
