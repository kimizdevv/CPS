local Http = game:GetService("HttpService");

export type CONSOLE_OBJECT = {
	input:	({ [string]: boolean? }) -> (),
	output: (string, { [string]: any? }?) -> (),
	clear:	(boolean?) -> (),
	reset:	() -> (),
	parse:	(string) -> ()
};
export type COMMANDS_TABLE = { [string]: { SYNTAX: string, DESCRIPTION: string, FUNC: (CONSOLE_OBJECT, any...) -> (boolean?, string?) } };
export type CONSOLE_CONFIG = {
	SERVER_REMOTE: RemoteEvent,
	SERVER_REMOTE_F: RemoteFunction, -- for getting the list of all commands and their syntax
	
	SHOWHIDE_KEY_COMBO: { Enum.KeyCode },
	
	INTERNAL_COMMANDS: COMMANDS_TABLE,
	COMMANDS: COMMANDS_TABLE,
	
	MSG: { [string]: string },
	ERROR_MSG: { [string]: string },
	HALT_ON_PARSE_ERROR: boolean,
	
	ABOUT: string,
	WELCOME_MESSAGE: string,
	LEXER: {
		USE_LEXICAL_TOKEN_SCANNING: boolean,
		COLORS: {
			COMMAND: Color3,
			PLAYER: Color3,
			STRING: Color3,
			NUMBER: Color3,
			IDEN: Color3
		},
		SEP: string;
	}
};

local CONFIG: CONSOLE_CONFIG;

local testfiles = require(script.Parent.testfiles);

-- this will be provided by the server (through SERVER_REMOTE_F)
local commands = {
	["FILE-GET-ALL"] = {
		SYNTAX = "",
		DESCRIPTION = "outputs all existing file names.",
		FUNC = function(console)
			local names: string = "";
			for name in testfiles do
				names ..= name..", ";
			end
			names = names == "" and "no files found." or names:sub(1, -3);
			console.output(names);
		end
	},
	["FILE-EDIT"] = {
		SYNTAX = "STRING",
		DESCRIPTION = "allows to edit the contents of a file.",
		FUNC = function(console, fileName)
			local file = testfiles[fileName];
			if not file then return false, "bad file name."; end;
			
			console.output("EDITING FILE", { color = Color3.fromRGB(226, 132, 69) });
			console.output(Http:JSONEncode(file), { color = Color3.new(1, 1, 1) });
			local new_s = console.input({ fromOutput = true, fromOutputModifiable = true, useHighlighting = true });
			local s, r = pcall(function() return Http:JSONDecode(new_s); end);
			
			if s and r then
				testfiles[fileName] = r;
				return true;
			else
				return false, "bad file format.";
			end
		end
	},
	["FILE-EXISTS"] = {
		SYNTAX = "STRING",
		DESCRIPTION = "checks if a given file exists.",
		FUNC = function(console, fileName)
			if testfiles[fileName] then
				console.output("true", { useHighlighting = true });
			else
				console.output("false", { useHighlighting = true });
			end
		end
	},
	["FILE-RENAME"] = {
		SYNTAX = "STRING STRING",
		DESCRIPTION = "renames a file.",
		FUNC = function(_, from, to)
			local file = testfiles[from];
			if not file then return false, "bad file name: '"..from.."'"; end;
			testfiles[from] = nil;
			testfiles[to] = file;
			return true;
		end
	},
	["FILE-VIEW"] = {
		SYNTAX = "STRING",
		DESCRIPTION = "outputs the contents of a file.",
		FUNC = function(console, fileName)
			local file = testfiles[fileName];
			if not file then return false, "bad file name."; end;
			console.output(Http:JSONEncode(file), { useHighlighting = true });
		end
	}
};
local internal_commands; internal_commands = {
	["ABOUT"] = {
		SYNTAX = "",
		DESCRIPTION = "shows information about the console.",
		FUNC = function(console)
			console.output(CONFIG.ABOUT);
		end
	},
	["HELP"] = {
		SYNTAX = "COMMAND?",
		DESCRIPTION = "shows the syntax and a short description of every supported command, or a specific command.",
		FUNC = function(console, cname: string)
			if cname then
				cname = cname:upper();
				local c = internal_commands[cname] or commands[cname];
				if not c then
					return false, CONFIG.ERROR_MSG.INVALID_COMMAND:format(cname);
				end
				console.output(c.DESCRIPTION and "  SYNTAX: "..c.SYNTAX.."\n  - "..c.DESCRIPTION or "no description found for this command.", { iserror = c.DESCRIPTION == nil });
			else
				local function listCommands(t)
					local commands: { string } = { };
					for name, data in t do
						table.insert(commands, "  "..name..((data.SYNTAX and data.SYNTAX ~= "") and " "..data.SYNTAX or "")..(data.DESCRIPTION and ("\n    - "..data.DESCRIPTION) or ""));
					end
					table.sort(commands);
					if #commands > 0 then
						for _, s in commands do
							console.output(s, { useHighlighting = true });
						end
					else
						console.output("  no elements found.", { iserror = true });
					end
				end
				
				console.output("INTERNAL COMMANDS", { color = Color3.fromRGB(226, 132, 69) });
				listCommands(internal_commands);
				console.output("\nGAME COMMANDS", { color = Color3.fromRGB(226, 132, 69) });
				listCommands(commands);
			end
		end
	},
	["CLEAR"] = {
		SYNTAX = "",
		DESCRIPTION = "clears out the console.",
		FUNC = function(console)
			console.clear();
		end
	},
	["PRINT"] = {
		SYNTAX = "ANY",
		DESCRIPTION = "outputs any value.",
		FUNC = function(console, v)
			console.output(v);
		end
	},
	["GET-SETTINGS"] = {
		SYNTAX = "",
		DESCRIPTION = "outputs all of the settings for the console.",
		FUNC = function()
			
		end
	},
	["RESET"] = {
		SYNTAX = "",
		DESCRIPTION = "resets the console.",
		FUNC = function(console)
			console.reset();
		end
	},
	["SET"] = {
		SYNTAX = "STRING ANY",
		DESCRIPTION = "modifies the console setting.",
		FUNC = function(console)
			
		end
	},
	["NOF"] = {
	--	SYNTAX = "ANY?",
		FUNC = function(console)
			return false;
		end
	}
};

