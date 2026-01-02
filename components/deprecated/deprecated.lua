local SwampGoblinsDeprecated = class()

function SwampGoblinsDeprecated:post_activate()
	local deprecated = self._entity
	radiant.on_game_loop_once('SwampGoblinsDeprecated equipment_piece', function()
		if self._entity:get_component("stonehearth:equipment_piece") then
			deprecated = self._entity:get_component("stonehearth:equipment_piece"):get_owner()
		end
		print('Destroying deprecated entity:')
		print(deprecated)
		radiant.entities.destroy_entity(deprecated)
	end)
end

return SwampGoblinsDeprecated