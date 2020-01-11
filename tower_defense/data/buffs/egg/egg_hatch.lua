local TowerCH = require 'tower_defense.call_handlers.tower_call_handler'

local FireflyTowerEggHatch = class()

function FireflyTowerEggHatch:on_buff_added(entity, buff)
	local location = radiant.entities.get_world_grid_location(entity)
	local player_id = entity:get_player_id()
	local facing = radiant.entities.get_facing(entity)
	radiant.entities.destroy_entity(entity)

	local uri = {
		"swamp_goblins:towers:worker",
		"swamp_goblins:towers:warrior",
		"swamp_goblins:towers:shaman",
		"swamp_goblins:towers:spirit_walker",
		"swamp_goblins:towers:trapper",
		"swamp_goblins:towers:beast_tamer",
		"swamp_goblins:towers:bonesmith",
		"swamp_goblins:towers:earthmaster"
	}
	local rng = _radiant.math.get_default_rng()
	local baby = radiant.entities.create_entity(uri[rng:get_int(1,8)], { owner = player_id })
	radiant.terrain.place_entity_at_exact_location(baby, location, { force_iconic = false, facing = facing })
	baby:get_component('tower_defense:tower'):placed(facing)
	local inventory = stonehearth.inventory:get_inventory(player_id)
	if inventory and not inventory:contains_item(baby) then
		inventory:add_item(baby)
	end
end

return FireflyTowerEggHatch