local vshard = require('vshard')
local uuid = require('uuid')
local fiber = require('fiber')
local log = require("log")
local json = require('json')
local errors = require('errors')

local GameError = errors.new_class("GameError")

local function add_suit(suit, rarity_type, flow_type)
    local r, e
    for _, rs in pairs(vshard.router.routeall()) do
        r, e = rs:callrw('add_suit', {suit, rarity_type, flow_type}, {timeout = 10})
        if e then
            log.info('**** e = '..tostring(e))
            fiber.sleep(1)

            return false
        end
    end

    return true
end

local function activate_suit(suit, total_count)
    local r, e
    for _, rs in pairs(vshard.router.routeall()) do
        r, e = rs:callrw('activate_suit', {suit, total_count}, {timeout = 10})
        if e then
            log.info('**** e = '..tostring(e))
            fiber.sleep(1)
            return false
        end
    end

    return true
end

local function get_usergame(req)
    -- req:json: 
        -- user_uuid:    string, mandatory

    local user_uuid = uuid.fromstr(req:json().user_uuid)
    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    local r, e = GameError:pcall(vshard.router.callrw, bucket_id, 'get_usergame', {user_uuid, bucket_id}, {timeout = 10})

    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local resp = req:render({json = r})
    resp.status = 200
    return resp
end

local function get_next_level(req)
    -- req:json: 
        -- user_uuid:    string, mandatory
        -- move_set:     array, mandatory

    local user_uuid = uuid.fromstr(req:json().user_uuid)
    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)
    local move_set = req:json().move_set

    local r, e = GameError:pcall(vshard.router.callrw, bucket_id, 'get_next_level', {user_uuid, move_set}, {timeout = 10})

    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local resp = req:render({json = r})
    resp.status = 200
    return resp
end

return {
    add_suit = add_suit,
    activate_suit = activate_suit,
    get_usergame = get_usergame,
    get_next_level = get_next_level,
}