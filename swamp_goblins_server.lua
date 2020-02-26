swamp_goblins = {}
print("Swamp Goblins Mod version 20.2.25")

--[[

spirit walker ranged attack as a high level skill (spirit ball attack)
ranged attack for beast tamer

waves:
	boss, bunnies, orcs, kobolds, ogres

add visible goblin trader
import hearthlings
move travel to earthmaster

mosquito model
banner shred
animals haulers requiring food and care
swamp slimes
varanus/mobs repelent
bug nests to attack eggs

ace stuff:
	add ace tools and tools upgrades
	Wait gobbos can't chop wood?
	shaman needs to craft pet food for the trappers pets, bug meat?

contruction:
	door, double door
	windows 2x2, 2x3, 3x2
	fence, fence door
containers:
	piles, crate/urn, chest, vault
	input_bin, input_corner, input_shelf_ground, input_shelf_wall, input_table, output_box
decorations:
	lamp post, lamp/lantern, mat/rug/mosaic, statue
	painting/tapestry, banner wall, awning, wall planter
	aroma candles, incenses
furniture:
	themes: mushroom, fiber, wood, fancy/clothed wood, stone, clay
	bed, chair, table, bench
templates:
	inn, dinning hall, tavern, combat houses (n.a. inspired)
earthmaster:
	dart traps, smoke traps
gizmos:
	goblinpedia
music:
	bongo, drum, flute, gong, triangulo
equipments:
	replace weapon placeholders, improve overall models
	beast_tamer/spirit_walker better weapons
	shields? worker outfit?
redo:
	hourglass effects
	checkers table
	warrior goblin aura effects
fisher:
	swamp fish colors, eels, blowfish
Bugs:
]]

function swamp_goblins:_on_services_init()
	if stonehearth.world_generation:get_biome_alias() ~= "swamp_goblins:biome:swamp" then
		return
	end
	local custom_swimming_service = require('services.server.swimming.custom_swimming_service')
	local swimming_service = radiant.mods.require('stonehearth.services.server.swimming.swimming_service')
	radiant.mixin(swimming_service, custom_swimming_service)
end

function swamp_goblins:_on_required_loaded()
	local custom_combat_service = require('services.server.combat.custom_combat_service')
	local combat_service = radiant.mods.require('stonehearth.services.server.combat.combat_service')
	radiant.mixin(combat_service, custom_combat_service)

	local custom_population_faction = require('services.server.population.custom_population_faction')
	local population_faction = radiant.mods.require('stonehearth.services.server.population.population_faction')
	radiant.mixin(population_faction, custom_population_faction)

	local custom_job_component = require('components.job.custom_job_component')
	local job_component = radiant.mods.require('stonehearth.components.job.job_component')
	radiant.mixin(job_component, custom_job_component)

	local mod_list = radiant.resources.get_mod_list()
	local ace_is_here = false
	for i, mod in ipairs(mod_list) do
		if mod == "stonehearth_ace" then
			ace_is_here = true
			break
		end
	end
	if ace_is_here then
		local ace_job_component = radiant.mods.require('stonehearth_ace.monkey_patches.ace_job_component')
		radiant.mixin(ace_job_component, custom_job_component)
	end
end

function swamp_goblins:_on_biome_set(e)
	if e.biome_uri ~= "swamp_goblins:biome:swamp" then
		return
	end
	local custom_overview_map = require('services.server.world_generation.custom_overview_map')
	local overview_map = radiant.mods.require('stonehearth.services.server.world_generation.overview_map')
	radiant.mixin(overview_map, custom_overview_map)

	local custom_height_map_renderer = require('services.server.world_generation.custom_height_map_renderer')
	local height_map_renderer = radiant.mods.require('stonehearth.services.server.world_generation.height_map_renderer')
	radiant.mixin(height_map_renderer, custom_height_map_renderer)

	local custom_landscaper = require('services.server.world_generation.custom_landscaper')
	local landscaper = radiant.mods.require('stonehearth.services.server.world_generation.landscaper')
	radiant.mixin(landscaper, custom_landscaper)

	local custom_micro_map_generator = require('services.server.world_generation.custom_micro_map_generator')
	local micro_map_generator = radiant.mods.require('stonehearth.services.server.world_generation.micro_map_generator')
	radiant.mixin(micro_map_generator, custom_micro_map_generator)

	local custom_world_generation_service = require('services.server.world_generation.custom_world_generation_service')
	local world_generation_service = radiant.mods.require('stonehearth.services.server.world_generation.world_generation_service')
	radiant.mixin(world_generation_service, custom_world_generation_service)
end

radiant.events.listen_once(radiant, 'radiant:services:init', swamp_goblins, swamp_goblins._on_services_init)
radiant.events.listen_once(radiant, 'radiant:required_loaded', swamp_goblins, swamp_goblins._on_required_loaded)
radiant.events.listen_once(radiant, 'stonehearth:biome_set', swamp_goblins, swamp_goblins._on_biome_set)

return swamp_goblins
