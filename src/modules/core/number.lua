-- TODO: make this a class for storing very large numbers (like TT2)

local number = { };

local abbreviations = {
    { 1e123 }, -- this has to be here, otherwise the below wouldn't work
    { 1e120, "Notg" },
    { 1e117, "Octg" },
    { 1e114, "Sptg" },
    { 1e111, "Sxtg" },
    { 1e108, "Qitg" },
    { 1e105, "Qatg" },
    { 1e102, "Ttg" },
    { 1e99, "Dtg" },
    { 1e96, "Utg" },
    { 1e93, "Tg" },
    { 1e90, "Novg" },
    { 1e87, "Ocvg" },
    { 1e84, "Spvg" },
    { 1e81, "Sxvg" },
    { 1e78, "Qivg" },
    { 1e75, "Qavg" },
    { 1e72, "Tvg" },
    { 1e69, "Dvg" },
    { 1e66, "Uvg" },
    { 1e63, "Vg" },
    { 1e60, "Nod" },
    { 1e57, "Ocd" },
    { 1e54, "Spd" },
    { 1e51, "Sxd" },
    { 1e48, "Qid" },
    { 1e45, "Qad" },
    { 1e42, "Td" },
    { 1e39, "Dd" },
    { 1e36, "Ud" },
    { 1e33, "Dc" },
    { 1e30, "No" },
    { 1e27, "Oc" },
    { 1e24, "Sp" },
    { 1e21, "Sx" },
    { 1e18, "Qi" },
    { 1e15, "Qd" },
    { 1e12, "T" },
    {  1e9, "B" },
    {  1e6, "M" },
    {  1e3, "K" }
};
table.sort(abbreviations, function(a, b)
    return a[1] < b[1];
end)

function number.abbreviate(n: number)
    if n < 1e3 then return tostring(math.floor(n)); end;
    if n >= 1e300 then return "inf"; end;
    for i, v in abbreviations do
        if n <= v[1] then
            v = abbreviations[i-1];
            return string.format("%.02f%s", n / v[1], v[2]);
        end
    end
    local digits = math.floor(math.log10(n));
    local rounded = math.floor(digits / 3) * 3;
    return string.format("%.02fe%d", n / 10^rounded, rounded);
end

return number;
