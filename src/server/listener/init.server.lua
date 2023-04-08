local modules = game.ReplicatedStorage.modules;
local std = require(modules.core.std);
local events = require(modules.events);
local devevents = require(script.devevents);
local Player = require(script.Parent.Player);

local eventsObj = game.ReplicatedStorage.remotes;

local e_stoc: RemoteEvent = eventsObj.e_stoc;
local f_stoc: RemoteFunction = eventsObj.f_stoc;
local e_ctos: RemoteEvent = eventsObj.e_ctos;
local f_ctos: RemoteFunction = eventsObj.f_ctos;

function process_protected_event(player, ev: string, ...)
    if player.developer then
        if ev == "DAMAGE_ALL_COINS" then
            devevents.damage_all_coins(player);
        end
    else
        std.warnf("unauthorized player '%s' tried to access a protected event.", player.name);
    end
end

e_ctos.OnServerEvent:Connect(function(player, ev: string, ...)
    assert(ev, "no event passed to server.");
    ev = ev:upper();
    local isProtected, eventName = ev:match("(PROTECTED):(.+)")
    if isProtected and eventName then
        process_protected_event(Player.get(player.UserId), eventName, ...);
    else
        std.warnf("server: unrecognized event topic '%s'", ev);
    end
end)
