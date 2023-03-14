local SummonComponent = class()

function SummonComponent:post_activate()
	radiant.entities.add_buff(self._entity, "swamp_goblins:buffs:despawn:in_2h")

	self._combat_battery_listener = radiant.events.listen(self._entity, 'stonehearth:combat:in_combat_changed', self, self._in_combat_changed)
end

function SummonComponent:_in_combat_changed(context)
	--when out of combat, they should talk with random citizens
	--but when they spawn or while switching targets, they are idle (a 1 frame of no combat)
	--so the timer is just a buffer to skip those frames and avoid trying to talk on those
	if context.in_combat then
		if self._conversation_timer then
			self._conversation_timer:destroy()
			self._conversation_timer = nil
		end
		self._entity:get_component('stonehearth:expendable_resources'):
		set_value('social_satisfaction', 99)
	else
		local delayed_function = function ()
			self._entity:get_component('stonehearth:expendable_resources'):
			set_value('social_satisfaction', 0)
		end
		self._conversation_timer = stonehearth.calendar:set_timer("SummonComponent delay adding conversation_component", "1m+4m", delayed_function)
	end
end

function SummonComponent:destroy()
	if self._combat_battery_listener then
		self._combat_battery_listener:destroy()
		self._combat_battery_listener = nil
	end
	if self._conversation_timer then
		self._conversation_timer:destroy()
		self._conversation_timer = nil
	end
end

return SummonComponent