---@diagnostic disable: need-check-nil
local fiber = require('fiber')
local log = require("log")
local json = require('json')
local utils = require('app.tools.utils')
local uuid = require('uuid')
local t2s = require('app.tools.t2s')
local level = require('app.game.level')
local base = require('app.game.base')

local function add_suit(suit, rarity_type, flow_type)
    box.begin()
    local suit_tuple = box.space.suit:insert({
        suit,
        rarity_type,
        flow_type,
        base.STATUS_PREPARED, -- prepared
        0, -- total_count
        0, -- rest_count
    })
    box.commit()
    return suit_tuple
end

local function activate_suit(suit, total_count)
    local suit_tuple = box.space.suit:get(suit)
    if suit_tuple ~= nil and suit_tuple.status == 0 then
        box.begin()
        suit_tuple = box.space.suit:update(
            suit, {
                {'=', 'status', base.STATUS_ACTIVE},
                {'=', 'total_count', total_count},
                {'=', 'rest_count', total_count}
            }
        )
        box.commit()
        return suit_tuple
    else
        return nil, base.GameError:new('ACTIVATION_IMPOSSIBLE')
    end
end

local function add_initial_suits()
    local suit
    for i = 101,110 do
        suit = i*100 + 11
        add_suit(suit, base.RARITY_SIMPLE, base.FLOW_MEDIUM)
        activate_suit(suit, 1000)
        suit = i*100 + 12
        add_suit(suit, base.RARITY_SIMPLE, base.FLOW_MEDIUM)
        activate_suit(suit, 100)
    end

    return true
end

local function create_level(user_uuid, lvl, balance, own_set)
    local col_set = {}
    local offer_set = {}
    local moves
    local card1, card2, card3, card4
    if level == 1 then
        -- Lesson 1: simplest party with one exchange
        card1 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE)
        card2 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1})

        if card1 == nil or card2 == nil then
            return nil, base.GameError:new('NOT_ENOUGH_CARDS_FOR_FIRST_LEVEL')
        end

        col_set = {card1}
        own_set = {card2}
        offer_set = {
            {orig_set = {card2}, flip_set = {card1}}
        }
        moves = 1
        balance = 0

    elseif level == 2 then
        -- Lesson 2: several exchanges
        card1 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE)
        card2 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1})
        card3 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1, card2})
        card4 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1, card2, card3})

        if card1 == nil or card2 == nil or card3 == nil or card4 == nil then
            return nil, base.GameError:new('NOT_ENOUGH_CARDS_FOR_STUDY_LEVEL')
        end

        col_set = {card1}
        own_set = {card2}
        offer_set = {
            {orig_set = {card2}, flip_set = {card3}},
            {orig_set = {card2}, flip_set = {card4}},
            {orig_set = {card3}, flip_set = {card1}}
        }
        moves = 2
        balance = 0

    elseif level == 3 then
        -- Lesson 3: coins!
        card1 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE)
        card2 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1})
        card3 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1, card2})
        card4 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1, card2, card3})

        if card1 == nil or card2 == nil or card3 == nil or card4 == nil then
            return nil, base.GameError:new('NOT_ENOUGH_CARDS_FOR_STUDY_LEVEL')
        end

        col_set = {card1, card4}
        own_set = {card2, card3}
        offer_set = {
            {orig_set = {card2}, flip_set = {card1, base.COIN}},
            {orig_set = {card3, base.COIN}, flip_set = {card4}}
        }
        moves = 2
        balance = 0

    elseif level == 4 then
        -- Lesson 4: persistent cards
        card1 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE)
        card2 = base.get_card_by_suit(base.get_persistent_suit(card1))
        card3 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1, card2})
        card4 = base.get_card(base.BURNED, base.ORDINARY, base.RARITY_SIMPLE, {card1, card2, card3})

        if card1 == nil or card2 == nil or card3 == nil or card4 == nil then
            return nil, base.GameError:new('NOT_ENOUGH_CARDS_FOR_STUDY_LEVEL')
        end

        col_set = {card1, card4}
        own_set = {card2, card3}
        offer_set = {
            {orig_set = {card1, card3}, flip_set = {card4}}
        }
        moves = 1
        balance = 0

    else
        return nil, base.GameError:new('INCORRECT_LEVEL')
    end

    return {
        col_set = col_set,
        own_set = own_set,
        offer_set = offer_set,
        moves = moves,
        balance = balance
    }
end

local function create_usergame(user_uuid, bucket_id)
    local level, error = create_level(
        user_uuid,
        1, -- level
        {} -- own_set
    )
    if level == nil then
        return nil, error
    end

    box.begin()
    local usergame_tuple = box.space.usergame:insert({
        user_uuid,
        bucket_id,
        0, -- balance
        level.moves,
        1,  -- level
        level.col_set,
        level.own_set,
        level.offer_set
    })
    box.commit()
    return usergame_tuple
end


