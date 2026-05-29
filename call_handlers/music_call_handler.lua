local validator = radiant.validator

local SwampGoblinMusicCallHandler = class()

function SwampGoblinMusicCallHandler:play_music(session, response, instrument)
	validator.expect_argument_types({'Entity'}, instrument)
	validator.expect.matching_player_id(session.player_id, instrument)

	radiant.create_controller("swamp_goblins:music_controller", instrument)
end

return SwampGoblinMusicCallHandler