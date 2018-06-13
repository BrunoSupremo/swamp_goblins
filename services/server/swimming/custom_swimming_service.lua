local Cube3 = _radiant.csg.Cube3

CustomSwimmingService = class()

function CustomSwimmingService:_is_swimming(entity)
	if not entity or not entity:is_valid() then
		return false
	end

	local location = radiant.entities.get_world_grid_location(entity)
	if not location then
		return false
	end
	local mob_collision_type = entity:add_component('mob'):get_mob_collision_type()
	local entity_height = self._mob_heights[mob_collision_type]
	if not entity_height then
		log:warning('unsupported mob_collision_type for swimming')
		return false
	end

	local cube = Cube3(location)
	cube.max.y = cube.min.y + entity_height
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local swimming = false

	local hearthling = entity
	radiant.entities.remove_buff(hearthling, 'swamp_goblins:buffs:sticky_water')
	for id, entity in pairs(intersected_entities) do
		local water_component = entity:get_component('stonehearth:water')
		if water_component then
			radiant.entities.add_thought(hearthling, 'swamp_goblins:thoughts:water:sticky_water')
			radiant.entities.add_buff(hearthling, 'swamp_goblins:buffs:sticky_water')
			local water_level = water_component:get_water_level()
			local swim_level = location.y + entity_height * 0.5
			if water_level > swim_level then
				swimming = true
				break
			end
		end
	end

	return swimming
end

return CustomSwimmingService