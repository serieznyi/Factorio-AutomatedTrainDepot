local util = {}

function util.print (data, indent)
    local indent = indent or 0

    if type(data) ~= 'table'then
        print(tostring(data));
        return
    end

    for kk, v in pairs(data) do
        local k = kk;
        -- if type(k) == "string" then
        -- 	k = string.format("%q", k)
        -- end
        local szSuffix = ""
        local formatting = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."['"..k.."']".." = "..szSuffix
        if type(v) == "table" then
            print(formatting)
            util.print(v, indent + 1)
            print(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting..szValue..",")
        end
    end
end

return util