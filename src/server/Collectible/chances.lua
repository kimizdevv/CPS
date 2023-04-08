-- @file    CPS collectible spawn chance table.
--
--[[ STRUCTURE:
    {
        [zoneId]: {
            types: {
                [collectibleTypeId]: CHANCE,
                ...
            },
            tiers = {
                [collectibleTypeId]: {
                    [collectibleTier]: CHANCE,
                    ...
                },
                ...
            }
        },
        ...
    }
    
    ! NOTES:
        * All CHANCEs in a particular table have to add up to 1.
]]

return {
    [1] = {
        types = {
            [1] = 0.95,
            [2] = 0.05
        },
        tiers = {
            [1] = {
                [1] = 1.00
            },
            [2] = {
                [1] = 1.00
            }
        }
    }
};
