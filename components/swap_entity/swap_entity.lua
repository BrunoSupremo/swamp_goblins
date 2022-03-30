local SwapEntity = class()

function SwapEntity:post_activate()
	local commands_component = self._entity:add_component("stonehearth:commands")
	commands_component:add_command("swamp_goblins:commands:swap_entity")
end

function SwapEntity:swap()
	local json = radiant.entities.get_json(self)
	
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	local facing = radiant.entities.get_facing(self._entity)

	local new_entity = radiant.entities.create_entity(json.swap_to, { owner = self._entity})
	radiant.entities.set_player_id(new_entity, self._entity)

	radiant.terrain.remove_entity(self._entity)

	radiant.terrain.place_entity_at_exact_location(new_entity, location, { force_iconic = false, facing = facing } )

	radiant.entities.destroy_entity(self._entity)	
end

return SwapEntity