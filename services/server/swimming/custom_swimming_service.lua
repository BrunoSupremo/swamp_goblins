local Cube3 = _radiant.csg.Cube3

CustomSwimmingService = class()

function CustomSwimmingService:_update(entity, location)
	local swimming
	if entity and entity:get_component("stonehearth:thoughts") then
		swimming = self:_swamp_goblins_is_swimming(entity, location)
	else
		swimming = self:_is_swimming(entity, location)
	end
	self:_set_swimming(entity, swimming)
end

function CustomSwimmingService:_swamp_goblins_is_swimming(entity, location)
	if not entity or not entity:is_valid() then
		return false
	end

	if not location then
		location = radiant.entities.get_world_grid_location(entity)
		if not location then
			--probably out of town?
			return false
		end
	end

	local id = entity:get_id()
	local mob_shape = self._cached_mob_shapes[id]
	local cube = mob_shape:translated(location)

	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local swimming = false

	local hearthling = entity
	radiant.entities.remove_buff(hearthling, 'swamp_goblins:buffs:sticky_water')
	for id, entity in pairs(intersected_entities) do
		local water_component = entity:get_component('stonehearth:water')
		if water_component then
			radiant.entities.add_thought(hearthling, 'stonehearth:thoughts:water:sticky_water')
			radiant.entities.add_buff(hearthling, 'swamp_goblins:buffs:sticky_water')
			local entity_height = mob_shape.max.y
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