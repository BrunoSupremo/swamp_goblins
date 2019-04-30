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

		$.get('/swamp_goblins/data/goblinpedia/goblinpedia.json')
		.done(function (result) {
			self.set('menu', self.convert_menu_to_array(result.menu));
			self.set('pages', self.convert_pages_to_array(result.pages));
		});

		self.$().draggable();
	},

	convert_menu_to_array: function(menu){
		let array = [];
		Object.keys(menu).forEach(function (menu_key) {
			let menu_value = menu[menu_key];
			let array2 = [];
			Object.keys(menu_value.items).forEach(function (growth_key) {
				let growth_value = menu_value.items[growth_key];
				let array3 = [];
				Object.keys(growth_value.items).forEach(function (pedestal_key) {
					let pedestal_value = growth_value.items[pedestal_key];

					array3.push(pedestal_value);
				});
				growth_value.items = array3;
				array2.push(growth_value);
			});
			menu_value.items = array2;
			array.push(menu_value);
		});
		return array;
	},

	convert_pages_to_array: function(pages){
		let array = [];
		Object.keys(pages).forEach(function (pages_key) {
			let pages_value = pages[pages_key];
			let array_descriptions = [];
			Object.keys(pages_value.descriptions).forEach(function (descriptions_key) {
				let descriptions_value = pages_value.descriptions[descriptions_key];

				array_descriptions.push(descriptions_value);
			});
			pages_value.descriptions = array_descriptions;

			let array_topics = [];
			Object.keys(pages_value.topics).forEach(function (topic_key) {
				let topic_value = pages_value.topics[topic_key];
				let array_topic_descriptions = [];
				Object.keys(topic_value.descriptions).forEach(function (descriptions_key) {
					let descriptions_value = topic_value.descriptions[descriptions_key];

					array_topic_descriptions.push(descriptions_value);
				});
				topic_value.descriptions = array_topic_descriptions;
				array_topics.push(topic_value);
			});
			pages_value.topics = array_topics;
			array.push(pages_value);
		});
		return array;
	},

	actions:{
		menu_button: function(button_id) {
			let divs = document.querySelectorAll("#goblinpedia button + div");
			for (let i = divs.length - 1; i >= 0; i--) {
				divs[i].style.display = "none";
			}
			document.querySelector("#"+button_id+" + div").style.display = "block";
		},
		open_page: function(page){
			document.querySelector(".current_page").classList.remove("current_page");
			document.querySelector("#"+page).classList.add("current_page");
		}
	}
});