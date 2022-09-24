local BabyComponent = class()
local rng = _radiant.math.get_default_rng()

--[[
function BabyComponent:create()
	local pop = stonehearth.population:get_population(self.player_id)
	pop:set_baby(baby)
	--if we end up showing it on character list, players "can" change its job...
end
]]
function BabyComponent:initialize()
	self._sv._calories_consumed = 0
end

function BabyComponent:post_activate()
	self.player_id = self._entity:get_player_id()

	self._sleep_listener = radiant.events.listen(self._entity, 'stonehearth:buff_added', function(e)
		if e.uri == "stonehearth:buffs:sleeping" then
			radiant.entities.add_buff(self._entity, "swamp_goblins:buffs:pause_hungry")
		end
	end)
	self._wakeup_listener = radiant.events.listen(self._entity, 'stonehearth:finished_sleeping', function(e)
		radiant.entities.remove_buff(self._entity, "swamp_goblins:buffs:pause_hungry")
	end)

	self._eat_listener = radiant.events.listen(self._entity, 'stonehearth:eat_food', function(e)
		self._sv._calories_consumed = self._sv._calories_consumed + e.food_data.satisfaction
		if self._sv._calories_consumed > self:calories_target() then
			self:grow()
		end
	end)

	self._conversation_listener = radiant.events.listen(self._entity, 'stonehearth:conversation:results_produced', function(e)
		local target = stonehearth.conversation:get_target(self._entity)
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

function BabyComponent:calories_target()
	if radiant.entities.has_buff(self._entity, "swamp_goblins:buffs:baby:bottle") then
		return 150
	end
	return 300
end

function BabyComponent:grow()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	local facing = radiant.entities.get_facing(self._entity)

	local equipment_component = self._entity:get_component("stonehearth:equipment")
	local mind_booster = equipment_component:has_item_type("swamp_goblins:baby:toy2")
	local body_booster = equipment_component:has_item_type("swamp_goblins:baby:bottle2")
	local spirit_booster = equipment_component:has_item_type("swamp_goblins:baby:blanket2")

	radiant.entities.destroy_entity(self._entity)

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

function BabyComponent:reroll_stats(adult, mind_booster,body_booster,spirit_booster)
	local attributes_component = adult:get_component('stonehearth:attributes')
	local current_mind = attributes_component:get_attribute("mind")
	local current_body = attributes_component:get_attribute("body")
	local current_spirit = attributes_component:get_attribute("spirit")

	local new_mind = rng:get_int(1,5)
	local new_body = rng:get_int(1,5)
	local new_spirit = rng:get_int(2,8)

	if mind_booster and (new_mind>current_mind) then
		attributes_component:set_attribute("mind", new_mind)
		for i=1, new_mind-current_mind do
			radiant.entities.add_thought(adult, 'stonehearth:thoughts:baby:mind_booster')
		end
	end
	if body_booster and (new_body>current_body) then
		attributes_component:set_attribute("body", new_body)
		for i=1, new_body-current_body do
			radiant.entities.add_thought(adult, 'stonehearth:thoughts:baby:body_booster')
		end
	end
	if spirit_booster and (new_spirit>current_spirit) then
		attributes_component:set_attribute("spirit", new_spirit)
		for i=1, new_spirit-current_spirit do
			radiant.entities.add_thought(adult, 'stonehearth:thoughts:baby:spirit_booster')
		end
	end
end

function BabyComponent:destroy()
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
end

return BabyComponent