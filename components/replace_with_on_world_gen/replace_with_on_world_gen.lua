local ReplaceWithOnWorldGen = class()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

function ReplaceWithOnWorldGen:post_activate()
	self._world_generated_listener = radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', self, self._on_world_generation_complete)
end

function ReplaceWithOnWorldGen:_on_world_generation_complete()
	local json = radiant.entities.get_json(self) or {}
	local weighted_set = WeightedSet(rng)
	for uri, weight in pairs(json) do
		weighted_set:add(uri, weight)
	end
	if not weighted_set:is_empty() then
		local uri = weighted_set:choose_random()
		local lily = radiant.entities.create_entity(uri)
		local location = radiant.entities.get_world_grid_location(self._entity)
		radiant.entities.turn_to(lily, rng:get_int(0,3)*90)
		radiant.terrain.place_entity_at_exact_location(lily, location)
	end

	radiant.entities.destroy_entity(self._entity)
end

return ReplaceWithOnWorldGen