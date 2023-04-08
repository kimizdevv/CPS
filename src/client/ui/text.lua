local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local number = require(game.ReplicatedStorage.modules.core.number);

local text = { };

do
    local nvalue;
    local connection;
    function disconnect()
        connection:Disconnect();
        connection = nil;
        if nvalue then
            nvalue:Destroy();
            nvalue = nil;
        end
    end
    function text.smoothly_interpolate_number(
            obj,
            from: number,
            to: number,
            tweenInfo: TweenInfo?,
            abbreviate: boolean
)
        -- TODO-HACKFIX that's is probably a terrible way of doing this
        
        if connection then
            disconnect();
        end
        
        nvalue = Instance.new("NumberValue");
        nvalue.Value = from;
                
        local tween = TweenService:Create(
            nvalue,
            tweenInfo or TweenInfo.new(0.5, Enum.EasingStyle.Linear),
            { Value = to }
        );
        tween:Play();
        
        connection = RunService.Heartbeat:Connect(function()
            obj.Text = abbreviate and number.abbreviate(nvalue.Value)
                                   or tostring(math.floor(nvalue.Value));
            if tween.PlaybackState == Enum.TweenStatus.Completed then
                disconnect();
            end
        end)
    end
end

return text;
