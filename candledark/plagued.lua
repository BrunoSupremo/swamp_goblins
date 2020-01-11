-- Implementation based on model variants.
-- Gender must also be defined in constants.json for the model_variants
local PlagueBuff = class()

function PlagueBuff:_init()
end

-- entity is the entity that has this buff aplied
-- plagued_buff is the buff controller that contains the buff properties (json)
function PlagueBuff:on_buff_added(entity, plagued_buff)
	local delayed_function = function ()
		plagued_buff:destroy()
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	local job = entity:get_component("stonehearth:job")
	if not job then
		--no jobs? must be an object or a simple critter, don't add a plague
		self.stupid_delay = stonehearth.calendar:set_persistent_timer("candledark_buff delay", 0, delayed_function)
		return
	end
	self._player_id = radiant.entities.get_player_id(entity)
	self._town = stonehearth.town:get_town(self._player_id)
	self._buff_data = plagued_buff._json.data

	if self._buff_data.disallowed_entities and self._buff_data.disallowed_entities[entity:get_uri()] then
		--is this entity not allowed to be plagued? don't add a plague
		self.stupid_delay = stonehearth.calendar:set_persistent_timer("candledark_buff delay", 0, delayed_function)
		return
	end
	if self._buff_data.disallowed_jobs and self._buff_data.disallowed_jobs[job:get_job_uri()] then
		--is this job not allowed to be plagued? don't add a plague
		self.stupid_delay = stonehearth.calendar:set_persistent_timer("candledark_buff delay", 0, delayed_function)
		return
	end

	-- Retrieve name of original entity for the bitten / turned notifications
	self._display_name = radiant.entities.get_display_name(entity)
	self._custom_name = radiant.entities.get_custom_name(entity)

	-- Notify that the entity has been bitten by undead
	self:show_notification(entity, self._player_id, self._town, 
		self._display_name, self._custom_name, 
		'i18n(candledark:ui.game.entities.bite_notification)')

	-- Create timer to turn the entity into a wight
	self._turn_time = self._buff_data.turn_time
	self._turn_timer = stonehearth.calendar:set_timer("Turning", self._turn_time, function ()

		-- Change their model variant to a '_turned' version
		local render_info = entity:add_component('render_info')
		local model_variant = render_info:get_model_variant()
		-- Only change variants if it's the first time we get bitten
		-- Alternatively, just let the buff finish its duration (it decreases their speed)
		if not string.match(model_variant, '_turned') then
			render_info:set_model_variant(model_variant .. '_turned')

			-- Promote them to Worker and prevent promotion to other jobs
			self:restrict_jobs(entity, self._buff_data)

			-- Retrieve the gender from the constants to apply a correctly localized name
			local pop = stonehearth.population:get_population(self._player_id)
			local gender = pop:get_gender(entity)
			local unit_info = entity:add_component('stonehearth:unit_info')
			if gender == 'female' then
				unit_info:set_display_name('i18n(candledark:data.names.plagued.female_name)')
			else
				unit_info:set_display_name('i18n(candledark:data.names.plagued.male_name)')
			end

			-- Set their base stats to 1/1/1
			self:apply_attributes(entity, self._buff_data)

			-- Remove the plagued buff from the entity
			plagued_buff:destroy()

			-- And finally, show the notification that the entity was turned to a mindless wight.
			-- We use the original entity's name here for the notification
			self:show_notification(entity, self._player_id, self._town, 
				self._display_name, self._custom_name,
				'i18n(candledark:ui.game.entities.turn_notification)')
		end
	end)
end

function PlagueBuff:on_buff_removed(entity)
	if self._turn_timer then
		self._turn_timer:destroy()
		self._turn_timer = nil
	end
end

function PlagueBuff:show_notification(entity, player_id, town, display_name, custom_name, title)
	self.bite_notification_bulletin = stonehearth.bulletin_board:post_bulletin(player_id)
	:set_callback_instance(town)
	:set_type('alert')
	:set_data ({
		title = title,
		message = '',
		zoom_to_entity = entity,
	})
	:add_i18n_data('entity_display_name', display_name)
	:add_i18n_data('entity_custom_name', custom_name)
end

function PlagueBuff:restrict_jobs(entity, buff_data)
	local job = buff_data.wight_job
	local jc = entity:add_component('stonehearth:job')
	jc:promote_to(job)
	jc:set_allowed_jobs(buff_data.allowed_jobs)
end

function PlagueBuff:apply_attributes(entity, buff_data)
	local attribute_component = entity:get_component('stonehearth:attributes')
	if attribute_component then
		for attr, value in pairs(buff_data.attributes) do
			attribute_component:set_attribute(attr, value)
		end
	end
end

return PlagueBuff
