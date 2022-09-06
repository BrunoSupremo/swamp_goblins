App.SwampGoblinsCrusherDialog = App.StonehearthBaseZonesModeView.extend({
	templateName: 'crusherDialog',
	closeOnEsc: true,

	components: {
		"stonehearth:unit_info": {},
		"swamp_goblins:crusher" : {
			"crushable_items" : {
				"tracking_data" : {
					"*" : {}
				}
			}
		},
		"stonehearth:storage" : {
			"filter": {}
		}
	},

	_registerTab: function(name, build, update, destroy) {
		let self = this;
		let tab = {
			name,
			build : function() {
				if(!tab.initialized) {
					build.call(self);
				}
				tab.initialized = true;
			},
			update : function () {
				if(tab.initialized) {
					update.call(self);
				}
			},
			destroy : function () {
				if(tab.initialized) {
					destroy.call(self);
				}
				tab.initialized = false;
			},
			initialized : false,
		};
		this._tabs[name] = tab;
	},

	init: function() {
		this._super();
		this._tabs = {};
		this._activeTab = false;
		this._paletteData = null;
		this._registerTab('marketTab', this._buildMarketTab, this._updateMarketTab, this._destroyMarketTab);
	},

	destroy: function() {
		this._super();
	},

	willDestroyElement: function() {
		this._super();
		for(let tab in this._tabs) {
			if (tab.initialized) {
				tab.destroy();
			}
		}
	},

	didInsertElement: function() {
		let self = this;
		this._super();

		this._update();
		self._updateSelectionView('sellable');
	},

	_onFiltersChanged: function () {
		let filter = this.get('model.stonehearth:storage.filter');
		let name = '';
		if (filter && filter.uri) {
			let catalogData = App.catalog.getCatalogData(filter.uri);
			if (catalogData) {
				name = i18n.t(catalogData.display_name);
			}
		} else {
			name = i18n.t('stonehearth:ui.game.zones_mode.stockpile.filters.none');
		}
		this.set('selected_filter_label', name);
	}.observes('model.stonehearth:storage.filter'),

	_onSellableItemsChanged: function() {
		if (!this.$()) { return; }
		this._paletteData = this.get('model.swamp_goblins:crusher.crushable_items.tracking_data');
		this._tabs.marketTab.update();
	}.observes('model.swamp_goblins:crusher.crushable_items'),

	_update: function () {
		if (!this.$()) return;
		var playerId = this.get('model.player_id');
		var isOwner = playerId && App.stonehearthClient.getPlayerId() == playerId;
		this.set('playerId', playerId);
		this.set('isOwner', isOwner);

		if (this.isOwner) {
			this._showTab('marketTab');
			this._onSellableItemsChanged();
		}
	}.observes('model.stonehearth:unit_info'),

	_updateSelectionView: function(paletteId) {
		let selectedFilter = this.$(`#${paletteId} .selected`);
		let name, icon;
		if (selectedFilter.length) {
			name = selectedFilter.attr('title');
			icon = selectedFilter.attr('src');
		} else {
			name = i18n.t('stonehearth:ui.game.zones_mode.stockpile.filters.none');
			icon = '/stonehearth/ui/common/images/transparent.png';
		}
		this._setSelectionView(name, icon);
	},

	_setSelectionView: function(name, icon) {
		this.$('.selectedFilter .label').text(name);
		this.$('.selectedFilter .icon')
		.attr('src', icon)
		.attr('title', name)
	},

	_showTab : function (tabName) {
		if (this._activeTab) {
			this._tabs[this._activeTab].destroy();
		}
		this._tabs[tabName].build();
		this._tabs[tabName].update();
		this._activeTab = tabName;

		this.$('.tabPage').hide();
		this.$(`#${tabName}`).show();
	},

	_buildMarketTab: function() {
		let self = this;

		self._sellablePalette = this.$('#sellable').stonehearthItemPalette({
			cssClass: 'shopItem',
			itemAdded: function(itemEl, itemData) {
				itemEl.attr('num', itemData.count);
				itemEl.attr('src', itemData.icon);
				itemEl.attr('title', i18n.t(itemData.display_name));
			},
			click: function(item, e) {
				let item_uri = item.attr('uri');
				radiant.call('stonehearth:set_exact_storage_filter', self.uri, item_uri);
				self._updateSelectionView('sellable');
			},
			hideCount: false
		});

		let filter = this.get('model.stonehearth:storage.filter');
		if (filter && filter.uri) {
			let catalogData = App.catalog.getCatalogData(filter.uri);
			name = i18n.t(catalogData.display_name);
			icon = catalogData.icon;
			this._setSelectionView(name, icon);
		}

		this.$('.clear').show();
		this.$('.clear').click(function() {
			radiant.call('stonehearth:set_exact_storage_filter', self.uri, '');
			self.$('#sellable .selected').removeClass('selected');
			self._updateSelectionView('sellable');
		});
	},

	_updateMarketTab : function() {
		this._sellablePalette.stonehearthItemPalette('updateItems', this._paletteData);
	},

	_destroyMarketTab : function() {
		this._sellablePalette.stonehearthItemPalette('destroy');
		this.$('#sellable').html('');
		this.$('.clear').off();
		delete this._sellablePalette;
	}
});