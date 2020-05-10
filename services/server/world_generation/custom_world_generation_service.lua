local SwampWorldGenerationService = class()
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3

function SwampWorldGenerationService:_add_water_bodies(regions)
	local biome_landscape_info = self._biome_generation_data:get_landscape_info()
	local biome_water_height_delta = biome_landscape_info and biome_landscape_info.water and biome_landscape_info.water.water_height_delta
	local water_height_delta = biome_water_height_delta or 1.5

	for _, terrain_region in pairs(regions) do
		terrain_region:force_optimize('add water bodies')

		local terrain_bounds = terrain_region:get_bounds()

		local height = terrain_bounds:get_size().y - water_height_delta

		local water_bounds = Cube3(terrain_bounds)
		water_bounds.max.y = water_bounds.max.y - math.floor(water_height_delta)

		local water_region = terrain_region:intersect_cube(water_bounds)
		stonehearth.hydrology:create_water_body_with_region(water_region, height, true)

		local water_bounds_negative = Cube3(terrain_bounds)
		water_bounds_negative.max.y = water_bounds_negative.max.y - math.floor(water_height_delta)
		if water_bounds_negative.min.y < 29 then
			water_bounds_negative.min.y = 29
		end

		local water_region_negative = terrain_region:intersect_cube(water_bounds_negative)
		for cube in water_region_negative:each_cube() do
			self:add_negative_pathfind_weight_in_water(Region3(cube))
		end
	end
end

function SwampWorldGenerationService:add_negative_pathfind_weight_in_water(region)
	assert(not region:empty())
	local boxed_region = _radiant.sim.alloc_region3()
	local location = self:select_origin_for_region(region)

	boxed_region:modify(function(cursor)
		cursor:copy_region(region)
		cursor:translate(-location)
	end)

	self:_create_water_body_internal(location, boxed_region)
end

function SwampWorldGenerationService:select_origin_for_region(region)
	if region:empty() then
		return nil
	end

	local bounds = region:get_bounds()
	local bottom_slice = Cube3(bounds)
	bottom_slice.max.y = bottom_slice.min.y + 1

	-- origin needs to be at the bottom of the region, preferably towards the center
	local footprint = region:intersect_cube(bottom_slice)
	local centroid = footprint:get_centroid():to_closest_int()
	-- concave shapes may have centroids outside the region
	-- 1x1 regions will also round the centroid outside the region
	local origin = footprint:get_closest_point(centroid)
	return origin
end

function SwampWorldGenerationService:_create_water_body_internal(location, boxed_region)
	if boxed_region == nil then
		boxed_region = _radiant.sim.alloc_region3()
	end

	local entity = radiant.entities.create_entity('swamp_goblins:terrain:water_negative_pathfind')
	
	local mms = entity:add_component('movement_modifier_shape')
	mms:set_region(boxed_region)
	mms:set_modifier(0)
	mms:set_nav_preference_modifier(-0.5)

	local delayed_function = function ()
		radiant.terrain.place_entity_at_exact_location(entity, location)
		if self.delay_to_escape_lag then
			self.delay_to_escape_lag:destroy()
			self.delay_to_escape_lag = nil
		end
	end
	self.delay_to_escape_lag = stonehearth.calendar:set_persistent_timer("water_negative_pathfind delay", "30m+30m", delayed_function)

	self.__saved_variables:mark_changed()
end

return SwampWorldGenerationService