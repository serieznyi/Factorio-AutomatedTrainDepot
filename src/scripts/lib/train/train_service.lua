local flib_train = require("__flib__.train")

local util_table = require("scripts.util.table")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local logger = require("scripts.lib.logger")
local Train = require("scripts.lib.domain.entity.Train")
local persistence_storage = require("scripts.persistence.persistence_storage")

local TrainService = {}

function TrainService.init()
    TrainService.register_trains()
    TrainService._register_event_handlers()
end

function TrainService.load()
    TrainService._register_event_handlers()
end

---@param deleted_entity LuaEntity
function TrainService.try_delete_train(deleted_entity)
    local left_carriages = util_table.filter(deleted_entity.train.carriages, function(carrier)
        return carrier.unit_number ~= deleted_entity.unit_number
    end, true)

    if #left_carriages > 0 then
        return
    end

    local train = persistence_storage.find_train(deleted_entity.train.id)

    if train == nil then
        return
    end

    train:delete()

    persistence_storage.add_train(train)

    logger.debug("Train {1} mark as deleted", {deleted_entity.train.id}, "TrainService.try_delete_train")
end

function TrainService.register_trains()
    logger.info("Try register all exists trains", {}, "TrainService.register_trains")

    ---@param train LuaTrain
    for _, train in ipairs(TrainService._get_trains()) do
        TrainService._register_train(train)
    end
end

---@param lua_train LuaTrain
---@param old_train_id_1 uint
---@param old_train_id_2 uint
function TrainService._register_train(lua_train, old_train_id_1, old_train_id_2)
    local train_has_locomotive = flib_train.get_main_locomotive(lua_train) ~= nil
    local create_new_locomotive = old_train_id_1 == nil and old_train_id_2 == nil and train_has_locomotive
    local change_exists_train = old_train_id_1 ~= nil and old_train_id_2 == nil
    local merge_exists_train = old_train_id_1 ~= nil and old_train_id_2 ~= nil

    if not train_has_locomotive then
        logger.debug("Ignore train without locomotive: Train id {1}", {lua_train.id}, "TrainService._register_train")
        return
    end

    if create_new_locomotive then
        ---@type scripts.lib.domain.entity.Train
        local train = Train.from_lua_train(lua_train)

        logger.debug("Try register new train {1}", {train.id}, "TrainService._register_train")

        return persistence_storage.add_train(train)
    elseif change_exists_train then
        -- todo mark as unregistered ?
        -- todo use train_structure_hash ?
        local old_train = persistence_storage.find_train(old_train_id_1)

        local new_train = old_train:copy(lua_train)

        old_train:delete()
        persistence_storage.add_train(old_train)
        logger.debug("Train {1} mark as deleted", {old_train_id_1}, "TrainService._register_train")

        logger.debug(
                "Try register new train {1} extended from {2}",
                { new_train.id, old_train_id_1},
                "TrainService._register_train"
        )

        return persistence_storage.add_train(new_train)
    elseif merge_exists_train then
        -- todo mark as unregistered ?
        -- todo use train_structure_hash ?
        local newest_train_id = math.max(old_train_id_1, old_train_id_2);
        local newest_train = persistence_storage.find_train(newest_train_id);

        if newest_train ~= nil then
            newest_train:delete()
            persistence_storage.add_train(newest_train)
            logger.debug("Train {1} mark as deleted", {newest_train_id}, "TrainService._register_train")
        end

        local oldest_train_id = math.min(old_train_id_1, old_train_id_2);
        local oldest_train = persistence_storage.find_train(oldest_train_id);

        local new_train_entity

        if oldest_train ~= nil then
            new_train_entity = oldest_train:copy(lua_train)

            oldest_train:delete()
            persistence_storage.add_train(oldest_train)
            logger.debug("Train {1} mark as deleted", {oldest_train_id}, "TrainService._register_train")
        else
            new_train_entity = Train.from_lua_train(lua_train)
        end

        logger.debug(
                "Try register new train {1} as merge trains {2} and {3}",
                {new_train_entity.id, old_train_id_1, old_train_id_2},
                "TrainService._register_train"
        )

        return persistence_storage.add_train(new_train_entity)
    end
end

function TrainService._get_trains()
    local trains = {}
    ---@param force LuaForce
    for _, force in pairs(game.forces) do
        ---@param lua_train LuaTrain
        for _, lua_train in pairs(force.get_trains()) do
            table.insert(trains, lua_train)
        end
    end

    return trains
end

---@param event scripts.lib.event.Event
function TrainService._handle_register_train(event)
    local lua_event = event.original_event

    TrainService._register_train(lua_event.train, lua_event.old_train_id_1, lua_event.old_train_id_2)
end

function TrainService._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(defines.events.on_train_created),
            handler = TrainService._handle_register_train,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "train_service")
    end
end

return TrainService