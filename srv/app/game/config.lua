---@diagnostic disable: need-check-nil
local fiber = require('fiber')
local log = require("log")
local json = require('json')
local utils = require('app.tools.utils')
local errors = require('errors')
local uuid = require('uuid')
local t2s = require('app.tools.t2s')

-- Level:                      1  2  3  4    5    6    7    8    9   10    11   12   13   14   15   16   17   18   19   20
local COL_COUNT =             {0, 0, 0, 0,   2,   3,   3,   4,   4,   4,    4,   4,   5,   5,   5,   5,   5,   5,   5,   5}
local OWN_COUNT =             {0, 0, 0, 0,   3,   4,   4,   5,   5,   5,    4,   4,   5,   5,   5,   5,   5,   5,   5,   5}
local DISTINCT_COUNT =        {0, 0, 0, 0,   2,   3,   3,   4,   4,   4,    4,   4,   4,   5,   5,   5,   5,   5,   5,   5}
local MOVE_COUNT =            {0, 0, 0, 0,   3,   3,   5,   5,   6,   6,    6,   6,   6,   6,   7,   7,   8,   8,   9,   9}
local FAKE_OFFER_COUNT =      {0, 0, 0, 0,   1,   1,   1,   2,   2,   2,    3,   3,   3,   4,   4,   4,   4,   4,   5,   5}
local FAKE_INCOMING_COUNT =   {0, 0, 0, 0,   0,   0,   1,   1,   1,   1,    2,   2,   2,   2,   3,   3,   3,   3,   4,   4}
local FAKE_CARD_PROB =        {0, 0, 0, 0,   0,   0, 0.2, 0.2, 0.2, 0.4,  0.4, 0.4, 0.6, 0.6, 0.6, 0.6, 0.8, 0.8, 0.8, 0.8}
-- TODO: add probability for gold, persistence and rarity

local LEVEL_COUNT = 20

local function set_config(
    level, 
    col_count, 
    own_count, 
    distinct_count, 
    move_count, 
    fake_offer_count, 
    fake_incoming_count, 
    fake_card_prob
)
    if level <= LEVEL_COUNT then
        COL_COUNT[level] =          col_count
        OWN_COUNT[level] =          own_count
        DISTINCT_COUNT[level] =     distinct_count
        MOVE_COUNT[level] =         move_count
        FAKE_OFFER_COUNT[level] =   fake_offer_count
        FAKE_INCOMING_COUNT[level]= fake_incoming_count
        FAKE_CARD_PROB[level] =     fake_card_prob
    end
end

local function get_col_count(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return  COL_COUNT[level]
end

local function get_own_count(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return OWN_COUNT[level]
end

local function get_distinct_count(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return DISTINCT_COUNT[level]
end

local function get_move_count(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return MOVE_COUNT[level]
end

local function get_fake_offer_count(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return FAKE_OFFER_COUNT[level]
end

local function get_fake_incoming_count(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return FAKE_INCOMING_COUNT[level]
end

local function get_fake_card_prob(level)
    if level > LEVEL_COUNT then
        level = LEVEL_COUNT
    end
    return FAKE_CARD_PROB[level]
end

return{
    set_config = set_config,
    get_col_count = get_col_count,
    get_own_count = get_own_count,
    get_distinct_count = get_distinct_count,
    get_move_count = get_move_count,
    get_fake_offer_count = get_fake_offer_count,
    get_fake_incoming_prob = get_fake_incoming_count,
    get_fake_card_prob = get_fake_card_prob
}