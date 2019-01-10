local validator = radiant.validator

local WeatherCallHandler = class()

function WeatherCallHandler:change_weather(session, response, weather_stone)
	validator.expect_argument_types({'Entity'}, weather_stone)
	validator.expect.matching_player_id(session.player_id, weather_stone)
	local weather_state = stonehearth.weather._sv.current_weather_state  
	if weather_state and weather_state._sv.uri == 'stonehearth:weather:titanstorm' then
		return
	end
	weather_stone:get_component("stonehearth:commands"):disable_commands()

--move shaman to here, run effect

	local current_season = stonehearth.seasons:get_current_season()
	local chosen_weather = stonehearth.weather:_get_weather_for_season(current_season)
	stonehearth.weather:_switch_to(chosen_weather, session.player_id)

	-- weather_stone:get_components("stonehearth:commands"):enable_commands()
end

return WeatherCallHandler