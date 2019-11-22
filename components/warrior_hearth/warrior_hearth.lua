local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'

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

function WarriorHearth:_spawn_wave(level)
	self._sv.current_wave = {}
	local pop = stonehearth.population:get_population("warrior_hearth")
	local citizen_table = {
		from_population = {
			role = "default",
			min = level,
			max = level,
			range = 4,
			location = { x = 0, z = 0 }
		}, 
		tuning = "swamp_goblins:monster_tuning:warrior_hearth:goblin_spirit"
	}
	local origin = radiant.entities.get_world_grid_location(self._entity)

	local members = game_master_lib.create_citizens(pop, citizen_table, origin)
	for _, member in ipairs(members) do
		local effect = radiant.effects.run_effect(member, 'stonehearth:effects:spawn_entity')
		self._sv.current_wave[member:get_id()] = member
		radiant.events.listen(member, 'radiant:entity:pre_destroy', function()
			self:_on_wave_member_died(member)
		end)
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