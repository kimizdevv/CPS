local std = require(script.Parent.std);

local random = {};

-- enhances chances lookup table with methods.
function random.new_rarity_lookup(t)
    local this = { };
    
    -- randomly chooses a value from the lookup table.
    function this:choose(): any
        local r = math.random();
        local count = 0;
        for k, v in t do
            count += v;
            if r <= count then
                return k;
            end
        end
    end
    
    
    return this;
end

return random;
