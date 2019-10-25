local SwampGoblinsDeprecated = class()

function SwampGoblinsDeprecated:post_activate()
	radiant.entities.destroy_entity(self._entity)
end

return SwampGoblinsDeprecated