#! /usr/bin/env lua

local function smi(b, ind)
	return setmetatable(b, {__index=ind})
end

local stack = {
	top = function(st, offset)
		offset = offset or 0
		return st[#st - offset]
	end,
	ins = function(st, offset, it)
		offset = offset or 0
		table.insert(st, #st - offset, it)
	end,
	rem = function(st, offset)
		offset = offset or 0
		return table.remove(st, #st - offset)
	end,
		
	push = function(st, it)
		st[#st + 1] = it
	end,
	pop = function(st)
		local it = st[#st]
		st[#st] = nil
		return it
	end,
}

local builtin = {
	nover = function(st)
		offset = st:pop()
		st:push(st:top(offset))
		return st
	end,

	dup = function(st)
		st:push(st:top(0))
		return st
	end,
	drop = function(st)
		st:pop()
		return st
	end,
	swap = function(st)
		st:push(st:rem(1))
		return st
	end,
	over = function(st)
		st:push(st:top(1))
		return st
	end,
	dupd = function(st)
		st:ins(1, st:top(1))
		return st
	end,
	swapd = function(st)
		st:ins(2, st:rem(1))
		return st
	end,
	nip = function(st)
		st:rem(1)
		return st
	end,
	rot = function(st)
		st:push(st:rem(2))
		return st
	end,
	nrot = function(st)
		st:ins(2, st:pop())
		return st
	end,
	ddup = function(st)
		st:over():over()
		return st
	end,

	add = function(st)
		local t = st:top() + st:top(1)
		st:pop()
		st:pop()
		st:push(t)
		return st
	end,
	sub = function(st)
		local t = st:top() - st:top(1)
		st:pop()
		st:pop()
		st:push(t)
		return st
	end,

	print = function(st)
		print(st:pop())
		return st
	end,

	exit = function(st)
		exit(st:top())
	end,
}
smi(stack, builtin)

local st = smi({}, stack)

local file = io.open(arg[1], "r")
local p = file:read("*all"):gmatch("%S+")
file:close()
for com in p do
	local act = builtin[com]
	if act then
		act(st)
	else
		st:push(tonumber(com) or com)
	end
end

