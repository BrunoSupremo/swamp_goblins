local ClericJob = require 'stonehearth.jobs.cleric.cleric'
local SpiritWalkerClass = class()
radiant.mixin(SpiritWalkerClass, ClericJob)
local Point3 = _radiant.csg.Point3
local conversation_subjects = {
	"stonehearth:subjects:cult",
	"stonehearth:subjects:darkness",
	"stonehearth:subjects:death",
	"stonehearth:cleric:talisman",
	"stonehearth:loot:dusty_tome",
	"stonehearth:npc:herald:untz",
	"stonehearth:monsters:forest:alligator",
	"swamp_goblins:beast_tamer:talisman",
	"swamp_goblins:bonesmith:talisman",
	"swamp_goblins:earthmaster:talisman",
	"swamp_goblins:scavenger:talisman",
	"swamp_goblins:shaman:talisman",
	"swamp_goblins:spirit_walker:talisman",
	"swamp_goblins:warrior:talisman"
}

function SpiritWalkerClass:summon_big_g(delay)
	local summoning_delay = (delay * 33.3)
	stonehearth.combat:set_timer("SpiritWalkerClass summoning_delay: big_g", summoning_delay, function()
		self:create_spirit("swamp_goblins:summons:big_g", "double")
	end)
end

function SpiritWalkerClass:summon_spirit(delay, amount)
	local spirit_amount = amount or 1
	if not radiant.util.is_number(spirit_amount) then
		spirit_amount = 1
	end
	for i=1, spirit_amount do
		local offset = (0.1*i+1) - (0.1*spirit_amount)/2
		local summoning_delay = (delay * 33.3 * offset)
		stonehearth.combat:set_timer("SpiritWalkerClass summoning_delay: "..i, summoning_delay, function()
			self:create_spirit("swamp_goblins:summons:goblin_spirit", "copy")
		end)
	end
end

function SpiritWalkerClass:summon_spirits(delay)
	local spirit_amount = radiant.entities.get_attribute(self._sv._entity, "spirit")
	self:summon_spirit(delay, spirit_amount)
end

function SpiritWalkerClass:create_spirit(url, attributes)
	local entity_location = radiant.entities.get_world_location(self._sv._entity)
	local player_id = radiant.entities.get_player_id(self._sv._entity)

	local spirit = radiant.entities.create_entity(url, {owner = player_id})
	if attributes == "copy" then
		self:copy_attributes(spirit)
	else
		if attributes == "double" then
			self:double_attributes(spirit)
		end
	end
	local location = radiant.terrain.find_placement_point(entity_location, 3, 6, self._sv._entity, nil, true)
	radiant.terrain.place_entity_at_exact_location(spirit, location)

	radiant.effects.run_effect(spirit, "stonehearth:effects:spawn_entity")

	for _, subject_uri in ipairs(conversation_subjects) do
		local subjects = spirit:get_component('stonehearth:subject_matter')
		subjects:add_subject(subject_uri)
		subjects:add_override({
			subject = subject_uri,
			sentiment = 1
		})
	end
	radiant.entities.add_buff(spirit, "swamp_goblins:buffs:despawn:in_2h")
end

function SpiritWalkerClass:copy_attributes(spirit)
	radiant.entities.set_attribute(spirit, "max_health", radiant.entities.get_attribute(self._sv._entity, "max_health") / radiant.entities.get_attribute(self._sv._entity, "spirit") +1)
	radiant.entities.set_attribute(spirit, "muscle", radiant.entities.get_attribute(self._sv._entity, "muscle") +1)
	radiant.entities.set_attribute(spirit, "menace", radiant.entities.get_attribute(self._sv._entity, "menace") +1)
	radiant.entities.set_attribute(spirit, "courage", radiant.entities.get_attribute(self._sv._entity, "courage") +1)
	radiant.entities.set_attribute(spirit, "speed", radiant.entities.get_attribute(self._sv._entity, "speed") +1)
end

function SpiritWalkerClass:double_attributes(spirit)
	radiant.entities.set_attribute(spirit, "max_health", radiant.entities.get_attribute(self._sv._entity, "max_health") *2)
	radiant.entities.set_attribute(spirit, "muscle", radiant.entities.get_attribute(self._sv._entity, "muscle") *2)
	radiant.entities.set_attribute(spirit, "menace", radiant.entities.get_attribute(self._sv._entity, "menace") *2)
	radiant.entities.set_attribute(spirit, "courage", radiant.entities.get_attribute(self._sv._entity, "courage") *2)
	radiant.entities.set_attribute(spirit, "speed", radiant.entities.get_attribute(self._sv._entity, "speed") +1)
end

function SpiritWalkerClass:warrior_aura(args)
	radiant.events.trigger_async(stonehearth.job, 'swamp_goblins:spirit_walker_buffing')
end

function SpiritWalkerClass:dragon_aura(args)
	radiant.events.trigger_async(stonehearth.job, 'swamp_goblins:spirit_walker_dragon_aura')
end

return SpiritWalkerClass