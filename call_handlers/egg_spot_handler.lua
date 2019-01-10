local validator = radiant.validator

local EggSpotCallHandler = class()

function EggSpotCallHandler:enable_egg_spot(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:lay_egg_spot"):now_waiting()
end

return EggSpotCallHandler