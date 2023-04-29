swamp_goblins = {}
print("Swamp Goblins Mod version 23.4.29")

--[[

elderstone reference

equips:
	fancy outfit (tier3)
	armors/equips for beasttamer summons
	upgrades:
		trapper fancy boots
		ranged attack for beast tamer, bow?
	replace weapon placeholders, improve overall models
	old shepherd_outfit as a new goblin outfit? (looks good at least)
	6? warrior tiers:
		plants
		wood
		leather
		varanus
		clan
		6th?

items with effects:
	remove stick water debuff with some item or trait
	speed up crafting with bonus from nearby items
	banner shred
	animals haulers requiring food and care
	varanus/mobs repelent
	bug nests or other mob structures for egg raiders

goblinpedia:
	templates
	party goblin

quests:
	make new orc/kobold gongs
	jobs side quests:
		shaman lvl 6: travel to learn cook recipes || eating contest?
	combat hearth waves:
		boss, bunnies, orcs, kobolds, ogres
	import hearthlings:
		traveler campaign, someone lost appears into the camp
	import goblins:
		someone finds a goblin egg basket
			after tier 2, some random amount of days (+jobs to make sure it can be defended)
			images with the dialogs, describe the finding, decide to keep or refuse the egg
	Maybe have a way for us to have ogres?
		orc+kobold+ogre group fleeing from undeads
	undeads:
		spirit world has inverted colors?

ace stuff:
	add ace tools and tools upgrades
	fuel system (Wait gobbos can't chop wood?)
	wounds and tonics
	composting
	fix raw food (meat and eggs) not being edible on ace
	ace dragon quest texts

mobs:
	slimes:
		cube shape
		animation:
			cube roll walking, particle effect trail
			size inflation for attack
			squish up/down idle
	black boe:
		from majoras mask
		army, small black smoke blobs with glowing eyes,

jobs:
	warrior rework:
		max level at 3
		two job promotions after:
			light/fast combat and heavy/strong combat
			varanus rider?

	steam maker:
		cook(+ace_brewer)

	grazer:
		farmer+shepherd

	party goblin:
		different tattoo color?
		chatty
		combat skills:
			smoke bomb: aoe, halfs enemy attack (blindness)
			fireworks: calls enemys attention
			frog escape: changes into a frog and jump out of battle

	earthshaper:
		dart traps, smoke traps
		upgraded workbenches

	fisher:
		swamp fish colors, eels, blowfish

decorations:
	Giant rug, or wall hanging rug.
	Varanus roasting on a stick
	goblinfied vanilla_lampposts
	lamp post, lamp/lantern, mat/rug/mosaic, statue
	painting/tapestry, banner wall, awning
	aroma candles, incenses
	weapon/armor decorations
	high/fancy bed
	bed of hot embers (firewalking)
		magmasword texture/effects
	reversed porticulis stone gate (opens going down instead of up)
	drying rack

templates:
	combat houses (n.a. inspired roofs?)

music:
	bongo, drum, flute, gong, triangulo

redo:
	hourglass effects
	travel stall

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
	local custom_promote_unit_to_class_script = require('data.gm.campaigns.amberstone.arcs.trigger.discovery.encounters.30_geomancy.custom_promote_unit_to_class_script')
	local promote_unit_to_class_script = radiant.mods.require('stonehearth.data.gm.campaigns.amberstone.arcs.trigger.discovery.encounters.30_geomancy.promote_unit_to_class_script')
	radiant.mixin(promote_unit_to_class_script, custom_promote_unit_to_class_script)

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
