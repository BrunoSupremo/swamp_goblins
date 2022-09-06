App.StonehearthZonesModeView.reopen({

	_examineEntity: function(entity) {
		var self = this;
		if (!entity && self._propertyView) {
			self._propertyView.destroyWithoutDeselect();
			self._propertyView = null;
			return;
		}

		if (entity['swamp_goblins:crusher']) {
			self._showZoneUi(entity, App.SwampGoblinsCrusherDialog);
		}else{
			self._super(entity);
		}
	}

});