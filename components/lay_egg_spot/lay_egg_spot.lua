local LayEgg_spot = class()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local Point3 = _radiant.csg.Point3
local Point2 = _radiant.csg.Point2
local rng = _radiant.math.get_default_rng()

function LayEgg_spot:initialize()
	self._sv._use_state = "off" --off, waiting, has_egg
	self._sv._current_egg = nil
	self._sv._current_baby = nil
	self._sv._task_effect = nil
end

function LayEgg_spot:post_activate()
	self.player_id = self._entity:get_player_id()

	self:update_commands()
	if self._sv._use_state == "waiting" then
		self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:egg_pedestal", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })
	end

	if self._sv._current_egg then
		self._egg_listener = radiant.events.listen_once(self._sv._current_egg, 'stonehearth:on_evolved', function(e)
			self:egg_hatched(e.evolved_form)
			self._sv._current_egg = nil
			self._egg_listener = nil
		end)
		self._kill_listener = radiant.events.listen_once(self._sv._current_egg, 'stonehearth:kill_event', function(e)
			self:reset_pedestal()
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

function LayEgg_spot:update_commands()
	local commands_component = self._entity:get_component("stonehearth:commands")
	if self._sv._use_state == "off" then
		commands_component:set_command_enabled('stonehearth:commands:move_item',true)
		commands_component:set_command_enabled('stonehearth:commands:undeploy_item',true)
		commands_component:add_command("swamp_goblins:commands:enable_egg_spot")
		commands_component:remove_command("swamp_goblins:commands:cancel_egg_spot")
	else
		commands_component:set_command_enabled('stonehearth:commands:move_item',false)
		commands_component:set_command_enabled('stonehearth:commands:undeploy_item',false)
		commands_component:remove_command("swamp_goblins:commands:enable_egg_spot")

		if self._sv._use_state == "waiting" then
			commands_component:add_command("swamp_goblins:commands:cancel_egg_spot")
		else --"has_egg"
			commands_component:remove_command("swamp_goblins:commands:cancel_egg_spot")
		end
	end
end

function LayEgg_spot:cancel_egg()
	radiant.events.trigger(self._entity, 'swamp_goblins:lay_egg:cancel')
	self:reset_pedestal()
end

function LayEgg_spot:now_waiting()
	self._sv._use_state = "waiting" --someone to lay an egg
	self:update_commands()
	self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:egg_pedestal", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:create_egg()
	self._sv._use_state = "has_egg"
	self:update_commands()
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
		self:reset_pedestal()
		self._sv._current_egg = nil
		self._kill_listener = nil
	end)

	stonehearth.ai:reconsider_entity(self._entity)

	self:trigger_raid_toward_the_egg(egg)
end

function LayEgg_spot:egg_hatched(baby)
	self:reset_pedestal()
	radiant.effects.run_effect(baby, "stonehearth:effects:buff_tonic_energy_added")

	-- local pop = stonehearth.population:get_population(self.player_id)
	-- pop:set_baby(baby)
	-- if we end up showing it on character list, players "can" change its job...

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

function LayEgg_spot:reset_pedestal()
	self._sv._use_state = "off"
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end
	self:update_commands()

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:current_stage()
	return self._sv._use_state
end

function LayEgg_spot:trigger_raid_toward_the_egg(egg)
	if stonehearth.game_creation:get_game_mode() == "stonehearth:game_mode:peaceful" then
		return
	end

	self.timer = stonehearth.calendar:set_timer('preparing egg raid', "30m+1h", function()
		self:_spawn()
		self.timer = nil
	end)
	self.timer2 = stonehearth.calendar:set_timer('preparing egg raid', "8h+1h", function()
		self:_spawn()
		self.timer2 = nil
	end)
	self.timer3 = stonehearth.calendar:set_timer('preparing egg raid', "16h+1h", function()
		self:_spawn()
		self.timer3 = nil
	end)
end

function LayEgg_spot:_spawn()
	if not self._sv._current_egg then
		return
	end

	local enemy
	local territory = self.player_id and stonehearth.terrain:get_territory(self.player_id) or stonehearth.terrain:get_total_territory()
	local territory_region = territory:get_region()
	local valid_points_region = territory_region:inflated(Point2(64, 64)) - territory_region:inflated(Point2(32, 32))
	local pedestal_location = radiant.entities.get_world_grid_location(self._entity) +Point3.unit_y+Point3.unit_z
	local valid_cubes = WeightedSet(rng)
	for cube in valid_points_region:each_cube() do
		valid_cubes:add(cube, cube:get_area())
	end
	local max_y = radiant.terrain.get_terrain_component():get_bounds().max.y

	for i=1, stonehearth.population:get_population_size(self.player_id) do
		enemy = radiant.entities.create_entity('swamp_goblins:monsters:doodles_egg_raider', {owner = "forest"})

		local location = self:find_spawning_point(valid_cubes, pedestal_location, max_y)
		radiant.terrain.place_entity_at_exact_location(enemy, location)

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

function LayEgg_spot:destroy()
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end
end

function LayEgg_spot:find_spawning_point(valid_cubes, target_location, max_y)
	local point
	for i=1, 100 do
		local cube = valid_cubes:choose_random()
		point = radiant.terrain.get_point_on_terrain(Point3(rng:get_int(cube.min.x, cube.max.x), max_y, rng:get_int(cube.min.y, cube.max.y)))
		
		if _radiant.sim.topology.are_strictly_connected(point, target_location, 0) then
			break
		end
	end
	return point
end

return LayEgg_spot