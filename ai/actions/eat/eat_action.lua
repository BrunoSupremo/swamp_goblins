local EatingLib = require 'stonehearth.ai.lib.eating_lib'

local GoblinEat = radiant.class()

GoblinEat.name = 'goblin eat to live'
GoblinEat.status_text_key = 'stonehearth:ai.actions.status_text.eat'
GoblinEat.does = 'stonehearth:eat'
GoblinEat.args = {}
GoblinEat.priority = {0, 1}

function GoblinEat._get_quality(food_stuff, food_preferences)
	local food = food_stuff
	local container_data = radiant.entities.get_entity_data(food, 'stonehearth:food_container', false)
	if container_data then
		food = container_data.food
	end
	local food_data = radiant.entities.get_entity_data(food, 'stonehearth:food', false)

	if not food_data or not food_data.default then
		return nil
	end

	if food_preferences ~= '' then
		if not radiant.entities.is_material(food_stuff, food_preferences) then
			return stonehearth.constants.food_qualities.UNPALATABLE
		end
	end

	return food_data.quality or stonehearth.constants.food_qualities.RAW_BLAND
end

function GoblinEat:start_thinking(ai, entity, args)
	if radiant.entities.get_resource(entity, 'calories') == nil then
		ai:set_debug_progress('dead: have no calories resource')
		return
	end

	self._ai = ai
	self._entity = entity

	self._ready = false
	local consumption = self._entity:get_component('stonehearth:consumption')
	local food_preferences = consumption:get_food_preferences()
	-- self._food_filter_fn = EatingLib.make_food_filter(food_preferences)
	--this should skip the ace modifications in make_food_filter
	self._food_filter_fn = stonehearth.ai:filter_from_key('food_filter', tostring(food_preferences), function(item)
		return GoblinEat._get_quality(item, food_preferences) ~= nil
	end)
	self._food_rating_fn = consumption:distinguishes_food_quality() and EatingLib.make_food_rater(food_preferences) or function(item) return 1 end

	self._calorie_listener = radiant.events.listen(self._entity, 'stonehearth:expendable_resource_changed:calories', self, self._rethink)
	self._timer = stonehearth.calendar:set_interval("eat_action hourly", '25m+5m', function() self:_rethink() end)
	self:_rethink()
end

function GoblinEat:stop_thinking(ai, entity, args)
	if self._calorie_listener then
		self._calorie_listener:destroy()
		self._calorie_listener = nil
	end
	if self._timer then
		self._timer:destroy()
		self._timer = nil
	end
end

function GoblinEat:stop(ai, entity, args)
	radiant.events.trigger_async(self._entity, 'stonehearth:entity:stopped_looking_for_food')
end

function GoblinEat:_rethink()
	local consumption = self._entity:get_component('stonehearth:consumption')
	local hunger_score = consumption:get_hunger_score()
	local min_hunger_to_eat = consumption:get_min_hunger_to_eat_now()

	self._ai:set_debug_progress(string.format('hunger = %s; min to eat now = %s', hunger_score, min_hunger_to_eat))
	if hunger_score >= min_hunger_to_eat then
		self:_mark_ready()
	else
		self:_mark_unready()
	end

	self._ai:set_utility(hunger_score)
end

function GoblinEat:_mark_ready()
	if not self._ready then
		self._ready = true
		self._ai:set_think_output({
			food_filter_fn = self._food_filter_fn,
			food_rating_fn = self._food_rating_fn,
		})
		radiant.events.trigger_async(self._entity, 'stonehearth:entity:looking_for_food')
	end
end

function GoblinEat:_mark_unready()
	if self._ready then
		self._ready = false
		self._ai:clear_think_output()
		radiant.events.trigger_async(self._entity, 'stonehearth:entity:stopped_looking_for_food')
	end
end

local ai = stonehearth.ai
return ai:create_compound_action(GoblinEat)
:execute('stonehearth:get_food', {
	food_filter_fn = ai.PREV.food_filter_fn,
	food_rating_fn = ai.PREV.food_rating_fn,
})
:execute('stonehearth:find_seat_and_eat')