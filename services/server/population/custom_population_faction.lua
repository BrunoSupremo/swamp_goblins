local GoblinPopulationFaction = class()

local rng = _radiant.math.get_default_rng()
local IntegerGaussianRandom = require 'stonehearth.lib.math.integer_gaussian_random'
local gaussian_rng = IntegerGaussianRandom(rng)

local firefly_kingdom = radiant.resources.load_json("swamp_goblins:kingdoms:firefly_clan")
local goblin_role_data = firefly_kingdom.roles["default"]

function GoblinPopulationFaction:set_baby(baby)
	radiant.entities.set_custom_name(baby, "i18n(swamp_goblins:entities.goblins.baby.display_name)")
	self._sv.citizens:add(baby:get_id(), baby)
	self:on_citizen_count_changed()
	self:_monitor_citizen(baby)

	self.__saved_variables:mark_changed()
end

function GoblinPopulationFaction:create_new_goblin_citizen_from_role_data(citizen)
	self:_set_citizen_initial_state(citizen, "male", goblin_role_data, {})
	self._sv.citizens:add(citizen:get_id(), citizen)
	self:on_citizen_count_changed()
	self:_monitor_citizen(citizen)

	if stonehearth.world_generation:get_biome_alias() == "swamp_goblins:biome:swamp" then
		radiant.entities.add_thought(citizen, 'stonehearth:thoughts:town:founding:swamp_home')
	else
		radiant.entities.add_thought(citizen, 'stonehearth:thoughts:town:founding:not_swamp_home')
	end
	self.__saved_variables:mark_changed()
end

function GoblinPopulationFaction:_assign_citizen_traits(citizen, options)
	local tc = citizen:get_component('stonehearth:traits')
	if options.suppress_traits or not tc then
		return
	end

	local num_traits = gaussian_rng:get_int(1, 2, 0.33)
	if citizen:get_component('swamp_goblins:firefly_goblin') then
		num_traits = gaussian_rng:get_int(1, 3, 0.66)
	end
	self._log:info('assigning %d traits', num_traits)

	local traits = {}
	local all_traits = radiant.deep_copy(self._flat_trait_index)
	local start = 1

	-- When doing embarkation trait assignment, make sure every hearthling
	-- gets a 'prime' trait (i.e. ensure we use at least K traits from the
	-- complete list of traits for K hearthlings).
	if options.embarking then
		local available_prime_traits = radiant.deep_copy(all_traits)

		-- Remove all the previously-assigned prime traits from our copy.
		for trait_uri, group_name in pairs(self._prime_traits) do
			if group_name and available_prime_traits[group_name] then
				available_prime_traits[group_name][trait_uri] = nil
				if not next(available_prime_traits[group_name]) then
					available_prime_traits[group_name] = nil
				end
			elseif available_prime_traits[trait_uri] then
				available_prime_traits[trait_uri] = nil
			end
		end

		local trait_uri, group_name = self:_pick_random_trait(citizen, traits, available_prime_traits, options)
		if not trait_uri then
			self._log:info('ran out of prime traits!')
			self._prime_traits = {}
			trait_uri, group_name = self:_pick_random_trait(citizen, traits, all_traits, options)
			assert(trait_uri)
		end
		self:_add_trait(traits, trait_uri, group_name, all_traits, tc)
		self._prime_traits[trait_uri] = group_name or false

		self._log:info('  prime trait %s', trait_uri)
		start = 2
	end

	for i = start, num_traits do
		local trait_uri, group_name = self:_pick_random_trait(citizen, traits, all_traits, options)
		if not trait_uri then
			self._log:info('ran out of traits!')
			break
		end

		self._log:info('  picked %s', trait_uri)
		self:_add_trait(traits, trait_uri, group_name, all_traits, tc)
	end
end

return GoblinPopulationFaction