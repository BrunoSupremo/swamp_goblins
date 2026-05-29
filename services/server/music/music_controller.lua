local rng = _radiant.math.get_default_rng()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3

local MusicController = class()

local STAGE = {
	NOT_STARTED = 'NOT_STARTED',

	SETUP = 'SETUP',
	CONGREGATING = 'CONGREGATING',
	UPGRADE_VFX = 'UPGRADE_VFX',
	CELEBRATING = 'CELEBRATING',
	WRAPUP = 'WRAPUP',

	FINISHED = 'FINISHED',
}

local RESOURCE_TO_RESTORE = {
	calories = 'max',
	sleepiness = 'min',
	social_satisfaction = 'max',
}

local CELEBRATION_TASK_GROUP = 'stonehearth:task_groups:solo:celebration'
local CHANCE_OF_CONVERSATION = 0.7

local MAX_CONGREGATE_TIME = '30m'
local CONGREGATION_SUCCESS_PERCENT_NEEDED = 0.8;

local conversation_subjects = {
	"swamp_goblins:goblinpedia",
	"swamp_goblins:critters:frog",
	"swamp_goblins:music:bongo",
	"swamp_goblins:music:drum",
	"swamp_goblins:music:xylophone",
	"swamp_goblins:music:subject"
}

function MusicController:initialize()
	self._sv.stage = STAGE.NOT_STARTED
	self._sv.instruments = {}

	self._injected_ai = {}
	self._congregate_success_count = 0
	self._congregate_success_required = 0
	self._congregate_end_timer = nil
	self._celebration_end_timer = nil
end

function MusicController:restore()
	-- Need to make sure Town, Faction, etc. are fully loaded.
	radiant.events.listen_once(radiant, 'radiant:game_loaded', self, function()
			-- Resume the celebration from the beginning of the last stage. We could keep track of remaining time,
			-- but that's probably an overkill.
			if self._sv.stage == STAGE.SETUP then
				assert(false, 'MusicController in SETUP state on restore, which should never happen as it transitions to CONGREGATING synchronously.')
			elseif self._sv.stage == STAGE.CONGREGATING then
				self:stage_2_congregate()
			elseif self._sv.stage == STAGE.UPGRADE_VFX then
				self:_inject_ai()
				self:stage_3_play_upgrade_vfx()
			elseif self._sv.stage == STAGE.CELEBRATING then
				self:_start_music()
				self:_inject_ai()
				self:stage_4_celebrate()
			end
		end)
end

function MusicController:create(instrument)
	self:_find_instruments(instrument)
	self._sv.player_id = radiant.entities.get_player_id(instrument)

	self:stage_1_setup()
end

function MusicController:stage_1_setup()
	self._sv.stage = STAGE.SETUP
	self.__saved_variables:mark_changed()

	for _, instrument in pairs(self._sv.instruments) do
		instrument:get_component("swamp_goblins:music"):in_use(true)
	end

	local population = stonehearth.population:get_population(self._sv.player_id)
	for _, citizen in population:get_citizens():each() do
		-- Reset needs.
		for resource_name, target in pairs(RESOURCE_TO_RESTORE) do
			local resources = citizen:get_component('stonehearth:expendable_resources')
			local value
			if target == 'max' then
				value = resources:get_max_value(resource_name)
			else
				value = resources:get_min_value(resource_name)
			end
			-- avg of max and current value
			resources:set_value(resource_name, (value + resources:get_value(resource_name))/2)
		end

		-- Seed conversation subjects.
		for _, subject_uri in ipairs(conversation_subjects) do
			local subjects = citizen:get_component('stonehearth:subject_matter')
			subjects:add_subject(subject_uri)
			subjects:add_override({
				subject = subject_uri,
				sentiment = 1
			})
		end

		-- Grant thought.
		radiant.entities.add_thought(citizen, "stonehearth:thoughts:traits:enjoys_company")
	end

	self:stage_2_congregate()
end

function MusicController:stage_2_congregate()
	self._sv.stage = STAGE.CONGREGATING
	self.__saved_variables:mark_changed()

	-- Give everyone involved celebration AI.
	self:_inject_ai()

	-- Issue congregate tasks, and wait for them all to finish.
	self._congregate_success_count = 0
	self._congregate_success_required = 0
	local population = stonehearth.population:get_population(self._sv.player_id)
	for _, citizen in population:get_citizens():each() do
		self:_add_congregate_task(citizen)
	end

	self._congregate_success_required = math.ceil( self._congregate_success_required * CONGREGATION_SUCCESS_PERCENT_NEEDED ) --0.8

	-- Wait for a maximum congregation time before starting.
	self._congregate_end_timer = stonehearth.calendar:set_timer('town upgrade congragation end', MAX_CONGREGATE_TIME, function()
		self:stage_3_play_upgrade_vfx()
	end)
end

function MusicController:stage_3_play_upgrade_vfx()
	self._sv.stage = STAGE.UPGRADE_VFX
	self.__saved_variables:mark_changed()

	if self._congregate_end_timer then
		self._congregate_end_timer:destroy()
	end

	self:stage_4_celebrate()
end

