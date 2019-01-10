local PoisonOverTimeBuffScript = class()

function PoisonOverTimeBuffScript:on_buff_added(entity, buff)
	self._buff = buff
	self._entity = entity

	self._pulse_listener = stonehearth.calendar:set_interval("PoisonOverTime pulse", "5m", 
		function()
			radiant.entities.add_buff(self._entity, "swamp_goblins:buffs:poison:add")
			radiant.effects.run_effect(self._entity, "stonehearth:effects:debuff_added:undead_infection")
			local health = radiant.entities.get_health(self._entity)
			radiant.entities.modify_health(self._entity, health*-0.02)
			end)
end

function PoisonOverTimeBuffScript:on_buff_removed(entity, buff)
	radiant.entities.remove_buff(self._entity, "swamp_goblins:buffs:poison:add", true)
	if self._pulse_listener then
		self._pulse_listener:destroy()
		self._pulse_listener = nil
	end
end

return PoisonOverTimeBuffScript