CONFIG = {
	SERVER_REMOTE = nil,
	SERVER_REMOTE_F = nil,
	
	SHOWHIDE_KEY_COMBO = { Enum.KeyCode.LeftControl, Enum.KeyCode.X },
	
	INTERNAL_COMMANDS = internal_commands,
	COMMANDS = commands,
	
	MSG = {
		POSITIVE =					"operation completed successfully.",
	},
	ERROR_MSG = {
		UNCAUGHT_ERROR =			"uncaught error occured during parsing [location: 0x%02x].",
		NULL_COMMAND =				"expected a COMMAND, but got a NULL instead.",
		INVALID_COMMAND =			"unknown command: \"%s\".",
		INVALID_FIRST_TOKEN =		"expected a COMMAND, but got a %s instead.",
		ARGUMENT_COUNT_TOO_LOW =	"invalid command syntax: argument count does not match. (expected at least %d arguments, but got %d instead.)",
		ARGUMENT_COUNT_TOO_HIGH =	"invalid command syntax: argument count overload. (expected at most %d arguments, but got %d instead.)",
		BAD_ARGUMENT =				"invalid command syntax: bad argument type. (expected %s, but got %s instead.)",
		EXECUTE_FAIL =				"unable to perform operation: %s",
	},
	HALT_ON_PARSE_ERROR = true, -- when set to false allows for displaying more than 1 error message at a time.
	
	ABOUT = "\nAbout the crimzytron Games Developer Console:\nThis is a console made by crimzytron Games for their own use in games.\n\nAll commands, along with their short description, can be found after typing help in the console.\n\nHow to understand command syntax?\nThere are 5 basic types of arguments: COMMAND, STRING, NUMBER, BOOLEAN and PLAYER.\nIf a type has a question mark (?) at the end of it, it means that the argument is optional and does not have to be provided.\n\nIf a command fails to execute, the console will give you an error message about what happened.\n",
	WELCOME_MESSAGE = "CG Developer Console\nType help to view all commands and info on how to use them.\nHit CTRL+X to show or hide the console window.\n",
	LEXER = {
		USE_LEXICAL_TOKEN_SCANNING = true, -- [def:true] i do not recommend modifying this
		COLORS = { -- freely modifiable console theme
			COMMAND = Color3.fromRGB(200, 200, 40),
			PLAYER = Color3.fromRGB(200, 70, 70),
			STRING = Color3.fromRGB(100, 200, 100),
			NUMBER = Color3.fromRGB(100, 150, 200),
			BOOLEAN = Color3.fromRGB(100, 200, 200),
			IDEN = Color3.fromRGB(200, 200, 200)
		},
		SEP = "[ \t\n:=,;/{}%[%]%(%)]" -- DO NOT MODIFY THIS!!
	}
} :: CONSOLE_CONFIG;

return CONFIG;
