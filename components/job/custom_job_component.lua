local JobComponent = require 'stonehearth.components.job.job_component'

local SwampGoblinsJobComponent = class()

SwampGoblinsJobComponent._goblin_promote_to = JobComponent.promote_to
function SwampGoblinsJobComponent:promote_to(job_uri, options)
	local player_id = radiant.entities.get_player_id(self._entity)
	local kingdom = stonehearth.player:get_kingdom(player_id)
	if kingdom == "swamp_goblins:kingdoms:firefly_clan" then
		if job_uri == "stonehearth:jobs:worker" then
			job_uri = "swamp_goblins:jobs:worker"
		end
	else
		if job_uri == "swamp_goblins:jobs:worker" then
			job_uri = "stonehearth:jobs:worker"
		end
	end
	self:_goblin_promote_to(job_uri, options)
end

return SwampGoblinsJobComponent