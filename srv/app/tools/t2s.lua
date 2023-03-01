local log = require('log')
local json = require('json')
local fiber = require('fiber')

local function table_length(tbl)
    if tbl == nil then
        return nil
    end
    local length = 0
    for _, v in pairs(tbl) do
        length = length + 1
    end
    return length
end

local table_to_str
local function table_val_to_str(v, level, linebreak_threshold)
    if type(v) == "string" then
       v = string.gsub(v, "\n", "\\n")
       if string.match(string.gsub(v,"[^'\"]",""), '^"+$') then
          return "'" .. v .. "'"
       end
       return '"' .. string.gsub(v,'"', '\\"') .. '"'
    end
    return type(v) == "table" and table_to_str(v, level+1, linebreak_threshold) or tostring(v)
 end

local function table_key_to_str(k)
    if type(k) == "string" and string.match(k, "^[_%a][_%a%d]*$") then
       return k
    end
    return "[" .. table_val_to_str(k) .. "]"
end

local function tabs(level)
    local str = ''
    for i = 1,level do
        str = str..'\t'
    end
    return str
end

table_to_str = function(tbl, level, linebreak_threshold)
    local done = {}
    local str = '{'
    local first = true
    for k, v in ipairs(tbl) do
        if first and level < linebreak_threshold then
            str = str..'\n'..tabs(level)..table_val_to_str(v, level, linebreak_threshold)
        elseif first and level >= linebreak_threshold then
            str = str..table_val_to_str(v, level, linebreak_threshold)
        elseif not first and level < linebreak_threshold then
            str = str..',\n'..tabs(level)..table_val_to_str(v, level, linebreak_threshold)
        else
            str = str..','..table_val_to_str(v, level, linebreak_threshold)
        end
        --table.insert( result, table.val_to_str( v, level ) )
        done[k] = true
        first = false
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            if first and level < linebreak_threshold then
                str = str..'\n'..tabs(level)..table_key_to_str(k) .. "=" .. table_val_to_str(v, level, linebreak_threshold)
            elseif first and level >= linebreak_threshold then
                str = str..table_key_to_str(k) .. "=" .. table_val_to_str(v, level, linebreak_threshold)
            elseif first == false and level < linebreak_threshold then
                str = str..',\n'..tabs(level)..table_key_to_str(k) .. "=" .. table_val_to_str(v, level, linebreak_threshold)
            else
                str = str..','..table_key_to_str(k) .. "=" .. table_val_to_str(v, level, linebreak_threshold)
            end
            --table.insert( result, table.key_to_str( k, level ) .. "=" .. table.val_to_str( v, level ) )
        end
        first = false
    end
    if level < linebreak_threshold then
        return str..'\n'..tabs(level-1)..'}'
    else
        return str..'}'
    end
end

local function t2s(tbl, linebreak_threshold)
    if  tbl == nil then
        return ''
    end
    if type(tbl) == 'table' and table_length(tbl) == 0 then
        return '{}'
    end

    if type(tbl) == 'string' then
        return tbl
    end    

    if linebreak_threshold == nil then
        linebreak_threshold = 1
    end

    return table_to_str(tbl, 1, linebreak_threshold)
end  

return {
    t2s = t2s,
    table_length = table_length
}