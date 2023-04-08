local TextService = game:GetService("TextService");
local UserInput = game:GetService("UserInputService");

local conscrgui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("console");
local ui = conscrgui:WaitForChild("main");
local canvas = ui.canvas;
local assets = ui.assets;

local con: TextBox;
local signalConnectionA: RBXScriptConnection;
local signalConnectionB: RBXScriptConnection;
local signalConnectionC: RBXScriptConnection;
local signalConnectionD: RBXScriptConnection;

local BOUNDX = canvas.AbsoluteSize.X;
local CONFIG = require(script.config);

local currentPrefix: string;
local hinting, currentHint: string? = false, nil;

local lexer = require(script.lexer);
local console = { };

local history: { string? }, historyEnabled: boolean = { }, true;
local currentHistoryIndex = 0;
local paddingValues: { { pos: number, y: number}? } = { };

UserInput.InputBegan:Connect(function(input)
	if input.KeyCode == CONFIG.SHOWHIDE_KEY_COMBO[2] and UserInput:IsKeyDown(CONFIG.SHOWHIDE_KEY_COMBO[1]) then
		if ui.Visible then
			if con then
				con:ReleaseFocus();
			end
			ui.Visible = false;
		else
			ui.Visible = true;
			if con then
				con:CaptureFocus();
			end
		end
	elseif historyEnabled and input.KeyCode == Enum.KeyCode.Up then
		currentHistoryIndex = math.clamp(currentHistoryIndex - 1, 1, #history < 1 and 1 or #history);
		con.Text = currentPrefix..(history[currentHistoryIndex] or "");
		con.CursorPosition = #con.Text + 1;
	elseif historyEnabled and input.KeyCode == Enum.KeyCode.Down then
		currentHistoryIndex = math.clamp(currentHistoryIndex + 1, 1, #history + 1);
		con.Text = currentPrefix..(history[currentHistoryIndex] or "");
		con.CursorPosition = #con.Text + 1;
	end
end)

function cursor_moved()
	local plenInc = #currentPrefix + 1;
	if con.CursorPosition < plenInc then
		con.CursorPosition = plenInc;
	end
	
	task.wait();
	
	-- render the cursor
	local pos = con.CursorPosition;
	for i, v in paddingValues do
		local next = paddingValues[i + 1];
		if next then
			if not (pos >= v.pos and pos < next.pos) then
				continue;
			end
		end
		local cursor = con:FindFirstChild("cursor");
		if cursor then
			cursor.Position = UDim2.fromOffset((pos - v.pos) * 7, 11 + v.y);
		end
		break;
	end
end

function selection_changed()
	local plenInc = #currentPrefix + 1;
	if con.SelectionStart ~= -1 and con.SelectionStart < plenInc then
		con.SelectionStart = plenInc;
	end
end

function do_prefix()
	if not currentPrefix or currentPrefix == "" then return; end;
	local plen = #currentPrefix;
	if con.Text:sub(1, plen) ~= currentPrefix then
		con.Text = currentPrefix..con.Text:sub(1 + math.clamp(con.CursorPosition == plen+1 and plen or plen+1, 0, plen), -1);
		con.CursorPosition += 1 + math.clamp(plen - con.CursorPosition, 0, plen);
	end
end

function text_changed()
	if not con then return; end;
	
	do_prefix();
	
	-- refresh syntax highlighting
	if CONFIG.LEXER.USE_LEXICAL_TOKEN_SCANNING then
		local tokens = lexer(con.Text);
		
		con.formats:ClearAllChildren();
		table.clear(paddingValues);
		paddingValues[1] = { pos = 1, y = 0 };
		
		local pos, x, y, nlc = 1, 0, 0, 1;
		for i, token in tokens do
			if not token or not token.value then continue; end;
			local h = assets.h:Clone();
			h.Name = i;
			h.Text = token.value;
			h.TextColor3 = CONFIG.LEXER.COLORS[token.type];
			h.Parent = con.formats;
			
			local bx = 7 * #token.value;
			if x + bx > BOUNDX then
				x = 0;
				y += 12;
				nlc += 1;
				table.insert(paddingValues, { pos = pos, y = y });
			end
			pos += #token.value;
			
			h.Position = UDim2.fromOffset(x, y);
			h.Size = UDim2.fromOffset(bx, 12);
			
			if token.nlcount > 0 then
				x = 0;
				y += token.nlcount * 12;
				nlc += token.nlcount;
				table.insert(paddingValues, { pos = pos, y = y });
			else
				x += bx;
			end
		end
		con.Size = UDim2.new(1, 0, 0, 12 * nlc);
	end
end

function text_changed_no_hl()
	if not con then return; end;
	
	do_prefix();
	
	local params = Instance.new("GetTextBoundsParams");
	params.Text = con.Text;
	params.Font = con.FontFace;
	params.Size = con.TextSize;
	params.Width = canvas.AbsoluteSize.X;
	con.Size = UDim2.new(1, 0, 0, TextService:GetTextBoundsAsync(params).Y);
end

function autocompleteHint(): number
	-- todo
	return 0;
end

function focusLost(ep)
	if ep then
		if not hinting then
			if signalConnectionA then signalConnectionA:Disconnect(); end;
			signalConnectionB:Disconnect();
			signalConnectionC:Disconnect();
			if signalConnectionD then signalConnectionD:Disconnect(); end;
			
			if not con.TextEditable then return; end;
			con.TextEditable = false;
			con.cursor.Visible = false;
			console.parse(con.Text:sub(#currentPrefix + 1, -1));
		else
			local cur = con.CursorPosition;
			local offset = autocompleteHint();
			con:CaptureFocus();
			con.CursorPosition = cur + offset;
		end
	end
end

function console.parse(input: string)
	-- verify that the command exists
	local tokens = lexer(input, false);
	local command: string, args: { string };
	local commandTok = tokens[1];
	local commandData;
	if commandTok then
		local cvalue = commandTok.value;
		local t = commandTok.type;
		if t == "COMMAND" then
			command = cvalue:upper();
			args = { };
			commandData = CONFIG.COMMANDS[command] or CONFIG.INTERNAL_COMMANDS[command];
		else
			console.output(t == "IDEN" and CONFIG.ERROR_MSG.INVALID_COMMAND:format(cvalue) or CONFIG.ERROR_MSG.INVALID_FIRST_TOKEN:format(t), { iserror = true });
		end
	end
	
	if command then
		-- add to history
		if historyEnabled and history[#history] ~= input then
			table.insert(history, input);
			currentHistoryIndex = #history + 1;
		end
		
		-- verify that the command syntax is correct
		local errored = false;
		-- TODO: check if SYNTAX is not null
		local syntax = commandData.SYNTAX:split(" ");
		local argSize, minimumArgSize = #tokens - 1, 0;
		for _, syn in syntax do
			if not syn:match("%?$") then
				minimumArgSize += 1;
			end
		end
		if commandData.SYNTAX == "" then
			syntax = { };
			minimumArgSize = 0;
		end
		
		if argSize < minimumArgSize then
			errored = true;
			console.output(CONFIG.ERROR_MSG.ARGUMENT_COUNT_TOO_LOW:format(minimumArgSize, argSize), { iserror = true });
		elseif argSize > #syntax then
			errored = true;
			console.output(CONFIG.ERROR_MSG.ARGUMENT_COUNT_TOO_HIGH:format(#syntax, argSize), { iserror = true });
		end
		
		if not errored then
			errored = false;
			for i = 2, #tokens do
				local tok = tokens[i];
				local t, v = tok.type, tok.value;
				local syn = syntax[i - 1];
				syn = syn:match("%?$") and syn:sub(1, -2) or syn;
				
				if syn ~= "ANY" and t ~= syn then
					errored = true;
					console.output(CONFIG.ERROR_MSG.BAD_ARGUMENT:format(syn, t), { iserror = true });
					if CONFIG.HALT_ON_PARSE_ERROR then
						break;
					end
				else
					local pass: any;
					if t == "STRING" then
						pass = v:sub(2, -2);
					elseif t == "NUMBER" then
						pass = tonumber(v);
					elseif t == "BOOLEAN" then
						pass = v == "true";
					elseif t == "PLAYER" then
						pass = game.Players[v];
					else
						pass = v;
					end
					args[i - 1] = pass;
				end
			end
			if not errored then
				local s, e = commandData.FUNC(console :: any, unpack(args));
				if s then
					console.output(CONFIG.MSG.POSITIVE);
				elseif s == false then
					console.output(CONFIG.ERROR_MSG.EXECUTE_FAIL:format(e or "no further details."), { iserror = true });
				end
			end
		end
	end
		
	console.input();
end

function console.clear(destroyCurrentCon: boolean?)
	for _, obj in canvas:GetChildren() do
		if not obj:IsA("UIListLayout") and (not destroyCurrentCon and obj ~= con or true) then
			obj:Destroy();
		end
	end
end

function console.reset()
	history = {};
	currentHistoryIndex = 0;
	console.clear();
	console.output(CONFIG.WELCOME_MESSAGE);
end

function console.input(data)
	task.wait();
	
	data = data or { };
	local fromOutput, fromOutputModifiable, useHighlighting = data.fromOutput, data.fromOutputModifiable, data.useHighlighting;
	if not fromOutput then
		historyEnabled = true;
		con = assets.con:Clone();
		con.Parent = canvas;
		
		currentPrefix = "> ";
		con.Text = currentPrefix;
	else
		historyEnabled = false;
		if fromOutputModifiable then con.TextColor3 = Color3.new(1, 1, 1); end;
		currentPrefix = fromOutputModifiable and "" or con.Text;
	end
	
	if useHighlighting == false then
		con.TextTransparency = 0;
		text_changed_no_hl();
	else
		con.TextTransparency = 1;
		signalConnectionD = con.FocusLost:Connect(focusLost);
		text_changed();
	end
	signalConnectionA = con:GetPropertyChangedSignal("Text"):Connect(useHighlighting == false and text_changed_no_hl or text_changed);
	signalConnectionB = con:GetPropertyChangedSignal("CursorPosition"):Connect(cursor_moved);
	signalConnectionC = con:GetPropertyChangedSignal("SelectionStart"):Connect(selection_changed);
	
	con.TextEditable = true;
	con:CaptureFocus();
	con.cursor.Visible = true;
	
	if fromOutput then
		while true do
			local ep = con.FocusLost:Wait();
			if ep then
				con.TextEditable = false;
				con.cursor.Visible = false;
				con:ReleaseFocus();
				return con.Text:sub(#currentPrefix + 1, -1);
			end
		end
	end
end

function console.output(s: string, data)
	data = data or { };
	local iserror, color, useHighlighting = data.iserror, data.color, data.useHighlighting;
	
	con = assets.con:Clone();
	con.TextEditable = false;
	con.Text = s;
	con.TextTransparency = 0;
	con.TextColor3 = color or iserror and Color3.fromRGB(255, 100, 100) or CONFIG.LEXER.COLORS.IDEN;
	con.Parent = canvas;
	
	currentPrefix = "";
	if useHighlighting then
		con.TextTransparency = 1;
		text_changed();
	else
		text_changed_no_hl();
	end
end

console.output(CONFIG.WELCOME_MESSAGE);
console.input();

conscrgui.Enabled = true;
