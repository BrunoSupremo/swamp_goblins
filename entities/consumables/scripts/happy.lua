local HappyTown = class()
local rng = _radiant.math.get_default_rng()

function HappyTown.use(consumable, consumable_data, player_id, target_entity)
	local EFFECTS = {
		'emote_dance_handsup',
		'emote_dance_shuffle',
		'emote_dance_themonkey'
	}
	local population = stonehearth.population:get_population(player_id)
	for _, entity in population:get_citizens():each() do
		if entity and entity:is_valid() then
			local paused_goblin = stonehearth.ai:inject_ai(entity, { actions = { 'stonehearth:actions:be_away_from_town' } })
			radiant.entities.add_thought(entity, 'stonehearth:thoughts:social:happy_potion')
			radiant.entities.set_resource(entity, 'calories', 50)

			radiant.effects.run_effect(entity, "stonehearth:effects:buff_tonic_energy_added")
			radiant.effects.run_effect(entity, EFFECTS[rng:get_int(1, #EFFECTS)])
			:set_finished_cb(function()
				if paused_goblin then
					paused_goblin:destroy()
					paused_goblin = nil
				end
			end)
		end
	end
	return true
end

return HappyTown