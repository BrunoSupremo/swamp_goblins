local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3
local CustomWorldGenerationService = class()

function CustomWorldGenerationService:_add_water_bodies(regions)
   local water_height_delta = stonehearth.world_generation:get_biome_generation_data():get_landscape_info().water.water_height_delta or 1.5

   for _, terrain_region in pairs(regions) do
      terrain_region:force_optimize_by_merge('add water bodies')

      local terrain_bounds = terrain_region:get_bounds()

      local height = terrain_bounds:get_size().y - water_height_delta

      local water_bounds = Cube3(terrain_bounds)
      water_bounds.max.y = water_bounds.max.y - math.floor(water_height_delta)

      local water_region = terrain_region:intersect_cube(water_bounds)
      stonehearth.hydrology:create_water_body_with_region(water_region, height)
   end
end

return CustomWorldGenerationService