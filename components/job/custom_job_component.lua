local JobComponent = require 'stonehearth.components.job.job_component'
local ACEJobComponent = require 'stonehearth_ace.monkey_patches.ace_job_component'

local SwampGoblinsJobComponent = class()

SwampGoblinsJobComponent._goblin_promote_to = JobComponent.promote_to
if ACEJobComponent then
	SwampGoblinsJobComponent._goblin_ace_promote_to = ACEJobComponent.promote_to
end
function SwampGoblinsJobComponent:promote_to(job_uri, options)
	local is_npc = stonehearth.player:is_npc(self._entity)
	if not is_npc then
		for _, sub_string in ipairs(radiant.util.split_string(job_uri, ":")) do
			if sub_string == "npc" then
				is_npc=true
			end
		end
	end
	local render_info = self._entity:add_component('render_info')
	local model = render_info:get_model_variant()
	if not self:get_allowed_jobs() and not is_npc then
		local player_id = radiant.entities.get_player_id(self._entity)
		local job_index = stonehearth.player:get_jobs(player_id)
		local firefly_job_list = {}
		local hearthling_job_list = {}
		for alias,data in pairs(job_index) do
			if not data.firefly_job then
				hearthling_job_list[alias] = true
			else
				if data.firefly_job == "exclusive" then
					firefly_job_list[alias] = true
				else
					firefly_job_list[alias] = true
					hearthling_job_list[alias] = true
				end
			end
		end
		if model == "firefly_goblin" then
			self:set_allowed_jobs(firefly_job_list)
		else
			self:set_allowed_jobs(hearthling_job_list)
		end
	end
	if ACEJobComponent then
		self:_goblin_ace_promote_to(job_uri, options)
	else
		self:_goblin_promote_to(job_uri, options)
	end

	if model == "firefly_goblin" then
		if self:get_job_uri() == "stonehearth:jobs:worker" then
			local equipment_component = self._entity:get_component("stonehearth:equipment")
			if not equipment_component:has_item_type("swamp_goblins:worker:abilities:goblin") then
				local equipment = radiant.entities.create_entity("swamp_goblins:worker:abilities:goblin")
				radiant.entities.equip_item(self._entity, equipment)
			end
		end
	end
end

return SwampGoblinsJobComponent