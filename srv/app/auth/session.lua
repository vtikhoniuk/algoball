local utils = require('app.tools.utils')
local digest = require('digest')
local uuid = require('uuid')
local log = require('log')
local json = require('json')
local errors = require('errors')
local auth_config = require('app.auth.config')

local AuthError = errors.new_class("AuthError")

local session = {}
function session.model()
    local model = {}

    model.SESSION_UUID = 1
    model.CODE = 2
    model.USER_UUID = 3
    model.CREDENTIAL = 4
    model.BUCKET_ID = 5

    --model.SOCIAL_SESSION_TYPE = 'social'
    model.COMMON_SESSION_TYPE = 'common'

    model.SESSION_LIFETIME =            1000 * 60 * 60 * 24 * 7 -- 7 days
    model.SESSION_UPDATE_TIMEDELTA =    1000 * 60 * 60 * 24 * 7 -- 7 days
    
    function model.set_timeframes(t1, t2)
        model.SESSION_LIFETIME = t1
        model.SESSION_UPDATE_TIMEDELTA = t2
    end

    function model.get_session_lifetime()
        return model.SESSION_LIFETIME
    end

    function model.get_session_timedelta()
        return model.SESSION_UPDATE_TIMEDELTA
    end
    
    function model.get_by_session_uuid(session_uuid)
        if not uuid.is_uuid(session_uuid) then
            AuthError:new('INVALID_SESSION_UUID')
        end
        return box.space.session:get(uuid.fromstr(session_uuid))
    end
    
    function model.decode(encoded_session_data)
        local session_data_json, session_data, ok, msg
        ok, msg = pcall(function()
            session_data_json = digest.base64_decode(encoded_session_data)
            session_data = json.decode(session_data_json)
        end)
        return session_data
    end

    function model.get_by_session(encoded_session_data)
        local session_data = model.decode(encoded_session_data)
        if session_data == nil then
            return nil
        end

        local session_tuple = model.get_by_session_uuid(session_data.sid)
        return session_tuple
    end

    function model.delete_by_session_uuid(session_uuid)
        local session_tuple = box.space.session:delete(session_uuid)
        return session_tuple ~= nil
    end    

    function model.delete(encoded_session_data)
        local session_tuple = model.get_by_session(encoded_session_data)
        if session_tuple == nil then
            return false
        end    

        return model.delete_by_session_uuid(session_tuple[model.ID])
    end    

    function model.drop_by_user_uuid(user_uuid)
        if user_uuid == nil then
            return nil
        end    
        for _, s in box.space.session.index.user_index:pairs(user_uuid, {iterator = box.index.EQ}) do
            box.space.session:delete(s[model.USER_UUID])
        end    
    end    

    local function make_session_sign(encoded_session_data, session_code)
        local sign = digest.sha256_hex(
            string.format('%s%s%s', session_code, encoded_session_data, auth_config.SESSION_SECRET)
        )
        return utils.base64_encode(sign)
    end

    local function get_expiration_time()
        return utils.now_ms() + model.get_session_lifetime()
    end

    function model.split_session(session)
        return string.match(session, '([^.]+).([^.]+)')
    end

    function model.create(user_uuid, type, credential, bucket_id)
        local session_uuid = uuid.new()
        local code = uuid.new()

        local session_tuple = box.space.session:insert({
            [model.SESSION_UUID] = session_uuid,
            [model.CODE] = code,
            [model.USER_UUID] = user_uuid,
            [model.CREDENTIAL] = credential,
            [model.BUCKET_ID] = bucket_id
        })
        
        local expiration_time, session_data
        expiration_time = get_expiration_time()

        session_data = {
                sid = session_uuid,
                exp = expiration_time,
                type = type,
        }

        session_data = json.encode(session_data)
        local encoded_session_data = utils.base64_encode(session_data)
        local encoded_sign = make_session_sign(encoded_session_data, code)
        return string.format('%s.%s', encoded_session_data, encoded_sign)
    end

    function model.validate_session(encoded_session)
        local encoded_session_data, session_sign = model.split_session(encoded_session)
        local session_tuple = model.get_by_session(encoded_session_data)

        if session_tuple == nil then
            return nil
        end

        local sign = make_session_sign(encoded_session_data, session_tuple[model.CODE])

        if sign ~= session_sign then
            return nil
        end

        return encoded_session_data
    end

    function model.is_expired(session_data)
        return session_data.exp <= utils.now_ms()
    end

    function model.is_refresh_needed(session_data)
        return session_data.exp <= (utils.now_ms() + model.get_session_timedelta())
    end

    return model
end

return session
