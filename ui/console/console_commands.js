$(document).ready(function(){
	radiant.console.register('add_goblin_citizen', {
		call: function(cmdobj, fn, args) {
			return radiant.call('swamp_goblins:add_goblin_citizen_command');
		},
		description: "Add a new goblin to your town, even if playing with hearthlings."
	});
});