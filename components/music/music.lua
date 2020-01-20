local SwampGoblinMusicComponent = class()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'
local rng = _radiant.math.get_default_rng()

function SwampGoblinMusicComponent:post_activate()
	self:set_state(false)

	local json = radiant.entities.get_json(self)
	self._instrument_sounds = json.instrument_sounds
	self._player_animations = json.player_animations
end

function SwampGoblinMusicComponent:get_random_effect(from)
	local weighted_set = WeightedSet(rng)
	for entry, weight in pairs(from) do
		weighted_set:add(entry, weight)
	end
	return weighted_set:choose_random() 
end

function SwampGoblinMusicComponent:get_player_effect()
	return self:get_random_effect(self._player_animations) or "whistle"
end

function SwampGoblinMusicComponent:get_instrument_effect()
	return self:get_random_effect(self._instrument_sounds) or "stonehearth:effects:death"
end

function SwampGoblinMusicComponent:is_ready()
	return self._enabled
end

function SwampGoblinMusicComponent:set_state(state)
	local commands_component = self._entity:get_component("stonehearth:commands")
	commands_component:set_command_enabled("swamp_goblins:commands:music", not state)
	self._enabled = state

	stonehearth.ai:reconsider_entity(self._entity)
end

return SwampGoblinMusicComponent