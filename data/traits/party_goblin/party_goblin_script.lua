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
end

function PartyGoblinTrait:activate()
	local is_goblin = self._sv._entity:get_component("swamp_goblins:firefly_goblin")
	if not is_goblin then
		self._delay_start_timer = radiant.on_game_loop_once('PartyGoblinTrait not a goblin', function()
			radiant.entities.remove_trait(self._sv._entity, "swamp_goblins:traits:party_goblin")
		end)
		return
	end
	self._conversation_start_listener = radiant.events.listen(self._sv._entity, 'stonehearth:conversation:start', self, self._on_conversation_start)
	self._conversation_result_listener = radiant.events.listen(self._sv._entity, 'stonehearth:conversation:results_produced', self, self._on_conversation_results)

	local json = radiant.resources.load_json(self._sv._uri)
	self._receives_thought = json.data.receives_thought
	self._gives_thought = json.data.gives_thought
	self._gives_animation = json.data.gives_animation

	self._job_changed_listener = radiant.events.listen(self._sv._entity, 'stonehearth:job_changed', self, self._on_job_changed)
	self:_on_job_changed()
	radiant.entities.add_buff(self._sv._entity, "swamp_goblins:buffs:chatty")
end

function PartyGoblinTrait:_on_job_changed()
	local job_comp = self._sv._entity:get_component("stonehearth:job")
	local job = job_comp:get_job_uri()
	if job == "stonehearth:jobs:worker" then
		local equip_component = self._sv._entity:get_component('stonehearth:equipment')
		equip_component:equip_item("swamp_goblins:armor:party_goblin_hat")
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
	if self._job_changed_listener then
		self._job_changed_listener:destroy()
		self._job_changed_listener = nil
	end
	self._sv._entity:get_component('stonehearth:equipment'):unequip_item("swamp_goblins:armor:party_goblin_hat")
	radiant.entities.remove_buff(self._sv._entity, "swamp_goblins:buffs:chatty")
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