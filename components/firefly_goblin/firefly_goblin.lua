local FireflyGoblin = class()

local VERSIONS = {
	ZERO = 0
}

function FireflyGoblin:get_version()
	return VERSIONS.ZERO
end

function FireflyGoblin:fixup_post_load(old_save_data)
	if old_save_data.version < VERSIONS.ZERO then

	end
end

function FireflyGoblin:post_activate()
	self.paused_goblin = stonehearth.ai:inject_ai(self._entity, { actions = { 'stonehearth:actions:be_away_from_town' } })
	self._delay_start_timer = radiant.on_game_loop_once('FireflyGoblin post post_activate', function()
		if not radiant.entities.exists(self._entity) then
			return
		end
		self:update_job_list()
		self:add_goblin_race_abilities()
		self:add_goblin_jobs_abilities()

		if self.paused_goblin then
			self.paused_goblin:destroy()
			self.paused_goblin = nil
		end
	end)
end

function FireflyGoblin:update_job_list()
	local player_id = radiant.entities.get_player_id(self._entity)
	local job_index = stonehearth.player:get_jobs(player_id)
	local job_list = {}
	for alias,data in pairs(job_index) do
		if data.firefly_job then
			job_list[alias] = true
		end
	end
	local job_comp = self._entity:get_component("stonehearth:job")
	local allowed_jobs = job_comp:get_allowed_jobs()
	if allowed_jobs then
		for alias,value in pairs(allowed_jobs) do
			job_list[alias] = value
		end
	end
	job_comp:set_allowed_jobs(job_list)
end

function FireflyGoblin:add_goblin_race_abilities()
	self:fix_traits()
end

function FireflyGoblin:fix_traits()
	local trait_comp = self._entity:get_component("stonehearth:traits")
	if not trait_comp then
		return
	end
	local traits_to_remove = {
		"stonehearth:traits:animal_companion",
		"stonehearth:traits:cultist",
		"stonehearth:traits:jokester",
		"stonehearth:traits:magnificent_beard",
		"stonehearth:traits:passion_archer",
		"stonehearth:traits:passion_blacksmith",
		"stonehearth:traits:passion_carpenter",
		"stonehearth:traits:passion_cleric",
		"stonehearth:traits:passion_cook",
		"stonehearth:traits:passion_engineer",
		"stonehearth:traits:passion_farmer",
		"stonehearth:traits:passion_footman",
		"stonehearth:traits:passion_herbalist",
		"stonehearth:traits:passion_knight",
		"stonehearth:traits:passion_mason",
		"stonehearth:traits:passion_potter",
		"stonehearth:traits:passion_shepherd",
		"stonehearth:traits:passion_weaver",
		
		"kmnky_traits:traits:barbarian",
		"kmnky_traits:traits:divine_soul",
		"kmnky_traits:traits:goblin",
		"kmnky_traits:traits:noble",
		"kmnky_traits:traits:pacifist",
		"kmnky_traits:traits:scarred",
		"kmnky_traits:traits:wizened",
	}
	for _, trait in pairs(traits_to_remove) do
		if trait_comp:has_trait(trait) then
			trait_comp:remove_trait(trait)
		end
	end
	if next(trait_comp:get_traits()) == nil then
		trait_comp:add_trait("swamp_goblins:traits:frog_companion")
	end
end

function FireflyGoblin:add_goblin_jobs_abilities()
	self:_remove_goblin_listeners()

	local job_comp = self._entity:get_component("stonehearth:job")
	local job = job_comp:get_job_uri()
	if job == "stonehearth:jobs:worker" then
		self:add_goblin_worker_abilities()
	end

	self.job_has_changed = radiant.events.listen_once(self._entity, 'stonehearth:job_changed', self, self.add_goblin_jobs_abilities)
end

function FireflyGoblin:add_goblin_worker_abilities()
	local equipment = "swamp_goblins:worker:abilities:goblin"
	radiant.entities.equip_item(self._entity, equipment)
	equipment = "/swamp_goblins/jobs/worker/worker_outfit/goblin_worker_outfit.json"
	radiant.entities.equip_item(self._entity, equipment)
	equipment = "swamp_goblins:weapons:crude_wooden_club"
	radiant.entities.equip_item(self._entity, equipment)

	local job_comp = self._entity:get_component("stonehearth:job")
	local roles = {
		goblin_worker_job = true,
		hunter = true,
		melee_combat = true,
		combat = true,
	}
	job_comp._roles = roles
	stonehearth.combat:set_stance(self._entity, "aggressive")

	local job_controller = job_comp:get_curr_job_controller()
	job_controller._sv.is_combat_class = true
	job_controller.__saved_variables:mark_changed()

	local job_info = job_comp:get_job_info()
	job_info._sv.is_combat_job = true
	job_info._sv.roles["combat"] = true
	job_info.__saved_variables:mark_changed()

	local player_id = radiant.entities.get_player_id(self._entity)
	local population = stonehearth.population:get_population(player_id)
	local curr_party = stonehearth.unit_control:get_party_for_entity_command({}, {}, self._entity)
	if not curr_party then
		--get the red party
		curr_party = population:get_party_by_name('party_4')
		if curr_party then -- npcs might not have party
			local party_component = curr_party:get_component('stonehearth:party')
			if party_component then
				party_component:add_member(self._entity)
			end
		end
	end

	self.waiting_for_combat_listener = radiant.events.listen(self._entity, 'stonehearth:combat:primary_target_changed', self, self.primary_target_changed)
end

function FireflyGoblin:primary_target_changed()
	local target = stonehearth.combat:get_primary_target(self._entity)
	local equipment = "swamp_goblins:worker:abilities:hunter"
	if target and target:get_player_id() == "animals" then
		radiant.entities.equip_item(self._entity, equipment)
	else
		radiant.entities.unequip_item(self._entity, equipment)
	end
end

function FireflyGoblin:_remove_goblin_listeners()
	if self.waiting_for_combat_listener then
		self.waiting_for_combat_listener:destroy()
		self.waiting_for_combat_listener = nil
	end
	if self.job_has_changed then
		self.job_has_changed:destroy()
		self.job_has_changed = nil
	end
end

function FireflyGoblin:destroy()
	self:_remove_goblin_listeners()
end

return FireflyGoblin