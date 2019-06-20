local validator = radiant.validator
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3

local GoblinsBattleRoyalCallHandler = class()

function GoblinsBattleRoyalCallHandler:end_madness_please(session, response, hearth)
	local ending_this_now = function ()
		

		self.fight_timer:destroy()
		self.fight_timer = nil
	end
	self.fight_timer = stonehearth.calendar:set_persistent_timer("SwampGoblins BattleRoyal", 0, ending_this_now)
end

function GoblinsBattleRoyalCallHandler:start_madness(session, response, hearth)
	validator.expect_argument_types({'Entity'}, hearth)
	validator.expect.matching_player_id(session.player_id, hearth)
	
	local location = radiant.entities.get_world_grid_location(hearth)
	if not location then
		return
	end
	local cube = Cube3(location):inflated(Point3(16,16,16))
	local goblin_fighters = radiant.terrain.get_entities_in_cube(cube, function(candidate)
		if candidate:get_player_id() == session.player_id then
			local job_component = candidate:get_component('stonehearth:job')
			return job_component and job_component:has_role("combat") and not job_component:has_role("goblin_worker_job")
		end
	end)
	local battle_royal_team = 0
	for id, entity in pairs(goblin_fighters) do
		battle_royal_team = battle_royal_team+1
		local battle_player_id = "battle_royal_team_" .. (battle_royal_team%2+1)
		
		-- if not stonehearth.player:get_kingdom(battle_player_id) then
		-- 	stonehearth.player:add_kingdom(battle_player_id, "swamp_goblins:kingdoms:battle_player_id")
		-- end
		radiant.entities.set_player_id(entity, battle_player_id)
	end

	self:end_madness_please()
end

return GoblinsBattleRoyalCallHandler