local FireflyHumanHearthUpdateScript = class()

function FireflyHumanHearthUpdateScript:start(ctx)
	local hearth = radiant.entities.create_entity("swamp_goblins:humans:hearth", { owner = "firefly_human_encounter"})
	local location = ctx["firefly_human_encounter"].boss_location
	local campfire = ctx["firefly_human_encounter"].entities.campfire and ctx["firefly_human_encounter"].entities.campfire.campfire
	if campfire then
		location = radiant.entities.get_world_grid_location(campfire)
		radiant.entities.destroy_entity(campfire)
	end
	radiant.terrain.place_entity_at_exact_location(hearth, location, {force_iconic = false} )
	ctx["firefly_human_encounter"].entities.campfire = hearth
end

return FireflyHumanHearthUpdateScript