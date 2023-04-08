local events = require(game.ReplicatedStorage.modules.events);

local player = game.Players.LocalPlayer;
local pUI = player:WaitForChild("PlayerGui");
local devUI = pUI:WaitForChild("DEV");

devUI.damageAllCoins.MouseButton1Click:Connect(function()
    events.send_over("PROTECTED:DAMAGE_ALL_COINS");
end)
