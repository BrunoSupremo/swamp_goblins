local TeleportTown = class()

function TeleportTown.use(consumable, consumable_data, player_id, target_entity)
	local function _play_effect_at_entity_location(entity, effect)
		if entity then
			local proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'town upgrade effect anchor' })
			local location = radiant.entities.get_world_grid_location(entity)
			radiant.terrain.place_entity_at_exact_location(proxy, location)
			local effect = radiant.effects.run_effect(proxy, effect)
			effect:set_finished_cb(function()
				radiant.entities.destroy_entity(proxy)
			end)
		end
	end
	local population = stonehearth.population:get_population(player_id)
	local town_center = stonehearth.town:get_town(player_id):get_landing_location()
	local location = radiant.terrain.find_placement_point(town_center, 1, 5)
	for _, entity in population:get_citizens():each() do
		local ic = entity:get_component('stonehearth:incapacitation')
		if entity and entity:is_valid() and not ic:is_incapacitated() then
			local paused_goblin = stonehearth.ai:inject_ai(entity, { actions = { 'stonehearth:actions:be_away_from_town' } })
			local delay_start_timer = radiant.on_game_loop_once('reset ai wait', function()
				if paused_goblin then
					paused_goblin:destroy()
					paused_goblin = nil
				end
			end)
			_play_effect_at_entity_location(entity, 'stonehearth:effects:teleport_blast')
			radiant.terrain.place_entity(entity, location)
			entity:get('mob'):set_skip_interpolation(true)
			_play_effect_at_entity_location(entity, 'stonehearth:effects:teleport_blast')
			radiant.effects.run_effect(entity, 'stonehearth:effects:teleport_end')
			--22 sleepiness is when they start to look for beds
			radiant.entities.set_resource(entity, 'sleepiness', 22)
		end
	end
	return true
end

return TeleportTown