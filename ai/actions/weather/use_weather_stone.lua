local ChargeWeatherStone = class()

ChargeWeatherStone.name = 'charge weather stone'
ChargeWeatherStone.does = 'swamp_goblins:use_weather_stone'
ChargeWeatherStone.status_text_key = 'swamp_goblins:ai.actions.status_text.using_weather_stone'
ChargeWeatherStone.args = { }
ChargeWeatherStone.version = 2
ChargeWeatherStone.priority = 1

function find_a_weather_stone(ai_entity)
	local player_id = ai_entity:get_player_id()
	return stonehearth.ai:filter_from_key('swamp_goblins:use_weather_stone', player_id,
		function(target)
			if target:get_player_id() ~= player_id then
				return false
			end
			if target:get_component("swamp_goblins:weather_stone") then
				return target:get_component("swamp_goblins:weather_stone"):current_stage() == "waiting"
			end
			return false
		end
		)
end

function change_weather(weather_stone)
	weather_stone:get_component("swamp_goblins:weather_stone"):change_weather()
end

local ai = stonehearth.ai
return ai:create_compound_action(ChargeWeatherStone)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
	filter_fn = ai.CALL(find_a_weather_stone, ai.ENTITY),
	description = 'find_a_weather_stone'
})
:execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
:execute('stonehearth:turn_to_face_entity', {
	entity = ai.BACK(2).destination_entity
})
:execute('stonehearth:run_effect', {
	effect = "cast_geomancer"
})
:execute('stonehearth:call_function', {
	fn = change_weather, args = {
		ai.BACK(4).destination_entity
	}
})