local Entity = _radiant.om.Entity
local GetRawFoodOnGround = radiant.class()

GetRawFoodOnGround.name = 'get raw food on the ground'
GetRawFoodOnGround.does = 'stonehearth:get_food'
GetRawFoodOnGround.args = {
   food_filter_fn = 'function',
   food_rating_fn = 'function',
}
GetRawFoodOnGround.think_output = {
   food_filter_fn = 'function',
}
GetRawFoodOnGround.priority = {0, 1}

local function make_filter_fn(owner_id, food_filter_fn)
   return function(item)
         if owner_id ~= nil and owner_id ~= radiant.entities.get_player_id(item) then
            return false
         end
         return (radiant.entities.is_material(item, 'food') or radiant.entities.is_material(item, 'meat') or radiant.entities.is_material(item, 'egg')) and food_filter_fn(item)
      end
end

function GetRawFoodOnGround:start_thinking(ai, entity, args)
   local owner_id = radiant.entities.get_player_id(entity)
   local key = tostring(args.food_filter_fn) .. ':' .. owner_id
   ai:set_think_output({
         food_filter_fn = stonehearth.ai:filter_from_key('find_raw_food_on_ground', key, make_filter_fn(owner_id, args.food_filter_fn))
      })
end

function GetRawFoodOnGround:compose_utility(entity, self_utility, child_utilities, current_activity)
   return child_utilities:get('stonehearth:find_best_reachable_entity_by_type')
end

local ai = stonehearth.ai
return ai:create_compound_action(GetRawFoodOnGround)
         :execute('stonehearth:drop_carrying_now', {})
         :execute('stonehearth:find_best_reachable_entity_by_type', {
            filter_fn = ai.BACK(2).food_filter_fn,
            rating_fn = ai.ARGS.food_rating_fn,
            description = 'raw food on ground filter',
         })
         :execute('stonehearth:pickup_item', {
            item = ai.PREV.item
         })
