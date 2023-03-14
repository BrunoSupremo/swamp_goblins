local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3

-- Adds a new citizen to the town, either of the player's population or of another race/faction.

local AddCitizenWithTraitsEncounter = class()

function AddCitizenWithTraitsEncounter:initialize()
	self._sv.ctx = nil
	self._sv.info = nil
	self._sv.searcher = nil
end

function AddCitizenWithTraitsEncounter:start(ctx, info)
	self._sv.ctx = ctx
	self._sv.info = info or {}
	-- Start looking for a location to spawn the new citizen in.
	self._fallback_location = self:_get_fallback_spawn_location()
	self._sv.searcher = radiant.create_controller('stonehearth:game_master:util:choose_location_outside_town',
		64, 128,
		radiant.bind(self, '_find_location_callback'),
		nil,
		ctx.player_id)
end

function AddCitizenWithTraitsEncounter:_find_location_callback(op, location)
	if op == 'check_location' then
		return self:_check_location(location)
	elseif op == 'set_location' then
		self:_place_citizen(location)
	elseif op == 'abort' then
		self:_place_citizen(self._fallback_location)
	else
		radiant.error('unknown op "%s" in choose_location_outside_town callback', op)
	end
end

function AddCitizenWithTraitsEncounter:_check_location(location)
	local r = stonehearth.terrain:get_sight_radius()
	local sight_radius = Point3(r, r, r)
	local cube = Cube3(location):inflated(sight_radius)
	local entities = radiant.terrain.get_entities_in_cube(cube)

	-- check for anything nearby that might attack the new citizen
	for _, entity in pairs(entities) do
		if entity:get_component('stonehearth:ai') then
			local player_id = radiant.entities.get_player_id(entity)
			if stonehearth.player:are_player_ids_hostile(player_id, self._sv.ctx.player_id) then
				return false
			end
		end
	end

	-- Check that it's reachable from the center of town.
	if not _radiant.sim.topology.are_connected(location, self._fallback_location, 0) then
		return false
	end

	return true
end

function AddCitizenWithTraitsEncounter:_get_fallback_spawn_location()
	local town_center = stonehearth.terrain:get_territory(self._sv.ctx.player_id):get_centroid()
	-- search from max_y to avoid tunnels
	local max_y = radiant.terrain.get_terrain_component():get_bounds().max.y
	local proposed_location = radiant.terrain.get_point_on_terrain(Point3(town_center.x, max_y, town_center.y))
	return radiant.terrain.find_placement_point(proposed_location, 20, 30)
end

function AddCitizenWithTraitsEncounter:_place_citizen(location)
	local pop = stonehearth.population:get_population(self._sv.ctx.player_id)

	local options = {}
	options.attribute_distribution_override = self._sv.info.attribute_distribution_override
	if self._sv.info.traits then
		options.suppress_traits = true
	end

	-- Create the citizen.
	local citizen
	if self._sv.info.population then
		citizen = pop:create_new_foreign_citizen(self._sv.info.population, self._sv.info.role, self._sv.info.gender, options)
	else
		citizen = pop:create_new_citizen(self._sv.info.role, self._sv.info.gender, options)
	end

	-- Place the citizen, make them run to the center of town, and notify the player.
	radiant.terrain.place_entity(citizen, location)
	local town = stonehearth.town:get_town(self._sv.ctx.player_id)
	citizen:get_component('stonehearth:ai')
	:get_task_group('stonehearth:task_groups:solo:unit_control')
	:create_task('stonehearth:goto_town_center', {town = town})
	:once()
	:start()
	if self._sv.info.notification_title then
		pop:show_notification_for_citizen(citizen, self._sv.info.notification_title)
	end
	
	-- Set up jobs if specified.
	if self._sv.info.job then
		local job_component = citizen:get_component('stonehearth:job')
		if job_component then
			job_component:promote_to(self._sv.info.job, {skip_visual_effects = true})
			if self._sv.info.level then
				for i=2, self._sv.info.level do
					job_component:level_up(true) --true = skip vfx
				end
			end
		end
	end

	if self._sv.info.equipment then
		for _, item_uri in ipairs(self._sv.info.equipment) do
			local item = radiant.entities.create_entity(item_uri)
			radiant.entities.equip_item(citizen, item)
		end
	end


	if self._sv.info.allowed_jobs then
		local allowed_jobs_set = {}
		for _, allowed_job in ipairs(self._sv.info.allowed_jobs) do
			allowed_jobs_set[allowed_job] = true
		end
		citizen:get_component('stonehearth:job'):set_allowed_jobs(allowed_jobs_set)
	end

	if self._sv.info.traits then
		local trait_comp = citizen:get_component("stonehearth:traits")
		for trait,enabled in pairs(self._sv.info.traits) do
			if enabled then
				trait_comp:add_trait(trait)
			end
		end
	end

	-- Continue encounter flow.
	self._sv.ctx.arc:trigger_next_encounter(self._sv.ctx)

	-- Clean up.
	self._sv.ctx = nil
	self._sv.info = nil
	if self._sv.searcher then
		self._sv.searcher:destroy()
		self._sv.searcher = nil
	end
end

return AddCitizenWithTraitsEncounter