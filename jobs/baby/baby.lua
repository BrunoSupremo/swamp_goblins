local BabyClass = class()
local BaseJob = require 'stonehearth.jobs.base_job'
local rng = _radiant.math.get_default_rng()
radiant.mixin(BabyClass, BaseJob)

function BabyClass:initialize()
	BaseJob.initialize(self)
	self._sv._calories_consumed = 0
end

function BabyClass:create(entity)
	BaseJob.create(self, entity)
	local pop = stonehearth.population:get_population(self._sv._entity:get_player_id())
	pop:set_baby(self._sv._entity)
	--adding it to character list, players can now change its job...
	--so there is a little trick in css to hide the promotion button instead
	--for ace though, that trick does not work (different html structure)
	--so the new trick is to limit and lock the job tree from being changed
	if swamp_goblins.ace_is_here then
		radiant.entities.add_buff(self._sv._entity, "stonehearth_ace:buffs:job_locked")
	end
	local job_comp = self._sv._entity:get_component('stonehearth:job')
	local allowed = {}
	allowed["stonehearth:jobs:worker"] = true
	allowed["swamp_goblins:jobs:baby"] = true
	job_comp:set_allowed_jobs(allowed)
end

function BabyClass:post_activate()
	self.player_id = self._sv._entity:get_player_id()

	self._sleep_listener = radiant.events.listen(self._sv._entity, 'stonehearth:buff_added', function(e)
		if e.uri == "stonehearth:buffs:sleeping" then
			radiant.entities.add_buff(self._sv._entity, "swamp_goblins:buffs:pause_hungry")
		end
	end)
	self._wakeup_listener = radiant.events.listen(self._sv._entity, 'stonehearth:finished_sleeping', function(e)
		radiant.entities.remove_buff(self._sv._entity, "swamp_goblins:buffs:pause_hungry")
	end)

	self._eat_listener = radiant.events.listen(self._sv._entity, 'stonehearth:eat_food', function(e)
		self._sv._calories_consumed = self._sv._calories_consumed + e.food_data.satisfaction
		if self._sv._calories_consumed > self:calories_target() then
			self:grow()
		else
			local job_component = self._sv._entity:get_component('stonehearth:job')
			job_component._sv.current_level_exp = self._sv._calories_consumed
			job_component.__saved_variables:mark_changed()
		end
	end)

	self._conversation_listener = radiant.events.listen(self._sv._entity, 'stonehearth:conversation:results_produced', function(e)
		local target = stonehearth.conversation:get_target(self._sv._entity)
		if not (target and target:is_valid()) then
			return
		end
		radiant.entities.add_thought(target, 'stonehearth:thoughts:social:animal:booped', {
			tooltip_args = {
				species = "i18n(swamp_goblins:entities.goblins.baby.display_name)"
			}
		})
	end)
end

function BabyClass:calories_target()
	local target = 300
	if radiant.entities.has_buff(self._sv._entity, "swamp_goblins:buffs:baby:bottle") then
		target = 150
	end
	--the xp is being used to visually track the growth progress
	local job_component = self._sv._entity:get_component('stonehearth:job')
	job_component._sv.xp_to_next_lv = target
	job_component.__saved_variables:mark_changed()
	return target
end

function BabyClass:grow()
	local location = radiant.entities.get_world_grid_location(self._sv._entity)
	if not location then
		return
	end
	local facing = radiant.entities.get_facing(self._sv._entity)

	local equipment_component = self._sv._entity:get_component("stonehearth:equipment")
	local mind_booster = equipment_component:has_item_type("swamp_goblins:baby:toy2")
	local body_booster = equipment_component:has_item_type("swamp_goblins:baby:bottle2")
	local spirit_booster = equipment_component:has_item_type("swamp_goblins:baby:blanket2")

	radiant.entities.destroy_entity(self._sv._entity)

	local adult = radiant.entities.create_entity("swamp_goblins:goblins:goblin", {owner = self.player_id} )
	radiant.entities.set_player_id(adult, self.player_id)

	radiant.terrain.place_entity_at_exact_location(adult, location, { force_iconic = false, facing = facing } )
	radiant.effects.run_effect(adult, "stonehearth:effects:fursplosion_effect")

	local pop = stonehearth.population:get_population(self.player_id)
	pop:create_new_goblin_citizen_from_role_data(adult)
	local job_component = adult:add_component('stonehearth:job')
	job_component:promote_to("stonehearth:jobs:worker", { skip_visual_effects = true })
	stonehearth.bulletin_board:post_bulletin(self.player_id)
	:set_data({
		zoom_to_entity = adult,
		title = "i18n(swamp_goblins:ui.data.new_goblin_citizen)"
	})
	:add_i18n_data('adult_name', radiant.entities.get_custom_name(adult))

	self:reroll_stats(adult, mind_booster,body_booster,spirit_booster)
end

function BabyClass:reroll_stats(adult, mind_booster,body_booster,spirit_booster)
	local attributes_component = adult:get_component('stonehearth:attributes')

	local function reroll_stat(min, max, stat, thought)
		local current_stat_value = attributes_component:get_attribute(stat)
		local new_stat_value = rng:get_int(min, max)
		if (new_stat_value <= current_stat_value) then
			--try a second time, to increase chances of improving the stat
			new_stat_value = rng:get_int(min, max)
			if (new_stat_value <= current_stat_value) then
				--bad luck, no improvement
				return
			end
		end
		attributes_component:set_attribute(stat, new_stat_value)
		for i=1, new_stat_value - current_stat_value do
			radiant.entities.add_thought(adult, thought)
		end
	end

	if mind_booster then
		reroll_stat(1, 5, "mind", "stonehearth:thoughts:baby:mind_booster")
	end
	if body_booster then
		reroll_stat(1, 5, "body", "stonehearth:thoughts:baby:body_booster")
	end
	if spirit_booster then
		reroll_stat(2, 8, "spirit", "stonehearth:thoughts:baby:spirit_booster")
	end
end

function BabyClass:destroy()
	if self._sleep_listener then
		self._sleep_listener:destroy()
		self._sleep_listener = nil
	end
	if self._wakeup_listener then
		self._wakeup_listener:destroy()
		self._wakeup_listener = nil
	end
	if self._eat_listener then
		self._eat_listener:destroy()
		self._eat_listener = nil
	end
	if self._conversation_listener then
		self._conversation_listener:destroy()
		self._conversation_listener = nil
	end
	BaseJob.destroy(self)
end

return BabyClass