swamp_goblins = {}
print("Swamp Goblins Mod version 26.1.1")

--[[

add that big snake model from stmpnk

add new workbench to shaman to avoid crafting stuff on cook pots

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
	ace dragon quest texts
	we need the terrain recipes form ACE on the Shaman @Bruno Or the earthmaster

mobs:
	slimes:
		cube shape
		animation:
			cube roll walking, particle effect trail
			size inflation for attack
			squish up/down idle
	black boe:
		probably for undead campaign
		small black smoke blobs with glowing eyes

jobs:
	alchemist?
	
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
		trickster job, combat skills:
			smoke bomb: aoe, halfs enemy attack (blindness)
			fireworks: calls enemys attention
			frog escape: changes into a frog and jump out of battle
			convert/confuse enemies into goblin team

	earthshaper:
		dart traps, smoke traps
		upgraded workbenches

	fisher:
		swamp fish colors, eels, blowfish

decorations:
	Giant rug, or wall hanging rug.
	goblinfied vanilla_lampposts
	lamp post, lamp/lantern, mat/rug/mosaic, statue
	painting/tapestry, banner wall, awning
	weapon/armor decorations
	high/fancy bed
	bed of hot embers (firewalking)
		magmasword texture/effects
	drying rack

templates:
	tier 3 templates
	stairs
	tier 2 walkways/bridges

music:
	bongo, drum, flute, gong, triangulo

redo:
	travel stall


----

Sure. The frog rider is a combat job that requires a high body and mind stat. They can evolve from the trapper or the warrior class. They need a frog saddle and a frog whip to ride a giant frog.

The frog rider has these abilities:

Leap: The frog rider can make their frog jump over a large distance, landing on an enemy or an empty tile. This deals damage and knocks back enemies in the landing area.
Tongue Lash: The frog rider can make their frog use its tongue to grab and pull an enemy or an item towards them. This can be used to disarm enemies or steal items.
Croak: The frog rider can make their frog emit a loud croak that lowers the morale and defense of nearby enemies. This also attracts other frogs to join the battle.
Sticky Spit: The frog rider can make their frog spit a sticky substance that slows down and damages enemies in a cone area.
The frog rider also has some passive perks:

Amphibious: The frog rider can move faster and breathe underwater.
Camouflage: The frog rider can blend in with the swamp environment, making them harder to detect by enemies.
Frog Bond: The frog rider has a strong bond with their frog, increasing their health and damage.
The frog rider is a versatile and mobile combat job that can deal damage, control enemies and support allies with their giant frog companion.

-----

The mud slinger is a combat job that requires a high mind and spirit stat. They can evolve from the trapper or the herbalist class. They need a mud sling and a mud pouch to throw mud balls.

The mud slinger has these abilities:

Mud Ball: The mud slinger can throw a mud ball at an enemy or an item, dealing damage and applying a debuff that reduces speed and accuracy.
Mud Trap: The mud slinger can place a mud trap on the ground that activates when an enemy steps on it, immobilizing them and dealing damage over time.
Mud Wall: The mud slinger can create a wall of mud that blocks enemies and projectiles. The wall can be destroyed by attacks or by the mud slinger’s own abilities.
Mud Slide: The mud slinger can cause a landslide of mud that sweeps away enemies and items in a line area, dealing damage and knocking them back.
The mud slinger also has some passive perks:

Dirty Tricks: The mud slinger can use their mud balls to sabotage enemy equipment and structures, causing them to malfunction or collapse.
Mud Sense: The mud slinger can sense vibrations in the ground, making them aware of hidden enemies and traps.
Mud Bath: The mud slinger can heal themselves and allies by covering them with healing mud.
The mud slinger is a cunning and versatile combat job that can deal damage, control enemies and support allies with their mastery of mud.

-----

make your Beast Tamer both formidable and unique:

Whip of Command: A magical whip that not only deals damage but also enhances the abilities of your tamed beasts.

Beastmaster's Bow: A bow that fires arrows infused with beastly energy, summoning spectral animals to aid in battle.

Claw Gauntlets: Gauntlets with retractable claws, allowing for close combat and the ability to channel the power of your beasts.

Totem Staff: A staff adorned with totems representing different beasts, each granting unique buffs or abilities.

Beast Bond Blade: A sword that strengthens the bond between the tamer and their beasts, increasing their combat effectiveness.

Nature's Fang: A dagger made from the fang of a legendary beast, with poison or elemental effects.

Beastcaller Horn: A horn that can summon beasts to your side or unleash powerful sonic attacks.

-----



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