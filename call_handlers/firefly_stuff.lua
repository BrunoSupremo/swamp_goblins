local validator = radiant.validator

local FireflyCallHandler = class()

function FireflyCallHandler:enable_egg_spot(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:lay_egg_spot"):now_waiting()
end

function FireflyCallHandler:travel(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

   local game_master = stonehearth.game_master:get_game_master(radiant.entities.get_player_id(entity))
   radiant.events.trigger(game_master, 'swamp_goblins:travel')
end

return FireflyCallHandler