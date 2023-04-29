local validator = radiant.validator
local Point3 = _radiant.csg.Point3

local FireflyCallHandler = class()

function FireflyCallHandler:enable_egg_spot(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:lay_egg_spot"):now_waiting()
end

function FireflyCallHandler:cancel_egg_spot(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:lay_egg_spot"):cancel_egg()
end

function FireflyCallHandler:travel(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	local game_master = stonehearth.game_master:get_game_master(radiant.entities.get_player_id(entity))
	radiant.events.trigger(game_master, 'swamp_goblins:travel')
end

function FireflyCallHandler:spawn_glory_wave(session, response, source_entity)
	validator.expect_argument_types({'Entity'}, source_entity)
	validator.expect.matching_player_id(session.player_id, source_entity)

	local warrior_hearth_component = source_entity:get_component("swamp_goblins:warrior_hearth")
	if warrior_hearth_component then
		return warrior_hearth_component:spawn_next_wave()
	end
	return false
end

function FireflyCallHandler:abandon_glory_wave(session, response, source_entity)
	validator.expect_argument_types({'Entity'}, source_entity)
	validator.expect.matching_player_id(session.player_id, source_entity)

	local warrior_hearth_component = source_entity:get_component("swamp_goblins:warrior_hearth")
	if warrior_hearth_component then
		return warrior_hearth_component:abandon_current_wave()
	end
	return false
end

function FireflyCallHandler:market(session, response, source_entity)
	validator.expect_argument_types({'Entity'}, source_entity)
	validator.expect.matching_player_id(session.player_id, source_entity)

	local market_component = source_entity:get_component("swamp_goblins:market")
	if market_component then
		return market_component:create_shop()
	end
	return false
end

function FireflyCallHandler:swap_entity(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:swap_entity"):swap()
end

function FireflyCallHandler:summon_allied_fighters(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:shrine:tall"):summon_allied_fighters()
end

function FireflyCallHandler:summon_allied_workers(session, response, entity)
	validator.expect_argument_types({'Entity'}, entity)
	validator.expect.matching_player_id(session.player_id, entity)

	entity:get_component("swamp_goblins:shrine:tall"):summon_allied_workers()
end

return FireflyCallHandler