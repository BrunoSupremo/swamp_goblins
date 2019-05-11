local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local CustomLandscaper = class()

function CustomLandscaper:place_features(tile_map, feature_map, place_item)
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
			self:_place_feature(feature_name, i, j, tile_map, place_item)
		end
	end
end

return CustomLandscaper