local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

local ALLIES_AMOUNT = 4

local ShrineTallComponent = class()

function ShrineTallComponent:initialize()
	self._sv._can_summon_fighters = false
	self._sv._can_summon_workers = false
	self._sv._fighters_timer = nil
	self._sv._workers_timer = nil
	self._sv._fighters_list = nil
	self._sv._workers_list = nil
end

function ShrineTallComponent:create()
	self._sv._can_summon_fighters = true
	self._sv._can_summon_workers = true
	self._sv._fighters_list = {}
	self._sv._workers_list = {}
end

function ShrineTallComponent:post_activate()
	self.player_id = self._entity:get_player_id()
	self.summons_json = radiant.resources.load_json("swamp_goblins:monster_tuning:shrine:summon_allies", true, false)
	self:update_buttons()
end

function ShrineTallComponent:destroy()
	if self._sv._fighters_timer then
		self._sv._fighters_timer:destroy()
		self._sv._fighters_timer = nil
	end
	if self._sv._workers_timer then
		self._sv._workers_timer:destroy()
		self._sv._workers_timer = nil
	end
end

function ShrineTallComponent:update_buttons()
	local commands_component = self._entity:get_component("stonehearth:commands")
	if self._sv._can_summon_fighters then
		commands_component:set_command_enabled('swamp_goblins:commands:shrine:summon_allied_fighters',true)
	else
		commands_component:set_command_enabled('swamp_goblins:commands:shrine:summon_allied_fighters',false)
	end
	if self._sv._can_summon_workers then
		commands_component:set_command_enabled('swamp_goblins:commands:shrine:summon_allied_workers',true)
	else
		commands_component:set_command_enabled('swamp_goblins:commands:shrine:summon_allied_workers',false)
	end
end

function ShrineTallComponent:summon_allied_fighters()
	self._sv._can_summon_fighters = false
	self:update_buttons()
	self._sv._fighters_timer = stonehearth.calendar:set_persistent_timer('summon fighters cooldown', '12h', radiant.bind(self, 'end_fighters_cooldown'))

	self:summon_entities_of_type("fighters")
end

function ShrineTallComponent:end_fighters_cooldown()
	self._sv._can_summon_fighters = true
	self:update_buttons()

	self:despawn_entities_of_type("fighters")
end

function ShrineTallComponent:summon_allied_workers()
	self._sv._can_summon_workers = false
	self:update_buttons()
	self._sv._workers_timer = stonehearth.calendar:set_persistent_timer('summon workers cooldown', '12h', radiant.bind(self, 'end_workers_cooldown'))

	self:summon_entities_of_type("workers")
end

function ShrineTallComponent:end_workers_cooldown()
	self._sv._can_summon_workers = true
	self:update_buttons()

	self:despawn_entities_of_type("workers")
end

function ShrineTallComponent:despawn_entities_of_type(type)
	local function destroy_entity( ally )
		local proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'running death effect' })
		local location = radiant.entities.get_world_grid_location(ally)
		radiant.terrain.place_entity(proxy, location)
		local effect = radiant.effects.run_effect(proxy, "stonehearth:effects:spawn_entity")
		effect:set_finished_cb(function()
			radiant.entities.destroy_entity(proxy)
			effect:set_finished_cb(nil)
			effect = nil
		end)

		local equipment_component = ally:get_component("stonehearth:equipment")
		equipment_component:drop_unsuitable_equipment({["all"] = true})

		radiant.entities.destroy_entity( ally )
	end
	if type == "fighters" then
		for i = 1, ALLIES_AMOUNT do
			destroy_entity( table.remove(self._sv._fighters_list) )
		end
	else
		for i = 1, ALLIES_AMOUNT do
			destroy_entity( table.remove(self._sv._workers_list) )
		end
	end
end

function ShrineTallComponent:summon_entities_of_type(type)
	local location = radiant.entities.get_world_grid_location(self._entity)
	local weighted_set = WeightedSet(rng)

	for _, type_data in pairs(self.summons_json[type]) do
		weighted_set:add(type_data, type_data.weight or 1)
	end
	for i=1, ALLIES_AMOUNT do
		local data = weighted_set:choose_random()
		local ally = self:create_new_foreign_citizen(data.population, data.role)

		local job_weighted_set = WeightedSet(rng)
		for job_alias, enabled in pairs(data.jobs or {}) do
			if enabled then
				job_weighted_set:add(job_alias, 1)
			end
		end
		local allowed_jobs = {["stonehearth:jobs:worker"] = true}
		local job_picked = job_weighted_set:choose_random() or "stonehearth:jobs:worker"
		allowed_jobs[job_picked] = true
		local job_component = ally:add_component('stonehearth:job')
		job_component:set_allowed_jobs(allowed_jobs)
		job_component:promote_to(job_picked, { skip_visual_effects = true })
		if job_picked ~= "stonehearth:jobs:worker" then
			for i=1, rng:get_int(1, 5) do
				job_component:level_up(true)
			end
		end

		local new_location = radiant.terrain.find_placement_point(location, 3, 5, ally)
		radiant.terrain.place_entity(ally, new_location)
		radiant.effects.run_effect(ally, "stonehearth:effects:spawn_entity")

		if type == "fighters" then
			table.insert(self._sv._fighters_list, ally)
		else
			table.insert(self._sv._workers_list, ally)
		end
	end
end

function ShrineTallComponent:create_new_foreign_citizen(foreign_population_uri, role)
	role = role or 'default'
	local foreign_pop_json = radiant.resources.load_json(foreign_population_uri)
	local role_data = foreign_pop_json.roles[role]
	if not role_data then
		error(string.format('unknown role %s in population %s', role, foreign_population_uri))
	end
	return self:create_new_citizen_from_role_data(role, role_data)
end

function ShrineTallComponent:create_new_citizen_from_role_data(role, role_data)
	local options = {}
	local gender = "female"
	if (not role_data[gender]) or (rng:get_int(1,2) == 2) then
		gender="male"
	end

	local citizen = self:_generate_citizen_from_role(role, role_data, gender)

	radiant.entities.set_custom_name(citizen, "i18n(swamp_goblins:data.monster_tuning.shrine.ally)")
	local cc = citizen:get_component('stonehearth:customization')
	if cc then
		cc:generate_custom_appearance()
	end

	return citizen
end

function ShrineTallComponent:_generate_citizen_from_role(role, role_data, gender)
	local entities = role_data[gender].uri
	if role_data[gender].uri_pc then
		entities = role_data[gender].uri_pc
	end
	if not entities then
		error(string.format('role %s in population has no gender table for %s', role, gender))
	end

	local uri = entities[rng:get_int(1, #entities)]
	return radiant.entities.create_entity(uri, { owner = self.player_id })
end

return ShrineTallComponent