local cartridge = require('cartridge')
local fiber = require('fiber')
local log = require("log")
local json = require('json')
local auth_router = require('app.auth.router')
local game_router = require('app.game.router')

local function handler(cx, resp)
    resp.headers = {
        ['Access-Control-Allow-Origin' ] = 'http://localhost:3000',
        ['Access-Control-Allow-Methods'] = '*',
        ['Access-Control-Allow-Credentials'] = 'true',
        ['Access-Control-Allow-Headers'] = 'authorization,content-type',
        ['content-type'] = 'application/json',
    }    
end

local router_api = {
    add_suit = game_router.add_suit,
    activate_suit = game_router.activate_suit,
}

local function init(opts)

    for name, func in pairs(router_api) do
        rawset(_G, name, func)
    end

    local httpd = assert(cartridge.service_get('httpd'), "Failed to get httpd service")
    httpd:hook('after_dispatch', handler)

    httpd:route(
        {path = '/signup', method = 'POST'--[[ , public = true ]] },
        auth_router.signup_user
    )

    httpd:route(
        {path = '/signup', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    --[[ httpd:route(
        {path = '/confirm', method = 'POST', public = true},
        auth_router.confirm_email
    ) ]]

    httpd:route(
        {path = '/restore', method = 'POST'--[[ , public = true ]] },
        auth_router.restore_password
    )

    httpd:route(
        {path = '/restore', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    httpd:route(
        {path = '/complete', method = 'POST'--[[ , public = true ]] },
        auth_router.complete_password_restoration
    )

    httpd:route(
        {path = '/complete', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    httpd:route(
        {path = '/signin', method = 'POST', public = true },
        auth_router.signin_user
    )

    httpd:route(
        {path = '/signin', method = 'OPTIONS', public = true },
        function() return {} end
    )

    httpd:route(
        {path = '/check', method = 'POST'--[[ , public = true ]] },
        auth_router.check_and_refresh_session
    )

    httpd:route(
        {path = '/check', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    httpd:route(
        {path = '/signout', method = 'POST'--[[ , public = true ]] },
        auth_router.signout_user
    )

    httpd:route(
        {path = '/signout', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    httpd:route(
        {path = '/usergame', method = 'POST'--[[ , public = true ]] },
        game_router.get_usergame
    )

    httpd:route(
        {path = '/usergame', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    httpd:route(
        {path = '/next_level', method = 'POST'--[[ , public = true ]] },
        game_router.get_next_level
    )

    httpd:route(
        {path = '/next_level', method = 'OPTIONS'--[[ , public = true ]] },
        function() return {} end
    )

    return true
end

return {
    role_name = 'router',
    init = init,
    dependencies = {'cartridge.roles.vshard-router'}
}