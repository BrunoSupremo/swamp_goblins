local FireflyBossNeutral = class()

function FireflyBossNeutral:start(ctx)
	stonehearth.player:set_neutral_to_everyone(ctx.npc_player_id, true)
	self._delay_for_nina = radiant.on_game_loop_once('delayed for nina ai', function()
		local nina = ctx["firefly_human_encounter"].boss
		local equips = nina:add_component('stonehearth:equipment')
		equips:equip_item("/stonehearth/jobs/cleric/cleric_abilities/cleric_abilities.json")
		self._delay_for_nina = nil
	end)
end

return FireflyBossNeutral