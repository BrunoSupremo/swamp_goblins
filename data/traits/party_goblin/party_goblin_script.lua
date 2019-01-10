local constants = require 'stonehearth.constants'

local PartyGoblinTrait = class()

local CONCLUSION = constants.conversation.stages.CONCLUSION

function PartyGoblinTrait:initialize()
   self._sv._entity = nil
   self._sv._uri = nil
end

function PartyGoblinTrait:create(entity, uri)
   self._sv._entity = entity
   self._sv._uri = uri
   self.went_through_create = true
end

function PartyGoblinTrait:activate()
   self._conversation_start_listener = radiant.events.listen(self._sv._entity, 'stonehearth:conversation:start', self, self._on_conversation_start)
   self._conversation_result_listener = radiant.events.listen(self._sv._entity, 'stonehearth:conversation:results_produced', self, self._on_conversation_results)

   local json = radiant.resources.load_json(self._sv._uri)
   self._receives_thought = json.data.receives_thought
   self._gives_thought = json.data.gives_thought
   self._gives_animation = json.data.gives_animation
end

function PartyGoblinTrait:post_activate()
   if self.went_through_create then
      self._sv._entity:get_component('stonehearth:equipment'):equip_item("swamp_goblins:armor:party_goblin_hat")
   end
end

function PartyGoblinTrait:destroy()
   if self._conversation_start_listener then
      self._conversation_start_listener:destroy()
      self._conversation_start_listener = nil
   end
   if self._conversation_result_listener then
      self._conversation_result_listener:destroy()
      self._conversation_result_listener = nil
   end
   self._sv._entity:get_component('stonehearth:equipment'):unequip_item("swamp_goblins:armor:party_goblin_hat")
end

function PartyGoblinTrait:_on_conversation_start(args)
   local target = stonehearth.conversation:get_target(self._sv._entity)
   if target and target:is_valid() then
      stonehearth.conversation:replace_thought(target, self._gives_thought.result, self._gives_thought.thought)
      stonehearth.conversation:replace_thought(self._sv._entity, self._receives_thought.result, self._receives_thought.thought)
   end
end

function PartyGoblinTrait:_on_conversation_results(args)
   local target = stonehearth.conversation:get_target(self._sv._entity)

   if target and target:is_valid() then
      local result = args.conversation_result.result
      if result == self._gives_animation.result then
         stonehearth.conversation:add_animation_override(target, CONCLUSION, self._gives_animation.animation)
      end
   end
end

return PartyGoblinTrait