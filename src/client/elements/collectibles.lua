local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local std = require(game.ReplicatedStorage.modules.core.std);
local number = require(game.ReplicatedStorage.modules.core.number);

local player = game.Players.LocalPlayer;
local pUI = player:WaitForChild("PlayerGui");
local wsUI = pUI:WaitForChild("ws");

local collectibles = { };
local createdCollectibles = { };

local FLASH_DURATION = 0.04;
local SMOOTH_TWEENINFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
local BILLBOARD_GUI_NAME_FORMAT = "BGUI_%s";
local DAMAGE_INDICATOR_NAME_FORMAT = "DMG_%s";
local COLORS = {
    [1] = Color3.fromRGB(255, 248, 166),    -- COIN
    [2] = Color3.fromRGB(166, 255, 185),    -- EMERALD
};

function collectibles.get_created(id: number)
    return createdCollectibles[id];
end

function collectibles.create_ui(data: {
        id: string, zoneId: number,
        typeId: number, tier: number,
        name: string, maxHealth: number, health: number?
})
    local this = {
        id = data.id,
        zoneId = data.zoneId,
        typeId = data.typeId,
        tier = data.tier,
        name = data.name,
        health = data.health or data.maxHealth,
        maxHealth = data.maxHealth,
        maxHealthString = number.abbreviate(data.maxHealth),
        collectible = workspace.zones[tostring(data.zoneId)].collectibles[data.id]
    };
    this.hitbox = this.collectible.HITBOX; -- ? why the fuck is 'collectible' deprecated
    
    local function spawn_damage_indicator(damage)
        local damageUIsize = math.clamp(damage.value/this.maxHealth + 0.3, 0.4, 1);
        local damageUI = game.ReplicatedStorage.models.gui.damageGUI:Clone();
        damageUI.UIScale.Scale = 0;
        damageUI.value.Size = UDim2.fromScale(1, damageUIsize);
        damageUI.value.Text = number.abbreviate(damage.value);
        damageUI.Adornee = this.collectible;
        damageUI.Parent = wsUI;
        
        task.spawn(function()
            TweenService:Create(
                damageUI.UIScale,
                TweenInfo.new(0.22, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                { Scale = 1 }
            ):Play();
            TweenService:Create(
                damageUI,
                TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {
                    StudsOffset = Vector3.new(
                        math.random(-30, 30)/10,
                        this.hitbox.Size.Y + math.random(5, 15)/10,
                        math.random(-30, 30)/10
                    )
                }
            ):Play();
            TweenService:Create(
                damageUI.value,
                TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                { Rotation = 20 }
            ):Play();
            task.wait(0.45);
            TweenService:Create(
                damageUI.value,
                TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, true),
                { Rotation = -20 }
            ):Play();
            
            TweenService:Create(
                damageUI.value,
                TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                { TextTransparency = 1 }
            ):Play();
            TweenService:Create(
                damageUI.value.UIStroke,
                TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                { Transparency = 1 }
            ):Play();
            task.wait(0.5);
            damageUI:Destroy();
        end)
    end
    
    local connection, tween: Tween;
    local function disconnect()
        tween:Cancel();
        connection:Disconnect();
        connection = nil;
    end
    
    local tweenValue = Instance.new("NumberValue");
    local flashInterrupted = false;
    
    function this:update_ui(health: number,
            damage: { value: number, greyedOut: boolean, clickInterval: number },
            initialCreation: boolean?)
        -- TODO: greyedOut
        
        local maxHealth = self.maxHealth;
        local bui = wsUI[string.format(BILLBOARD_GUI_NAME_FORMAT, self.id)];
        local healthLabel = bui.canvas.health;
        local healthBar = bui.canvas.bar;
        local healthValue = bui.healthValue;
        
        if connection then
            disconnect();
        end
        if health == 0 then
            bui:Destroy();
            createdCollectibles[this.id] = nil;
            return;
        end
        
        -- display click interval bar
        local reloadBar = bui.canvas.reload.bar;
        reloadBar.Size = UDim2.fromScale(1, reloadBar.Size.Y.Scale);
        TweenService:Create(
            bui.canvas.reload.bar,
            TweenInfo.new(damage.clickInterval, Enum.EasingStyle.Linear),
            { Size = UDim2.fromScale(0, reloadBar.Size.Y.Scale) }
        ):Play();
        
        
        local hrp = player.Character.HumanoidRootPart;
        local damageSignificance = damage.value / maxHealth;
        local isDamageInsignificant = health > 1000 and damageSignificance < 0.002;
        local isFarAway = (hrp.Position - self.hitbox.Position).Magnitude > bui.MaxDistance + self.hitbox.Size.X;
        
        -- if the player is close enough or the health change
        --   is significant enough then we can use more effects,
        --   otherwise we just simply update the UI without any animations
        --   to increase performance.
        
        if not initialCreation and not isFarAway then
            -- give visual feedback
            if flashInterrupted then
                flashInterrupted = false;
            end
            if not initialCreation then
                task.spawn(function()
                    if not flashInterrupted then
                        TweenService:Create(
                            healthBar,
                            TweenInfo.new(FLASH_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                            { BackgroundColor3 = Color3.fromRGB(114, 202, 77) }
                        ):Play();
                    end
                    task.wait(FLASH_DURATION);
                    if not flashInterrupted then
                        TweenService:Create(
                            healthBar,
                            TweenInfo.new(FLASH_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                            { BackgroundColor3 = Color3.fromRGB(68, 180, 20) }
                        ):Play();
                    end
                end)
            end
            
            spawn_damage_indicator(damage);
        end
        
        if initialCreation or (isDamageInsignificant or isFarAway) then
            healthLabel.Text = string.format("%s / %s",
                number.abbreviate(health), self.maxHealthString);
            healthBar.Size = UDim2.fromScale(health / maxHealth, 1);
            healthValue.Value = health;
        else
            TweenService:Create(
                healthBar,
                SMOOTH_TWEENINFO,
                { Size = UDim2.fromScale(health / maxHealth, 1) }
            ):Play();
            
            tween = TweenService:Create(
                tweenValue,
                SMOOTH_TWEENINFO,
                { Value = health }
            );
            tween:Play();
            
            tweenValue.Value = healthValue.Value;
            healthValue.Value = health;
            
            connection = RunService.Heartbeat:Connect(function()
                healthLabel.Text = string.format("%s / %s",
                    number.abbreviate(tweenValue.Value), self.maxHealthString);
                if tween.PlaybackState == Enum.TweenStatus.Completed then
                    disconnect();
                end
            end)
        end
    end
    
    do
        local gui = game.ReplicatedStorage.models.gui.collectibleGUI:Clone();
        gui.stats.tier.Text = string.format("Tier %d", this.tier);
        gui.stats.type.Text = string.format("%s", this.name);
        gui.stats.type.TextColor3 = COLORS[this.typeId];
        gui.Adornee = this.collectible.HITBOX;
        gui.Name = string.format(BILLBOARD_GUI_NAME_FORMAT, this.id);
        gui.Parent = wsUI;
        
        local healthValue = Instance.new("NumberValue");
        healthValue.Name = "healthValue";
        healthValue.Value = this.maxHealth;
        healthValue.Parent = gui;
    end
    
    -- initial ui setup
    this:update_ui(
        this.health,
        { value = 0, greyedOut = false, clickInterval = 0 },
        true
    );
    
    createdCollectibles[this.id] = this;
    return this;
end

function collectibles.sparkles_on_click(data: {
    id: string, zoneId: string, typeId: number
})
    local sparkle = game.ReplicatedStorage.models.sparkles.collectibleSparkle;
    
    -- TODO
end

return collectibles;
