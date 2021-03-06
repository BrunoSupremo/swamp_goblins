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

function FireflyCallHandler:add_goblin_citizen_command(session, response)
	local player_id = session.player_id
	local pop = stonehearth.population:get_population(player_id)
	local goblin = radiant.entities.create_entity("swamp_goblins:goblins:goblin", {owner = player_id})
	pop:create_new_goblin_citizen_from_role_data(goblin)
	local job_component = goblin:add_component('stonehearth:job')
	job_component:promote_to("stonehearth:jobs:worker", { skip_visual_effects = true })

	local explored_region = stonehearth.terrain:get_visible_region(player_id):get()
	local centroid = explored_region:get_centroid():to_closest_int()
	local town_center = radiant.terrain.get_point_on_terrain(Point3(centroid.x, 0, centroid.y))

	local spawn_point = radiant.terrain.find_placement_point(town_center, 20, 30)
	radiant.terrain.place_entity(goblin, spawn_point)

	return true
end

function FireflyCallHandler:everyone_max_level_command(session, response)
	local player_id = session.player_id
	local population = stonehearth.population:get_population(player_id)
	for _, citizen in population:get_citizens():each() do
		local job_component = citizen:get_component('stonehearth:job')
		for i=2,6 do
			if not job_component:is_max_level() then
				job_component:level_up(true)
			end
		end
	end

	return true
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

return FireflyCallHandler