local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3

local CustomHeightMapRenderer = class()

function CustomHeightMapRenderer:_add_foothills_to_region(region3, rect, height)
	local biome_name = stonehearth.world_generation:get_biome_alias()
	local colon_position = string.find (biome_name, ":", 1, true) or -1
	local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
	local fn = "_add_foothills_to_region_" .. mod_name_containing_the_biome
	if self[fn] ~= nil then
		--found a function for the biome being used, named:
		-- self:_add_foothills_to_region_<biome_name>(args,...)
		self[fn](self, region3, rect, height)
	else
		--there is no function for this specific biome, so call a copy of the original from stonehearth
		self:_add_foothills_to_region_original(region3, rect, height)
	end
end

function CustomHeightMapRenderer:_add_foothills_to_region_original(region3, rect, height)
	local terrain_info = self._biome:get_terrain_info()
	local foothills_step_size = terrain_info.foothills.step_size
	local plains_max_height = terrain_info.plains.height_max

	local has_grass = height % foothills_step_size == 0
	local soil_top = has_grass and height-1 or height

	self:_add_soil_strata_to_region(region3, Cube3(
			Point3(rect.min.x, 0,		  rect.min.y),
			Point3(rect.max.x, soil_top, rect.max.y)
		))

	if has_grass then
		local material = self._block_types.grass_hills
		if material == nil then
			material = self._block_types.grass
		end
		region3:add_unique_cube(Cube3(
				Point3(rect.min.x, soil_top, rect.min.y),
				Point3(rect.max.x, height,	rect.max.y),
				material
			))
	end
end

function CustomHeightMapRenderer:_add_foothills_to_region_swamp_goblins(region3, rect, height)
	self:_add_soil_strata_to_region(region3, Cube3(
		Point3(rect.min.x, 0,		  rect.min.y),
		Point3(rect.max.x, height-1, rect.max.y)
	))

	local material = self._block_types.grass_hills or self._block_types.grass

	region3:add_unique_cube(Cube3(
			Point3(rect.min.x, height-1, rect.min.y),
			Point3(rect.max.x, height,	rect.max.y),
			material
		))
end

function CustomHeightMapRenderer:_add_mountains_to_region(region3, rect, height)
	local biome_name = stonehearth.world_generation:get_biome_alias()
	local colon_position = string.find (biome_name, ":", 1, true) or -1
	local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
	local fn = "_add_mountains_to_region_" .. mod_name_containing_the_biome
	if self[fn] ~= nil then
		--found a function for the biome being used, named:
		-- self:_add_mountains_to_region_<biome_name>(args,...)
		self[fn](self, region3, rect, height)
	else
		--there is no function for this specific biome, so call a copy of the original from stonehearth
		self:_add_mountains_to_region_original(region3, rect, height)
	end
end

function CustomHeightMapRenderer:_add_mountains_to_region_original(region3, rect, height)
	local rock_layers = self._rock_layers
	local num_rock_layers = self._num_rock_layers
	local i, block_min, block_max
	local stop = false

	block_min = 0

	for i=1, num_rock_layers do
		if (i == num_rock_layers) or (height <= rock_layers[i].max_height) then
			block_max = height
			stop = true
		else
			block_max = rock_layers[i].max_height
		end

		region3:add_unique_cube(Cube3(
				Point3(rect.min.x, block_min, rect.min.y),
				Point3(rect.max.x, block_max, rect.max.y),
				rock_layers[i].terrain_tag
			))

		if stop then return end
		block_min = block_max
	end
end

function CustomHeightMapRenderer:_add_mountains_to_region_swamp_goblins(region3, rect, height)
	local rock_layers = self._rock_layers
	local num_rock_layers = self._num_rock_layers
	local i, block_min, block_max
	local stop = false

	block_min = 0

	local max_foothills_height = 35 --hardcoded value

	for i=1, num_rock_layers do
		if (i == num_rock_layers) or (height <= rock_layers[i].max_height) then
			block_max = height
			stop = true
		else
			block_max = rock_layers[i].max_height
		end

		local has_grass = stop and block_max > max_foothills_height and block_max <60 --hardcoded value
		local rock_top = has_grass and block_max-1 or block_max
		local terrain_tag = has_grass and rock_layers[8].terrain_tag or rock_layers[i].terrain_tag

		region3:add_unique_cube(Cube3(
			Point3(rect.min.x, block_min, rect.min.y),
			Point3(rect.max.x, rock_top, rect.max.y),
			terrain_tag
		))
		
		if has_grass then
			local material = self._block_types.grass_hills or self._block_types.grass
			region3:add_unique_cube(Cube3(
				Point3(rect.min.x, rock_top, rect.min.y),
				Point3(rect.max.x, block_max, rect.max.y),
				material
			))
		end

		if stop then return end
		block_min = block_max
	end
end

return CustomHeightMapRenderer
