local Point3 = _radiant.csg.Point3

local GoblinWorkerClass = class()
local CombatJob = require 'stonehearth.jobs.combat_job'
radiant.mixin(GoblinWorkerClass, CombatJob)

function GoblinWorkerClass:initialize()
	CombatJob.initialize(self)
	self._sv.no_levels = true
	self._sv.is_max_level = true
end

-- Returns all the data for all the levels
function GoblinWorkerClass:get_level_data()
	return nil
end

-- Given the ID of a perk, find out if we have the perk. 
function GoblinWorkerClass:has_perk(id)
	return false
end

function GoblinWorkerClass:is_goblin()
	local render_info = self._sv._entity:add_component('render_info')
	return render_info:get_model_variant() == "firefly_goblin"
end

function GoblinWorkerClass:post_activate()
	CombatJob.post_activate(self)
	if self:is_goblin() then
		local equipment = "swamp_goblins:worker:abilities:goblin"
		radiant.entities.equip_item(self._sv._entity, equipment)
	end
end

function GoblinWorkerClass:_create_listeners()
	CombatJob._create_listeners(self)
	if self:is_goblin() then
		self.waiting_for_combat_listener = radiant.events.listen(self._sv._entity, 'stonehearth:combat:primary_target_changed', self, self.primary_target_changed)
	end
end

function GoblinWorkerClass:primary_target_changed()
	local target = stonehearth.combat:get_primary_target(self._sv._entity)
	local equipment = "swamp_goblins:worker:abilities:hunter"
	if target and target:get_player_id() == "animals" then
		radiant.entities.equip_item(self._sv._entity, equipment)
	else
		radiant.entities.unequip_item(self._sv._entity, equipment)
	end
end

function GoblinWorkerClass:_remove_listeners()
	CombatJob._remove_listeners(self)

	if self.waiting_for_combat_listener then
		self.waiting_for_combat_listener:destroy()
		self.waiting_for_combat_listener = nil
	end
end

return GoblinWorkerClass