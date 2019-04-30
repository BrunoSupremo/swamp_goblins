local FireflyBossDeathScript = class()

function FireflyBossDeathScript:start(ctx)
	stonehearth.player:set_neutral_to_everyone(ctx.npc_player_id, true)
end

return FireflyBossDeathScript