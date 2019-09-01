local FireflyCombatAmount = class()

function FireflyCombatAmount:start(ctx)
	local population = stonehearth.population:get_population(ctx.player_id)
	local firefly_counter = 0
	for _, citizen in population:get_citizens():each() do
		local jc = citizen:get_component('stonehearth:job')
		if jc and jc:has_role('combat') then
			firefly_counter = firefly_counter +1
		end
	end
	population = stonehearth.population:get_population("firefly_human_encounter")
	local enemy_counter = 0
	for _, citizen in population:get_citizens():each() do
		local jc = citizen:get_component('stonehearth:job')
		if jc and jc:has_role('combat') then
			enemy_counter = enemy_counter +1
		end
	end

	return firefly_counter < enemy_counter
end

return FireflyCombatAmount