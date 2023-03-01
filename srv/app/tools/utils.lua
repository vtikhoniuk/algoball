local digest = require('digest')
local fiber = require('fiber')
local math = require('math')
local uuid = require('uuid')
local json = require('json')
local log = require('log')

local function now_ms()
    return math.floor(fiber.time()*1000)
end    

local function is_string(str)
    return type(str) == 'string'
end    

local function is_not_empty_string(str)
    return is_string(str) and str ~= ''
end    

local function is_positive_number(number)
    return type(number) == 'number' and number >= 0
end    

local function nvl2(value, nil_value, not_nil_value)
    if value == nil then
        return nil_value
    end
    return not_nil_value
end

local function lower(string)
    if is_string(string) then
        return string:lower()
    end
end

local function format(string, tab)
    return (string:gsub('($%b{})', function(word) return tab[word:sub(3, -2)] or word end))
end    

local function format_update(tuple) -- TODO: convert to serialize?
    local fields = {}
    for number, value in pairs(tuple) do
        table.insert(fields, {'=', number, value})
    end    
    return fields
end    

local function base64_encode(string) -- TODO: move to crypto_utils?
    return string.gsub(
        digest.base64_encode(string), '\n', ''
    )    
end    

local function gen_random_key(key_len) -- TODO: move to crypto_utils?
    return string.hex(digest.urandom(key_len or 10))
end

local function salted_hash(str, salt) -- TODO: move to crypto_utils?
    return digest.sha256(string.format('%s%s', salt, str))
end

local function is_table(tbl)
    return type(tbl) == 'table'
end    

