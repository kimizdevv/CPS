local TweenService = game:GetService("TweenService");

local std = require(game.ReplicatedStorage.modules.core.std);

local styling = { };

function parse_style_arg(styleArg: string)
    if not styleArg then return nil; end;
    local args: { [string]: string|number } = {};
    for _, set in styleArg:split(';') do
        local param, value = set:match("(%a+)=(.+)");
        std.wassert(param and value, "unknown param or value.");
        
        args[param] = tonumber(value) or value;
    end
    return args;
end

function apply_events(object, ev: { [string]: { Tween } })
    for evName, tweens in ev do
        object[evName]:Connect(function()
            for _, tween in tweens do
                tween:Play();
            end
        end)
    end
end

function size_add(object, xs, xo, ys, yo)
    return UDim2.new(
        object.Size.X.Scale + xs, object.Size.X.Offset + xo,
        object.Size.Y.Scale + ys, object.Size.Y.Offset + yo
    );
end
function position_add(object, xs, xo, ys, yo)
    return UDim2.new(
        object.Position.X.Scale + xs, object.Position.X.Offset + xo,
        object.Position.Y.Scale + ys, object.Position.Y.Offset + yo
    );
end

function styling.apply(object: GuiObject, style: string)
    local pattern = style:match("{")~=nil and "(%a+):(%a+):{(.-)}" or "(%a+):(.+)";
    local styleClass, styleName, styleArg = style:match(pattern);
    
    std.assert(styleClass and styleName,
        "style class or name does not exist. (c=%s, n=%s)", tostring(styleClass), tostring(styleName));
    
    local args = parse_style_arg(styleArg);
    
    local function get_param_value(param: string, mustExist: boolean?)
        local value = args and args[param] or nil;
        if mustExist and not value then
            std.warnf("style parameter %s must be specified.", param);
        end
        return value;
    end
    
    if styleClass == "button" then
        if styleName == "modern-choose" then
            local raise = get_param_value("raise") or 4;
            
            apply_events(object, {
                MouseEnter = {
                    TweenService:Create(
                        object,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                        {
                            Position = position_add(object, 0, 0, 0, -raise),
                            BackgroundColor3 = Color3.fromRGB(225, 254, 255),
                        }
                    ),
                    TweenService:Create(
                        object.UIStroke,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                        {
                            Color = Color3.fromRGB(155, 200, 213),
                        }
                    ),
                    TweenService:Create(
                        object.label,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                        {
                            TextColor3 = Color3.fromRGB(121, 180, 225),
                        }
                    )
                },
                MouseLeave = {
                    TweenService:Create(
                        object,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                        {
                            Position = object.Position,
                            BackgroundColor3 = object.BackgroundColor3,
                        }
                    ),
                    TweenService:Create(
                        object.UIStroke,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                        {
                            Color = object.UIStroke.Color,
                        }
                    ),
                    TweenService:Create(
                        object.label,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                        {
                            TextColor3 = object.label.TextColor3,
                        }
                    )
                },
                MouseButton1Down = {
                    TweenService:Create(
                        object,
                        TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        {
                            BackgroundColor3 = Color3.fromRGB(213, 240, 241),
                            Position = position_add(object, 0, 0, 0, raise/2),
                        }
                    ),
                },
                MouseButton1Up = {
                    TweenService:Create(
                        object,
                        TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        {
                            BackgroundColor3 = Color3.fromRGB(225, 254, 255),
                            Position = position_add(object, 0, 0, 0, -raise),
                        }
                    ),
                }
            });
            
            return;
        end
    elseif styleClass == "canvas" then
        if styleName == "menu" then
            local raise = get_param_value("raise", true);
            local scale = get_param_value("scale");
            
            apply_events(object, {
                MouseEnter = {
                    TweenService:Create(
                        object.UIScale,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Scale = scale or 1.2 }
                    ),
                    TweenService:Create(
                        object,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        {
                            Size = size_add(object, 0, 0, 0, raise)
                        }
                    )
                },
                MouseLeave = {
                    TweenService:Create(
                        object.UIScale,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Scale = 1.0 }
                    ),
                    TweenService:Create(
                        object,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        {
                            Size = object.Size
                        }
                    )
                }
            });
            
            return;
        end
    end
    std.warnf("style '%s' does not exist for %s", styleName, styleClass);
end

return styling;
