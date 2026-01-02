local DeviantPigmentTrait = class()
local rng = _radiant.math.get_default_rng()

function DeviantPigmentTrait:initialize()
	self._sv._entity = nil
	self._sv._material_map = nil
end

function DeviantPigmentTrait:post_activate()
	radiant.on_game_loop_once('deprecated', function()
		radiant.entities.remove_trait(self._sv._entity, "swamp_goblins:traits:deviant_pigment")
	end)
end

return DeviantPigmentTrait