local function add_full_table(tbl, add_tbl)
    table.move(add_tbl, 1, #add_tbl, #tbl + 1, tbl)
end

local function complement_table(tbl, add_tbl) -- Only for one dimention table!: {1, 3, 48, ..}
    local return_set = {}
    return_set = table.deepcopy(tbl)
    for _, j in ipairs(add_tbl) do
        local found = false
        for _, i in ipairs(return_set) do
            if i == j then
                found = true
                break
            end
        end
        if found == false then
            table.insert(return_set, j)
        end
    end
    return return_set
end

local function exclude_table(tbl, exclude_tbl) -- Only for one dimention table!: {1, 3, 48, ..}
    local return_set = {}
    return_set = table.deepcopy(tbl)
    for _, j in ipairs(exclude_tbl) do
        local found = false
        for i, k in ipairs(return_set) do
            if k == j then
                table.remove(return_set, i)
                break
            end
        end
    end
    return return_set
end

local function compare_tables(tbl_1, tbl_2) -- Only for one dimention table!: {1, 3, 48, ..}
    -- Return true or false
    if tbl_1 == nil or tbl_2 == nil or #tbl_1 ~= #tbl_2 then
        return false
    end
    for _, i in ipairs(tbl_1) do
        local found = false
        for _, j in ipairs(tbl_2) do
            if i == j then
                found = true
                break
            end
        end
        if found == false then
            return false
        end
    end
    return true
end

local function table_length(tbl)
    if tbl == nil then
        return nil
    end
    local length = 0
    for v in pairs(tbl) do
        length = length + 1
    end
    return length
end

local function get_index_set(tbl)
    local return_set = {}
    for i = 1, #tbl do
        table.insert(return_set, i)
    end
    return return_set
end

local trace_mode = false
local func_for_trace = {}
local user_uuid_for_trace = {}
local topic_for_trace = {}

local function trace(func, tbl, topic)
    -- func     -- func name: string, mandatory
    -- tbl      -- structure for log: string/map/array of map, mandatory
                -- string could be logged only when user_uuid_for_trace is nil
                -- when user_uuid_for_trace or topic_for_trace is not nil, standalone map or map in array
                --      should contain user_uuid field
    -- topic    -- mark of trace point: string

    local f = debug.getinfo(1)
    log.info('**** func = '..tostring(f))
    log.info('**** func = '..tostring(f.name))
    log.info('**** func = '..tostring(f.what))
    log.info('**** func = '..tostring(f.namewhat))
    log.info('**** func = '..tostring(f.short_src))
    fiber.sleep(1)
end
    
    
--[[     if not trace_mode then
        return
    end

    local msg
    if  (func == nil) or
        (func == '') or
        (type(func) ~= 'string')
    then
        msg = "*** trace: Incorrect func format"
        log.info(msg)
        return msg
    end
    
    if  (tbl == nil) or
        (
            type(tbl) ~= 'string' and
            type(tbl) ~= 'table'
        ) or
        (    
            type(tbl) == 'table' and
            table_length(tbl) == 0
        )
    then
        msg = "*** trace: Incorrect tbl format"
        log.info(msg)
        return msg
    end

    if topic ~= nil and type(topic) ~= 'string' then
        msg = "*** trace: Incorrect topic format"
        log.info(msg)
        return msg
    end

    local func_found = false
    if func_for_trace ~= nil then
        for _, f in pairs(func_for_trace) do
            if  (func == f) or
                (string.sub(func, 9) == string.sub(f, 5)) or -- for different prefixes: sls_tnt_ and sls_
                (string.sub(func, 5) == string.sub(f, 9))
            then
                func_found = true
                break
            end
        end
    end

    local user_uuid_found = false
    if user_uuid_for_trace ~= nil and type(tbl) ~= 'string' then
        if tbl.user_uuid ~= nil then
            for _, i in pairs(user_uuid_for_trace) do
                if tbl.user_uuid == i then
                    user_uuid_found = true
                    break
                end
            end
        else
            for _, v in ipairs(tbl) do
                for _, i in pairs(user_uuid_for_trace) do
                    if v.user_uuid == i then
                        user_uuid_found = true
                        break
                    end
                end
                if user_uuid_found == true then
                    break
                end
            end
        end
    end

    local topic_found = false
    if topic_for_trace ~= nil and type(tbl) ~= 'string' then
        if tbl.topic ~= nil then
            for _, i in pairs(topic_for_trace) do
                if tbl.topic == i then
                    topic_found = true
                    break
                end
            end
        else
            for _, v in ipairs(tbl) do
                for _, i in pairs(topic_for_trace) do
                    if v.topic == i then
                        topic_found = true
                        break
                    end
                end
                if topic_found == true then
                    break
                end
            end
        end
    end

    if  (
            (func_for_trace == nil) or
            (func_for_trace ~= nil and func_found)
        ) and
        (
            (user_uuid_for_trace ~= nil and user_uuid_found) or
            (topic_for_trace ~= nil and topic_found) or
            (user_uuid_for_trace == nil and topic_for_trace == nil)
        )
    then
        msg = "*** trace for "..func
        if topic ~= nil then
            msg = msg..", "..topic
        end
        msg = msg..": "..json.encode(tbl)
        log.info(msg)
        return msg
    end
end ]]

local function set_trace_on(
    func,       -- one func name or array of func names, nil -> all funcs
    user_uuid,  -- one user_uuid or array of user_uuid's, nil -> all user_uuid’s
    topic       -- one topic (string) or array of topics, nil -> all topics
    -- next call overwrite previous options
)
    local func_for_trace_tmp = {}
    if  (func == nil) or
        (func == '') or
        (
            type(func) == 'table' and 
            table_length(func) == 0
        )
    then
        func_for_trace_tmp = nil
    elseif type(func) == 'string' then
        table.insert(func_for_trace_tmp, func)
    elseif type(func) == 'table' and #func == table_length(func) then
        for _, f in ipairs(func) do
            if f ~= nil and f ~= '' and type(f) == 'string' then
                table.insert(func_for_trace_tmp, f)
            else
                return error("Incorrect func format")
            end
        end
    else
        return error("Incorrect func format")
    end

    local user_uuid_for_trace_tmp = {}
    if  (user_uuid == nil) or 
        (
            type(user_uuid) == 'table' and
            table_length(user_uuid) == 0
        )
    then
        user_uuid_for_trace_tmp = nil
    elseif uuid.is_uuid(user_uuid) then
        table.insert(user_uuid_for_trace_tmp, user_uuid)
    elseif type(user_uuid) == 'table' and #user_uuid == table_length(user_uuid) then
        for _, u in ipairs(user_uuid) do
            if u ~= nil and uuid.is_uuid(u) then
                table.insert(user_uuid_for_trace_tmp, u)
            else
                return error("Incorrect user_uuid format")
            end
        end
    else
        return error("Incorrect user_uuid format")
    end

    local topic_for_trace_tmp = {}
    if  (topic == nil) or
        (
            type(topic) == 'table' and
            table_length(topic) == 0
        )
    then
        topic_for_trace_tmp = nil
    elseif type(topic) == 'string' then
        table.insert(topic_for_trace_tmp, topic)
    elseif type(topic) == 'table' and #topic == table_length(topic) then
        for _, t in ipairs(topic) do
            if t ~= nil and t ~= '' and type(t) == 'string' then
                table.insert(topic_for_trace_tmp, t)
            else
                return error("Incorrect topic format")
            end
        end
    else
        return error("Incorrect topic format")
    end

    func_for_trace = func_for_trace_tmp
    user_uuid_for_trace = user_uuid_for_trace_tmp
    topic_for_trace = topic_for_trace_tmp
    trace_mode = true

    return (
        nvl2(func_for_trace, "nil", json.encode(func_for_trace))..", "..
        nvl2(user_uuid_for_trace, "nil", json.encode(user_uuid_for_trace))..", "..
        nvl2(topic_for_trace, "nil", json.encode(topic_for_trace))
    )
end

local function set_trace_off()
    trace_mode = false
    return true
end

return {
    now_ms = now_ms,
    is_string = is_string,
    is_not_empty_string = is_not_empty_string,
    is_positive_number = is_positive_number,
    lower = lower,
    format = format,
    format_update = format_update,
    base64_encode = base64_encode,
    gen_random_key = gen_random_key,
    salted_hash = salted_hash,
    is_table = is_table,
    add_full_table = add_full_table,
    complement_table = complement_table,
    exclude_table = exclude_table,
    compare_tables = compare_tables,
    get_index_set = get_index_set,
    trace = trace,
    set_trace_on = set_trace_on,
    set_trace_off = set_trace_off
}
