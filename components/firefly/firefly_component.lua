local FireflyComponent = class()

function FireflyComponent:post_activate()
	self._entity:remove_component("swamp_goblins:firefly")
end

return FireflyComponent