local MemoryTown = class()

function MemoryTown.use(consumable, consumable_data, player_id, target_entity)
	local population = stonehearth.population:get_population(player_id)
	for _, entity in population:get_citizens():each() do
		local ic = entity:get_component('stonehearth:incapacitation')
		if entity and entity:is_valid() and not ic:is_incapacitated() then
			radiant.effects.run_effect(entity, 'stonehearth:effects:poof_effect:grey')
			radiant.effects.run_effect(entity, 'stonehearth:effects:thoughts:alert')
			local happiness = entity:get_component('stonehearth:happiness')
			happiness:debug_remove_all_thoughts()
			happiness:create()
		end
	end
	return true
end

return MemoryTown