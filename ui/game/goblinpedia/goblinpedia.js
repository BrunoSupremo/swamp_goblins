$(document).ready(function() {
	$(top).on('swamp_goblins:goblinpedia', function (_, e) {
		var view = App.gameView.addView(App.GoblinpediaView);
	});
});

App.GoblinpediaView = App.View.extend({
	templateName: 'goblinpedia',
	modal: false,
	closeOnEsc: true,

	didInsertElement: function() {
		var self = this;
		// self.set('title', 'A new beginning'); // lala "{{view.title}}"

		self.$().draggable();
	},

	actions:{
		goblin_button: function() {
			document.querySelector("#swamp_button + div").style.display = "none";
			document.querySelector("#goblin_button + div").style.display = "block";
		},
		swamp_button: function() {
			document.querySelector("#goblin_button + div").style.display = "none";
			document.querySelector("#swamp_button + div").style.display = "block";
		},
		open_page: function(page){
			document.querySelector(".current_page").classList.remove("current_page");
			document.querySelector("#"+page).classList.add("current_page");
		}
	}
});