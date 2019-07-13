local CombatJob = require 'stonehearth.jobs.combat_job'
local BeastTamerClass = class()
radiant.mixin(BeastTamerClass, CombatJob)
local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3
local rng = _radiant.math.get_default_rng()

function BeastTamerClass:dragon_aura_equip()
	local render_info = self._sv._entity:add_component('render_info')
	local model = render_info:get_model_variant()
	if model ~= "firefly_goblin" then
		return
	end
	local player_id = radiant.entities.get_player_id(self._sv._entity)
	local job = stonehearth.job:get_job_info(player_id, "swamp_goblins:jobs:spirit_walker")
	if job:get_highest_level() >=6 then
		self:spirit_walker_dragon_aura()
	else
		self.spirit_listener = radiant.events.listen_once(stonehearth.job, 'swamp_goblins:spirit_walker_dragon_aura', self, self.spirit_walker_dragon_aura)
	end
end

function BeastTamerClass:big_wolf_equip()
	local render_info = self._sv._entity:add_component('render_info')
	local model = render_info:get_model_variant()
	if model == "firefly_goblin" then
		return
	end
	local equipment_component = self._sv._entity:get_component("stonehearth:equipment")
	if not equipment_component:has_item_type("swamp_goblins:beast_tamer:abilities:summon_big_wolf") then
		local equipment = radiant.entities.create_entity("swamp_goblins:beast_tamer:abilities:summon_big_wolf")
		radiant.entities.equip_item(self._sv._entity, equipment)
	end
end

function BeastTamerClass:_create_listeners()
	CombatJob._create_listeners(self)
	
end

function BeastTamerClass:spirit_walker_dragon_aura()
	local equipment_component = self._sv._entity:get_component("stonehearth:equipment")
	if not equipment_component:has_item_type("swamp_goblins:beast_tamer:abilities:summon_dragon_aura") then
		local equipment = radiant.entities.create_entity("swamp_goblins:beast_tamer:abilities:summon_dragon_aura")
		radiant.entities.equip_item(self._sv._entity, equipment)
	end
	self:_remove_spirit_listener()
end

function BeastTamerClass:_remove_spirit_listener()
	if self.spirit_listener then
		self.spirit_listener:destroy()
		self.spirit_listener = nil
	end
end

function BeastTamerClass:_remove_listeners()
	CombatJob._remove_listeners(self)
	self:_remove_spirit_listener()
end

function BeastTamerClass:summon_big_wolf(delay)
	local uris = {"swamp_goblins:summons:big_wolf"}
	self:summon_animals(delay, uris, 1, true)
end

function BeastTamerClass:summon_dragon_aura(delay)
	local uris = {"swamp_goblins:summons:dragon_aura"}
	self:summon_animals(delay, uris, 1, true)
end

function BeastTamerClass:summon_firefly(delay, target)
	if not target then return end
	local location = radiant.entities.get_world_grid_location(target)
	if not location then return end

	local region = Region3()
	region:add_point(location)
	region = region:inflated(Point3(11,11,11))
	local entities = radiant.terrain.get_entities_in_region(region)
	for _, entity in pairs(entities) do
		local is_hostile = stonehearth.player:are_entities_hostile(entity, self._sv._entity)
		if is_hostile and radiant.entities.has_free_will(entity) then
			radiant.entities.add_buff(entity, "swamp_goblins:buffs:firefly_confusion")
		end
	end
end

function BeastTamerClass:summon_varanus(delay)
	local uris = {"swamp_goblins:summons:varanus"}
	self:summon_animals(delay, uris, 2)
end

function BeastTamerClass:summon_traps(delay, target)
	if not target then return end
	local location = radiant.entities.get_world_grid_location(target)
	if not location then return end

	local region = Region3()
	region:add_point(location)
	region = region:inflated(Point3(10,10,10))
	local entities = radiant.terrain.get_entities_in_region(region)
	local limit = radiant.entities.get_attribute(self._sv._entity, "mind")
	for _, entity in pairs(entities) do
		local is_hostile = stonehearth.player:are_entities_hostile(entity, self._sv._entity)
		if is_hostile and radiant.entities.has_free_will(entity) then
			radiant.entities.add_buff(entity, "swamp_goblins:buffs:trapped")
			limit = limit -1
			if limit <1 then
				break
			end
		end
	end
end

function BeastTamerClass:summon_wildlife(delay)
	local uris = {
		"swamp_goblins:summons:frog",
		"swamp_goblins:summons:beetle",
		"swamp_goblins:summons:bitsy_ant",
		"swamp_goblins:summons:doodles",
		"swamp_goblins:summons:rabbit",
		"swamp_goblins:summons:racoon",
		"swamp_goblins:summons:red_fox_wolf",
		"swamp_goblins:summons:squirrel"
	}
	self:summon_animals(delay, uris, 6)
end

function BeastTamerClass:summon_poyos(delay)
	local uris = {"swamp_goblins:summons:poyo"}
	self:summon_animals(delay, uris, 4)
end

function BeastTamerClass:summon_animals(delay, uris, amount, has_attributes)
	for i=1, amount do
		local uri = uris and uris[rng:get_int(1,#uris)]
		local offset = (0.1*i+1) - (0.1*amount)/2
		local summoning_delay = (delay * 33.3 * offset)
		stonehearth.combat:set_timer("BeastTamerClass summoning_delay: "..i, summoning_delay, function()
			self:create_animal(uri, has_attributes)
		end)
	end
end

function BeastTamerClass:create_animal(url, has_attributes)
	local entity_location = radiant.entities.get_world_location(self._sv._entity)
	local player_id = radiant.entities.get_player_id(self._sv._entity)

	local x, z = entity_location.x, entity_location.z
	local dir = radiant.math.random_xz_unit_vector()
	dir:scale(5)

	local location = radiant.terrain.get_point_on_terrain(Point3(dir.x + x, 1, dir.z + z))
	local animal = radiant.entities.create_entity(url, {owner = player_id})
	if not has_attributes then
		self:copy_menace(animal)
	end
	radiant.terrain.place_entity_at_exact_location(animal, location)

	radiant.effects.run_effect(animal, "stonehearth:effects:spawn_entity")

	radiant.entities.add_buff(animal, "swamp_goblins:buffs:despawn:in_2h")
end

function BeastTamerClass:copy_menace(animal)
	radiant.entities.set_attribute(animal, "menace", radiant.entities.get_attribute(self._sv._entity, "menace") +1)
	radiant.entities.set_attribute(animal, "courage", radiant.entities.get_attribute(self._sv._entity, "courage") +1)
end

return BeastTamerClass