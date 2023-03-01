local vshard = require('vshard')
local uuid = require('uuid')
local fiber = require('fiber')
local log = require("log")
local json = require('json')
local errors = require('errors')

local AuthError = errors.new_class("AuthError")

local function get_user_uuid_by_email(email)
    local r, e, user_uuid
    for _, rs in pairs(vshard.router.routeall()) do
        r, e = rs:callro('get_user_uuid_by_email', {email}, {timeout = 10})
        if not e then
            -- User found
            user_uuid = r
            break
        elseif e.err ~= "USER_NOT_FOUND" then
            -- Error excepts USER_NOT_FOUND
            local err_message = e.err or e.message or "Unhandled error"
            return nil, AuthError:new(err_message)
        end
    end

    if user_uuid == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end

    return user_uuid
end

local function get_user_uuid_by_session(session)
    local r, e
    local user_uuid
    for _, rs in pairs(vshard.router.routeall()) do
        r, e = rs:callro('get_user_uuid_by_session', {session}, {timeout = 10})
        if not e then
            -- Session found
            user_uuid = r
            break
        elseif e.err ~= "NOT_AUTHENTICATED" then
            -- Error excepts NOT_AUTHENTICATED
            local err_message = e.err or e.message or "Unhandled error"
            return nil, AuthError:new(err_message)
        end
    end

    if user_uuid == nil then
        return nil, AuthError:new('NOT_AUTHENTICATED')
    end

    return user_uuid
end

local function signup_user(req)
    -- req:json: 
        -- email:    string, not mandatory for anonymous
        -- password: string, not mandatory for anonymous    

    local user = req:json()
    
    local r, e
    if user.email ~= nil then
        r, e = AuthError:pcall(get_user_uuid_by_email, user.email)
        if not e then
            -- User found
            local err_message = "USER_ALREADY_EXISTS"
            local resp = req:render({json = {error = err_message}})
            resp.status = 500
            return resp
        elseif e.err ~= "USER_NOT_FOUND"  then
            -- Error excepts USER_NOT_FOUND
            local err_message = e.err or e.message or "Unhandled error"
            local resp = req:render({json = {error = err_message}})
            resp.status = 500
            return resp
        end
    end

    user.user_uuid = uuid.new()
    user.bucket_id = vshard.router.bucket_id_mpcrc32(user.user_uuid)

    r, e = AuthError:pcall(vshard.router.callrw, user.bucket_id, 'signup_user', {user}, {timeout = 10})

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

local function confirm_email(req)
    -- req:json: 
        -- email:   string, mandatory
        -- code:    string, mandatory

    local params = req:json()

    local r, e, user_uuid
    user_uuid, e = AuthError:pcall(get_user_uuid_by_email, params.email)
    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    r, e = AuthError:pcall(vshard.router.callrw, bucket_id, 'confirm_email', {user_uuid, params.code}, {timeout = 10})

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

local function restore_password(req)
    -- req:json: 
        -- email:   string, mandatory

    local params = req:json()

    local r, e, user_uuid
    user_uuid, e = AuthError:pcall(get_user_uuid_by_email, params.email)
    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    r, e = AuthError:pcall(vshard.router.callrw, bucket_id, 'restore_password', {params.email}, {timeout = 10})

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

local function complete_password_restoration(req)
    -- req:json: 
        -- email:       string, mandatory
        -- token:       string, mandatory
        -- password:    string, mandatory

    local params = req:json()

    local r, e, user_uuid
    user_uuid, e = AuthError:pcall(get_user_uuid_by_email, params.email)
    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    r, e = AuthError:pcall(
        vshard.router.callrw, 
        bucket_id, 
        'complete_password_restoration', 
        {params.email, params.token, params.password}, 
        {timeout = 10}
    )
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

local function signin_user(req)
    -- req:json: 
        -- user_uuid:   string, mandatory only for anonymous
        -- email:       string, mandatory only for unanonymous
        -- password:    string, mandatory only for unanonymous

    local params = req:json()

    local r, e, user_uuid
    if params.email ~= nil then
        user_uuid, e = AuthError:pcall(get_user_uuid_by_email, params.email)
        if e then
            local err_message = e.err or e.message or "Unhandled error"
            local resp = req:render({json = {error = err_message}})
            resp.status = 500
            return resp
        end
    else
        user_uuid = uuid.fromstr(params.user_uuid)
    end

    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    r, e = AuthError:pcall(vshard.router.callrw, bucket_id, 'signin_user', {user_uuid, params.email, params.password, bucket_id}, {timeout = 10})
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

local function check_and_refresh_session(req)
    -- req:json: 
        -- session:     string, mandatory

    local params = req:json()

    local r, e, user_uuid
    user_uuid, e = AuthError:pcall(get_user_uuid_by_session, params.session)
    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    r, e = AuthError:pcall(vshard.router.callrw, bucket_id, 'check_and_refresh_session', {params.session}, {timeout = 10})
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


local function signout_user(req)
    -- req:json: 
        -- session:     string, mandatory
        
    local params = req:json()

    local r, e, user_uuid
    user_uuid, e = AuthError:pcall(get_user_uuid_by_session, params.session)
    if e then
        local err_message = e.err or e.message or "Unhandled error"
        local resp = req:render({json = {error = err_message}})
        resp.status = 500
        return resp
    end

    local bucket_id = vshard.router.bucket_id_mpcrc32(user_uuid)

    r, e = AuthError:pcall(vshard.router.callrw, bucket_id, 'signout_user', {params.session}, {timeout = 10})

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
    signup_user = signup_user,
    confirm_email = confirm_email,
    restore_password = restore_password,
    complete_password_restoration = complete_password_restoration,
    signin_user = signin_user,
    check_and_refresh_session = check_and_refresh_session,
    signout_user = signout_user
}