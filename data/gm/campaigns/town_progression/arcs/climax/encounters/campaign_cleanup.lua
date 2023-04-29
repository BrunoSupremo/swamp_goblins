local CampaignCleanupScript = class()

function CampaignCleanupScript:start(ctx)
	self.timer = stonehearth.calendar:set_timer('wait the ui to distract the player', 1, function()
		-- Find all units owned by the specified player ID. This is slow, but fine for a single-use encounter.
		for _, entity in pairs(_radiant.sim.get_all_entities()) do
			if entity:get_player_id() == "firefly_human_encounter" then
				radiant.entities.destroy_entity(entity)
			end
		end
		self.timer = nil
	end)
end

return CampaignCleanupScript