local function get_usergame(user_uuid, bucket_id)
    if not uuid.is_uuid(user_uuid) then
        return nil, base.GameError:new('INVALID_UUID')
    end

    local usergame_tuple
    usergame_tuple = box.space.usergame:get(user_uuid)
    if usergame_tuple == nil then
        -- New user - add usergame and first collection, cards and offers
        usergame_tuple = create_usergame(user_uuid, bucket_id)
        if usergame_tuple == nil then
            return nil, base.GameError:new('USERGAME_CREATION_ERROR')
        end
    end

    local usergame = usergame_tuple:tomap({names_only = true})

    return {
        balance = usergame.balance,
        moves = usergame.moves,
        level = usergame.level,
        col_set = usergame.col_set,
        own_set = usergame.own_set,
        offer_set = usergame.offer_set
    }
end

local function get_next_level(user_uuid, move_set)
    if not uuid.is_uuid(user_uuid) then
        return nil, base.GameError:new('INVALID_UUID')
    end

    local usergame_tuple
    usergame_tuple = box.space.usergame:get(user_uuid)
    if usergame_tuple == nil then
        return nil, base.GameError:new('INVALID_USERGAME')
    end

    local usergame = usergame_tuple:tomap({names_only = true})

    -- check move_set and change own_set
    for _, offer in ipairs(move_set) do
        local index_to_burn_set = {}
        local index_to_mark_set = {}
        for _, offer_card in ipairs(offer.orig_set) do
            if base.is_coin(offer_card) then
                if usergame.balance > 0 then
                    usergame.balance = usergame.balance - 1
                else
                    return nil, base.GameError:new('NOT_ENOUGH_COINS')
                end
            else
                local persistent_found = false
                for persistent_index, persistent_card in ipairs(usergame.own_set) do
                    if persistent_card == base.get_persistent_suit(offer_card) then
                        local found_earlier = false
                        for _, index_to_mark in ipairs(index_to_mark_set) do
                            if index_to_mark == persistent_index then
                                found_earlier = true
                                break
                            end
                        end
                        if not found_earlier then
                            table.insert(index_to_mark_set, persistent_index)
                            persistent_found = true
                            break
                        end
                    end
                end
                if not persistent_found then
                    local burned_found = false
                    for burned_index, burned_card in ipairs(usergame.own_set) do
                        if burned_card == base.get_burned_suit(offer_card) then
                            local found_earlier = false
                            for _, index_to_burn in ipairs(index_to_burn_set) do
                                if index_to_burn == burned_index then
                                    found_earlier = true
                                    break
                                end
                            end
                            if not found_earlier then
                                table.insert(index_to_burn_set, burned_index)
                                burned_found = true
                                break
                            end
                        end
                    end
                    if not burned_found then
                        return nil, base.GameError:new('INCORRECT_OFFER_APPRUVAL')
                    end
                end
            end
        end

        for i, index in ipairs(index_to_burn_set) do
            table.remove(usergame.own_set, index - i + 1)
        end
        for _, card in ipairs(offer.flip_set) do
            if base.is_coin(card) then
                usergame.balance = usergame.balance + 1
            else
                table.insert(usergame.own_set, card)
            end
        end
    end

    -- check that collection is complete
    local set = {}
    for _, col_card in ipairs(usergame.col_set) do
        local found = false
        for index, card in ipairs(usergame.own_set) do
            if base.get_base_suit(card) == base.get_base_suit(col_card) then
                local found_earlier = false
                for _, index_to_remember in ipairs(set) do
                    if index_to_remember == index then
                        found_earlier = true
                        break
                    end
                end
                if not found_earlier then
                    table.insert(set, index)
                    found = true
                    break
                end
            end
        end
        if not found then
            -- TODO: support gold cards
            return nil, base.GameError:new('INCORRECT_MOVE_SET')
        end
    end

    -- Remove burned card from own_set
    local i = 1
    while i <= #usergame.own_set do
        if usergame.own_set[i] == base.get_burned_suit(usergame.own_set[i]) then
            table.remove(usergame.own_set, i)
        else
            i = i + 1
        end
    end

    -- Create new level
    local level, error = create_level(
        user_uuid,
        usergame.level + 1, -- level
        usergame.balance, -- balance before level start
        usergame.own_set -- own_set before level start
    )

    if level == nil then
        return nil, error
    end

    box.begin()
    usergame_tuple = box.space.usergame:update(
        user_uuid,{
            {'=', 'moves', level.moves},
            {'=', 'balance', level.balance},
            {'=', 'level', usergame.level + 1},
            {'=', 'col_set', level.col_set},
            {'=', 'own_set', level.own_set},
            {'=', 'offer_set', level.offer_set},
        }
    )
    box.commit()

    usergame = usergame_tuple:tomap({names_only = true})

    return {
        balance = usergame.balance,
        moves = usergame.moves,
        level = usergame.level,
        col_set = usergame.col_set,
        own_set = usergame.own_set,
        offer_set = usergame.offer_set
    }
end

return{
    add_suit = add_suit,
    activate_suit = activate_suit,
    add_initial_suits = add_initial_suits,
    get_usergame = get_usergame,
    get_next_level = get_next_level
}