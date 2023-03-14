local CustomPromoteUnitToClassScript = class()

function CustomPromoteUnitToClassScript:start(ctx, data)
	local citizen = ctx:get(data.unit_reference)
	if citizen and data.job then
		local job_comp = citizen:get_component('stonehearth:job')
		local allowed = job_comp:get_allowed_jobs()
		if allowed then
			allowed[data.job] = true
			job_comp:set_allowed_jobs(allowed)
		end
		job_comp:promote_to(data.job)
	end
end

return CustomPromoteUnitToClassScript