local LayEgg_spot = class()
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()

function LayEgg_spot:initialize()
	self._sv._use_state = "off" --off, waiting, has_egg
	self._sv._current_egg = nil
	self._sv._current_baby = nil
end

function LayEgg_spot:post_activate()
	if self._sv._use_state == "off" then
		self:enable_commands(true)
	else --waiting or has_egg
		self:enable_commands(false)
	end
	self.player_id = self._entity:get_player_id()

	if self._sv._current_egg then
		self._egg_listener = radiant.events.listen_once(self._sv._current_egg, 'stonehearth:on_evolved', function(e)
			self:egg_hatched(e.evolved_form)
			self._sv._current_egg = nil
			self._egg_listener = nil
			end)
	end
	if self._sv._current_baby then
		self._baby_listener = radiant.events.listen_once(self._sv._current_baby, 'stonehearth:on_evolved', function(e)
			local pop = stonehearth.population:get_population(self.player_id)
			pop:create_new_goblin_citizen_from_role_data(e.evolved_form)
			local job_component = e.evolved_form:add_component('stonehearth:job')
			job_component:promote_to("stonehearth:jobs:worker", { skip_visual_effects = true })
			self._sv._current_baby = nil
			self._baby_listener = nil
			end)
	end
end

function LayEgg_spot:enable_commands(enable)
	local commands_component = self._entity:get_component("stonehearth:commands")
	commands_component:set_command_enabled("swamp_goblins:commands:enable_egg_spot",enable)
	commands_component:set_command_enabled('stonehearth:commands:move_item',enable)
	commands_component:set_command_enabled('stonehearth:commands:undeploy_item',enable)
end

function LayEgg_spot:now_waiting()
	self:enable_commands(false)
	self._sv._use_state = "waiting" --someone lay an egg

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:create_egg()
	self:enable_commands(false)
	self._sv._use_state = "has_egg"
	local egg = radiant.entities.create_entity("swamp_goblins:goblins:egg", {owner = self.player_id})
	local location = radiant.entities.get_world_grid_location(self._entity)
	radiant.entities.turn_to(egg, rng:get_int(0,3)*90)
	radiant.terrain.place_entity_at_exact_location(egg, location +Point3.unit_y)
	radiant.effects.run_effect(egg, "stonehearth:effects:buff_tonic_energy_added")
	radiant.effects.run_effect(egg, "stonehearth:effects:fursplosion_effect")

	self._sv._current_egg = egg
	self._egg_listener = radiant.events.listen_once(egg, 'stonehearth:on_evolved', function(e)
		self:egg_hatched(e.evolved_form)
		self._sv._current_egg = nil
		self._egg_listener = nil
		end)

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:egg_hatched(baby)
	self:enable_commands(true)
	self._sv._use_state = "off"
	radiant.effects.run_effect(baby, "stonehearth:effects:buff_tonic_energy_added")

	self._sv._current_baby = baby
	self._baby_listener = radiant.events.listen_once(baby, 'stonehearth:on_evolved', function(e)
		local pop = stonehearth.population:get_population(self.player_id)
		pop:create_new_goblin_citizen_from_role_data(e.evolved_form)
		local job_component = e.evolved_form:add_component('stonehearth:job')
		job_component:promote_to("stonehearth:jobs:worker", { skip_visual_effects = true })
		self._sv._current_baby = nil
		self._baby_listener = nil
		end)

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:current_stage()
	return self._sv._use_state
end

return LayEgg_spot