local modules = game.ReplicatedStorage.modules;
local std = require(modules.core.std);
local events = require(modules.events);

local wallet = require(script.Parent:WaitForChild("ui"):WaitForChild("wallet"));

local elemFolder = script.Parent:WaitForChild("elements");
local elements = {
    collectibles = require(elemFolder.collectibles)
};

local eventsObj = game.ReplicatedStorage.remotes;

local e_stoc: RemoteEvent = eventsObj.e_stoc;
local f_stoc: RemoteFunction = eventsObj.f_stoc;
local e_ctos: RemoteEvent = eventsObj.e_ctos;
local f_ctos: RemoteFunction = eventsObj.f_ctos;

e_stoc.OnClientEvent:Connect(function(ev: string, ...)
    ev = ev:upper();
    local args = { ... };
    if ev == "UPDATE_CURRENCY_VALUE" then
        wallet.update_currency_value(args[1], args[2]);
    elseif ev == "CREATE_COLLECTIBLE_UI" then
        elements.collectibles.create_ui(args[1]);
    elseif ev == "UPDATE_COLLECTIBLE_UI" then
        elements.collectibles.get_created(args[1]):update_ui(args[2], args[3]);
    elseif ev == "SPARKLES_ON_COLLECTIBLE_CLICK" then
        elements.collectibles.sparkles_on_click(args[1]);
    else
        std.warnf("client: unrecognized event topic '%s'", ev);
    end
end)
