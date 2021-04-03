local GetRawFoodFromContainerFromStorage = radiant.class()

GetRawFoodFromContainerFromStorage.name = 'get raw food from storage'
GetRawFoodFromContainerFromStorage.does = 'stonehearth:get_food'
GetRawFoodFromContainerFromStorage.args = {
   food_filter_fn = 'function',
   food_rating_fn = 'function',
}
GetRawFoodFromContainerFromStorage.think_output = {
   food_container_filter_fn = 'function',
}
GetRawFoodFromContainerFromStorage.priority = 0

local function make_food_container_filter(owner_id, food_filter_fn)
   return function(item)
         if not (radiant.entities.is_material(item, 'food') or radiant.entities.is_material(item, 'meat') or radiant.entities.is_material(item, 'egg')) then
            return false
         end
         if owner_id ~= '' and radiant.entities.get_player_id(item) ~= owner_id then
            return false
         end
         return food_filter_fn(item)
      end
end

function GetRawFoodFromContainerFromStorage:start_thinking(ai, entity, args)
   local owner_id = radiant.entities.get_player_id(entity)
   local key = tostring(args.food_filter_fn) .. ':' .. owner_id
   ai:set_think_output({
         food_container_filter_fn = stonehearth.ai:filter_from_key('raw_food_filter', key, make_food_container_filter(owner_id, args.food_filter_fn)),
      })
end

local ai = stonehearth.ai
return ai:create_compound_action(GetRawFoodFromContainerFromStorage)
         :execute('stonehearth:drop_carrying_now', {})
         :execute('stonehearth:find_reachable_storage_containing_best_entity_type', {
            filter_fn = ai.BACK(2).food_container_filter_fn,
            rating_fn = ai.ARGS.food_rating_fn,
            description = 'find path to raw food container',
         })
         :execute('stonehearth:pickup_item_type_from_storage', {
            filter_fn = ai.ARGS.food_filter_fn,
            rating_fn = ai.ARGS.food_rating_fn,
            storage = ai.PREV.storage,
            description = 'find path to raw food container',
         })