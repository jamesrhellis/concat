lex = {
	patterns = {
		string = "^\"([^\n]*)\"",
		number = "^(%d+%.?%d*)",
		s_symbol = "^([%[%]])",
	},
	s_symbol = function(string)
		return string
	end,
	string = function(string)
		return string:sub(2, -2)
	end,
	number = tonumber,
	-- Default file starting point
	pos = 0,
	token = nil,
}
lex.__index = lex

function lex:lex(string, from_int) 
	local _, e_space = string:find("^%s*", from_int)
	from_int = (e_space+1) or from_int

	for tp, pattern in pairs(self.patterns) do
		local start, e_match, match_str = string:find(pattern, from_int)
		if start then
			return e_match + 1, self[tp](match_str)
		end
	end

	local start, e_match, match_str = string:find("^(%S+)", from_int)

	return (e_match or string:len()) + 1, builtin[match_str]
end

function lex:next()
	self.pos, self.token = self:lex(self.str, self.pos)
	return self.token
end

function lex:iter()
	return function()
		return self:next()
	end
end

function lex:new(str)
	return setmetatable({str = str}, lex)
end
