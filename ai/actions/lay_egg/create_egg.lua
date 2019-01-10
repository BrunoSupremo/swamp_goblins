local Swamp_goblins_create_egg = radiant.class()
local Entity = _radiant.om.Entity

Swamp_goblins_create_egg.name = 'create goblin egg'
Swamp_goblins_create_egg.does = 'swamp_goblins:create_egg'
Swamp_goblins_create_egg.args = {
   pedestal = Entity
}
Swamp_goblins_create_egg.priority = 0
Swamp_goblins_create_egg.weight = 1

function Swamp_goblins_create_egg:run(ai, entity, args)
   args.pedestal:get_component("swamp_goblins:lay_egg_spot"):create_egg()
end

return Swamp_goblins_create_egg