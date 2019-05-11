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

	local delayed_function = function ()
		self:goblin_worker_abilities()

		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("FireflyGoblin delay", 0, delayed_function)
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

function FireflyGoblin:goblin_worker_abilities()
	local job_component = self._entity:get_component("stonehearth:job")
	if job_component and job_component:get_job_uri() == "stonehearth:jobs:worker" then
		local equipment_component = self._entity:get_component("stonehearth:equipment")
		if not equipment_component:has_item_type("swamp_goblins:worker:abilities:goblin") then
			local equipment = radiant.entities.create_entity("swamp_goblins:worker:abilities:goblin")
			radiant.entities.equip_item(self._entity, equipment)
		end
	end
end

return FireflyGoblin