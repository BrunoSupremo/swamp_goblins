local RageOverTimeBuffScript = class()

function RageOverTimeBuffScript:on_buff_added(entity, buff)
	self._buff = buff

	self._entity = entity
	self._combat_battery_listener = radiant.events.listen(self._entity, 'stonehearth:combat:in_combat_changed', self, self._in_combat_changed)
end

function RageOverTimeBuffScript:_in_combat_changed(context)
	if context.in_combat then
		self._pulse_listener = stonehearth.calendar:set_interval("RageOverTime pulse", "6m", 
			function()
				radiant.entities.add_buff(self._entity, "swamp_goblins:buffs:rage_over_time:add")
				end)
	else
		if self._pulse_listener then
			self._pulse_listener:destroy()
			self._pulse_listener = nil
		end
		radiant.entities.remove_buff(self._entity, "swamp_goblins:buffs:rage_over_time:add", true)
	end
end

function RageOverTimeBuffScript:on_buff_removed(entity, buff)
	radiant.entities.remove_buff(self._entity, "swamp_goblins:buffs:rage_over_time:add", true)
	if self._combat_battery_listener then
		self._combat_battery_listener:destroy()
		self._combat_battery_listener = nil
	end
	if self._pulse_listener then
		self._pulse_listener:destroy()
		self._pulse_listener = nil
	end
end

return RageOverTimeBuffScript