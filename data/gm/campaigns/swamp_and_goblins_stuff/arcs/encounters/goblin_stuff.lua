local GoblinStuff = class()

function GoblinStuff:initialize()
	self._sv.firefly_script = nil
end

function GoblinStuff:start(ctx)
	if stonehearth.world_generation:get_biome_alias() ~= "swamp_goblins:biome:swamp" then
		--if we are in the swamp, this is not needed as the biome will create this itself for all players
		self._sv.firefly_script = radiant.create_controller("swamp_goblins:game_master:spawn_firefly", ctx.player_id)
	end
end

function GoblinStuff:stop()
end

function GoblinStuff:restore()
end

function GoblinStuff:post_activate()
end

function GoblinStuff:destroy()
end

return GoblinStuff