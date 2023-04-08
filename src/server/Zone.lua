local core = game.ReplicatedStorage.modules.core;
local std = require(core.std);
local random = require(core.random);

local server = script.Parent;
local events = require(server.events);
local Collectible = require(server.Collectible);


local COLLECTIBLE_MAX_COUNT = 50;
local SPAWN_RATE = { min = 0, max = 10 }; -- [ms] def: 100-500
function get_random_spawn_rate(): number
    return math.random(SPAWN_RATE.min, SPAWN_RATE.max);
end

local Zone = { };
local zones = { };

function Zone.get(id: number)
    return zones[id];
end

function Zone.new(id: number, rarities)
    std.debugf("ZONE COLLECTIBLE MAX COUNT: %d", COLLECTIBLE_MAX_COUNT);
    
    local this = {
        id = id,
        gameObject = workspace.zones[tostring(id)],
        rarities = { }
    };
    this.collectibleCount = 0;
    this.collectibles = { };
    local spawnJobRunning = false;
    
    do -- fill the rarities table
        this.rarities.types = random.new_rarity_lookup(rarities.types);
        this.rarities.tiers = { };
        for typeName, tierRarities in rarities.tiers do
            this.rarities.tiers[typeName] = random.new_rarity_lookup(tierRarities);
        end
    end
    
    
    function this:spawn_collectible(type: Collectible.Type, dataOverwrite)
        local on_collected = function(cid)
            self.collectibleCount -= 1;
            self.collectibles[cid] = nil;
            self:run_async_spawn_job();
        end;
        
        local collectible = Collectible.new(type, self, {
            on_collected = on_collected
        }, dataOverwrite);

        self.collectibles[collectible.id] = collectible;
        self.collectibleCount += 1;
    end
    
    function this:spawn_random_collectible()
        local rars = self.rarities;
        local typeId = rars.types:choose();
        local tier = rars.tiers[typeId]:choose();
        self:spawn_collectible({
            typeId = typeId,
            tier = tier,
        });
    end
    
    function this:run_async_spawn_job()
        if spawnJobRunning or (self.collectibleCount > COLLECTIBLE_MAX_COUNT) then
            return;
        end
        
        spawnJobRunning = true;
        task.spawn(function()
            while self.collectibleCount <= COLLECTIBLE_MAX_COUNT do
                task.wait(get_random_spawn_rate() / 1000);
                self:spawn_random_collectible();
            end
            spawnJobRunning = false;
        end);
    end
    
    task.wait(1);
    -- this:spawn_collectible({ typeId = 1, tier = 5 }, {
    --     name = "abrv-test",
    --     maxHealth = 2.599175e122
    -- });
    -- this:spawn_collectible({ typeId = 1, tier = 5 }, {
    --     name = "hp-test",
    --     maxHealth = 6.145917e256
    -- });
    -- this:spawn_collectible({ typeId = 1, tier = 5 }, {
    --     name = "inf-test",
    --     maxHealth = 1e308
    -- });
    this:run_async_spawn_job();
    
    zones[id] = this;
    return this;
end

return Zone;
