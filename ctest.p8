pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

function str_to_bytes(s)
    local out = {}
    for i=1,#s do add(out, ord(s[i])) end
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
    bit_pop = function(self)
        v = shr(band(self.data[self.cursor[1]]), shl(1,self.cursor[2]-1), self.cursor[2]-1)
        self:next()
        return v
    end,
    byte_pop = function(self)
        local v = 0
        for i = 0,7 do
            v += shl(self:bit_pop(), i)
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
    end
}

function read_bits(stream, start, count)
    -- start is bit - not byte. 0-based.
    -- count is in bits
    if count == nil then count = 1 end
    local returns = {}
    for i = start,start+count-1 do
        local cur_byte = flr(i/8)+1
        local cur_bit = i%8
        local byte_val = ord(stream[cur_byte])
        local bit_val = shr(band(byte_val, shl(1,cur_bit)), cur_bit)
        add(returns, bit_val)
    end
    return returns
end

function read_bytes(stream, start, count)
    -- start is bit - not byte. 0-based.
    -- count is in bytes
    local returns = {}
    for i = 1,count do
        local cur_overall_bit = start + (i - 1) * 8
        local val = 0
        for b,v in ipairs(read_bits(stream, cur_overall_bit, 8)) do
            if v == 1 then val += shl(1, b-1) end
        end
        add(returns, val)
    end
    return returns
end

function write_bits(stream, bits, start)
    -- start is bit in the stream to start writing to
    for i in all(bits) do
        local cur_overall_bit = start + i
        local cur_byte = flr(cur_overall_bit / 8) + 1
        local cur_bit = cur_overall_bit % 8
        while stream[cur_byte] == nil do stream ..= chr(0) end
        print(cur_overall_bit)
    end
end

function write_bytes(stream, bytes, start)
end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
