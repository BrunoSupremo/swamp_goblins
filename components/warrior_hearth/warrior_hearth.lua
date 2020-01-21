local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

local WarriorHearth = class()

function WarriorHearth:initialize()
	self._sv.glory_level = 1
	self._sv.current_wave = nil  -- When a wave is in progress, a table of wave members still alive, keyed by their entity ID.

	self.current_wave_abandoned = false
end

function WarriorHearth:create()
	self._entity:get_component('stonehearth:commands'):remove_command('stonehearth:commands:spawn_glory_wave')
	self._entity:get_component('stonehearth:commands'):remove_command('stonehearth:commands:abandon_glory_wave')
end

function WarriorHearth:activate()
	if self._sv.current_wave then
		for _, member in pairs(self._sv.current_wave) do
			radiant.events.listen(member, 'radiant:entity:pre_destroy', function()
				self:_on_wave_member_died(member)
			end)
		end
		self._entity:get_component('stonehearth:commands'):remove_command('swamp_goblins:commands:glory_wave:spawn')
		self._entity:get_component('stonehearth:commands'):add_command('swamp_goblins:commands:glory_wave:abandon')
	else
		self._entity:get_component('stonehearth:commands'):remove_command('swamp_goblins:commands:glory_wave:abandon')
		self._entity:get_component('stonehearth:commands'):add_command('swamp_goblins:commands:glory_wave:spawn')
	end

	self.waves_json = radiant.resources.load_json("swamp_goblins:monster_tuning:warrior_hearth:waves", true, false)
end

-- Returns whether a wave was summoned (i.e. another isn't in progress, and there are more levels to go).
function WarriorHearth:spawn_next_wave()
	if self._sv.current_wave then
		return false  -- Wave already in progress
	end

	self._entity:get_component('stonehearth:commands'):remove_command('swamp_goblins:commands:glory_wave:spawn')
	self._entity:get_component('stonehearth:commands'):add_command('swamp_goblins:commands:glory_wave:abandon')

	-- Spawn the wave combo.
	self:_spawn_wave(self._sv.glory_level)

	self.current_wave_abandoned = false

	return true
end

function WarriorHearth:abandon_current_wave()
	if not self._sv.current_wave then
		return false
	end

	self.current_wave_abandoned = true

	for _, member in pairs(self._sv.current_wave) do
		if member:is_valid() then
			local proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'running death effect' })
			local location = radiant.entities.get_world_grid_location(member)
			radiant.terrain.place_entity(proxy, location)

			local effect = radiant.effects.run_effect(proxy, "stonehearth:effects:spawn_entity")
			effect:set_finished_cb(function()
				radiant.entities.destroy_entity(proxy)
				effect:set_finished_cb(nil)
				effect = nil
			end)

			radiant.entities.destroy_entity(member)
		end
	end
end

function WarriorHearth:_pick_a_wave(level)
	local weighted_set = WeightedSet(rng)
	for wave, info in pairs(self.waves_json) do
		local min = info.at_glory_level and info.at_glory_level.min or 1
		local max = info.at_glory_level and info.at_glory_level.max or 9999
		if level >= min and level <= max then
			weighted_set:add(info, info.weight)
		end
	end
	return weighted_set:choose_random()
end

function WarriorHearth:_pick_members(wave, level)
	local weighted_set = WeightedSet(rng)
	for key, value in pairs(wave.members) do
		weighted_set:add(key, value.weight)
	end
	local members = {}
	for i=1,level do
		local chosen = weighted_set:choose_random()
		if not chosen then break end
		if members[chosen] then
			members[chosen] = members[chosen]+1
		else
			members[chosen] = 1
		end
		local max = wave.members[chosen].max_allowed or 9999
		if members[chosen] >= max then
			weighted_set:remove(chosen)
		end
	end
	return members
end

function WarriorHearth:_spawn_wave(level)
	radiant.effects.run_effect(self._entity, 'stonehearth:effects:glory_wave_spawn')

	self._sv.current_wave = {}
	local origin = radiant.entities.get_world_grid_location(self._entity)
	local pop = stonehearth.population:get_population("warrior_hearth")
	local wave = self:_pick_a_wave(level)
	local members_keys = self:_pick_members(wave, level)

	for key, quantity in pairs(members_keys) do
		local citizen_table = {
			from_population = {
				role = wave.members[key].role,
				min = quantity,
				max = quantity,
				range = 4,
				location = { x = 0, z = 0 }
			},
			combat_leash_range = 32,
			tuning = wave.members[key].tuning
		}

		local members = game_master_lib.create_citizens(pop, citizen_table, origin)
		for _, member in ipairs(members) do
			member:remove_component("stonehearth:traits")
			member:add_component("stonehearth:trivial_death")
			local ai = member:get_component("stonehearth:ai")
			ai:remove_action("stonehearth:actions:die_citizen")
			ai:add_action("stonehearth:actions:die_generic")

			radiant.entities.add_buff(member, "stonehearth:buffs:combat_basics")
			radiant.effects.run_effect(member, 'stonehearth:effects:spawn_entity')
			self._sv.current_wave[member:get_id()] = member
			radiant.events.listen(member, 'radiant:entity:pre_destroy', function()
				self:_on_wave_member_died(member)
			end)
		end
	end
end

function WarriorHearth:_on_wave_member_died(entity)
	if self._sv.current_wave[entity:get_id()] then
		self._sv.current_wave[entity:get_id()] = nil
	end

	if self._sv.current_wave and not next(self._sv.current_wave) then
		-- Everyone defeated! Go to next level.
		if not self.current_wave_abandoned then
			self._sv.glory_level = self._sv.glory_level + 1

			stonehearth.bulletin_board:post_bulletin(radiant.entities.get_player_id(self._entity))
			:set_data({title = "i18n(stonehearth:data.commands.spawn_glory_wave.glory_level_achieved_bulletin)"})
			:add_i18n_data("glory_level", self._sv.glory_level)
			:set_close_on_handle(true)
			:set_active_duration("2h")
		end
		self._sv.current_wave = nil
		self._entity:get_component('stonehearth:commands'):remove_command('swamp_goblins:commands:glory_wave:abandon')
		self._entity:get_component('stonehearth:commands'):add_command('swamp_goblins:commands:glory_wave:spawn')
	end
end

return WarriorHearth