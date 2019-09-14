local game_master_lib = require 'lib.game_master.game_master_lib'
local rng = _radiant.math.get_default_rng()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3

local SwampStuff = class()

function SwampStuff:initialize()
	print("function SwampStuff:initialize()")
end

function SwampStuff:start()
	print("function SwampStuff:start()")
end

function SwampStuff:stop()
	print("function SwampStuff:stop()")
	self:remove_fireflies()
end

function SwampStuff:restore()
	print("function SwampStuff:restore()")
end

function SwampStuff:post_activate()
	print("function SwampStuff:post_activate()")
	self:_check_day_light()
end

function SwampStuff:_check_day_light()
	print("function SwampStuff:_check_day_light()")
	if stonehearth.calendar:is_daytime() then
		self:remove_fireflies()
	else
		self:spawn_fireflies()
	end

	local calendar_constants = stonehearth.calendar:get_constants()
	local event_times = calendar_constants.event_times
	local sunrise_alarm_time = stonehearth.calendar:format_time(event_times.sunrise_start)
	local sunset_alarm_time = stonehearth.calendar:format_time(event_times.sunset_end)

	self._sunrise_listener = stonehearth.calendar:set_alarm(sunrise_alarm_time, function()
		print("function()")
		self:remove_fireflies()
	end)
	self._sunset_listener = stonehearth.calendar:set_alarm(sunset_alarm_time, function()
		print("function()")
		self:spawn_fireflies()
	end)
end

function SwampStuff:spawn_fireflies()
	print("function SwampStuff:spawn_fireflies()")
	
end

function SwampStuff:remove_fireflies()
	print("function SwampStuff:remove_fireflies()")
	
end

function SwampStuff:destroy()
	print("function SwampStuff:destroy()")
	if self._sunset_listener then
		self._sunset_listener:destroy()
		self._sunset_listener = nil
	end

	if self._sunrise_listener then
		self._sunrise_listener:destroy()
		self._sunrise_listener = nil
	end
end

return SwampStuff