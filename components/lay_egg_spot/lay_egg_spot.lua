local LayEgg_spot = class()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local Point3 = _radiant.csg.Point3
local Point2 = _radiant.csg.Point2
local rng = _radiant.math.get_default_rng()

function LayEgg_spot:initialize()
	self._sv._use_state = "off" --off, waiting, has_egg
	self._sv._current_egg = nil
	self._sv._task_effect = nil
end

function LayEgg_spot:post_activate()
	self.player_id = self._entity:get_player_id()
	self.egg_raid_json = radiant.resources.load_json("swamp_goblins:monster_tuning:egg_raid", true, false)
	self.component_json = radiant.entities.get_json(self)
	if self.component_json.start_with_egg and not (self._sv._use_state == "has_egg") then
		if not self._added_to_world_listener then
			self._added_to_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_added_to_world', function()
				local delayed_function = function ()
					--delayed_function because location is not imediately set
					self:create_egg()
					self.stupid_delay:destroy()
					self.stupid_delay = nil
				end
				self.stupid_delay = stonehearth.calendar:set_persistent_timer("LayEgg_spot delay", 0, delayed_function)
			end)
		end
	end

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
		else 
			--"has_egg"
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
	self:is_someone_able_to_lay_the_egg()
	self:update_commands()
	self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:egg_pedestal", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })

	stonehearth.ai:reconsider_entity(self._entity)
end

function LayEgg_spot:is_someone_able_to_lay_the_egg()
	local job = stonehearth.job:get_job_info(self.player_id, "stonehearth:jobs:worker")
	if job:has_members() then
		return
	end

	stonehearth.bulletin_board:post_bulletin(self.player_id)
	:set_data({
		zoom_to_entity = self._entity,
		title = "i18n(swamp_goblins:ui.data.no_workers)"
	})
end

function LayEgg_spot:create_egg()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	self._sv._use_state = "has_egg"
	self:update_commands()
	local egg = radiant.entities.create_entity("swamp_goblins:goblins:egg", {owner = self.player_id})
	radiant.entities.turn_to(egg, rng:get_int(0,3)*90)
	radiant.terrain.place_entity(egg, location)

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

function LayEgg_spot:reset_pedestal()
	self._sv._use_state = "off"
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end
	if self.timer then
		self.timer:destroy()
		self.timer = nil
	end
	if self.timer2 then
		self.timer2:destroy()
		self.timer2 = nil
	end
	if self.timer3 then
		self.timer3:destroy()
		self.timer3 = nil
	end
	self:update_commands()

	stonehearth.ai:reconsider_entity(self._entity)

	if self.component_json.destroy_after_hatch then
		radiant.entities.destroy_entity(self._entity)
	end
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

	local pop_amount = stonehearth.population:get_population_size(self.player_id)
	local raid = self:_pick_a_raid(pop_amount)
	local monsters_keys = self:_pick_monsters(raid, pop_amount)
	for key, quantity in pairs(monsters_keys) do
		for i=1, quantity do
			enemy = radiant.entities.create_entity(raid.monsters[key].uri, {owner = raid.monsters_kingdom})
			if raid.monsters[key].add_door_break_ability then
				radiant.entities.equip_item(enemy, "stonehearth:abilities:door_breaker_abilities")
			end
			if raid.monsters[key].health_per_citizen then
				radiant.entities.set_attribute(enemy, "max_health", raid.monsters[key].health_per_citizen *pop_amount)
			end
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
	end

	stonehearth.bulletin_board:post_bulletin(self.player_id)
	:set_type('alert')
	:set_data({
		zoom_to_entity = enemy,
		title = raid.bulletin
	})
end


function LayEgg_spot:_pick_a_raid(population)
	local weighted_set = WeightedSet(rng)
	for raid, info in pairs(self.egg_raid_json) do
		local min = info.at_population and info.at_population.min or 0
		local max = info.at_population and info.at_population.max or 9999
		if population >= min and population <= max then
			weighted_set:add(info, info.weight or 1)
		end
	end
	return weighted_set:choose_random()
end

function LayEgg_spot:_pick_monsters(raid, population)
	local weighted_set = WeightedSet(rng)
	for key, value in pairs(raid.monsters) do
		weighted_set:add(key, value.weight or 1)
	end
	local monsters = {}
	local amount = math.ceil(population * raid.monster_spawn_ratio_per_citizen)
	for i=1, amount do
		local chosen = weighted_set:choose_random()
		if monsters[chosen] then
			monsters[chosen] = monsters[chosen]+1
		else
			monsters[chosen] = 1
		end
	end
	return monsters
end

function LayEgg_spot:destroy()
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end
	if self._added_to_world_listener then
		self._added_to_world_listener:destroy()
		self._added_to_world_listener = nil
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