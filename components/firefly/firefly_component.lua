local rng = _radiant.math.get_default_rng()
local FireflyComponent = class()

function FireflyComponent:activate()
	local json = radiant.entities.get_json(self)
	self.chance_to_run = json.chance_to_run or 100
	self.random_location = json.random_location
	self.firefly_effect = "swamp_goblins:effects:firefly_effect"
end

function FireflyComponent:post_activate()
	self:_check_light()
	self:_create_nighttime_alarms()
end

function FireflyComponent:destroy()
	if self._running_effect then
		self._running_effect:stop()
		self._running_effect = nil
	end

	if self._sunset_listener then
		self._sunset_listener:destroy()
		self._sunset_listener = nil
	end

	if self._sunrise_listener then
		self._sunrise_listener:destroy()
		self._sunrise_listener = nil
	end
end

function FireflyComponent:_create_nighttime_alarms()
	local calendar_constants = stonehearth.calendar:get_constants()
	local event_times = calendar_constants.event_times
	local jitter = '+30m'
	local sunrise_alarm_time = stonehearth.calendar:format_time(event_times.sunrise) .. jitter
	local sunset_alarm_time = stonehearth.calendar:format_time(event_times.sunset) .. jitter

	self._sunrise_listener = stonehearth.calendar:set_alarm(sunrise_alarm_time, function()
		self:light_off()
	end)
	self._sunset_listener = stonehearth.calendar:set_alarm(sunset_alarm_time, function()
		self:light_on()
	end)
end

function FireflyComponent:_check_light()
	if stonehearth.calendar:is_daytime() then
		self:light_off()
	else
		self:light_on()
	end
end

function FireflyComponent:light_on()
	if not self._running_effect and self.chance_to_run >= rng:get_int(1, 100) then
		local location = radiant.entities.get_world_grid_location(self._entity)
		if location==nil then
			local delayed_function = function ()
				self:light_on()

				self.stupid_delay:destroy()
				self.stupid_delay = nil
				-- log:error("loop")
			end
			self.stupid_delay = stonehearth.calendar:set_persistent_timer("FireflyComponent delay", 0, delayed_function)
			return
		end
		if self.random_location then
			location = radiant.terrain.find_placement_point(location, 1, 16)
		end
		self.proxy = radiant.entities.create_entity('stonehearth:object:transient')
		radiant.terrain.place_entity(self.proxy, location)
		self._running_effect = radiant.effects.run_effect(self.proxy, self.firefly_effect);
	end
end

function FireflyComponent:light_off()
	if self._running_effect then
		self._running_effect:stop()
		self._running_effect = nil
		if self.proxy then
			radiant.entities.destroy_entity(self.proxy)
		end
	end
end

return FireflyComponent