local special_players = require(script.specialplayers);

local modules = game.ReplicatedStorage.modules;
local std = require(modules.core.std);
local events = require(modules.events);

local DEBUG_STATIC_BUFF_MULTIPLIER = 1.5;

type BuffTable = {
    [string]: number
};

local Player = { }
local players = { };

function Player.get(id: number)
    return players[id];
end

function Player.new(robloxPlayer: Player)
    local kID = robloxPlayer.UserId;
    if Player.get(kID) then
        std.warnf("creating a duplicate %s player.", robloxPlayer.Name);
    end
    local this = {
        id = kID,
        developer = special_players.developers[kID] ~= nil,
        name = robloxPlayer.Name,
        dname = robloxPlayer.DisplayName,
        data = {
            currencies = {
                coins = 0,
                emeralds = 0
            },
            buffs = {
                coins = {
                    base = { 1.0, '+' },
                },
                emeralds = {
                    base = { 1.0, '+' },
                },
                collection = {
                    base = { 1, '+' },
                    _DEBUG = { 10.0, 'x' }
                }
            },
            stats = {
                clickInterval = 1   -- how much a click takes to recharge (in seconds)
            }
        },
        lastClick = 0
    };
    
    
    -- attempts to retrieve player's save file from the datastores.
    -- * returns nil if it fails to obtain the file.
    function this:get_save_file(): string?
        local file: string = std.NULL_BUFFER();
        -- TODO
        return nil;
    end
    
    function this:load_data_from_file(file: string)
        
    end
    
    function this:get_buff_multipliers(of: string)
        local total, mul, perc = 0, 1, 0;
        local buffs = self.data.buffs[of];
        for _, buff in buffs do
            local v, op = buff[1], buff[2];
            if op == '+' then
                total += v;
            elseif op == 'x' then
                mul *= v;
            elseif op == '%' then
                perc += v;
            end
        end
        return total * mul * (perc / 100 + 1);
    end
    
    function this:add_currency(currency: string, amount: number)
        self.data.currencies[currency] += amount;
        events.send_over(
            robloxPlayer,
            "UPDATE_CURRENCY_VALUE",
            currency,
            self.data.currencies[currency]
        );
    end
    function this:add_currency_buffed(currency: string, amount: number)
        self:add_currency(currency, amount * self:get_buff_multipliers(currency));
    end
    
    -- checks if the player can click a collectible, based on click interval.
    function this:verify_collectible_click_interval()
        local clock = os.clock();
        if clock - self.lastClick > self.data.stats.clickInterval then
            self.lastClick = clock;
            return true;
        end
        return false;
    end
    
    function this:on_join()
        local saveFile = self:get_save_file();
        if saveFile then
            self:load_data_from_file(saveFile);
        else
            std.warnf(std.msg.w.NONEXISTENT_SAVE_FILE, self.name);
        end
        for currency, value in self.data.currencies do
            events.send_over(robloxPlayer, "UPDATE_CURRENCY_VALUE", currency, value);
        end
        -- TODO update existing GUIs for a new player
    end
    function this:on_exit()
        -- TODO save data
        
        players[self.id] = nil;
    end
    
    
    ---------------------------------------------
    -- developer specific "cheat codes"; those functions are not used
    --   anywhere in the source code, and are only meant to be available for
    --   the developers to use in-game through the console.
    ---------------------------------------------
    
    function this:__dev_currency_set(cur: string, to: number)
        std.assert(cur, "invalid arguments: __dev_currency_set(currency: string, to: number)");
        self.data.currencies[cur] = to;
        std.printf("success.");
    end
    
    function this:__dev_currency_set_advanced(cur: string, op: string, by: number)
        std.errorf("not implemented yet.");
    end
    
    do
        this:on_join();
        players[kID] = this;
    end
    
    return this;
end



return Player;
