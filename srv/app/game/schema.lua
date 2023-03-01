local function create()

    -----------------------------  usergame  ---------------------------------------
    local usergame = box.schema.space.create(
        'usergame', 
        {
            format = {
                {'user_uuid', 'uuid'}, -- sharding key
                {'bucket_id', 'unsigned'},
                {'balance', 'integer'},
                {'moves', 'integer'},
                {'level', 'integer'},
                {'col_set', 'array'}, -- array of suits
                {'own_set', 'array'}, -- array of suits
                {'offer_set', 'array'} -- array of records {original_set, flip_set}, where each set is array of suits
            },
            if_not_exists = true
        }
    )
    usergame:create_index(
        'primary',
        {
            parts = {'user_uuid'},
            unique = true,
            if_not_exists = true
        }
    )
    usergame:create_index(
        'bucket_id',
        {
            parts = {'bucket_id'},
            unique = false,
            if_not_exists = true
        }
    )

    -----------------------------  suit  ---------------------------------------
    local suit = box.schema.space.create(
        'suit', 
        {
            format = {
                {'suit', 'unsigned'},           -- primary key (5 digits)
                {'rarity_type', 'integer'},     -- 1: simple, 2: flags, 3: exclusive?
                {'flow_type', 'integer'},       -- 1: slow, 2: mid, 3: quick
                {'status', 'integer'},          -- 0: prepared, 1: active
                {'total_count', 'integer'},     -- total count of activated cards on the specific replicaset
                {'rest_count', 'integer'}       -- rest count on the specific replicaset
            },
            if_not_exists = true
        }
    )
    suit:create_index(
        'primary',
        {
            parts = {'suit'},
            unique = true,
            if_not_exists = true
        }
    )

    box.schema.func.create(
        'get_card_func',
        {
            is_deterministic = true, 
            is_sandboxed = true,
            if_not_exists = true,
            body = [[function(tuple) 
                return {
                    tuple[1]%10,                     -- persistence: 1-BURNED, 2-PERSISTENT
                    math.floor(tuple[1]/10)%10,      -- universality (gold): 1-8-ORDINARY, 9-GOLD (universal)
                    tuple[2],                        -- rarity_type
                    tuple[4],                        -- status
                    tuple[6] > 0                     -- not empty: boolean
                } 
            end]]
        }
    )
    suit:create_index(
        'get_card',
        {
            parts={
                {field = 1, type = 'integer'},
                {field = 2, type = 'integer'},
                {field = 3, type = 'integer'},
                {field = 4, type = 'integer'},
                {field = 5, type = 'boolean'}
            },
            func = 'get_card_func',
            if_not_exists = true,
            unique = false
        }
    )

    -----------------------------  card  ---------------------------------------
    --[[ local card = box.schema.space.create(
        'card',
        {
            format = {
                {'card_uuid', 'uuid'},
                {'user_uuid', 'uuid'}, -- sharding key
                {'bucket_id', 'unsigned'},
                {'level', 'unsigned'},
                {'suit', 'unsigned'},
            },
            if_not_exists = true
        }
    )
    card:create_index(
        'primary',
        {
            parts = {'card_uuid'},
            unique = true,
            if_not_exists = true
        }
    )
    card:create_index(
        'bucket_id',
        {
            parts = {'bucket_id'},
            unique = false,
            if_not_exists = true
        }
    )
    card:create_index(
        'user_uuid',
        {
            parts = {'user_uuid'},
            unique = false,
            if_not_exists = true
        }
    )
    card:create_index(
        'level_suit',
        {
            parts = {'level', 'suit'},
            unique = false,
            if_not_exists = true
        }
    ) ]]

    -----------------------------  collection  ---------------------------------------
    --[[ local col_card = box.schema.space.create(
        'col_card',
        {
            format = {
                {'col_card_uuid', 'uuid'},
                {'user_uuid', 'uuid'},     -- sharding key
                {'bucket_id', 'unsigned'},
                {'level', 'unsigned'},
                {'suit', 'unsigned'},
            },
            if_not_exists = true
        }
    )
    col_card:create_index(
        'primary',
        {
            parts = {'col_card_uuid'},
            unique = true,
            if_not_exists = true
        }
    )
    col_card:create_index(
        'bucket_id',
        {
            parts = {'bucket_id'},
            unique = false,
            if_not_exists = true
        }
    )
    col_card:create_index(
        'user_uuid',
        {
            parts = {'user_uuid'},
            unique = false,
            if_not_exists = true
        }
    )
    col_card:create_index(
        'level_suit',
        {
            parts = {'level', 'suit'},
            unique = false,
            if_not_exists = true
        }
    ) ]]
    
    -----------------------------  offer ---------------------------------------
    --[[ local offer = box.schema.space.create(
        'offer',
        {
            format = {
                {'offer_uuid', 'uuid'}, 
                {'user_uuid', 'uuid'},      -- sharding key
                {'bucket_id', 'unsigned'},
                {'set', 'array'},           -- array of record {level, suit}
                {'flip_set', 'array'},      -- array of record {level, suit}
            },
            if_not_exists = true
        }
    )
    offer:create_index(
        'primary',
        {
            parts = {'offer_uuid'},
            unique = true,
            if_not_exists = true
        }
    )
    offer:create_index(
        'bucket_id',
        {
            parts = {'bucket_id'},
            unique = false,
            if_not_exists = true
        }
    )        
    offer:create_index(
        'user', 
        {
            parts = { 'user_uuid'},
            unique = false,
            if_not_exists = true
        }
    )  ]]
    
end 

local function truncate()
    box.space.usergame:truncate()
    box.space.suit:truncate()
    --box.space.col_card:truncate()
    --box.space.offer:truncate()
end

return {
    create = create,
    truncate = truncate
}