local FireflyCombatAmount = class()

function FireflyCombatAmount:start(ctx)
	local population = stonehearth.population:get_population(ctx.player_id)
	local citizens = population:get_citizens()
	local firefly_soldiers_counter = 0
	for _, citizen in citizens:each() do
		local jc = citizen:get_component('stonehearth:job')
		if jc and jc:has_role('combat') and jc:get_job_uri()~="stonehearth:jobs:worker" then
			firefly_soldiers_counter = firefly_soldiers_counter +1
		end
	end
	local this_node_counter = ctx._sv.arc_encounters["footman_attacks"] or 0
	if firefly_soldiers_counter < this_node_counter then
		ctx._sv.arc_encounters["footman_attacks"] = this_node_counter -1
		ctx.__saved_variables:mark_changed()
	end
	if citizens:get_size()<6 then
		-- wait for the player to atleast figure out babies
		return false
	end
	return true
end

return FireflyCombatAmount