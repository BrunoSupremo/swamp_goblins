local WeatherStone = class()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

function WeatherStone:initialize()
	self._sv._use_state = "off" --[off, charging, ready, waiting]
	self._sv._charged_state = 0 --0~3
	self._sv._task_effect = nil
end

-- check weather for titan weather and block it
-- local weather_state = stonehearth.weather:get_current_weather()
-- lhs = weather_state and weather_state:get_uri()

function WeatherStone:post_activate()
	self.player_id = self._entity:get_player_id()

	self._sv._task_effect = nil
	if self._sv._use_state == "off" then
		self:enable_commands(true)
	else
		self:enable_commands(false)
		if self._sv._use_state == "ready" then
			self:switch_command()
		end
	end
end

function WeatherStone:enable_commands(enable)
	local commands_component = self._entity:get_component("stonehearth:commands")
	commands_component:set_command_enabled("swamp_goblins:commands:weather_stone:charge",enable)
	commands_component:set_command_enabled("swamp_goblins:commands:weather_stone:use",enable)
	commands_component:set_command_enabled('stonehearth:commands:move_item',enable)
	commands_component:set_command_enabled('stonehearth:commands:undeploy_item',enable)
end

function WeatherStone:switch_command(to_charging)
	local commands_component = self._entity:get_component("stonehearth:commands")
	if to_charging then
		commands_component:add_command("swamp_goblins:commands:weather_stone:charge")
		commands_component:set_command_enabled("swamp_goblins:commands:weather_stone:charge",true)
		commands_component:remove_command("swamp_goblins:commands:weather_stone:use")
	else
		commands_component:remove_command("swamp_goblins:commands:weather_stone:charge")
		commands_component:add_command("swamp_goblins:commands:weather_stone:use")
		commands_component:set_command_enabled("swamp_goblins:commands:weather_stone:use",true)
	end
end

function WeatherStone:now_charging()
	self:enable_commands(false)
	self._sv._use_state = "charging"
	self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:weather_stone:charging", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })

	stonehearth.ai:reconsider_entity(self._entity)
end

function WeatherStone:increase_charge()
	self._sv._charged_state = self._sv._charged_state +1
	self._entity:get_component('render_info'):set_model_variant("charged_"..self._sv._charged_state)
	radiant.effects.run_effect(self._entity, "stonehearth:effects:buff_tonic_energy_added")
	if self._sv._charged_state >= 3 then
		self:ready()
	end
end

function WeatherStone:ready()
	self:enable_commands(false)
	self:switch_command()
	self._sv._use_state = "ready"

	self:remove_effect()
	self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:green_fire:large_candle")

	stonehearth.ai:reconsider_entity(self._entity)
end

function WeatherStone:now_waiting()
	self:enable_commands(false)
	self._sv._use_state = "waiting" --someone will be using it soon

	self:remove_effect()
	self._sv._task_effect = radiant.effects.run_effect(self._entity, "swamp_goblins:effects:weather_stone:waiting", nil, nil, { playerColor = stonehearth.presence:get_color_integer(self.player_id) })

	stonehearth.ai:reconsider_entity(self._entity)
end

function WeatherStone:change_weather()
	local current_season = stonehearth.seasons:get_current_season()

	local weighted_set = WeightedSet(rng)
	for _, entry in ipairs(current_season.weather) do
		weighted_set:add(entry.uri, entry.weight)
	end
	--avoid picking the same weather by removing it out of the set
	local current_weather = stonehearth.weather._sv.current_weather_state
	weighted_set:remove(current_weather)
	local chosen_weather = weighted_set:choose_random() or "stonehearth:weather:sunny"

	stonehearth.weather:_switch_to(chosen_weather, self.player_id)

	radiant.effects.run_effect(self._entity, "stonehearth:effects:buff_tonic_energy_added")

	self:full_reset()
end

function WeatherStone:full_reset()
	self:switch_command(true)
	self:enable_commands(true)
	self._sv._use_state = "off"
	self._sv._charged_state = 0
	self._entity:get_component('render_info'):set_model_variant("default")
	self:remove_effect()

	stonehearth.ai:reconsider_entity(self._entity)
end

function WeatherStone:current_stage()
	return self._sv._use_state
end

function WeatherStone:destroy()
	self:remove_effect()
end

function WeatherStone:remove_effect()
	if self._sv._task_effect then
		self._sv._task_effect:stop()
		self._sv._task_effect = nil
	end
end

return WeatherStone