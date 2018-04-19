local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local PerturbationGrid = require 'stonehearth.services.server.world_generation.perturbation_grid'
local Point2 = _radiant.csg.Point2
local CustomLandscaper = class()
local log = radiant.log.create_logger('meu_log')

function CustomLandscaper:place_features(tile_map, feature_map, place_item)
	local biome_name = stonehearth.world_generation:get_biome_alias()
	local colon_position = string.find (biome_name, ":", 1, true) or -1
	local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
	local fn = "place_features_" .. mod_name_containing_the_biome
	if self[fn] ~= nil then
		--found a function for the biome being used, named:
		-- self:place_features_<biome_name>(args,...)
		self[fn](self, tile_map, feature_map, place_item)
	else
		--there is no function for this specific biome, so call a copy of the original from stonehearth
		self:place_features_original(tile_map, feature_map, place_item)
	end
end

function CustomLandscaper:place_features_original(tile_map, feature_map, place_item)
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local feature_name = feature_map:get(i, j)
			self:_place_feature(feature_name, i, j, tile_map, place_item)
		end
	end
end

function CustomLandscaper:place_features_swamp_goblins(tile_map, feature_map, place_item)
	local water_1_table
	local water_2_table
	if self._landscape_info.water.spawn_objects then
		water_1_table = WeightedSet(self._rng)
		water_2_table = WeightedSet(self._rng)
		for item, weight in pairs(self._landscape_info.water.spawn_objects.water_1) do
			water_1_table:add(item,weight)
		end
		for item, weight in pairs(self._landscape_info.water.spawn_objects.water_2) do
			water_2_table:add(item,weight)
		end
	end

	local new_feature
	for j=1, feature_map.height do
		for i=1, feature_map.width do
			local feature_name = feature_map:get(i, j)
			if self._landscape_info.water.spawn_objects then
				if feature_name == "water_1" then
					new_feature = water_1_table:choose_random()
					if new_feature ~= "none" then
						feature_name = new_feature
					end
				end
				if feature_name == "water_2" then
					new_feature = water_2_table:choose_random()
					if new_feature ~= "none" then
						feature_name = new_feature
					end
				end
			end
			self:_place_feature_swamp_goblins(feature_name, i, j, tile_map, place_item)
		end
	end
end

function CustomLandscaper:_place_feature_swamp_goblins(feature_name, i, j, tile_map, place_item)
	local perturbation_grid = self._perturbation_grid
	local x, y = perturbation_grid:get_unperturbed_coordinates(i, j)
	local elevation = tile_map:get(x, y)
	local terrain_type = self._biome:get_terrain_type(elevation)
	local placement_type, params = self:_get_placement_info(feature_name, terrain_type)

	if not placement_type then
		if not feature_name then
			log:spam('no feature to place exists at %d, %d', i, j)
		else
			log:spam('%s not in feature table', feature_name)
		end
		return
	end

	if placement_type == 'single' then
		local x, y = perturbation_grid:get_perturbed_coordinates(i, j, params.exclusion_radius)
		if self:_is_flat(tile_map, x, y, params.ground_radius) then
			place_item(feature_name, x, y)
		end
		return
	end

	local try_place_item = function(x, y)
		--original
		place_item(feature_name, x, y)
		return true
	end

	local try_place_mushroom = function(mushroom_uri, x, y)
		--swamp_version, sending a new uri
		place_item(mushroom_uri, x, y)
		return true
	end

	if placement_type == 'dense' then
		local x, y, w, h = perturbation_grid:get_cell_bounds(i, j)
		local nested_grid_spacing = math.floor(perturbation_grid.grid_spacing / params.grid_multiple)

		self:_place_dense_items(tile_map, x, y, w, h, nested_grid_spacing,
			params.exclusion_radius, params.item_density, try_place_item)
		return
	end

	if placement_type == 'swamp_mushroom' then
		local x, y, w, h = perturbation_grid:get_cell_bounds(i, j)
		local nested_grid_spacing = math.floor(perturbation_grid.grid_spacing / params.grid_multiple)

		self:_place_dense_items_swamp_goblins(tile_map, x, y, w, h, nested_grid_spacing,
			params.exclusion_radius, params.item_density, try_place_mushroom)
		return
	end

	if placement_type == 'pattern' then
		local x, y, w, h = perturbation_grid:get_cell_bounds(i, j)
		local rows, columns = self:_random_pattern(params.min_rows, params.max_rows, params.min_cols, params.max_cols)
		self:_place_pattern(tile_map, x, y, w, h, rows, columns, params.item_spacing, params.item_density, try_place_item)
		return
	end

	assert(false, 'unknown placement_type ' .. placement_type .. ' for ' .. feature_name)
end

function CustomLandscaper:_place_dense_items_swamp_goblins(tile_map, cell_origin_x, cell_origin_y, cell_width, cell_height, grid_spacing, exclusion_radius, probability, try_place_mushroom)
	local rng = self._rng
	-- consider removing this memory allocation
	local perturbation_grid = PerturbationGrid(cell_width, cell_height, grid_spacing, rng)
	local grid_width, grid_height = perturbation_grid:get_dimensions()
	local i, j, dx, dy, x, y, result
	local placed = false

	for j=1, grid_height do
		for i=1, grid_width do
			if rng:get_real(0, 1) < probability then
				if exclusion_radius >= 0 then
					dx, dy = perturbation_grid:get_perturbed_coordinates(i, j, exclusion_radius)
				else
					dx, dy = perturbation_grid:get_unperturbed_coordinates(i, j)
				end

				-- -1 because get_perturbed_coordinates returns base 1 coords and cell_origin is already at 1,1 of cell
				x = cell_origin_x + dx-1
				y = cell_origin_y + dy-1

				local location_in_the_chunk = Point2(x,y)
				local distance_to_chunk_center = location_in_the_chunk:distance_to(Point2(cell_origin_x +7.5, cell_origin_y +7.5))
				local mushroom_uri = "swamp_goblins:plants:mushroom"
				if distance_to_chunk_center<4 then
					-- log:error("distance_to_chunk_center<4")
					mushroom_uri = "swamp_goblins:plants:mushroom"
				else
					if distance_to_chunk_center<6 then
						-- log:error("distance_to_chunk_center<6")
						mushroom_uri = "swamp_goblins:plants:mushroom_medium"
					else
						-- log:error("distance_to_chunk_center>6")
						mushroom_uri = "swamp_goblins:plants:mushroom_small"
					end
				end

				result = try_place_mushroom(mushroom_uri, x, y)
				if result then
					placed = true
				end
			end
		end
	end

	return placed
end

return CustomLandscaper