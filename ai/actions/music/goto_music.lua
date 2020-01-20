local SwampGoblinGoToMusicAction = class()

SwampGoblinGoToMusicAction.name = 'go to music'
SwampGoblinGoToMusicAction.does = 'swamp_goblins:goto_music'
SwampGoblinGoToMusicAction.status_text_key = 'swamp_goblins:ai.actions.status_text.enjoy_music'
SwampGoblinGoToMusicAction.args = { }
SwampGoblinGoToMusicAction.version = 2
SwampGoblinGoToMusicAction.priority = 1

function find_instrument(ai_entity)
	local player_id = ai_entity:get_player_id()
	return stonehearth.ai:filter_from_key('swamp_goblins:goto_music', player_id,
		function(target)
			if target:get_player_id() ~= player_id then
				return false
			end
			return radiant.entities.get_entity_data(target, 'swamp_goblins:audience_spot') ~= nil
		end
		)
end

local ai = stonehearth.ai
return ai:create_compound_action(SwampGoblinGoToMusicAction)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
	filter_fn = ai.CALL(find_instrument, ai.ENTITY),
	description = 'find instrument',
	stop_distance = 10
})
:execute('stonehearth:wander', { radius = 3, radius_min = 0 })
:execute('stonehearth:turn_to_face_entity', {
	entity = ai.BACK(2).destination_entity
})
:execute('swamp_goblins:enjoy_music', {instrument = ai.BACK(3).destination_entity})