local server = script.Parent;
local Player = require(server.Player);
local Zone = require(server.Zone);

function player_on_exit(p: Player)
    local player = Player.get(p);
    if player then
        player:on_exit();
    end
end

game.Players.PlayerAdded:Connect(function(p)
    Player.new(p); -- register the new player
end)
game.Players.PlayerRemoving:Connect(player_on_exit);

game:BindToClose(function()
    for _, p in game.Players:GetPlayers() do
        player_on_exit(p);
    end
end)

-- TODO: move this somewhere
local RARITIES = {
    [1] = {
        types = {
            [1] = 0.95,
            [2] = 0.05
        },
        tiers = {
            [1] = {
                [1] = 0.99,
                [5] = 0.01,
            },
            [2] = {
                [1] = 1.00
            }
        }
    }
};

do -- register zones
    for zoneId, rarities in RARITIES do
        Zone.new(zoneId, rarities);
    end
end
