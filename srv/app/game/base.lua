---@diagnostic disable: need-check-nil
local fiber = require('fiber')
local log = require("log")
local json = require('json')
local utils = require('app.tools.utils')
local errors = require('errors')
local uuid = require('uuid')
local t2s = require('app.tools.t2s')

-- persistence
BURNED = 1
PERSISTENT = 2 -- sparks arount

-- universality
ORDINARY = 1
UNIVERSAL = 2 -- gold

-- rarity_type
RARITY_SIMPLE = 1
RARITY_MEDIUM = 2 -- flags, etc.
RARITY_EXCLUSIVE = 3 -- ???

-- flow_type
FLOW_SLOW = 1
FLOW_MEDIUM = 2
FLOW_QUICK = 3

-- status
STATUS_PREPARED = 0
STATUS_ACTIVE = 1

-- count
NOT_EMPTY = true
EMPTY = false

-- special suits
COIN = 90111
LOOTBOX = 90211

GameError = errors.new_class("GameError")

local function is_coin(suit)
    return suit == COIN
end

local function get_base_suit(suit)
    return math.floor(suit/10)*10
end

local function get_persistent_suit(suit)
    return get_base_suit(suit) + 2
end

local function get_burned_suit(suit)
    return get_base_suit(suit) + 1
end

local function get_burned_set(tbl)
    local output_tbl = {}
    for _, v in ipairs(tbl) do
        table.insert(output_tbl, get_burned_suit(v))
    end
    return output_tbl
end

local function choose_random_card_set(set, exclude_set, count)
    if count == nil then count = 1 end
    if exclude_set == nil then exclude_set = {} end

    -- Remove exclude_set's cards from set including duplicates
    local temp_set = table.deepcopy(set)
    for _,k in ipairs(exclude_set) do
        local l = 1
        while l <= #temp_set do
            if temp_set[l] == k then
                table.remove(temp_set, l)
            else
                l = l + 1
            end
        end
    end

    if #temp_set < count then
        return nil, GameError:new('NOT ENOUGH_CARDS_IN_SET')
    end

    --[[ local output_set = {}
    local index_set = {}
    local j = 1
    while j <= count do
        local index = math.random(#temp_set)
        local found = false
        for _, i in ipairs(index_set) do
            if index == i then
                found = true
                break
            end
        end
        if not found then
            table.insert(output_set, temp_set[index])
            table.insert(index_set, index)
            j = j + 1
        end
    end ]]

    local output_set = {}
    for i = 1, count do
        local index = math.random(#temp_set)
        table.insert(output_set, temp_set[index])
        table.remove(temp_set, index)
    end

    return output_set
end

local function choose_random_card(set, exclude_set)
    local s, e = choose_random_card_set(set, exclude_set, 1)
    if e then
        return nil, e
    end
    return s[1]
end

local function get_card(persistence, universality, rarity_type, exclude_set, count)
    if exclude_set == nil then exclude_set = {} end
    if count == nil then count = 1 end

    local suit = {}
    local available_suit = {}
    local total_weight = 0
    for _,s in box.space.suit.index.get_card:pairs({persistence, universality, rarity_type, STATUS_ACTIVE, NOT_EMPTY}) do
        suit = s:tomap({names_only=true})
        if suit.rest_count >= count then
            local found = false
            for _,e in ipairs(exclude_set) do
                if suit.suit == e then
                    found = true
                    break
                end
            end
            if not found then
                suit.weight = s.rest_count/s.total_count
                total_weight = total_weight + suit.weight
                table.insert(available_suit, suit)
            end
        end
    end

    if #available_suit == 0 then
        return nil, GameError:new('NOT_ENOUGH_CARDS')
    end

    local position = 0
    local suit_tuple = {}
    local r = math.random()
    for _,s in ipairs(available_suit) do
        if r < position + s.weight/total_weight then
            box.begin()
            suit_tuple = box.space.suit:update(
                s.suit, {
                    {'-', 'rest_count', count},
                }
            )
            box.commit()
            break
        else
            position = position + s.weight/total_weight
        end
    end

    return suit_tuple[1]
end

local function get_unique_card_set(persistence, universality, rarity_type, exclude_set, count)
    local output_set = {}
    local set = table.deepcopy(exclude_set)
    for j = 1, count do
        local card, e = get_card(persistence, universality, rarity_type, set, 1)
        if e then
            return nil, e
        end
        table.insert(output_set, card)
        table.insert(set, card)
    end

    return output_set
end

local function get_card_by_suit(suit, count)
    if count == nil then count = 1 end

    local tuple = box.space.suit:get(suit)
    local s = tuple:tomap({names_only=true})
    if s.rest_count >= count then
        box.begin()
        local suit_tuple = box.space.suit:update(
            s.suit, {
                {'-', 'rest_count', count},
            }
        )
        box.commit()
    end
    return s.suit
end

return{
    BURNED = BURNED,
    PERSISTENT = PERSISTENT,
    ORDINARY = ORDINARY,
    UNIVERSAL = UNIVERSAL,
    RARITY_SIMPLE = RARITY_SIMPLE,
    RARITY_MEDIUM = RARITY_MEDIUM,
    RARITY_EXCLUSIVE = RARITY_EXCLUSIVE,
    FLOW_SLOW = FLOW_SLOW,
    FLOW_MEDIUM = FLOW_MEDIUM,
    FLOW_QUICK = FLOW_QUICK,
    STATUS_PREPARED = STATUS_PREPARED,
    STATUS_ACTIVE = STATUS_ACTIVE,
    COIN = COIN,
    LOOTBOX = LOOTBOX,    
    
    GameError = GameError,

    is_coin = is_coin,
    get_base_suit = get_base_suit,
    get_persistent_suit = get_persistent_suit,
    get_burned_suit = get_burned_suit,
    get_burned_set = get_burned_set,
    choose_random_card_set = choose_random_card_set,
    choose_random_card = choose_random_card,
    get_card = get_card,
    get_unique_card_set = get_unique_card_set,
    get_card_by_suit = get_card_by_suit
}