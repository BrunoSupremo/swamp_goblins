local FireflyBossLocationScript = class()

function FireflyBossLocationScript:start(ctx)
	ctx["firefly_human_encounter"].boss_location = radiant.entities.get_world_grid_location(ctx["firefly_human_encounter"].boss)

end

return FireflyBossLocationScript