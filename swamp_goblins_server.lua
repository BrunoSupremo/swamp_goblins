swamp_goblins = {
version = 24
}
local log = radiant.log.create_logger('version')
log:error("Swamp Goblins mod for alpha %d", swamp_goblins.version)

function swamp_goblins:_on_required_loaded()
	local custom_swimming_service = require('services.server.swimming.custom_swimming_service')
	local swimming_service = radiant.mods.require('stonehearth.services.server.swimming.swimming_service')
	radiant.mixin(swimming_service, custom_swimming_service)

	local custom_biome = require('services.server.world_generation.custom_biome')
	local biome = radiant.mods.require('stonehearth.services.server.world_generation.biome')
	radiant.mixin(biome, custom_biome)
end

function swamp_goblins:_on_biome_set(e)
	if e.biome_uri ~= "swamp_goblins:biome:swamp" then
		return
	end
	local custom_overview_map = require('services.server.world_generation.custom_overview_map')
	local overview_map = radiant.mods.require('stonehearth.services.server.world_generation.overview_map')
	radiant.mixin(overview_map, custom_overview_map)

	local custom_world_generation_service = require('services.server.world_generation.custom_world_generation_service')
	local world_generation_service = radiant.mods.require('stonehearth.services.server.world_generation.world_generation_service')
	radiant.mixin(world_generation_service, custom_world_generation_service)

	local custom_height_map_renderer = require('services.server.world_generation.custom_height_map_renderer')
	local height_map_renderer = radiant.mods.require('stonehearth.services.server.world_generation.height_map_renderer')
	radiant.mixin(height_map_renderer, custom_height_map_renderer)

	local custom_landscaper = require('services.server.world_generation.custom_landscaper')
	local landscaper = radiant.mods.require('stonehearth.services.server.world_generation.landscaper')
	radiant.mixin(landscaper, custom_landscaper)
end

radiant.events.listen_once(radiant, 'radiant:required_loaded', swamp_goblins, swamp_goblins._on_required_loaded)
radiant.events.listen_once(radiant, 'stonehearth:biome_set', swamp_goblins, swamp_goblins._on_biome_set)

return swamp_goblins
