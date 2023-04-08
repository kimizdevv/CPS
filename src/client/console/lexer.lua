export type Token = {
	type: string,
	value: string,
	nlcount: number
};

local CONFIG = require(script.Parent.config);
local SEP = CONFIG.LEXER.SEP;

function capture_until_sep(s: string, i: number): (string?, string?, number)
	local capture: string, sepCapture: string = "", "";
	local pos = i;
	local nowsep, nownl = false, false;
	local quote = false;
	while true do
		local c = s:sub(pos, pos);
		local matchesSep = c:match(SEP) ~= nil;
		if c == '\n' then
			if pos == i then
				nownl = true;
				sepCapture ..= c;
			else
				break;
			end
		elseif c ~= '\n' and nownl then
			break;
		elseif c == "" or (nowsep and not matchesSep) then
			break;
		elseif c == '"' then
			quote = not quote;
			capture ..= c;
		elseif not quote and matchesSep then
			nowsep = true;
			sepCapture ..= c;
		elseif not nowsep then
			capture ..= c;
		elseif not quote then
			break;
		end
		pos += 1;
	end
	return capture ~= "" and capture or nil, sepCapture ~= "" and sepCapture or nil, pos;
end

function getNumOfChar(s: string, c: string)
	local n = 0;
	for _, char in s:split("") do
		n = n + (char == c and 1 or 0);
	end
	return n;
end

function isCommand(s: string)
	return CONFIG.COMMANDS[s:upper()] ~= nil or CONFIG.INTERNAL_COMMANDS[s:upper()] ~= nil;
end

function isString(s: string)
	return s:sub(1, 1) == '"' and s:sub(-1, -1) == '"';
end

function isNumber(s: string)
	return tonumber(s) ~= nil;
end

function isBoolean(s: string)
	return s == "true" or s == "false";
end

function isPlayer(s: string)
	return game.Players:FindFirstChild(s) ~= nil;
end

-- 'ban crimzytron "You have been banned for exploiting."'
return function(s: string, highlightingMode: boolean?)
	highlightingMode = highlightingMode == nil and true or false;
	local tok: { Token } = { };
	local ws, rest = s:match("^("..SEP.."*)(.+)");
	if ws ~= "" then
		s = rest;
		if highlightingMode then tok[1] = { type = "IDEN", value = ws, nlcount = 0 }; end;
	end
	if s then
		local capture, sepCapture, pos = capture_until_sep(s, 1);
		while capture or sepCapture do
			-- determine the type of that string
			if capture then
				local token: Token = { type = "IDEN", value = capture, nlcount = 0 };
				if isCommand(capture) then
					token.type = "COMMAND";
				elseif isString(capture) then
					token.type = "STRING";
				elseif isNumber(capture) then
					token.type = "NUMBER";
				elseif isBoolean(capture) then
					token.type = "BOOLEAN";
				elseif isPlayer(capture) then
					token.type = "PLAYER";
				end
				tok[#tok+1] = token;
			end
			if highlightingMode and sepCapture then
				tok[#tok+1] = { type = "IDEN", value = sepCapture, nlcount = getNumOfChar(sepCapture, '\n') };
			end
			capture, sepCapture, pos = capture_until_sep(s, pos);
		end
	end
	return tok;
end
