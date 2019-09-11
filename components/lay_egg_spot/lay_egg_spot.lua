local LayEgg_spot = class()
local Point3 = _radiant.csg.Point3
local rng = _radiant.math.get_default_rng()

function LayEgg_spot:initialize()
	self._sv._use_state = "off" --off, waiting, has_egg
	self._sv._current_egg = nil
	self._sv._current_baby = nil
	self._sv._task_effect = nil
end

function LayEgg_spot:post_activate()
	self.player_id = self._entity:get_player_id()

	if self._sv._use_state == "off" then
		self:enable_commands(true)
	else --waiting or has_egg
		self:enable_commands(false)
		if self._sv._use_state == "waiting" then
			self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:egg_pedestal", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })
		end
	end

	if self._sv._current_egg then
		self._egg_listener = radiant.events.listen_once(self._sv._current_egg, 'stonehearth:on_evolved', function(e)
			self:egg_hatched(e.evolved_form)
			self._sv._current_egg = nil
			self._egg_listener = nil
		end)
		self._kill_listener = radiant.events.listen_once(self._sv._current_egg, 'stonehearth:kill_event', function(e)
			self:egg_killed()
			self._sv._current_egg = nil
			self._kill_listener = nil
		end)
	end
	if self._sv._current_baby then
		self._baby_listener = radiant.events.listen_once(self._sv._current_baby, 'stonehearth:on_evolved', function(e)
			self:grow_into_adult(e.evolved_form)
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
	self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:egg_pedestal", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:create_egg()
	self:enable_commands(false)
	self._sv._use_state = "has_egg"
	local egg = radiant.entities.create_entity("swamp_goblins:goblins:egg", {owner = self.player_id})
	local location = radiant.entities.get_world_grid_location(self._entity)
	radiant.entities.turn_to(egg, rng:get_int(0,3)*90)
	radiant.terrain.place_entity_at_exact_location(egg, location +Point3.unit_y)

	local inventory = stonehearth.inventory:get_inventory(self.player_id)
	if inventory then
		inventory:add_item_if_not_full(egg)
	end

	radiant.effects.run_effect(egg, "stonehearth:effects:buff_tonic_energy_added")
	radiant.effects.run_effect(egg, "stonehearth:effects:fursplosion_effect")
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end

	self._sv._current_egg = egg
	self._egg_listener = radiant.events.listen_once(egg, 'stonehearth:on_evolved', function(e)
		self:egg_hatched(e.evolved_form)
		self._sv._current_egg = nil
		self._egg_listener = nil
	end)
	self._kill_listener = radiant.events.listen_once(egg, 'stonehearth:kill_event', function(e)
		self:egg_killed()
		self._sv._current_egg = nil
		self._kill_listener = nil
	end)

	stonehearth.ai:reconsider_entity(self._entity)

	self:trigger_raid_toward_the_egg(egg)
end

function LayEgg_spot:egg_hatched(baby)
	self:enable_commands(true)
	self._sv._use_state = "off"
	radiant.effects.run_effect(baby, "stonehearth:effects:buff_tonic_energy_added")

	self._sv._current_baby = baby
	self._baby_listener = radiant.events.listen_once(baby, 'stonehearth:on_evolved', function(e)
		self:grow_into_adult(e.evolved_form)
	end)

	local inventory = stonehearth.inventory:get_inventory(self.player_id)
	if inventory then
		inventory:add_item_if_not_full(baby)
	end

	stonehearth.bulletin_board:post_bulletin(self.player_id)
	:set_data({
		zoom_to_entity = baby,
		title = "i18n(swamp_goblins:ui.data.new_goblin_baby)"
	})

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:grow_into_adult(adult)
	local pop = stonehearth.population:get_population(self.player_id)
	pop:create_new_goblin_citizen_from_role_data(adult)
	local job_component = adult:add_component('stonehearth:job')
	job_component:promote_to("stonehearth:jobs:worker", { skip_visual_effects = true })
	self._sv._current_baby = nil
	self._baby_listener = nil
	stonehearth.bulletin_board:post_bulletin(self.player_id)
	:set_data({
		zoom_to_entity = adult,
		title = "i18n(swamp_goblins:ui.data.new_goblin_citizen)"
	})
	:add_i18n_data('adult_name', radiant.entities.get_custom_name(adult))
end

function LayEgg_spot:egg_killed()
	self:enable_commands(true)
	self._sv._use_state = "off"

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:current_stage()
	return self._sv._use_state
end

function LayEgg_spot:trigger_raid_toward_the_egg(egg)
	if stonehearth.game_creation:get_game_mode() == "stonehearth:game_mode:peaceful" then
		return
	end

	self._searcher = radiant.create_controller('stonehearth:game_master:util:choose_location_outside_town',
		16, 100,
		function(op, location)
			return self:_find_location_callback(op, location)
		end)

	self.timer = stonehearth.calendar:set_timer('preparing egg raid', "30m+1h", function()
		self:_spawn(self.doodle_spawn_location)
		self.timer = nil
	end)
	self.timer2 = stonehearth.calendar:set_timer('preparing egg raid', "8h+1h", function()
		self:_spawn(self.doodle_spawn_location)
		self.timer2 = nil
	end)
	self.timer3 = stonehearth.calendar:set_timer('preparing egg raid', "16h+1h", function()
		self:_spawn(self.doodle_spawn_location)
		self.timer3 = nil
	end)
end

function LayEgg_spot:_spawn(location)
	if not self._sv._current_egg or not location then
		return
	end
	local enemy
	for i=1, stonehearth.population:get_population_size(self.player_id) do
		enemy = radiant.entities.create_entity('swamp_goblins:monsters:doodles_egg_raider', {owner = "forest"})
		location = radiant.terrain.find_placement_point(location, 1, 8, enemy)
		radiant.terrain.place_entity(enemy, location)
		radiant.entities.add_buff(enemy, 'stonehearth:buffs:despawn:after_day')

		enemy:get_component('stonehearth:ai')
		:get_task_group('stonehearth:task_groups:solo:combat_unit_control')
		:create_task('stonehearth:goto_location_ignoring_threats', {
			location = radiant.entities.get_world_grid_location(self._entity),
			reason = "go direct to the egg first, then attack it and/or around it"
			})
		:once()
		:start()
	end

	stonehearth.bulletin_board:post_bulletin(self.player_id)
	:set_type('alert')
	:set_data({
		zoom_to_entity = enemy,
		title = "i18n(swamp_goblins:ui.data.raid_egg)"
	})
end

function LayEgg_spot:_find_location_callback(op, location)
	if op == 'check_location' then
		return true
	elseif op == 'set_location' then
		self.doodle_spawn_location = location

		if self._searcher then
			self._searcher:destroy()
			self._searcher = nil
		end
	else
		radiant.error('op "%s" in LayEgg_spot _find_location_callback', op)
	end
end

function LayEgg_spot:destroy()
	if self._searcher then
		self._searcher:destroy()
		self._searcher = nil
	end
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end
end



return LayEgg_spot