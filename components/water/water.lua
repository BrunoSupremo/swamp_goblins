local SwampWater = class()

function SwampWater:post_activate()
	self._world_generated_listener = radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', self, self._on_world_generation_complete)
end

function SwampWater:_on_world_generation_complete()
	self._mms = self._entity:add_component('movement_modifier_shape')
	self._mms:set_region(_radiant.sim.alloc_region3())
	self._mms:set_modifier(0)
	self._mms:set_nav_preference_modifier(-0.5)

	self._mms:get_region():modify(function(cursor)
		cursor:copy_region(self._entity:get('region_collision_shape'):get_region():get())
		cursor:optimize_by_defragmentation('swamp water movement modifier shape')
	end)
end

return SwampWater