local AppearancePotion = class()

function AppearancePotion.use(consumable, consumable_data, player_id, target_entity)
	radiant.create_controller('swamp_goblins:potion:appearance', player_id )

	return true
end

return AppearancePotion