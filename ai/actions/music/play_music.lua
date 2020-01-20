local SwampGoblinPlayMusicAction = class()

SwampGoblinPlayMusicAction.name = 'play music'
SwampGoblinPlayMusicAction.does = 'swamp_goblins:play_music'
SwampGoblinPlayMusicAction.status_text_key = 'swamp_goblins:ai.actions.status_text.play_music'
SwampGoblinPlayMusicAction.args = { }
SwampGoblinPlayMusicAction.version = 2
SwampGoblinPlayMusicAction.priority = 1

function find_instrument(ai_entity)
	local player_id = ai_entity:get_player_id()
	return stonehearth.ai:filter_from_key('swamp_goblins:play_music', player_id,
		function(target)
			if target:get_player_id() ~= player_id then
				return false
			end
			if target:get_component("swamp_goblins:music") then
				return target:get_component("swamp_goblins:music"):is_ready()
			end
			return false
		end
		)
end

local ai = stonehearth.ai
return ai:create_compound_action(SwampGoblinPlayMusicAction)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
	filter_fn = ai.CALL(find_instrument, ai.ENTITY),
	description = 'find instrument'
	})
:execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
:execute('stonehearth:turn_to_face_entity', {
	entity = ai.BACK(2).destination_entity
})
:execute('swamp_goblins:create_audience', {instrument = ai.BACK(3).destination_entity})
:execute('swamp_goblins:play_instrument', {instrument = ai.BACK(4).destination_entity})