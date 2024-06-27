local FireflyBossNeutral = class()

function FireflyBossNeutral:start(ctx)
	stonehearth.player:set_neutral_to_everyone(ctx.npc_player_id, true)
	self._delay_for_nina = radiant.on_game_loop_once('delayed for nina ai', function()
		local nina = ctx["firefly_human_encounter"].boss
		radiant.entities.add_buff(nina, "swamp_goblins:buffs:heal_aura")
		self._delay_for_nina = nil
	end)
end

return FireflyBossNeutral