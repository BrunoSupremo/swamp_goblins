local ClericJob = require 'stonehearth.jobs.cleric.cleric'
local SpiritWalkerClass = class()
radiant.mixin(SpiritWalkerClass, ClericJob)

local rng = _radiant.math.get_default_rng()
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local conversation_subjects = {
	"stonehearth:subjects:cult",
	"stonehearth:subjects:darkness",
	"stonehearth:subjects:death",
	"stonehearth:npc:herald:untz",
	"stonehearth:monsters:forest:alligator",
	"swamp_goblins:goblinpedia",
	"swamp_goblins:critters:frog",
	"swamp_goblins:music:subject",
	"swamp_goblins:goblins:egg",
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

function SpiritWalkerClass:spirit_ball(delay, target)
	local spirit_amount = radiant.entities.get_attribute(self._sv._entity, "spirit")
	local enemies = self:find_enemies(target)
	for i=1, spirit_amount do
		local offset = (0.1*i+1) - (0.1*spirit_amount)/2
		local summoning_delay = (delay * 33.3 * offset)
		stonehearth.combat:set_timer("SpiritWalkerClass summoning_balls_delay: "..i, summoning_delay, function()
			local rotation = 360/spirit_amount * i
			self:create_ball(rotation, enemies)
		end)
	end
end

function SpiritWalkerClass:find_enemies(target)
	local target_location = radiant.entities.get_world_grid_location(target)
	if not target_location then
		return
	end
	local cube = Cube3(target_location):inflated(Point3(20, 6, 20))
	local intersected_entities = radiant.terrain.get_entities_in_cube(cube)
	local hostiles = {}
	for id, entity in pairs(intersected_entities) do
		local is_hostile = stonehearth.player:are_entities_hostile(entity, self._sv._entity)
		if is_hostile and radiant.entities.has_free_will(entity) then
			table.insert(hostiles, entity)
		end
	end
	return hostiles
end

function SpiritWalkerClass:create_ball(rotation, enemies)
	local player_id = radiant.entities.get_player_id(self._sv._entity)
	local spirit_ball = radiant.entities.create_entity("swamp_goblins:weapons:spirit_ball", {owner = player_id})

	local rotated = radiant.math.rotate_about_y_axis(Point3(2,3,0), rotation)
	local entity_location = radiant.entities.get_world_location(self._sv._entity) +rotated
	radiant.terrain.place_entity_at_exact_location(spirit_ball, entity_location)

	stonehearth.combat:set_timer("SpiritWalkerClass balls attack: "..rotation, 1500, function()
		self:ball_attack(spirit_ball, enemies)
	end)
end

function SpiritWalkerClass:ball_attack(spirit_ball, enemies)
	local still_existing_enemies = {}
	--to filter out now invalid entries from the old enemy list
	for i = 1, #enemies do
		if enemies[i] and enemies[i]:is_valid() then
			table.insert(still_existing_enemies, enemies[i])
		end
	end
	local target = still_existing_enemies[rng:get_int(1,#still_existing_enemies)]
	if not target or not target:is_valid() then
		local effect = radiant.effects.run_effect(spirit_ball, "swamp_goblins:effects:spirit:poof")
		effect:set_finished_cb(function()
			radiant.entities.destroy_entity(spirit_ball)
			effect:set_finished_cb(nil)
			effect = nil
		end)
		return
	end

	local projectile_component = spirit_ball:add_component('stonehearth:projectile')
	projectile_component:set_speed(25)
	projectile_component:set_target_offset(Point3(0, 2, 0))
	projectile_component:set_target(target)

	projectile_component:start()

	local impact_trace
	impact_trace = radiant.events.listen(spirit_ball, 'stonehearth:combat:projectile_impact', function()
		if spirit_ball:is_valid() and target:is_valid() then
			local proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'running death effect' })
			local location = radiant.entities.get_world_location(target)+Point3(0,2,0)
			radiant.terrain.place_entity_at_exact_location(proxy, location)

			local effect = radiant.effects.run_effect(proxy, "swamp_goblins:effects:spirit:poof")
			effect:set_finished_cb(function()
				radiant.entities.destroy_entity(proxy)
				effect:set_finished_cb(nil)
				effect = nil
			end)

			stonehearth.combat:battery({attacker = self._sv._entity, target = target, damage = 10})
		end

		if impact_trace then
			impact_trace:destroy()
			impact_trace = nil
		end
	end)
end

function SpiritWalkerClass:summon_spirits(delay)
	local spirit_amount = radiant.entities.get_attribute(self._sv._entity, "spirit")
	spirit_amount = math.floor( (spirit_amount+1) / 2 ) --1 summon for every 2 spirit stat
	spirit_amount = math.max(2, spirit_amount) --at least 2 summons, pls
	for i=1, spirit_amount do
		local offset = (0.2*i+1) - (0.2*spirit_amount)/2
		local summoning_delay = (delay * 33.3 * offset)
		stonehearth.combat:set_timer("SpiritWalkerClass summoning_delay: "..i, summoning_delay, function()
			self:create_spirit("swamp_goblins:summons:goblin_spirit", "copy")
		end)
	end
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

	radiant.effects.run_effect(spirit, "swamp_goblins:effects:spirit:poof")

	for _, subject_uri in ipairs(conversation_subjects) do
		local subjects = spirit:get_component('stonehearth:subject_matter')
		subjects:add_subject(subject_uri)
		subjects:add_override({
			subject = subject_uri,
			sentiment = 1
		})
	end
	spirit:add_component('swamp_goblins:summon')
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

function SpiritWalkerClass:spirit_armor(args)
	radiant.events.trigger_async(stonehearth.job, 'swamp_goblins:spirit_armor')
end

function SpiritWalkerClass:dragon_aura(args)
	radiant.events.trigger_async(stonehearth.job, 'swamp_goblins:spirit_walker_dragon_aura')
end

return SpiritWalkerClass