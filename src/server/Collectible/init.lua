local MAX_CLICK_DISTANCE = 20;

local modules = game.ReplicatedStorage.modules;
local std = require(modules.core.std);
local events = require(modules.events);
local colData = require(script.data);
local Player = require(script.Parent.Player);

local models = game.ReplicatedStorage.models;

export type Type = {
    typeId: number,
    tier: number
};

function typeid_to_string(id: number)
    return id==1 and "coins" or id==2 and "emeralds" or id==3 and "chests"
        or std.warnf("invalid typeid %d", id);
end

local Collectible = { };

function Collectible.new(type: Type, zone, data, dataOverwrite: any?)
    dataOverwrite = dataOverwrite or { };
    local collectibleData = colData[typeid_to_string(type.typeId)][type.tier];
    local this = {
        id = std.uuid();
        type = type,
        zone = zone,
        name = dataOverwrite.name or collectibleData.name,
        rewardBuff = dataOverwrite.rewardBuff or collectibleData.rewardBuff,
        data = {
            health = dataOverwrite.maxHealth or collectibleData.maxHealth,
            maxHealth = dataOverwrite.maxHealth or collectibleData.maxHealth
        },
        damageList = { },
        collected = false
    };
    local typeIdStr = typeid_to_string(type.typeId);
    local gameObject: Model;
    local click: ClickDetector;
    
    
    -- @private updates the collectible gui after the health has been modified.
    local function _update_gui(damage: number, playerDamaged: number)
        for _, p in game.Players:GetPlayers() do
            local id = p.UserId;
            local player = Player.get(id);
            events.send_over(
                "all", "UPDATE_COLLECTIBLE_UI", this.id,
                this.data.health,
                {
                    value = damage,
                    greyedOut = id ~= playerDamaged,
                    clickInterval = player.data.stats.clickInterval
                }
            );
        end
    end
    
    -- @private adds player id to the damage list, which makes the player
    --   eligible for a reward upon full collection.
    local function _add_player_to_damagelist(id: number, value: number)
        this.damageList[id] = (this.damageList[id] or 0) + value;
    end
    
    -- @private marks the coin as collected, removes it as an object and rewards
    --   the players who damaged it.
    local function _collected()
        if this.collected then return; end;
        
        this.collected = true;
        gameObject:Destroy();
        
        for id: number, damage: number in this.damageList do
        --    std.debugf("rewarding player: %d (damage done: %d / %d %d%%)", id, damage, this.data.maxHealth, damage / this.data.maxHealth * 100);
            Player.get(id):add_currency_buffed(typeIdStr, math.floor(damage * this.rewardBuff));
            -- TODO: use player:reward(pos)
        end
        
        if data.on_collected then
            data.on_collected(this.id);
        end
    end
    
    -- decreases collectible's health and saves the player id to the
    --   damage list. also checks if the collectible is about to be
    --   fully collected and calls _collected() if yes.
    function this:take_damage(playerID: number, value: number)
        if self.collected then return; end;
        
        local collected = value >= self.data.health;
        if collected then
            value = math.clamp(value, 0, self.data.health);
        end
        
        self.data.health -= value;
        _add_player_to_damagelist(playerID, value);
        -- TODO
        -- events.send_over(
        --     game.Players:GetPlayerByUserId(playerID),
        --     "SPARKLES_ON_COLLECTIBLE_CLICK",
        --     { id = this.id, zoneId = this.zone.id, typeId = this.type.typeId }
        -- );
        
    --    std.debugf("[%d] collectible damaged (-%d)", playerID, value);
        
        if collected then
            _collected();
        end
        _update_gui(value, playerID);
    end
    
    
    -- creates the gameobject with appropriate texture and a random
    --   position offset relative to the zone platform.
    do
        -- find and create the correct model of specified collectible type
        local clonePath = models.collectibles[typeIdStr];
        local obj = clonePath:FindFirstChild(string.format("tier%d", type.tier));
        std.assert(obj, "null object for collectible.");
        
        gameObject = obj:Clone();
        local hitbox = gameObject.HITBOX;
        
        local zone = this.zone.gameObject;
        local platform = zone.platform;
        local psx, psz = platform.Size.X - 10, platform.Size.Z - 10;
        gameObject:PivotTo(CFrame.new(Vector3.new(
            platform.Position.X + math.random(-psx/2, psx/2),
            platform.Position.Y + platform.Size.Y/2 + hitbox.Size.Y/2,
            platform.Position.Z + math.random(-psz/2, psz/2)
        )));
        gameObject.Name = this.id;
        gameObject.Parent = zone.collectibles;
        
        -- attach billboardgui
        events.send_over("all", "CREATE_COLLECTIBLE_UI", {
            id = this.id,
            zoneId = this.zone.id,
            typeId = this.type.typeId,
            tier = this.type.tier,
            name = this.name,
            maxHealth = this.data.maxHealth
        });
        
        -- attach click detector
        click = Instance.new("ClickDetector");
        click.MaxActivationDistance = MAX_CLICK_DISTANCE;
        click.Parent = hitbox;
    end
    
    -- connect click events
    -- TODO: click rate limit
    click.MouseClick:Connect(function(p)
       -- std.debugf("clicked");
        local hitbox = gameObject.HITBOX;
        local playerPos = p.Character.HumanoidRootPart.Position;
        local collectiblePos = hitbox.Position;
        std.wassert(
            (playerPos - collectiblePos).Magnitude <= MAX_CLICK_DISTANCE + hitbox.Size.X,
            "pending flag for %s: illegal collection.", p.Name
        );
        
        local player = Player.get(p.UserId);
        if player:verify_collectible_click_interval() then
            this:take_damage(player.id, player:get_buff_multipliers("collection"));
        end
    end)
    
    return this;
end

return Collectible;
