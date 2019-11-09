local validator = radiant.validator

local WeatherCallHandler = class()

function WeatherCallHandler:weather_stone_charge(session, response, weather_stone)
	validator.expect_argument_types({'Entity'}, weather_stone)
	validator.expect.matching_player_id(session.player_id, weather_stone)

	weather_stone:get_component("swamp_goblins:weather_stone"):now_charging()
end

function WeatherCallHandler:weather_stone_use(session, response, weather_stone)
	validator.expect_argument_types({'Entity'}, weather_stone)
	validator.expect.matching_player_id(session.player_id, weather_stone)

	weather_stone:get_component("swamp_goblins:weather_stone"):now_waiting()
end

return WeatherCallHandler