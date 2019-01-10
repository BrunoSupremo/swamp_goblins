local ChargeWeatherStone = class()

ChargeWeatherStone.name = 'charge weather stone'
ChargeWeatherStone.does = 'swamp_goblins:charge_weather_stone'
ChargeWeatherStone.status_text_key = 'swamp_goblins:ai.actions.status_text.charging_weather_stone'
ChargeWeatherStone.args = { }
ChargeWeatherStone.version = 2
ChargeWeatherStone.priority = 1

function find_an_essense_spot(ai_entity)
	local player_id = ai_entity:get_player_id()
	return stonehearth.ai:filter_from_key('swamp_goblins:charge_weather_stone', player_id,
		function(target)
			if target:get_player_id() ~= player_id then
				return false
			end
			return radiant.entities.get_entity_data(target, 'swamp_goblins:essense_spot') ~= nil
		end
		)
end

local function rate_essense_spot(entity)
	local rng = _radiant.math.get_default_rng()
	return rng:get_real(0, 1)
end

function ChargeWeatherStone:start_thinking(ai, entity, args)
	ai:set_think_output({})
end

local ai = stonehearth.ai
return ai:create_compound_action(ChargeWeatherStone)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:find_best_reachable_entity_by_type', {
	filter_fn = ai.CALL(find_an_essense_spot, ai.ENTITY),
	rating_fn = rate_essense_spot,
	description = 'find a dock'
	})
:execute('stonehearth:goto_entity', {
	entity = ai.PREV.item
	})
:execute('stonehearth:reserve_entity', { entity = ai.BACK(2).item })
:execute('swamp_goblins:turn_to_face_water', {dock = ai.BACK(3).item})
:execute('swamp_goblins:fishing_animations', {effort = ai.BACK(6).effort})
:execute('swamp_goblins:pickup_fish', {
	dock = ai.BACK(5).item,
	fish_alias = ai.BACK(7).alias
	})
:execute('stonehearth:wait_for_closest_storage_space', { item = ai.PREV.fish })
:execute('stonehearth:drop_carrying_in_storage', {storage = ai.PREV.storage})