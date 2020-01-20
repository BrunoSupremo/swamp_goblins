local validator = radiant.validator

local SwampGoblinMusicCallHandler = class()

function SwampGoblinMusicCallHandler:play_music(session, response, instrument)
	validator.expect_argument_types({'Entity'}, instrument)
	validator.expect.matching_player_id(session.player_id, instrument)

	instrument:get_component("swamp_goblins:music"):set_state(true)
end

return SwampGoblinMusicCallHandler