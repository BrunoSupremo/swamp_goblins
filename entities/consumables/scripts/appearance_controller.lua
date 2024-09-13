local AppearancePotionController = class()
local rng = _radiant.math.get_default_rng()

function AppearancePotionController:initialize()
end

function AppearancePotionController:create(player_id)
	local info = {}
	info.title = "i18n(swamp_goblins:entities.consumables.potions.appearance.ui.title)"
	info.dialog_title = "i18n(swamp_goblins:entities.consumables.potions.appearance.ui.dialog_title)"
	info.text = "i18n(swamp_goblins:entities.consumables.potions.appearance.ui.text)"
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
		cc:regenerate_appearance()

		local trait_comp = entity:get_component("stonehearth:traits")
		trait_comp:remove_trait("swamp_goblins:traits:deviant_pigment")
		if rng:get_int(1,2) == 1 then
			trait_comp:add_trait("swamp_goblins:traits:deviant_pigment")
		end

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