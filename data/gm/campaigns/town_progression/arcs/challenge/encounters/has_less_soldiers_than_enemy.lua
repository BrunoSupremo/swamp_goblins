local FireflyCombatAmount = class()

function FireflyCombatAmount:start(ctx)
	ctx._has_run = (ctx._has_run or 0) +1
	if ctx._has_run>6 then
		--spawn anyway, no more delays
		return false
	end
	local population = stonehearth.population:get_population(ctx.player_id)
	local firefly_counter = 0
	for _, citizen in population:get_citizens():each() do
		local jc = citizen:get_component('stonehearth:job')
		if jc and jc:has_role('combat') then
			firefly_counter = firefly_counter +1
		end
	end

	return firefly_counter < ctx._has_run
end

return FireflyCombatAmount