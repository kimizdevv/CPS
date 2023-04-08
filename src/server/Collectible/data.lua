local STANDARD_COIN_REWARD_BUFF = 1;
local STANDARD_CHEST_REWARD_BUFF = 1;
local STANDARD_EMERALD_REWARD_BUFF = 1/10;

return {
    coins = {
        [1] = {
            name = "Coin",
            maxHealth = 50,
            rewardBuff = STANDARD_COIN_REWARD_BUFF
        },
        [2] = {
            name = "unnamed coin 2",
            maxHealth = 250,
            rewardBuff = STANDARD_COIN_REWARD_BUFF
        },
        [3] = {
            name = "unnamed coin 3",
            maxHealth = 1250,
            rewardBuff = STANDARD_COIN_REWARD_BUFF
        },
        [4] = {
            name = "unnamed coin 4",
            maxHealth = 10_000,
            rewardBuff = STANDARD_COIN_REWARD_BUFF
        },
        [5] = {
            name = "Chest",
            maxHealth = 100_000,
            rewardBuff = STANDARD_CHEST_REWARD_BUFF
        },
        [6] = {
            name = "unnamed chest 2",
            maxHealth = 2_500_000,
            rewardBuff = STANDARD_CHEST_REWARD_BUFF
        },
        [7] = {
            name = "unnamed chest 3",
            maxHealth = 50_000_000,
            rewardBuff = STANDARD_CHEST_REWARD_BUFF
        }
    },
    emeralds = {
        [1] = {
            name = "Emerald",
            maxHealth = 100,
            rewardBuff = STANDARD_EMERALD_REWARD_BUFF
        },
        [2] = {
            name = "unnamed emerald 2",
            maxHealth = 2500,
            rewardBuff = STANDARD_EMERALD_REWARD_BUFF
        },
        [3] = {
            name = "unnamed emerald 3",
            maxHealth = 50_000,
            rewardBuff = STANDARD_EMERALD_REWARD_BUFF
        }
    },
};
