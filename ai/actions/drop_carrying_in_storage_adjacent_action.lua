local Entity = _radiant.om.Entity

local DropCarryingInStorageAdjacent = radiant.class()

DropCarryingInStorageAdjacent.name = 'drop carrying in storage'
DropCarryingInStorageAdjacent.does = 'stonehearth:drop_carrying_in_storage_adjacent'
DropCarryingInStorageAdjacent.args = {
	storage = Entity,
}
DropCarryingInStorageAdjacent.think_output = {
	item = Entity,
}
DropCarryingInStorageAdjacent.priority = 0

function DropCarryingInStorageAdjacent:start_thinking(ai, entity, args)
	if not ai.CURRENT.carrying then
		return
	end

	local sc = args.storage:add_component('stonehearth:storage')
	if sc:is_full() then
		ai:reject('storage is full')
		return
	end

	local carrying = ai.CURRENT.carrying
	ai.CURRENT.carrying = nil
	ai:set_think_output({ item = carrying })
end

function DropCarryingInStorageAdjacent:run(ai, entity, args)
	radiant.check.is_entity(entity)

	if not radiant.entities.get_carrying(entity) then
		ai:abort('cannot put carrying in storage if you are not carrying anything')
		return
	end

	local sc = args.storage:add_component('stonehearth:storage')
	if sc:is_full() then
		return
	end

	if not radiant.entities.is_adjacent_to(entity, args.storage) then
		ai:abort(string.format('%s is not adjacent to %s', tostring(entity), tostring(args.storage)))
	end

	radiant.entities.turn_to_face(entity, args.storage)
	local storage_location = radiant.entities.get_world_grid_location(args.storage)
	local table_data = radiant.entities.get_entity_data(args.storage, 'stonehearth:table')
	if table_data then
		self._drop_effect = table_data['drop_effect']
	end
	ai:execute('stonehearth:run_putdown_effect', {
		location = storage_location,
		effect_name = self._drop_effect
	})

	if sc:is_full() then
		-- Have to check again if the storage is full because it might have become full while we were running the
		-- put down effect.
		return
	end

	local item = radiant.entities.remove_carrying(entity)
	-- note that the item might have been destroyed during the putdown effect (in one case the food rotted away)
	if item then
		sc:add_item(item)
	end
end

return DropCarryingInStorageAdjacent