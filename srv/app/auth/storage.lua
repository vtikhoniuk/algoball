local fiber = require('fiber')
local log = require("log")
local json = require('json')
local utils = require('app.tools.utils')
local errors = require('errors')
local digest = require('digest')
local uuid = require('uuid')
local auth_config = require('app.auth.config')
local auth_schema = require('app.auth.schema')

local NULL = require("msgpack").NULL
local AuthError = errors.new_class("AuthError")

local function get_user_uuid_by_email(email)
    email = utils.lower(email)
    if not auth_schema.user.is_email(email) then
        return nil, AuthError:new('INVALID_PARAMS')
    end

    local user_tuple = auth_schema.user.get_by_email(email, auth_schema.user.COMMON_TYPE)
    if user_tuple == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end    

    return user_tuple[auth_schema.user.USER_UUID]
end

local function get_user_uuid_by_session(session)
    if not utils.is_not_empty_string(session) then
        return nil, AuthError:new('INVALID_PARAMS')
    end

    local encoded_session_data, session_sign = auth_schema.session.split_session(session)
    if encoded_session_data == nil then
        return nil, AuthError:new('WRONG_SESSION_SIGN')
    end

    local session_tuple = auth_schema.session.get_by_session(encoded_session_data)
    if session_tuple == nil then
        return nil, AuthError:new('NOT_AUTHENTICATED')
    end

    return session_tuple[auth_schema.session.USER_UUID]
end

local signin_user

local function signup_user(user)
    -- user.user_uuid:      string, mandatory
    -- user.bucket_id:      unsigned, mandatory
    -- user.email:          string, not mandatory for anonymous
    -- user.password:       string, not mandatory for anonymous   TODO: should be checked on client side and transfered encrypted

    if not uuid.is_uuid(user.user_uuid) then
        return nil, AuthError:new('INVALID_UUID')
    end

    local password_hash, user_tuple
    if user.email ~= nil then
        user.email = utils.lower(user.email)
        if not auth_schema.user.is_email(user.email) then
            return nil, AuthError:new('INVALID_PARAMS')
        end

        if not auth_schema.user.is_strong_enough(user.password) then
            return nil, AuthError:new('WEAK_PASSWORD')
        end

        password_hash = utils.salted_hash(user.password, user.user_uuid)
    end

    user_tuple = {
        [auth_schema.user.USER_UUID] = user.user_uuid,
        [auth_schema.user.EMAIL] = user.email or NULL,
        [auth_schema.user.PASSWORD_HASH] = password_hash or NULL,
        [auth_schema.user.TYPE] = auth_schema.user.COMMON_TYPE,
        [auth_schema.user.REGISTRATION_TIMESTAMP] = utils.now_ms(),
        [auth_schema.user.IS_EMAIL_CONFIRMED] = false,
        [auth_schema.user.BUCKET_ID] = user.bucket_id
    }

    box.begin()
    local tuple = auth_schema.user.create(user_tuple)
    if not tuple then
        return nil, AuthError:new('INTERNAL_ERROR')
    end
    box.commit()

    return signin_user(user.user_uuid, user.email, user.password, user.bucket_id)
end

local function confirm_email(user_uuid, code)
    local user_tuple = auth_schema.user.get_by_user_uuid(user_uuid)
    if user_tuple == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end

    if user_tuple[auth_schema.user.IS_EMAIL_CONFIRMED] then
        return nil, AuthError:new('EMAIL_ALREADY_CONFIRMED')
    end

    local correct_code = auth_schema.user.generate_activation_code(user_uuid)
    if code:match('^"*(.-)"*$') ~= correct_code then
        return nil, AuthError:new('WRONG_ACTIVATION_CODE')
    end

    auth_schema.user.update({
        [auth_schema.user.USER_UUID] = user_uuid,
        [auth_schema.user.IS_EMAIL_CONFIRMED] = true
    })

    return true
end

local function restore_password(email)
    email = utils.lower(email)

    local user_tuple = auth_schema.user.get_by_email(email, auth_schema.user.COMMON_TYPE)
    if user_tuple == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end

    --[[ if not user_tuple[auth_schema.user.IS_EMAIL_CONFIRMED] then
        return nil, AuthError:new('EMAIL_NOT_CONFIRMED')
    end ]]

    local token = digest.md5_hex(user_tuple[auth_schema.user.USER_UUID]:str()..os.time()..auth_config.RESTORE_SECRET)
    auth_schema.user.update({
        [auth_schema.user.USER_UUID] = user_tuple[auth_schema.user.USER_UUID],
        [auth_schema.user.PASSWORD_RESTORATION_TOKEN] = token,
        [auth_schema.user.PASSWORD_RESTORATION_TIMESTAMP] = utils.now_ms(),
    })

    return token
end

