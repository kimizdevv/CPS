local TweenService = game:GetService("TweenService");

local number = require(game.ReplicatedStorage.modules.core.number);
local text = require(script.Parent.text);

local walletUI = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                :WaitForChild("ui"):WaitForChild("wallet");

local wallet = { };
local currencies = {
    ["coins"] = 0,
    ["emeralds"] = 0
};

function wallet.update_currency_value(currency: string, value: number)
    local from = currencies[currency];
    currencies[currency] = value;
    if from > 1000 and (value-from)/value < 0.001 then
        walletUI.currencies[currency].value.Text = number.abbreviate(value);
    else
        text.smoothly_interpolate_number(
            walletUI.currencies[currency].value,
            from,
            value,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            true
        );
    end
end

return wallet;
