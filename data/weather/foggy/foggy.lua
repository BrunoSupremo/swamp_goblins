local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'
local rng = _radiant.math.get_default_rng()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3

local SwampFoggyWeather = class()

local NUM_GROUPS = 15
local MAX_TRIES_PER_GROUP = 10
local MONSTER_GROUPS = {
	{
		npc_player_id = "undead",
		members = {
			{from_population = {role = "zombie",   min=0, max=1}, tuning = "stonehearth:monster_tuning:undead:easy_undead"},
		}
	},
	{
		npc_player_id = "undead",
		members = {
			{from_population = {role = "skeleton", min=0, max=1}, tuning = "stonehearth:monster_tuning:undead:easy_undead"}
		}
	},
}

function SwampFoggyWeather:initialize()
	self._sv.spawned_monsters = {}
	self._sv.is_active = false
end

function SwampFoggyWeather:start()
	self._sv.is_active = true
	if stonehearth.game_creation:get_game_mode() ~= 'stonehearth:game_mode:peaceful' then
		self:_find_spawn_point_and_spawn_monsters()
	end
end

function SwampFoggyWeather:stop()
	self._sv.is_active = false
	self:_make_monsters_leave()
end

function SwampFoggyWeather:restore()
	self._is_restoring = true
end

function SwampFoggyWeather:post_activate()
	if self._is_restoring then
		if not self._sv.is_active then
			self:_make_monsters_leave()
		end
	end
end

function SwampFoggyWeather:_make_monsters_leave()
	for _, monster in pairs(self._sv.spawned_monsters) do
		if radiant.entities.exists(monster) then
			monster:get_component('stonehearth:ai')
			:get_task_group('stonehearth:task_groups:solo:unit_control')
			:create_task('stonehearth:depart_visible_area', { give_up_after = '8h' })
			:start()
		end
	end
end

function SwampFoggyWeather:destroy()
	-- If anyone hasn't left by now, just destroy them.
	for _, monster in pairs(self._sv.spawned_monsters) do
		if radiant.entities.exists(monster) then
			radiant.entities.destroy_entity(monster)
		end
	end
	self._sv.spawned_monsters = {}
end

function SwampFoggyWeather:_find_spawn_point_and_spawn_monsters()
	if stonehearth.calendar:get_converted_elapsed_time().day <7 then
		return --stop spawning in early games
	end
	local territory = stonehearth.terrain:get_total_territory():get_region()
	local min_region = territory:inflated(_radiant.csg.Point2(80, 80))
	local max_region_bounds = territory:inflated(_radiant.csg.Point2(240, 240)):get_bounds()
	local tries = 0
	local num_groups_left_to_spawn = NUM_GROUPS
	while tries < MAX_TRIES_PER_GROUP * NUM_GROUPS and num_groups_left_to_spawn > 0 do
		local x = rng:get_int(max_region_bounds.min.x, max_region_bounds.max.x)
		local y = rng:get_int(max_region_bounds.min.y, max_region_bounds.max.y)
		if not min_region:contains(Point2(x, y)) then
			local location = radiant.terrain.get_point_on_terrain(Point3(x, 0, y))
			self:_spawn_monsters(location)
			num_groups_left_to_spawn = num_groups_left_to_spawn - 1
		end
		tries = tries + 1
	end
end

function SwampFoggyWeather:_spawn_monsters(origin)
	local monster_group_spec = MONSTER_GROUPS[rng:get_int(1, #MONSTER_GROUPS)]

	local population = stonehearth.population:get_population(monster_group_spec.npc_player_id)
	for _, member_spec in ipairs(monster_group_spec.members) do
		if not member_spec.from_population.range then
			member_spec.from_population.range = 10
		end
		if not member_spec.from_population.location then
			member_spec.from_population.location = { x = 0, z = 0 }
		end
		
		if not member_spec.from_population.max then
			member_spec.from_population.max = member_spec.from_population.min or 1
		end
		
		local members = game_master_lib.create_citizens(population, member_spec, origin)
		for _, member in ipairs(members) do
			local effect = radiant.effects.run_effect(member, 'stonehearth:effects:spawn_entity')
			self._sv.spawned_monsters[member:get_id()] = member
		end
	end
end

return SwampFoggyWeather
