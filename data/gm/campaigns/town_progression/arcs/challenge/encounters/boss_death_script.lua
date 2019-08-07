local FireflyBossDeathScript = class()
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function FireflyBossDeathScript:start(ctx)
	stonehearth.player:set_neutral_to_everyone(ctx.npc_player_id, true)
	if ctx.boss and ctx.boss:is_valid() then
		--bleh
	else
		self._delay_for_nina = radiant.on_game_loop_once('delayed for nina ai', function()
			local nina = radiant.entities.create_entity("swamp_goblins:humans:nina", {owner = ctx.npc_player_id})
			nina:get_component('stonehearth:job'):promote_to("stonehearth:jobs:footman")
			local equips = nina:add_component('stonehearth:equipment')
			equips:equip_item("stonehearth:geomancer:staff")
			equips:equip_item("/stonehearth/jobs/cleric/cleric_abilities/cleric_abilities.json")
			radiant.terrain.place_entity(nina, ctx["firefly_human_encounter"].boss_location)
			game_master_lib.register_entities(ctx, 'firefly_human_encounter', { boss = nina })
			self._delay_for_nina = nil
		end)
	end
end

return FireflyBossDeathScript