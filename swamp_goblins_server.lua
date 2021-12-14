swamp_goblins = {}
print("Swamp Goblins Mod version 21.12.13")

--[[

replace rabbit statues

high bed
bed of hot embers (firewalking)
drying rack

instead of recipes to break items (chair -> wood), have a container with input filters (crusher?)
	detects itens inside, delete them and spill out the resources
		worked a little on this, will need custom ui
			⚠️ui:crusher:filter

goblinpedia:
	templates
	party goblin

speed up crafting with bonus from nearby items

warrior rework:
	max level at 3
	two job promotions after:
		light/fast combat and heavy/strong combat


reversed porticulis stone gate (opens going down instead of up)
wolf reward? (i can't remember this one lol [orc campaign?])

jobs side quests for new stuff
	shaman lvl 6: travel to learn cook recipes || eating contest?

trapper fancy boots upgrade

ace stuff:
	add ace tools and tools upgrades
	fuel system (Wait gobbos can't chop wood?)
	wounds and tonics

orc quest
	food arc

humans:
oh, so what about we get a farmer to help with your quest, and in return you convince them to not bother us anymore?
*ok
--fulfill quest
--finish fighting the last rank
--rewarded with orc footman that liked your town and warriors
your town is way better than it looks, you should display it somehow
--shrine options
--tier 3 reached, new templates, etc...


move default market stall to earthshaper

non blue skin trait

combat hearth waves:
	boss, bunnies, orcs, kobolds, ogres

import hearthlings/goblins to the other kingdom
	(traveler campaign)

banner shred
animals haulers requiring food and care
varanus/mobs repelent
bug nests or other mob structures for egg raiders
old shepherd_outfit as a new goblin outfit? (looks good at least)
spirit world has inverted colors?

mobs:
	slimes, mosquito

party goblin:
	different tattoo color?
	chatty
	combat skills:
		smoke bomb: aoe, halfs enemy attack (blindness)
		fireworks: calls enemys attention
		frog escape: changes into a frog and jump out of battle

contruction:
	door, double door
	windows 2x2, 2x3, 3x2
	fence, fence door
containers:
	piles, crate/urn, chest, vault
	input_bin, input_corner, input_shelf_ground, input_shelf_wall, input_table, output_box
decorations:
	lamp post, lamp/lantern, mat/rug/mosaic, statue
	painting/tapestry, banner wall, awning
	aroma candles, incenses
	weapon/armor decorations
	wall planter, pots, violets versions
furniture:
	themes:
		mushroom, fiber, wood, fancy/clothed wood, stone, clay
	bed, chair, table, bench
templates:
	combat houses (n.a. inspired roofs?)
earthshaper:
	dart traps, smoke traps
	upgraded workbenches
gizmos:
	goblinpedia
music:
	bongo, drum, flute, gong, triangulo
equipments:
	replace weapon placeholders, improve overall models
	shields? worker outfit?
	ranged attack for beast tamer, bow?
redo:
	hourglass effects
	checkers table
	travel stall
fisher:
	swamp fish colors, eels, blowfish

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
	local custom_ladder_builder = require('services.server.build.custom_ladder_builder')
	local ladder_builder = radiant.mods.require('stonehearth.services.server.build.ladder_builder')
	radiant.mixin(ladder_builder, custom_ladder_builder)

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
	swamp_goblins.ace_is_here = false
	for i, mod in ipairs(mod_list) do
		if mod == "stonehearth_ace" then
			swamp_goblins.ace_is_here = true
			break
		end
	end
	if swamp_goblins.ace_is_here then
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
