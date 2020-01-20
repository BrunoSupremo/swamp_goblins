local SwampGoblinPlayInstrumentAction = radiant.class()
local Entity = _radiant.om.Entity

SwampGoblinPlayInstrumentAction.name = 'play instrument'
SwampGoblinPlayInstrumentAction.does = 'swamp_goblins:play_instrument'
SwampGoblinPlayInstrumentAction.args = {
	instrument = Entity
}
SwampGoblinPlayInstrumentAction.priority = 0
SwampGoblinPlayInstrumentAction.weight = 1

function SwampGoblinPlayInstrumentAction:run(ai, entity, args)
	local component = args.instrument:get_component("swamp_goblins:music")

	self._keep_playing = true
	self._timer = stonehearth.calendar:set_timer("SwampGoblinPlayInstrumentAction resume", "40m", function()
		self._keep_playing = false
		ai:resume('effect finished')
	end)

	local function play_player_effect()
		if not self._keep_playing then
			return
		end
		self._player_effect = radiant.effects.run_effect(entity, component:get_player_effect())
		self._player_effect:set_finished_cb(function()
			play_player_effect()
		end)
	end
	local function play_instrument_effect()
		if not self._keep_playing then
			return
		end
		self._instrument_effect = radiant.effects.run_effect(entity, component:get_instrument_effect())
		self._instrument_effect:set_finished_cb(function()
			play_instrument_effect()
		end)
	end

	play_player_effect()
	play_instrument_effect()

	ai:suspend('waiting for effect')

	component:set_state(false)
end

function SwampGoblinPlayInstrumentAction:stop(ai, entity, args)
	if self._timer then
		self._timer:destroy()
		self._timer = nil
	end
	if self._instrument_effect then
		self._instrument_effect:stop()
		self._instrument_effect = nil
	end
	if self._player_effect then
		self._player_effect:stop()
		self._player_effect = nil
	end
end

return SwampGoblinPlayInstrumentAction