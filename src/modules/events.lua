local isClient = game:GetService("RunService"):IsClient();

local std = require(game.ReplicatedStorage.modules.core.std);
local remotes = game.ReplicatedStorage.remotes;

local events = {};
local listeners: { [string]: { topic: string, f: (any)->nil } } = { };

-- bindable event
function events.send(ev: string, ...)
    for _, listener in listeners[ev] do
        if listener.topic == ev then
            listener.f(...);
        end
    end
end
function events.listen(ev: string, f: (any)->nil)
    local id = std.uuid();
    listeners[id] = { topic = ev, f = f };
    return function()
        listeners[id] = nil;
    end
end

-- remote event
-- @param CLIENT:   ev: string, ...
-- @param SERVER:   p: Player|string{"all"}, ev: string, ...
function events.send_over(...)
    local data = { ... };
    if isClient then
        local ev: string = data[1];
        table.remove(data, 1);
        remotes.e_ctos:FireServer(ev, unpack(data));
    else
        local p: Player|string = data[1];
        local ev: string = data[2];
        table.remove(data, 1);
        table.remove(data, 1);
        if typeof(p) == "string" and p:lower() == "all" then
            remotes.e_stoc:FireAllClients(ev, unpack(data));
        else
            remotes.e_stoc:FireClient(p, ev, unpack(data));
        end
    end
end

-- remote function
-- @param CLIENT:   ev: string, ...
-- @param SERVER:   p: Player, ev: string, ...
function events.send_over_invoked(...): ...any
    local data = { ... };
    if isClient then
        local ev: string = data[1];
        table.remove(data, 1);
        return remotes.f_ctos:InvokeServer(ev, unpack(data));
    else
        local p: Player = data[1];
        local ev: string = data[2];
        table.remove(data, 1);
        table.remove(data, 1);
        return remotes.f_stoc:InvokeClient(p, ev, unpack(data));
    end
end

return events;
