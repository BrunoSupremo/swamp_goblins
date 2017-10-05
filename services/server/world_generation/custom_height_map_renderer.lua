local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3

local CustomHeightMapRenderer = class()

function CustomHeightMapRenderer:_add_foothills_to_region(region3, rect, height)
   local mod_name = stonehearth.world_generation:get_biome_alias()
   --log:error('nome %s', mod_name)
   --mod_name is the mod that has the current biome
   local colon_pos = string.find (mod_name, ":", 1, true) or -1
   mod_name = "_add_foothills_to_region_" .. string.sub (mod_name, 1, colon_pos-1)
   if self[mod_name]~=nil then
      self[mod_name](self,region3,rect,height)
   else
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
         Point3(rect.min.x, 0,        rect.min.y),
         Point3(rect.max.x, soil_top, rect.max.y)
      ))

   if has_grass then
      local material = self._block_types.grass_hills
      if material == nil then
         material = self._block_types.grass
      end
      region3:add_unique_cube(Cube3(
            Point3(rect.min.x, soil_top, rect.min.y),
            Point3(rect.max.x, height,   rect.max.y),
            material
         ))
   end
end

function CustomHeightMapRenderer:_add_foothills_to_region_swamp_goblins(region3, rect, height)
   self:_add_soil_strata_to_region(region3, Cube3(
      Point3(rect.min.x, 0,        rect.min.y),
      Point3(rect.max.x, height-1, rect.max.y)
   ))

   local material = self._block_types.grass_hills or self._block_types.grass

   region3:add_unique_cube(Cube3(
         Point3(rect.min.x, height-1, rect.min.y),
         Point3(rect.max.x, height,   rect.max.y),
         material
      ))
end

return CustomHeightMapRenderer
