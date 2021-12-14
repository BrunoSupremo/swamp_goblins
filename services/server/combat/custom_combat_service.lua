CustomCombatService = class()
local rng = _radiant.math.get_default_rng()

function CustomCombatService:_calculate_dart_damage(attacker, target, attack_info)
	local weapon = radiant.entities.get_equipped_item(attacker, 'darts_slot')

	if not weapon or not weapon:is_valid() then
		return 0
	end

	local weapon_data = radiant.entities.get_entity_data(weapon, 'stonehearth:combat:weapon_data')
	local base_damage = weapon_data["base_ranged_damage"]

	local total_damage = base_damage
	local attributes_component = attacker:get_component('stonehearth:attributes')
	if not attributes_component then
		return total_damage
	end
	local additive_dmg_modifier = attributes_component:get_attribute('additive_dmg_modifier')
	local multiplicative_dmg_modifier = attributes_component:get_attribute('multiplicative_dmg_modifier')
	local muscle = attributes_component:get_attribute('muscle')

	if muscle then
		local muscle_dmg_modifier = muscle * stonehearth.constants.attribute_effects.MUSCLE_MELEE_MULTIPLIER
		muscle_dmg_modifier = muscle_dmg_modifier + stonehearth.constants.attribute_effects.MUSCLE_MELEE_MULTIPLIER_BASE
		additive_dmg_modifier = additive_dmg_modifier + muscle_dmg_modifier
	end

	if multiplicative_dmg_modifier then
		local dmg_to_add = base_damage * multiplicative_dmg_modifier
		total_damage = dmg_to_add + total_damage
	end
	if additive_dmg_modifier then
		total_damage = total_damage + additive_dmg_modifier
	end

	--Get damage from weapons
	if attack_info.damage_multiplier then
		total_damage = total_damage * attack_info.damage_multiplier
	end

	--Get the damage reduction from armor
	local total_armor = self:calculate_total_armor(target)

	-- Reduce armor if attacker has armor reduction attributes
	local multiplicative_target_armor_modifier = attributes_component:get_attribute('multiplicative_target_armor_modifier', 1)
	local additive_target_armor_modifier = attributes_component:get_attribute('additive_target_armor_modifier', 0)

	if attack_info.target_armor_multiplier then
		multiplicative_target_armor_modifier = multiplicative_target_armor_modifier * attack_info.target_armor_multiplier
	end

	total_armor = total_armor * multiplicative_target_armor_modifier + additive_target_armor_modifier

	local damage = total_damage - total_armor
	damage = radiant.math.round(damage)

	if attack_info.minimum_damage and damage <= attack_info.minimum_damage then
		damage = attack_info.minimum_damage
	elseif damage < 1 then
		-- if attack will Do less than 1 damage, Then randomly it will Do either 1 or 0
		damage = rng:get_int(0, 1)
	end

	return damage
end

function CustomCombatService:start_cooldown(entity, action_info)
	local combat_state = self:get_combat_state(entity)
	if not combat_state then
		return
	end
	combat_state:start_cooldown(action_info.name, action_info.cooldown)

	if action_info.shared_cooldown_name then
		combat_state:start_cooldown(action_info.shared_cooldown_name, action_info.shared_cooldown)
	end

	if action_info.image then
		self:thought_bubble(entity, action_info.image)
	end
end

function CustomCombatService:thought_bubble(entity,image)
	entity:add_component('stonehearth:thought_bubble')
	:add_bubble(stonehearth.constants.thought_bubble.effects.INDICATOR,
		stonehearth.constants.thought_bubble.priorities.HUNGER+1,
		image, nil, '5m')
end

return CustomCombatService