local std = require(game.ReplicatedStorage.modules.core.std);
local styling = require(script.Parent);

local STYLING_SPECIFIER_NAME = "STYLING";

local function recursiveSearch(within: Instance)
    local stylingSpecifierFound = within:FindFirstChild(STYLING_SPECIFIER_NAME);
    if stylingSpecifierFound and stylingSpecifierFound:IsA("StringValue") then
        styling.apply(within, stylingSpecifierFound.Value);
    end
    local children = within:GetChildren();
    if #children > 0 then
        for _, child in children do
            recursiveSearch(child);
        end
    end
end

local pUI = game.Players.LocalPlayer:WaitForChild("PlayerGui");
task.wait(2);
std.debugf("started recursive search.");
recursiveSearch(pUI);
std.debugf("recursive search done.");