function MusicController:stage_4_celebrate()
	self._sv.stage = STAGE.CELEBRATING
	self.__saved_variables:mark_changed()

	-- Start music.
	self:_start_music()
	self:_play_musical_effects()

	-- Issue carouse task.
	local population = stonehearth.population:get_population(self._sv.player_id)
	for _, citizen in population:get_citizens():each() do
		self:_add_carouse_task(citizen)
	end

	-- Wait until the end of the celebration.
	self._celebration_end_timer = stonehearth.calendar:set_timer('town upgrade celebration end', "77m", function()
		-- 1m = 0.54 (real life) seconds of celebration
		self:stage_5_wrapup()
	end)
end

function MusicController:stage_5_wrapup()
	self._sv.stage = STAGE.WRAPUP
	self.__saved_variables:mark_changed()

	for id, instrument in pairs(self._sv.instruments) do
		instrument:get_component("swamp_goblins:music"):stop_notes_effect()
		instrument:get_component("swamp_goblins:music"):in_use(false)
	end

	-- Clear all celebration tasks.
	local population = stonehearth.population:get_population(self._sv.player_id)
	for _, citizen in population:get_citizens():each() do
		local ai = citizen:add_component('stonehearth:ai')
		if ai:has_task_group('stonehearth:task_groups:solo:celebration') then
			ai:get_task_group('stonehearth:task_groups:solo:celebration'):clear_tasks()
		end
	end

	-- Remove injected celebration AI from citizens
	self:_uninject_ai()

	-- Stop music.
	radiant.events.trigger(radiant, 'stonehearth:request_music_track', { player_id = self._sv.player_id, track = nil })

	self._sv.stage = STAGE.FINISHED
	self.__saved_variables:mark_changed()
end

function MusicController:_find_instruments(instrument)
	self._sv.instruments[instrument:get_id()] = instrument

	local location = radiant.entities.get_world_grid_location(instrument)
	if not location then
		return
	end

	local region = Region3()
	region:add_point(location)
	region = region:inflated(Point3(10,10,10))
	local entities = radiant.terrain.get_entities_in_region(region)
	for _, entity in pairs(entities) do
		local is_instrument = entity:get_component("swamp_goblins:music")
		if is_instrument and not self._sv.instruments[entity:get_id()] then
			self._sv.instruments[entity:get_id()] = entity
			self:_find_instruments(entity)
		end
	end
end

function MusicController:_start_music()
	radiant.events.trigger(radiant, 'stonehearth:request_music_track', { player_id = self._sv.player_id, track = 'goblin_party' })
end

function MusicController:_play_musical_effects()
	for id, instrument in pairs(self._sv.instruments) do
		instrument:get_component("swamp_goblins:music"):play_notes_effect()
	end
end

function MusicController:_inject_ai()
	local population = stonehearth.population:get_population(self._sv.player_id)
	for _, citizen in population:get_citizens():each() do
		if not self._injected_ai[citizen:get_id()] then
			self._injected_ai[citizen:get_id()] = stonehearth.ai:inject_ai(citizen, { ai_packs = { "stonehearth:ai_pack:celebration" } })
		end
	end
end

function MusicController:_uninject_ai()
	for _, injected_ai_handle in pairs(self._injected_ai) do
		injected_ai_handle:destroy()
	end
	self._injected_ai = {}
end

function MusicController:_pick_random_instrument()
	local weighted_set = WeightedSet(rng)
	for id, instrument in pairs(self._sv.instruments) do
		weighted_set:add(instrument, 1)
	end
	return weighted_set:choose_random()
end

function MusicController:_add_congregate_task(entity)
	local celebration_location = radiant.entities.get_world_location(self:_pick_random_instrument())
	local celebration_task_group = entity:add_component('stonehearth:ai'):get_task_group('stonehearth:task_groups:solo:celebration')
	celebration_task_group:create_task('stonehearth:celebrate:congregate', { location = celebration_location } )
	:once()
	:notify_completed(function()
		self._congregate_success_count = self._congregate_success_count + 1
		if self._congregate_success_count == self._congregate_success_required and self._sv.stage == STAGE.CONGREGATING then
			self:stage_3_play_upgrade_vfx()
		end
	end)
	:start()
	celebration_task_group:create_task('stonehearth:celebrate:admire_focus', { location = celebration_location } )
	:start()
	self._congregate_success_required = self._congregate_success_required + 1
end

function MusicController:_add_carouse_task(entity)
	local celebration_location = radiant.entities.get_world_location(self:_pick_random_instrument())
	local celebration_task_group = entity:add_component('stonehearth:ai'):get_task_group('stonehearth:task_groups:solo:celebration')
	celebration_task_group:create_task('stonehearth:celebrate:carouse', { location = celebration_location })
	:start()

	-- Some folks will get chatty during the celebration.
	if rng:get_real(0, 1) <= CHANCE_OF_CONVERSATION then
		local resources = entity:get_component('stonehearth:expendable_resources')
		-- Set it to a value in a range so that some conversations are delayed.
		resources:set_value('social_satisfaction', rng:get_real(0, 0.075) * (resources:get_max_value('social_satisfaction') or 0))
	end
end

return MusicController