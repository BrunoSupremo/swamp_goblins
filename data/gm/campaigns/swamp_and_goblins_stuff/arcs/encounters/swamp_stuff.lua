local SwampStuff = class()

function SwampStuff:initialize()
	self._sv.firefly_script = nil
end

function SwampStuff:start(ctx)
	self._sv.firefly_script = radiant.create_controller("swamp_goblins:game_master:spawn_firefly", ctx.player_id)
end

function SwampStuff:stop()
end

function SwampStuff:restore()
end

function SwampStuff:post_activate()
end

function SwampStuff:destroy()
end

return SwampStuff