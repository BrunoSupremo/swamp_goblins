local FireflyGoblin = class()

local VERSIONS = {
	ZERO = 0
}

function FireflyGoblin:get_version()
	return VERSIONS.ZERO
end

function FireflyGoblin:fixup_post_load(old_save_data)
	if old_save_data.version < VERSIONS.ZERO then

	end
end

function FireflyGoblin:initialize()
end

function FireflyGoblin:post_activate()
	self:update_job_list()
end

function FireflyGoblin:update_job_list()
	local player_id = radiant.entities.get_player_id(self._entity)
	local job_index = stonehearth.player:get_jobs(player_id)
	local firefly_job_list = {}
	for alias,data in pairs(job_index) do
		if data.firefly_job then
			firefly_job_list[alias] = true
		end
	end
	self._entity:get_component("stonehearth:job"):set_allowed_jobs(firefly_job_list)
end

return FireflyGoblin