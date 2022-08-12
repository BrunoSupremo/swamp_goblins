$(document).ready(function() {
	$(top).on('swamp_goblins:goblinpedia', function (_, e) {
		if (!App.stonehearth.GoblinpediaView) {
			App.stonehearth.GoblinpediaView = App.gameView.addView(App.GoblinpediaView);
		}
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
			self.set('categories', self.change_some_levels_to_arrays_so_ember_foreach_can_loop_it(result.categories));
		});

		self.$().draggable();
	},

	change_some_levels_to_arrays_so_ember_foreach_can_loop_it: function(categories){
		//ember´s {{#each}} loop only works with arrays...
		// the idea here is to keep the whole original structure as seem on json,
		// but the parts where the html has to loop are then converted to arrays
		let categories_array = [];
		Object.keys(categories).forEach(function (category_key) {
			let category_value = categories[category_key];
			let sub_categories_array = [];
			Object.keys(category_value.sub_categories).forEach(function (sub_category_key) {
				let sub_category_value = category_value.sub_categories[sub_category_key];
				let articles_array = [];
				Object.keys(sub_category_value.articles).forEach(function (article_key) {
					let article_value = sub_category_value.articles[article_key];
					let descriptions_array = [];
					Object.keys(article_value.descriptions).forEach(function (description_key) {
						let description_value = article_value.descriptions[description_key];

						descriptions_array.push(description_value);
					});
					article_value.descriptions = descriptions_array;
					let topics_array = [];
					Object.keys(article_value.topics).forEach(function (topic_key) {
						let topic_value = article_value.topics[topic_key];
						let descriptions_array = [];
						Object.keys(topic_value.descriptions).forEach(function (description_key) {
							let description_value = topic_value.descriptions[description_key];

							descriptions_array.push(description_value);
						});
						topic_value.descriptions = descriptions_array;
						topics_array.push(topic_value);
					});
					article_value.id = category_key+"_"+sub_category_key+"_"+article_key;
					article_value.ordinal = article_value.ordinal || 999;
					article_value.topics = topics_array;
					articles_array.push(article_value);
				});
				sub_category_value.articles = articles_array;
				sub_categories_array.push(sub_category_value);
			});
			category_value.id = category_key;
			category_value.sub_categories = sub_categories_array;
			categories_array.push(category_value);
		});
		return categories_array;
	},

	destroy: function() {
		App.stonehearth.GoblinpediaView = null;

		this._super();
	},

	actions:{
		menu_button: function(category_id) {
			let goblinpedia_dom = document.querySelector("#goblinpedia");
			let divs = goblinpedia_dom.querySelectorAll(".category");
			for (let i = divs.length - 1; i >= 0; i--) {
				divs[i].style.display = "none";
			}
			goblinpedia_dom.querySelector("#"+category_id).style.display = "block";
		},
		open_page: function(article_id){
			let goblinpedia_dom = document.querySelector("#goblinpedia");
			goblinpedia_dom.querySelector(".current_page").classList.remove("current_page");
			goblinpedia_dom.querySelector("#"+article_id).classList.add("current_page");
		}
	}
});