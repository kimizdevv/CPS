local Zone = require(script.Parent.Parent.Zone);

local devevents = { };

function devevents.damage_all_coins(player)
    local zone = Zone.get(1);
    for _, collectible in zone.collectibles do
        collectible:take_damage(player.id, player:get_buff_multipliers("collection"));
    end
end

return devevents;
