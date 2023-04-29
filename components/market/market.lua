local GoblinMarketComponent = class()

function GoblinMarketComponent:initialize()
	self._sv._restock_timer = nil
	self._sv._is_open = false
end

function GoblinMarketComponent:create()
	self._sv._is_open = true
end

function GoblinMarketComponent:post_activate()
	self.json = radiant.entities.get_json(self)
	local commands_component = self._entity:get_component("stonehearth:commands")
	if self._sv._is_open then
		commands_component:set_command_enabled('swamp_goblins:commands:market',true)
		self._entity:get_component('render_info'):set_model_variant("default")
	else
		commands_component:set_command_enabled('swamp_goblins:commands:market',false)
		self._entity:get_component('render_info'):set_model_variant("closed")
	end
end


function GoblinMarketComponent:create_shop()
	local player_id = radiant.entities.get_player_id(self._entity)
	local population = stonehearth.population:get_population(player_id)
	local city_tier = population:get_city_tier() or 0
	if city_tier < 1 then
		city_tier = 1
	end
	city_tier = "tier_" .. city_tier
	local info = radiant.resources.load_json(self.json[city_tier]).shop_info
	local shop_name = radiant.entities.get_entity_data(self._entity, 'stonehearth:catalog').display_name
	info.name = shop_name or info.name 
	info.title = shop_name or info.title 

	local shop = stonehearth.shop:create_shop(player_id, info.name, info.inventory)

	local bulletin = stonehearth.bulletin_board:post_bulletin(player_id)
	:set_ui_view('StonehearthShopBulletinDialog')
	:set_callback_instance(self)
	:set_sticky(true)
	:set_data({
		shop = shop,
		title = info.title,
		opened_callback = '_on_opened',
		closed_callback = '_on_closed'
	})
	self.shop = shop
	self.bulletin = bulletin

	local commands_component = self._entity:get_component("stonehearth:commands")
	commands_component:set_command_enabled('swamp_goblins:commands:market',false)
end

function GoblinMarketComponent:destroy()
	if self._sv._restock_timer then
		self._sv._restock_timer:destroy()
		self._sv._restock_timer = nil
	end
	if self.shop then
		stonehearth.shop:destroy_shop(self.shop)
		self.shop = nil
	end
	if self.bulletin then
		stonehearth.bulletin_board:remove_bulletin(self.bulletin)
		self.bulletin = nil
	end
end

function GoblinMarketComponent:_on_opened()
	radiant.effects.run_effect(self._entity, 'emote_count')
end

function GoblinMarketComponent:_on_closed()
	self:close_shop()
	self._sv._restock_timer = stonehearth.calendar:set_persistent_timer('shopkeeper restocking', '1d', radiant.bind(self, 'open_shop'))
	radiant.effects.run_effect(self._entity, 'stonehearth:effects:spawn_entity')
end

function GoblinMarketComponent:open_shop()
	self._sv._is_open = true
	local commands_component = self._entity:get_component("stonehearth:commands")
	commands_component:set_command_enabled('swamp_goblins:commands:market',true)
	self._entity:get_component('render_info'):set_model_variant("default")
end

function GoblinMarketComponent:close_shop()
	self._sv._is_open = false
	self._entity:get_component('render_info'):set_model_variant("closed")
	if self.shop then
		stonehearth.shop:destroy_shop(self.shop)
		self.shop = nil
	end
	if self.bulletin then
		stonehearth.bulletin_board:remove_bulletin(self.bulletin)
		self.bulletin = nil
	end
end

return GoblinMarketComponent