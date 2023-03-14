local CombatJob = require 'stonehearth.jobs.combat_job'
local BeastTamerClass = class()
radiant.mixin(BeastTamerClass, CombatJob)
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
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
	self.summons = radiant.resources.load_json(self._job_json.summons)
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
	local uris, amount = self:get_summons_uris("summon_big_wolf")
	self:summon_animals(delay, uris, amount, true)
end

function BeastTamerClass:summon_dragon_aura(delay)
	local uris, amount = self:get_summons_uris("summon_dragon_aura")
	self:summon_animals(delay, uris, amount, true)
end

function BeastTamerClass:summon_firefly(delay, target)
	if not target then return end
	local location = radiant.entities.get_world_grid_location(target)
	if not location then return end

	local cube = Cube3(location):inflated(Point3(11, 6, 11))
	local all_entities = radiant.terrain.get_entities_in_cube(cube)
	local enemies = self:get_menacing_enemy_list_ascending(all_entities)
	local limit = radiant.entities.get_attribute(self._sv._entity, "mind") *2
	for _, entity in pairs(enemies) do
		radiant.entities.add_buff(entity, "swamp_goblins:buffs:firefly_confusion")
		limit = limit -1
		if limit <1 then
			break
		end
	end
end

function BeastTamerClass:summon_varanus(delay)
	local uris, amount = self:get_summons_uris("summon_varanus")
	self:summon_animals(delay, uris, amount)
end

function BeastTamerClass:get_menacing_enemy_list_ascending(all_entities)
	--return a list of enemies in order of low to high menace
	local enemies = {}
	local not_menacing = {}
	for _, enemy in pairs(all_entities) do
		local is_hostile = stonehearth.player:are_entities_hostile(enemy, self._sv._entity)
		if is_hostile and radiant.entities.has_free_will(enemy) then
			if radiant.entities.get_attribute(enemy, "menace")>1 then
				table.insert(enemies, enemy)
			else
				table.insert(not_menacing, enemy)
			end
		end
	end
	table.sort(enemies, function(a, b)
		return radiant.entities.get_attribute(a, "menace") < radiant.entities.get_attribute(b, "menace")
	end)
	if #enemies < 1 then
		--no menacing enemies? ok, grab the rest
		enemies = not_menacing
	end
	return enemies
end

function BeastTamerClass:summon_traps(delay, target)
	if not target then return end
	local location = radiant.entities.get_world_grid_location(target)
	if not location then return end

	local cube = Cube3(location):inflated(Point3(11, 6, 11))
	local all_entities = radiant.terrain.get_entities_in_cube(cube)
	local enemies = self:get_menacing_enemy_list_ascending(all_entities)
	local limit = radiant.entities.get_attribute(self._sv._entity, "mind")
	for _, entity in ipairs(enemies) do
		radiant.entities.add_buff(entity, "swamp_goblins:buffs:trapped")
		limit = limit -1
		if limit <1 then
			break
		end
	end
end

function BeastTamerClass:summon_wildlife(delay)
	local uris, amount = self:get_summons_uris("summon_wildlife")
	self:summon_animals(delay, uris, amount)
end

function BeastTamerClass:summon_poyos(delay)
	local uris, amount = self:get_summons_uris("summon_poyos")
	self:summon_animals(delay, uris, amount)
end

function BeastTamerClass:get_summons_uris(category)
	local uris = {}
	local amount = self.summons[category].quantity
	for entity, active in pairs(self.summons[category].entities) do
		if active then
			table.insert(uris, entity)
		end
	end
	return uris, amount
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

	local animal = radiant.entities.create_entity(url, {owner = player_id})
	if not has_attributes then
		self:copy_menace(animal)
	end
	local location = radiant.terrain.find_placement_point(entity_location, 3, 5, self._sv._entity, nil, true)
	radiant.terrain.place_entity_at_exact_location(animal, location)

	radiant.effects.run_effect(animal, "stonehearth:effects:spawn_entity")

	animal:add_component('swamp_goblins:summon')
end

function BeastTamerClass:copy_menace(animal)
	radiant.entities.set_attribute(animal, "menace", radiant.entities.get_attribute(self._sv._entity, "menace") +1)
	radiant.entities.set_attribute(animal, "courage", radiant.entities.get_attribute(self._sv._entity, "courage") +1)
end

return BeastTamerClass