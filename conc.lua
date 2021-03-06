#! /usr/bin/env lua
dofile("lex.lua")

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
		return st
	end,
	pop = function(st)
		local it = st[#st]
		st[#st] = nil
		return it
	end,
}

local function build_q(lex)
	local st = smi({}, stack)
	for token in lex:iter() do
		if token == "[" then
			token = build_q(lex)
		elseif token == "]" then
			return st
		end
		st:push(token)
	end

	return st
end

builtin = {
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
	rot = function(st)
		st:push(st:rem(2))
		return st
	end,
	nrot = function(st)
		st:ins(2, st:pop())
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
		local t = st:top(1) - st:top()
		st:pop()
		st:pop()
		st:push(t)
		return st
	end,
	gt = function(st)
		local t = st:top(1) > st:top()
		st:pop()
		st:pop()
		st:push(t)
		return st
	end,

	wrap = function(st)
		local no = st:pop()
		local t = {}
		for i=1,no do
			t[#t + 1] = st:pop()
		end
		st:push(t)
		return st
	end,

	call = function(st)
		if type(st:top()) ~= "function" then
			return st
		end

		st:pop()(st)
		return st
	end,
	dip = function(st)
		local hid = st:rem(1)
		st:apply()
		st:push(hid)

		return st
	end,

	pop = function(st)
		st:push(st:top():pop())
		return st
	end,
	push = function(st)
		st:push(st:top():pop())
		return st
	end,

	map = function(st)
		local f = st:pop()
		for _, it in ipairs(st:pop()) do
			st:push(it):push(f):apply()
		end
		return st
	end,
	[ "if" ] = function(st)
		local f = st:pop()
		local t = st:pop()
		if st:pop() == true then
			st:push(t)
		else
			st:push(f)
		end
		st:apply()
	
		return st
	end,

	apply = function(st)
		for _, it in ipairs(st:pop()) do
			st:push(it):call()
		end

		return st
	end,

	stat = function(st)
		print("")
		print("----stack----")
		for i, v in ipairs(st) do
			print(v)
		end
		print("--")
		
		return st
	end,

	def = function(st)
		local name = st:pop()
		local body = st:pop()
		user[name] = function(st)
			st:push(body):apply()
		end
		return st
	end,

	print = function(st)
		io.write(st:pop())
		return st
	end,

	dofile = function(st)
		local file = io.open(st:pop(), "r")
		st:push(build_q(lex:new(file:read("*all"))))
		file:close()
		st:apply()
		return st
	end,
		
	exit = function(st)
		exit(st:top())
	end,
}

smi(stack, builtin)
user = smi({}, builtin)

local st = smi({}, stack)
st:push("std"):dofile():push(arg[1]):dofile()


	--[[
for com in p do

	print("")
	print("----stack----")
	for i, v in ipairs(st) do
		print(v)
	end
	print("--")
end
	--]]
