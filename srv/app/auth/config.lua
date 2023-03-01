local DEFAULT_RESTORE_TIMEOUT =             1000 * 60 * 5 -- 5 min
local RESTORE_TIMEOUT =                     DEFAULT_RESTORE_TIMEOUT

local ACTIVATION_SECRET =   'a3840c81-fa21-4a52-a1b1-21e1abbca1f0'
local SESSION_SECRET =      '5590e2b2-31e0-4ed0-b1bf-28399e54a583'
local RESTORE_SECRET =      'bcc38d2f-a680-4a72-8bde-c8bf41f2dc89'

local CHAR_GROUP_PATTERNS = {
    '[%l]',   -- lower case
    '[%u]',   -- upper case
    '[%d]',   -- digits
    '[!@#&_=;:,/\\|`~ %?%+%-%.%^%%%$%*]',  -- ! @ # & _ = ; : , / \ | ` ~ ? + - . ^ % $ *
}

local STRENGTH = {
    none = {
        min_len = 0,
        min_group = 0,
    },
    whocares = {
        min_len = 4,
        min_group = 1,
    },
    common = {   -- default pattern
        min_len = 8,
        min_group = 3,
    },
    moderate = {
        min_len = 8,
        min_group = 4,
    },
    nightmare = {
        min_len = 12,
        min_group = 4,
    },
}

local PASSWORD_STRENGTH = 'common'

return {
    --SESSION_LIFETIME = SESSION_LIFETIME,
    --SESSION_UPDATE_TIMEDELTA = SESSION_UPDATE_TIMEDELTA,
    RESTORE_TIMEOUT = RESTORE_TIMEOUT,

    ACTIVATION_SECRET = ACTIVATION_SECRET,
    SESSION_SECRET = SESSION_SECRET,
    RESTORE_SECRET = RESTORE_SECRET,

    CHAR_GROUP_PATTERNS = CHAR_GROUP_PATTERNS,
    STRENGTH = STRENGTH,
    PASSWORD_STRENGTH = PASSWORD_STRENGTH
}