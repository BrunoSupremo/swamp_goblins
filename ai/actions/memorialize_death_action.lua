local MemorializeDeathAction = radiant.class()

MemorializeDeathAction.name = 'memorialize death'
MemorializeDeathAction.does = 'stonehearth:memorialize_death'
MemorializeDeathAction.args = {}
MemorializeDeathAction.priority = 0.5

local CUSTOMIZED_DISPLAY_NAME = "i18n(stonehearth:entities.furniture.tombstone.tombstone_ghost.display_name)"
local CUSTOMIZED_DESCRIPTION = "i18n(stonehearth:entities.furniture.tombstone.tombstone_ghost.description)"

function MemorializeDeathAction:start_thinking(ai, entity, args)
   ai:set_think_output()
end

function MemorializeDeathAction:run(ai, entity, args)
   local display_name = radiant.entities.get_display_name(entity)
   local custom_name = radiant.entities.get_custom_name(entity)
   local player_id = radiant.entities.get_player_id(entity)
   local location = radiant.entities.get_world_grid_location(entity)

   local tombstone = radiant.entities.create_entity('swamp_goblins:decoration:tombstone', { owner = entity })
   local name_component = tombstone:add_component('stonehearth:unit_info')
   if custom_name:len() > 0 then
      name_component:set_display_name(CUSTOMIZED_DISPLAY_NAME)
      name_component:set_description(CUSTOMIZED_DESCRIPTION)
      name_component:set_custom_name(custom_name)
   else
      name_component:set_display_name(display_name)
   end

   location = radiant.terrain.find_closest_standable_point_to(location, 5, tombstone)
   radiant.terrain.place_entity(tombstone, location, { force_iconic = false })
   radiant.effects.run_effect(tombstone, 'stonehearth:effects:tombstone_effect')

   local town = stonehearth.town:get_town(player_id)
   town:add_thought_to_town('stonehearth:thoughts:violence:townmember_died')

   self.notification_bulletin = stonehearth.bulletin_board:post_bulletin(player_id)
   :set_callback_instance(town)
   :set_type('alert')
   :set_data({
      title = 'i18n(stonehearth:ui.game.entities.death_notification)',
      message = '',
      zoom_to_entity = tombstone,
   })
   :add_i18n_data('entity_display_name', display_name)
   :add_i18n_data('entity_custom_name', custom_name)
end

return MemorializeDeathAction