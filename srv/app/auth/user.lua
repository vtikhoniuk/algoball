local fiber = require('fiber')
local log = require("log")
local json = require('json')
local digest = require('digest')
local uuid = require('uuid')
local utils = require('app.tools.utils')
local auth_config = require('app.auth.config')

local user = {}
function user.model()
    local model = {}

    model.USER_UUID = 1
    model.EMAIL = 2
    model.PASSWORD_HASH = 3
    model.TYPE = 4
    model.REGISTRATION_TIMESTAMP = 5    -- timestamp of register_user
    model.IS_EMAIL_CONFIRMED = 6
    model.PASSWORD_RESTORATION_TOKEN = 7
    model.PASSWORD_RESTORATION_TIMESTAMP = 8  -- timestamp of restore_password
    model.BUCKET_ID = 9

    model.COMMON_TYPE = 1
    --model.SOCIAL_TYPE = 2

    -- Convert tuple to map
    function model.deserialize(user_tuple, data)
    
        local user_data = {
            user_uuid = user_tuple[model.USER_UUID],
            email = user_tuple[model.EMAIL],
            password_hash = user_tuple[model.PASSWORD_HASH],
            is_email_confirmed = user_tuple[model.IS_EMAIL_CONFIRMED],
            profile = user_tuple[model.PROFILE],
        }
        if data ~= nil then
            for k,v in pairs(data) do
                user_data[k] = v
            end
        end

        return user_data
    end

    function model.get_by_user_uuid(USER_UUID)
        return box.space.user:get(USER_UUID)
    end

    function model.get_by_email(email, type)
        if utils.is_not_empty_string(email) then
            return box.space.user.index.email_index:select({email, type})[1]
        end
    end

    function model.create(user_tuple)
        local tuple = box.space.user:insert{
            user_tuple[model.USER_UUID],
            user_tuple[model.EMAIL],
            user_tuple[model.PASSWORD_HASH],
            user_tuple[model.TYPE],
            user_tuple[model.REGISTRATION_TIMESTAMP],
            user_tuple[model.IS_EMAIL_CONFIRMED],
            user_tuple[model.PASSWORD_RESTORATION_TOKEN],
            user_tuple[model.PASSWORD_RESTORATION_TIMESTAMP],
            user_tuple[model.BUCKET_ID]
        }
        return tuple
    end

    function model.update(user_tuple)
        local user_uuid, fields
        user_uuid = user_tuple[model.USER_UUID]
        fields = utils.format_update(user_tuple)
        return box.space.user:update(user_uuid, fields)
    end

    function model.generate_activation_code(USER_UUID)
        return digest.md5_hex(string.format('%s%s', auth_config.ACTIVATION_SECRET, USER_UUID))
    end

    function model.is_email(email_string)
        return utils.is_not_empty_string(email_string) and email_string:match('([^@]+@[^@]+)') == email_string
    end
    
    function model.is_strong_enough(password)
        local min_len = auth_config.STRENGTH[auth_config.PASSWORD_STRENGTH]['min_len']
        local min_group = auth_config.STRENGTH[auth_config.PASSWORD_STRENGTH]['min_group']
    
        if min_len ~= nil and string.len(password) < min_len then
            return false
        end
    
        if min_group ~= nil then
            local char_group_count = 0
            for _, pattern in pairs(auth_config.CHAR_GROUP_PATTERNS) do
                if string.match(password, pattern) then
                    char_group_count = char_group_count + 1
                end
            end
    
            if char_group_count < min_group then
                return false
            end
        end
    
        return true
    end
    
    function model.is_password_valid(password, user_uuid)
        local user_tuple = model.get_by_user_uuid(user_uuid)
        if user_tuple == nil then
            return false
        end

        return user_tuple[model.PASSWORD_HASH] == utils.salted_hash(password, user_uuid)
    end

    function model.is_password_token_valid(token, user_id)
        local user_tuple = model.get_by_user_uuid(user_id)
        if user_tuple == nil then
            return false
        end
        local user_token = user_tuple[model.PASSWORD_RESTORATION_TOKEN]
        if token ~= user_token then
            return false
        else
            return true
        end
    end

    return model
end

return user