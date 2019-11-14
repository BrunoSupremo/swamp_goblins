local SwampWater = class()

function SwampWater:post_activate()
	print("function SwampWater:post_activate()")
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("delay for getting water shape", "1h+1h", radiant.bind(self, 'delayed_function'))
	-- self._world_generated_listener = radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', self, self._on_world_generation_complete)
end

function SwampWater:delayed_function()
	print("function SwampWater:delayed_function()")
	if self._entity and self._entity:is_valid() then
		local mms = self._entity:get_component('movement_modifier_shape')
		if not mms then
			print("movement_modifier_shape")
			mms = self._entity:add_component('movement_modifier_shape')
			mms:set_region(_radiant.sim.alloc_region3())
			mms:set_modifier(0)
			mms:set_nav_preference_modifier(-0.5)
			mms:get_region():modify(function(cursor)
				cursor:copy_region(self._entity:get('region_collision_shape'):get_region():get())
				cursor:optimize_by_defragmentation('swamp water movement modifier shape')
			end)
			self.stupid_delay:destroy()
			self.stupid_delay = nil
		end
	end
	print("end")
end

return SwampWater