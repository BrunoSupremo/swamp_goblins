local DespawnSummon = radiant.class()

DespawnSummon.name = 'despawnSummon'
DespawnSummon.does = 'stonehearth:idle'
DespawnSummon.args = {}
DespawnSummon.priority = 1.0

function DespawnSummon:start_thinking(ai, entity, args)
	ai:set_think_output()
end

function DespawnSummon:run(ai, entity, args)
	local proxy = radiant.entities.create_entity('stonehearth:object:transient')
	local summon_location = radiant.entities.get_world_grid_location(entity)
	radiant.terrain.place_entity_at_exact_location(proxy, summon_location)
	radiant.effects.run_effect(proxy, "stonehearth:effects:spawn_entity"):set_finished_cb(function()
		radiant.entities.destroy_entity(proxy)
		end)
	ai:execute('stonehearth:destroy_entity')
end

return DespawnSummon