local WarriorClass = class()
local CombatJob = require 'stonehearth.jobs.combat_job'
radiant.mixin(WarriorClass, CombatJob)

function WarriorClass:_create_listeners()
	CombatJob._create_listeners(self)

	local player_id = radiant.entities.get_player_id(self._sv._entity)
	local job = stonehearth.job:get_job_info(player_id, "swamp_goblins:jobs:spirit_walker")
	if job:get_highest_level() >=5 then
		self:spirit_walker_buffing()
	else
		self.spirit_listener = radiant.events.listen_once(stonehearth.job, 'swamp_goblins:spirit_walker_buffing', self, self.spirit_walker_buffing)
	end
end

function WarriorClass:spirit_walker_buffing()
	local equipment_component = self._sv._entity:get_component("stonehearth:equipment")
	if not equipment_component:has_item_type("swamp_goblins:armor:goblin_aura") then
		local equipment = radiant.entities.create_entity("swamp_goblins:armor:goblin_aura")
		radiant.entities.equip_item(self._sv._entity, equipment)
	end
	self:_remove_spirit_listener()
end

function WarriorClass:_remove_spirit_listener()
	if self.spirit_listener then
		self.spirit_listener:destroy()
		self.spirit_listener = nil
	end
end

function WarriorClass:_remove_listeners()
	CombatJob._remove_listeners(self)
	self:_remove_spirit_listener()
end

return WarriorClass