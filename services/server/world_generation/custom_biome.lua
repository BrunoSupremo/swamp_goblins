local CustomBiome = class()

function CustomBiome:_generate_color_map()
   local biome_name = stonehearth.world_generation:get_biome_alias()
   local colon_position = string.find (biome_name, ":", 1, true) or -1
   local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
   local fn = "_generate_color_map_" .. mod_name_containing_the_biome
   if self[fn] ~= nil then
      --found a function for the biome being used, named:
      -- self:_add_soil_strata_to_region_<biome_name>(args,...)
      self[fn](self)
   else
      --there is no function for this specific biome, so call a copy of the original from stonehearth
      self:_generate_color_map_original()
   end
end

function CustomBiome:_generate_color_map_original()
   local palette = self._palettes[self._season]
   local elevations = self:_get_terrain_elevations()
   local color_map = {
      water = '#1cbfff'
   }

   for _, elevation in ipairs(elevations) do
      local terrain_type, step = self:get_terrain_type_and_step(elevation)
      local terrain_code = self:_assemble_terrain_code(terrain_type, step)
      local color

      if terrain_type == 'plains' then
         color = step <= 1 and palette.dirt or palette.grass
      elseif terrain_type == 'foothills' then
         color = palette.grass_hills
      elseif terrain_type == 'mountains' then
         color = palette['rock_layer_' .. step]
      else
         error('unknown terrain type')
      end

      color_map[terrain_code] = color
   end

   self._color_map = color_map
end

function CustomBiome:_generate_color_map_swamp_goblins()
   local palette = self._palettes[self._season]
   local elevations = self:_get_terrain_elevations()
   local color_map = {
      water = self:get_landscape_info().water.minimap_color or '#1cbfff'
   }

   for _, elevation in ipairs(elevations) do
      local terrain_type, step = self:get_terrain_type_and_step(elevation)
      local terrain_code = self:_assemble_terrain_code(terrain_type, step)
      local color

      if terrain_type == 'plains' then
         color = step <= 1 and palette.dirt or palette.grass
      elseif terrain_type == 'foothills' then
         color = palette.grass_hills
      elseif terrain_type == 'mountains' then
         color = palette['rock_layer_' .. step]
      else
         error('unknown terrain type')
      end

      color_map[terrain_code] = color
   end

   self._color_map = color_map
end

return CustomBiome