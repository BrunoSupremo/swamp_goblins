$.widget( "stonehearth.stonehearthMenu", $.stonehearth.stonehearthMenu, {
	unlockItem: function(attributeName, attributeValue) {
		var self = this;
		var item = this.element.find('[' + attributeName + '=' + attributeValue + ']');
		if (item.length > 0) {
			if (attributeName == "job"){
				item.addClass("show_this_button_now_you_dummy");
			}
			item.removeClass('locked');
			item.each(function() {
				self._buildTooltip($(this));
			});
			if (item.attr('menu_action') == 'show_crafter_ui') {
				App.workshopManager.createWorkshop(attributeValue.replace(/\\:/g, ':'));
			}
		}
	}
});