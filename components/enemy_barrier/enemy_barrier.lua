local EnemyBarrierComponent = class()

local DOOR_FILTERS = {}

local ALWAYS_FALSE_FRC = nil

local get_always_false_filter = function()
	if not ALWAYS_FALSE_FRC then
		local filter_fn = function(entity)
			return false
		end

		ALWAYS_FALSE_FRC = stonehearth.ai:create_filter_result_cache(filter_fn, ' always false door movement_guard_shape frc')
	end
	return ALWAYS_FALSE_FRC
end

local get_door_filter = function(door_entity)
	local player_id = radiant.entities.get_player_id(door_entity)
	local filter = DOOR_FILTERS[player_id]
	if not filter then
		local filter_fn = function(entity)
			local entity_player_id = radiant.entities.get_player_id(entity)
			local is_not_hostile = stonehearth.player:are_player_ids_not_hostile(player_id, entity_player_id)
			return is_not_hostile
		end

		local frc = stonehearth.ai:create_filter_result_cache(filter_fn, player_id .. ' door movement_guard_shape frc')
		local amenity_changed_listener = radiant.events.listen(radiant, 'stonehearth:amenity:sync_changed', function(e)
			local faction_a = e.faction_a
			local faction_b = e.faction_b
			if player_id == faction_a or player_id == faction_b then
				if frc and frc.cache then
					frc.cache:clear()
				end
			end
		end)
		filter = {
			frc = frc,
			listener = amenity_changed_listener
		}
		DOOR_FILTERS[player_id] = filter
	end
	return filter
end

function EnemyBarrierComponent:initialize()
	local json = radiant.entities.get_json(self)
	self._tracked_entities = {}
end

function EnemyBarrierComponent:activate(entity, json)
	self:_add_collision_shape()
	self._player_id_trace = self._entity:trace_player_id('door component')
	:on_changed(function(player_id)
		self:_update_filter_cache()
	end)
	:push_object_state()
end

function EnemyBarrierComponent:destroy()
	if self._player_id_trace then
		self._player_id_trace:destroy()
		self._player_id_trace = nil
	end
end

-- On load, the doors have a player id of "", so recalculate when
-- it can get the correct player id
function EnemyBarrierComponent:_update_filter_cache()
	local mgs = self._entity:get_component('movement_guard_shape')
	local cache = self:_get_filter_cache()
	if cache then
		mgs:set_filter_result_cache(cache)
	end
end

function EnemyBarrierComponent:_get_filter_cache()
	return get_door_filter(self._entity).frc.cache
end

function EnemyBarrierComponent:_add_collision_shape()
	local mgs = self._entity:add_component('movement_guard_shape')

	local region3 = mgs:get_region()
	if not region3 then
		region3 = radiant.alloc_region3()
		mgs:set_region(region3)
	end
end

return EnemyBarrierComponent