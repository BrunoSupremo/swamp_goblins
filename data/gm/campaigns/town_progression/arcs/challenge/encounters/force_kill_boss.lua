local FireflyForceKillBossScript = class()

function FireflyForceKillBossScript:start(ctx)
	radiant.entities.kill_entity(ctx["firefly_human_encounter"].boss)
end

return FireflyForceKillBossScript