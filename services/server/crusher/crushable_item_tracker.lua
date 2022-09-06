local entity_forms = require 'stonehearth.lib.entity_forms.entity_forms_lib'

local CrushableItemTracker = class()

function CrushableItemTracker:create_key_for_entity(entity, storage)
	assert(entity:is_valid(), 'entity is not valid.')

	local entity_uri, _ = entity_forms.get_uris(entity)

	local net_worth = radiant.entities.get_entity_data(entity_uri, 'stonehearth:net_worth')
	if not (net_worth and net_worth.shop_info and net_worth.shop_info.sellable) then
		-- if it can't be sold, then better not be destroyed (quest items, important stuff, etc...)
		return nil
	end

	if self.recipes_list then
		if not self.recipes_list[entity_uri] then
			-- no recipe for this, destroying would give nothing, so don't be an option
			return nil
		end
	end

	if storage then
		local storage_component = storage:get_component('stonehearth:storage')
		if storage_component and (storage_component:is_public() or storage_component:get_type() == 'escrow') then
			return entity_uri
		end
	end

	return nil
end

function CrushableItemTracker:add_entity_to_tracking_data(entity, tracking_data)
	if not tracking_data then
		local entity_uri, _ = entity_forms.get_uris(entity)
		tracking_data = {
			uri = entity_uri,
			count = 0,
			items = {}
		}
	end

	local id = entity:get_id()
	if not tracking_data.items[id] then
		tracking_data.count = tracking_data.count + 1
		tracking_data.items[id] = entity
	end

	return tracking_data
end

function CrushableItemTracker:remove_entity_from_tracking_data(entity_id, tracking_data)
	if not tracking_data then
		return nil
	end

	if tracking_data.items[entity_id] then
		tracking_data.items[entity_id] = nil
		tracking_data.count = tracking_data.count - 1

		if tracking_data.count <= 0 then
			return nil
		end
	end

	return tracking_data
end

return CrushableItemTracker