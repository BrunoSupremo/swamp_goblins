local FireflyBossDeathScript = class()
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

function FireflyBossDeathScript:recreate_knight(ctx)
	local population = stonehearth.population:get_population("firefly_human_encounter")
	local knight = radiant.entities.create_entity("swamp_goblins:humans:female", {owner = "firefly_human_encounter"})
	population:set_citizen_name(knight, 'female')
	knight:add_component('stonehearth:customization'):generate_custom_appearance()
	local job_component = knight:add_component('stonehearth:job')
	job_component:promote_to("stonehearth:jobs:knight")
	job_component:_equip_equipment(job_component:get_job_data())
	radiant.terrain.place_entity(knight, ctx["firefly_human_encounter"].boss_location)
	game_master_lib.register_entities(ctx, 'firefly_human_encounter.citizens', {knight = knight})
	return knight
end

function FireflyBossDeathScript:start(ctx)
	stonehearth.player:set_neutral_to_everyone(ctx.npc_player_id, true)
	stonehearth.player:set_amenity("firefly_human_encounter", "forest", "hostile")
	stonehearth.player:set_amenity("firefly_human_encounter", "orcs", "hostile")
	stonehearth.player:set_amenity("firefly_human_encounter", "undead", "hostile")
	stonehearth.player:set_amenity("firefly_human_encounter", "goblins", "hostile")

	self._delay_for_nina = radiant.on_game_loop_once('delayed for nina ai', function()
		local nina = radiant.entities.create_entity("swamp_goblins:humans:nina", {owner = ctx.npc_player_id})
		local job_component = nina:get_component('stonehearth:job')
		job_component:promote_to("stonehearth:jobs:footman")
		for i=2,6 do
			job_component:level_up(true)
		end
		radiant.entities.set_attribute(nina, "max_health", 250)
		radiant.entities.set_attribute(nina, "spirit", 10)
		local equips = nina:add_component('stonehearth:equipment')
		equips:equip_item("stonehearth:geomancer:staff")
		radiant.entities.add_buff(nina, "swamp_goblins:buffs:heal_aura")
		radiant.terrain.place_entity(nina, ctx["firefly_human_encounter"].boss_location)
		game_master_lib.register_entities(ctx, 'firefly_human_encounter', { boss = nina })

		local knight = ctx["firefly_human_encounter"].citizens.knight
		if knight then
			local job_component = knight:get_component('stonehearth:job')
			if not job_component then
				knight = self:recreate_knight(ctx)
				job_component = knight:get_component('stonehearth:job')
			end
			for i=2,6 do
				job_component:level_up(true)
			end
			radiant.entities.set_attribute(knight, "max_health", 250)
			radiant.entities.set_attribute(knight, "body", 10)
		end

		self._delay_for_nina = nil
	end)
end

return FireflyBossDeathScript