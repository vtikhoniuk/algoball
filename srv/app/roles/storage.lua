local auth_schema = require('app.auth.schema')
local auth_storage = require('app.auth.storage')
local game_schema = require('app.game.schema')
local game_storage = require('app.game.storage')
local game_level = require('app.game.level')
local game_base = require('app.game.base')

local storage_api = {
    get_user_uuid_by_email = auth_storage.get_user_uuid_by_email,
    get_user_uuid_by_session = auth_storage.get_user_uuid_by_session,
    signup_user = auth_storage.signup_user,
    confirm_email = auth_storage.confirm_email,
    restore_password = auth_storage.restore_password,
    complete_password_restoration = auth_storage.complete_password_restoration,
    signin_user = auth_storage.signin_user,
    check_and_refresh_session = auth_storage.check_and_refresh_session,
    signout_user = auth_storage.signout_user,
    set_timeframes = auth_schema.session.set_timeframes,
    auth_truncate = auth_schema.truncate,

    add_suit = game_storage.add_suit,
    activate_suit = game_storage.activate_suit,
    add_initial_suits = game_storage.add_initial_suits,
    get_usergame = game_storage.get_usergame,
    get_next_level = game_storage.get_next_level,
    get_card = game_base.get_card,
    create_level = game_level.create_level,
    create_fake_incoming_branches = game_level.create_fake_incoming_branches,
    game_truncate = game_schema.truncate,
}

local function init(opts)

    for name, func in pairs(storage_api) do
        rawset(_G, name, func)
    end

    math.randomseed(os.clock()*100000000000)

    --game_storage.add_initial_suits()

    return true
end

local function apply_config(conf, opts)
    if opts.is_master then
        auth_schema.create()
        game_schema.create()
    end
end

return {
    role_name = 'storage',
    init = init,
    apply_config = apply_config,
    dependencies = {'cartridge.roles.vshard-storage'}
}