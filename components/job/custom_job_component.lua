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
	if not is_npc then
		self:update_job_list()
	end
	
	if ACEJobComponent then
		self:_goblin_ace_promote_to(job_uri, options)
	else
		self:_goblin_promote_to(job_uri, options)
	end

	self:apply_town_bonus()
end

function SwampGoblinsJobComponent:update_job_list()
	if self:get_allowed_jobs() then
		return
	end
	local render_info = self._entity:add_component('render_info')
	local model = render_info:get_model_variant()
	local player_id = radiant.entities.get_player_id(self._entity)
	local job_index = stonehearth.player:get_jobs(player_id)
	local allowed_job_list = {}
	if model == "firefly_goblin" then
		for alias,data in pairs(job_index) do
			if data.firefly_job ~= "disabled" then
				allowed_job_list[alias] = true
			end
		end
	else
		for alias,data in pairs(job_index) do
			if data.firefly_job ~= "exclusive" then
				allowed_job_list[alias] = true
			end
		end
	end
	self:set_allowed_jobs(allowed_job_list)
end

function SwampGoblinsJobComponent:apply_town_bonus()
	local town = stonehearth.town:get_town(self._entity:get_player_id())
	if town and town:get_town_bonus('swamp_goblins:town_bonus:book') then
		local more_levels = 3 - self:get_current_job_level()
		for i = 1, more_levels do
			if not self:is_max_level() then
				--max_level check just to skip workers
				local skip_notification = i<more_levels
				self:level_up(skip_notification)
			end
		end
	end
end

return SwampGoblinsJobComponent