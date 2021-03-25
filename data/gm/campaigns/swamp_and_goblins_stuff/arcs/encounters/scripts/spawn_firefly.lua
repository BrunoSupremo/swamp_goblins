local rng = _radiant.math.get_default_rng()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'

local SpawnFirefly = class()

function SpawnFirefly:initialize()
	self._sv.firefly_list = {}
	self._sv.player_id = nil
end

function SpawnFirefly:create(player_id)
	self._sv.player_id = player_id
end

function SpawnFirefly:start()
end

function SpawnFirefly:stop()
	self:remove_fireflies()
end

function SpawnFirefly:restore()
end

function SpawnFirefly:post_activate()
	self:_check_day_light()
end

function SpawnFirefly:_check_day_light()
	if stonehearth.calendar:is_daytime() then
		self:remove_fireflies()
	else
		if not next(self._sv.firefly_list) then
			--only try to spawn if there is none
			self:spawn_fireflies()
		end
	end

	local calendar_constants = stonehearth.calendar:get_constants()
	local event_times = calendar_constants.event_times
	local sunrise_alarm_time = stonehearth.calendar:format_time(event_times.sunrise_start)
	local sunset_alarm_time = stonehearth.calendar:format_time(event_times.sunset_end)

	self._sunrise_listener = stonehearth.calendar:set_alarm(sunrise_alarm_time, function()
		self:remove_fireflies()
	end)
	self._sunset_listener = stonehearth.calendar:set_alarm(sunset_alarm_time, function()
		self:spawn_fireflies()
	end)
end

function SpawnFirefly:spawn_fireflies()
	if not self._sv.player_id then
		return
	end
	local territory = self._sv.player_id and stonehearth.terrain:get_territory(self._sv.player_id) or stonehearth.terrain:get_total_territory()
	local territory_region = territory:get_region()
	local valid_points_region = territory_region:inflated(Point2(32, 32)) - territory_region:inflated(Point2(16, 16))
	local valid_cubes = WeightedSet(rng)
	for cube in valid_points_region:each_cube() do
		valid_cubes:add(cube, cube:get_area())
	end
	local max_y = radiant.terrain.get_terrain_component():get_bounds().max.y

	for i=1, stonehearth.population:get_population_size(self._sv.player_id) do
		local firefly_critter = radiant.entities.create_entity('swamp_goblins:critters:firefly')

		local cube = valid_cubes:choose_random()
		if cube then
			local location = radiant.terrain.get_point_on_terrain(Point3(rng:get_int(cube.min.x, cube.max.x), max_y, rng:get_int(cube.min.y, cube.max.y)))
			radiant.terrain.place_entity_at_exact_location(firefly_critter, location)
		end
		radiant.entities.add_buff(firefly_critter, 'stonehearth:buffs:despawn:after_day')

		table.insert(self._sv.firefly_list, firefly_critter)
	end
end

function SpawnFirefly:remove_fireflies()
	for i = #self._sv.firefly_list, 1, -1 do
		radiant.entities.destroy_entity( table.remove(self._sv.firefly_list) )
	end
end

function SpawnFirefly:destroy()
	if self._sunset_listener then
		self._sunset_listener:destroy()
		self._sunset_listener = nil
	end

	if self._sunrise_listener then
		self._sunrise_listener:destroy()
		self._sunrise_listener = nil
	end
end

return SpawnFirefly