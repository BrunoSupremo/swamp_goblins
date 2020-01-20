local SwampGoblinAudienceAction = radiant.class()
local Entity = _radiant.om.Entity

SwampGoblinAudienceAction.name = 'create_audience instrument'
SwampGoblinAudienceAction.does = 'swamp_goblins:create_audience'
SwampGoblinAudienceAction.args = {
	instrument = Entity
}
SwampGoblinAudienceAction.priority = 0
SwampGoblinAudienceAction.weight = 1

function SwampGoblinAudienceAction:run(ai, entity, args)
	self._audience_spot = radiant.entities.create_entity("swamp_goblins:music:audience",
		{owner = entity:get_player_id()})
	radiant.terrain.place_entity(self._audience_spot,
		radiant.entities.get_world_grid_location(entity))
end

function SwampGoblinAudienceAction:stop(ai, entity, args)
	radiant.entities.destroy_entity(self._audience_spot)
end

return SwampGoblinAudienceAction