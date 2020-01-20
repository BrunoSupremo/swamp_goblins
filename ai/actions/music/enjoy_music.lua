local SwampGoblinEnjoyMusicAction = radiant.class()
local Entity = _radiant.om.Entity
local rng = _radiant.math.get_default_rng()

SwampGoblinEnjoyMusicAction.name = 'enjoy music'
SwampGoblinEnjoyMusicAction.does = 'swamp_goblins:enjoy_music'
SwampGoblinEnjoyMusicAction.args = {
	instrument = Entity
}
SwampGoblinEnjoyMusicAction.priority = {0, 1}
SwampGoblinEnjoyMusicAction.weight = 1

local EFFECTS = {
   'emote_confetti',
   'emote_dance_handsup',
   'emote_dance_shuffle',
   'emote_dance_themonkey',
   'emote_applaud',
   'emote_applaud_upward',
   'happy_idle_breathe',
   'happy_idle_breathe',
   'happy_idle_breathe',
   'idle_look_around',
   'idle_look_around',
   'idle_look_around',
   'idle_breathe',
   'idle_breathe',
   'idle_breathe',
   'whistle'
}

function SwampGoblinEnjoyMusicAction:start_thinking(ai, entity, args)
	ai:set_utility(rng:get_real(0, 1))
	ai:set_think_output()
end

function SwampGoblinEnjoyMusicAction:run(ai, entity, args)
	local function play_player_effect()
		if not args.instrument then
			ai:resume('effect finished')
			return
		end
		self._effect = radiant.effects.run_effect(entity, EFFECTS[rng:get_int(1, #EFFECTS)])
		self._effect:set_finished_cb(function()
			play_player_effect()
		end)
	end
	play_player_effect()

	ai:suspend('waiting for effect')
end

function SwampGoblinEnjoyMusicAction:stop(ai, entity, args)
	if self._effect then
		self._effect:stop()
		self._effect = nil
	end
end

return SwampGoblinEnjoyMusicAction