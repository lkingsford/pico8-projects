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
    end,
}

function merge(t1, t2)
    local o = {}
    for i in all(t1) do add(o, i) end
    for i in all(t2) do add(o, i) end
    return o
end

function huff_enc(data)
    local freq_table = {}
    for i in all(data) do if freq_table[i] == nil then freq_table[i] = 1 else freq_table[i] += 1 end end
    sorted_table = kv_to_ikv(freq_table)
    sort(sorted_table, function(a,b) return a[2] > b[2] end)
    nodes = {}
    for i in all(sorted_table) do add(nodes, {c={i[1]},p=i[2]}) end
    while #nodes > 1 do
        sort(nodes, function(a,b) return a.p > b.p end)
        new_node = {c=merge(nodes[1].c, nodes[2].c), p=nodes[1].p+nodes[2].p, l=nodes[1],r=nodes[2]}
        local s = "("
        for i in all(new_node.c) do s ..= i end
        s ..=")"
        add(nodes, new_node)
        del(nodes, nodes[1])
        del(nodes, nodes[1])
    end
    return nodes[1]
end

function huff_dec(data)
end

huff_enc({1,2,3,6,6,6,7,1,2,2,4,2})
