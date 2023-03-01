local user = require('app.auth.user').model()
local session = require('app.auth.session').model()

---------------------------------------- user -----------------------------------------
local function create()
    local user_space = box.schema.space.create(
        'user', {
            format = {
                {'user_uuid', 'uuid'},
                {'email', 'string', is_nullable = true},
                {'password_hash', 'string', is_nullable = true},
                {'type', 'unsigned'},
                {'registration_timestamp', 'number'},    -- timestamp of register_user
                {'is_email_confirmed', 'boolean'},
                {'password_restoration_token', 'string', is_nullable = true}, 
                {'password_restoration_timestamp', 'number', is_nullable = true},   -- timestamp of restore_password
                {'bucket_id', 'unsigned'}
            },                        
            if_not_exists = true
        }
    )
    user_space:create_index(
        'primary', {
            parts = {'user_uuid'},
            if_not_exists = true
        }
    )
    user_space:create_index(
        'email_index', {
            unique = false,
            parts = {'email','type'},
            if_not_exists = true
        }
    )
    user_space:create_index(
        'bucket_id', {
            unique = false,
            parts = {'bucket_id'},
            if_not_exists = true
        }
    )

    --------------------------------------- session ---------------------------------------
    local session_space = box.schema.space.create(
        'session', {
            format = {
                {'session_uuid', 'uuid'},
                {'code_uuid', 'uuid'},
                {'user_uuid', 'uuid'},
                {'credential', 'string', is_nullable = true},
                {'bucket_id', 'unsigned'}
            },
            if_not_exists = true
        }
    )
    session_space:create_index(
        'primary', {
            parts = {'session_uuid'},
            if_not_exists = true
        }
    )
    session_space:create_index(
        'user_index', {
            unique = false,
            parts = {'user_uuid'},
            if_not_exists = true
        }
    )
    session_space:create_index(
        'bucket_id', {
            unique = false,
            parts = {'bucket_id'},
            if_not_exists = true
        }
    )
end

local function truncate()
    box.space.user:truncate()
    box.space.session:truncate()
end

return {
    user = user,
    session = session,
    create = create,
    truncate = truncate
}
