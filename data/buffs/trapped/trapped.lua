local SwampGoblins_TrappedBuff = class()

function SwampGoblins_TrappedBuff:on_buff_added(entity, buff)
	self.trap = radiant.entities.create_entity("swamp_goblins:summons:trap")
	local radius = radiant.entities.get_entity_data(entity, 'stonehearth:entity_radius')
	if not radius then
		radius = entity:get_component("render_info"):get_scale()*2
	else
		radius = radius/4
	end
	if radius < 0.1 then radius = 0.1 end
	if radius > 1 then radius = 1 end
	self.trap:get_component("render_info"):set_scale(radius)
	local location = radiant.entities.get_world_location(entity)
	radiant.terrain.place_entity_at_exact_location(self.trap, location)
end

function SwampGoblins_TrappedBuff:on_buff_removed(entity, buff)
	radiant.entities.destroy_entity(self.trap)
end

return SwampGoblins_TrappedBuff