local function complete_password_restoration(email, token, password)
    email = utils.lower(email)
    token = token:match('^"*(.-)"*$')

    if not utils.is_not_empty_string(token) then
        return nil, AuthError:new('INVALID_PARAMS')
    end

    local user_tuple = auth_schema.user.get_by_email(email, auth_schema.user.COMMON_TYPE)
    if user_tuple == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end

    if utils.now_ms() - user_tuple[auth_schema.user.PASSWORD_RESTORATION_TIMESTAMP] > auth_config.RESTORE_TIMEOUT then
        return nil, AuthError:new('PASSWORD_RESTORATION_TIMEOUT_EXCEEDED')
    end

    --[[ if not user_tuple[auth_schema.user.IS_EMAIL_CONFIRMED] then
        return nil, AuthError:new('EMAIL_NOT_CONFIRMED')
    end ]]

    if not auth_schema.user.is_strong_enough(password) then
        return nil, AuthError:new('WEAK_PASSWORD')
    end

    local user_uuid = user_tuple[auth_schema.user.USER_UUID]
    if auth_schema.user.is_password_token_valid(token, user_uuid) then

        box.begin()
        auth_schema.user.update({
            [auth_schema.user.USER_UUID] = user_uuid,
            [auth_schema.user.PASSWORD_HASH] = utils.salted_hash(password, user_uuid),
            [auth_schema.user.PASSWORD_RESTORATION_TOKEN] = NULL,
            [auth_schema.user.PASSWORD_RESTORATION_TIMESTAMP] = NULL
        })
        auth_schema.session.drop_by_user_uuid(user_uuid)
        box.commit()

        return true
    else
        return nil, AuthError:new('WRONG_RESTORATION_TOKEN')
    end
end

signin_user = function(user_uuid, email, password, bucket_id)
    
    email = utils.lower(email)    
    if email ~= nil and not auth_schema.user.is_password_valid(password, user_uuid) then
        return nil, AuthError:new('WRONG_PASSWORD')
    end

    box.begin()
    local session = auth_schema.session.create(
        user_uuid, 
        auth_schema.session.COMMON_SESSION_TYPE,
        nil,
        bucket_id
    )
    box.commit()

    if email == nil then
        email = ""
    end

    return  {
        user_uuid = user_uuid,
        session = session,
        --email = email
    }
end

local function check_and_refresh_session(session)
    if not utils.is_not_empty_string(session) then
        return nil, AuthError:new('INVALID_PARAMS')
    end

    local encoded_session_data = auth_schema.session.validate_session(session)
    if encoded_session_data == nil then
        return nil, AuthError:new('WRONG_SESSION_SIGN')
    end

    local session_tuple = auth_schema.session.get_by_session(encoded_session_data)
    if session_tuple == nil then
        return nil, AuthError:new('NOT_AUTHENTICATED')
    end

    --[[ if not user_tuple[auth_schema.user.IS_ACTIVE] then
        return nil, AuthError:new('USER_NOT_ACTIVE')
    end ]]

    local session_data = auth_schema.session.decode(encoded_session_data)

    local new_session
    if auth_schema.session.is_expired(session_data) then
        return nil, AuthError:new('NOT_AUTHENTICATED')
   
    elseif auth_schema.session.is_refresh_needed(session_data) then
        box.begin()
        new_session = auth_schema.session.create(
            session_tuple[auth_schema.session.USER_UUID], 
            auth_schema.session.COMMON_SESSION_TYPE,
            nil,
            session_tuple[auth_schema.session.BUCKET_ID]  
        )
        auth_schema.session.delete_by_session_uuid(session_tuple[auth_schema.session.SESSION_UUID])
        box.commit()
    else
        new_session = session
    end

    local user_tuple = auth_schema.user.get_by_user_uuid(session_tuple[auth_schema.session.USER_UUID])
    if user_tuple == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end

    return {
        user_uuid = session_tuple[auth_schema.session.USER_UUID],
        session = new_session,
        email = user_tuple[auth_schema.user.EMAIL]
    }
end

local function signout_user(session)
    if not utils.is_not_empty_string(session) then
        return nil, AuthError:new('INVALID_PARAMS')
    end

    local encoded_session_data = auth_schema.session.validate_session(session)
    if encoded_session_data == nil then
        return nil, AuthError:new('WRONG_SESSION_SIGN')
    end

    local session_tuple = auth_schema.session.get_by_session(encoded_session_data)
    if session_tuple == nil then
        return nil, AuthError:new('NOT_AUTHENTICATED')
    end

    local user_tuple = auth_schema.user.get_by_user_uuid(session_tuple[auth_schema.session.USER_UUID])
    if user_tuple == nil then
        return nil, AuthError:new('USER_NOT_FOUND')
    end

    box.begin()
    auth_schema.session.delete_by_session_uuid(session_tuple[auth_schema.session.SESSION_UUID])
    box.commit()

    return true
end

return {
    get_user_uuid_by_email = get_user_uuid_by_email,
    get_user_uuid_by_session = get_user_uuid_by_session,
    signup_user = signup_user,
    confirm_email = confirm_email,
    restore_password = restore_password,
    complete_password_restoration = complete_password_restoration,
    signin_user = signin_user,
    check_and_refresh_session = check_and_refresh_session,
    signout_user = signout_user
}
