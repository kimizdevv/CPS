-- a collection of useful, standard library functions and extensions
--   that should have already been implemented into the language.

local httpService = game:GetService("HttpService");

local std = {
    msg = { -- a table of warning and error messages used across the entire game.
        w = {
            NONEXISTENT_SAVE_FILE = "failed to obtain a valid save file for player: %s"
        };
    },
};


-----------------------
-- GENERAL
-----------------------

function std.NULL_BUFFER(): string
    return "";
end

-- generates a universally unique identifier using the roblox API.
-- ! this function assumes that the generated UUID never repeats and does not
--   provide any additional error handling in case it does.
function std.uuid()
    return httpService:GenerateGUID(false);
end

-- an enhancement of std.uuid(); generates 4 uuid strings and merges them into one.
-- * this is my way of making sure that the uuids will never repeat itself,
--   although it is still possible.
-- cryptography goin' strong, boys :)
function std.long_uuid()
    return std.uuid()..std.uuid();
end

-- generic print with format string.
function std.printf(s: string, ...)
    print(string.format(s, ...));
end
function std.debugf(s: string, ...)
    std.printf("[DEBUG] "..s, ...);
end

-- generic warn with format string.
function std.warnf(s: string, ...)
    warn(string.format(s, ...));
end

-- generic error with format string.
function std.errorf(s: string, ...)
    error(string.format(s, ...), 0);
end

function std.assert(cond: any, emsg: string, ...)
    if not cond then
        std.errorf(emsg, ...);
    end
end

function std.wassert(cond: any, wmsg: string, ...)
    if not cond then
        std.warnf(wmsg, ...);
    end
end

-- calls specified function with specified arguments if condition fails
function std.fassert(cond: any, func: (...any)->nil, ...)
    if not cond then
        func(...);
    end
end

return std;
