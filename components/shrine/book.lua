local ShrineBookComponent = class()

function ShrineBookComponent:post_activate()	
	local population = stonehearth.population:get_population(self._entity:get_player_id())
	for _, citizen in population:get_citizens():each() do
		local job_component = citizen:get_component('stonehearth:job')
		local more_levels = 3 - job_component:get_current_job_level()
		for i = 1, more_levels do
			if not job_component:is_max_level() then
				--max_level check just to skip workers
				local skip_notification = i<more_levels
				job_component:level_up(skip_notification)
			end
		end
	end
end

return ShrineBookComponent