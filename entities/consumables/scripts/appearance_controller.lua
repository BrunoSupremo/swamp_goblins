local AppearancePotionController = class()

function AppearancePotionController:initialize()
end

function AppearancePotionController:create(player_id)
	local info = {}
	info.title = "i18n(swamp_goblins:entities.consumables.appearance_potion.ui.title)"
	info.dialog_title = "i18n(swamp_goblins:entities.consumables.appearance_potion.ui.dialog_title)"
	info.text = "i18n(swamp_goblins:entities.consumables.appearance_potion.ui.text)"
	info.requirements = { { } }

	local bulletin_data = info
	bulletin_data.on_try_dispatch = '_on_try_dispatch'
	bulletin_data.on_abandon = '_on_abandon'

	self.bulletin = stonehearth.bulletin_board:post_bulletin(player_id)
	:set_callback_instance(self)
	:set_sticky(true)
	:set_close_on_handle(false)
	:set_type('quest')

	self.bulletin:set_data(bulletin_data)
	:set_ui_view('StonehearthDispatchQuestBulletinDialog')
	self.__saved_variables:mark_changed()
end

function AppearancePotionController:_on_try_dispatch(session, request, citizens)
	for _, entity in pairs(citizens) do
		local cc = entity:get_component('stonehearth:customization')
		cc:_remove_all_styles()
		cc:generate_custom_appearance()
		radiant.effects.run_effect(entity, "stonehearth:effects:spawn_entity")
	end

	self:destroy()
end

function AppearancePotionController:_on_abandon()
	self:destroy()
end

function AppearancePotionController:destroy()
	if self.bulletin then
		stonehearth.bulletin_board:remove_bulletin(self.bulletin)
		self.bulletin = nil
		self.__saved_variables:mark_changed()
	end
end

return AppearancePotionController