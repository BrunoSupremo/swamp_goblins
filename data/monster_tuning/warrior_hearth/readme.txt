Instructions on how to use the waves.json file

It is a list of waves, each wave needs an unique name identifier, can't repeat names.
For example:

{
	"my_cool_wave":{
		"inner fields that will":"be explained below"
	},
	"another_cool_wave":{
		"inner fields that will":"be explained below"
	}
}

Each wave has 4 fields. bulletin, weight, at_glory_level and members.
* "bulletin" is optional, it is the custom message that appears when confirmation window asks to accept or decline a challenge. When ommited, a default message is used instead.
* "at_glory_level" is optional too. It defaults to {"min":1,"max":9999}. It restricts at which glory levels this wave can appear.
* "weight" is optional, defaults to 1. weight measures the chance this wave has to be picked (has to be on the correct glory level) against other wave options. 
* "members" is a required field. It should contain a list of unique members, using this format:

"members": {
	"cool_member": {
		"inner fields that will":"be explained below"
	},
	"another_cool_member": {
		"inner fields that will":"be explained below"
	}
}

The total amount of members spawned in a wave is measured by the formula:
Round_Up( Square_Root( glory_level ) )
Examples:
	wave 1 = 1 enemy
	wave 10 = 4 enemies
	wave 100 = 10 enemies
(a quick check in a calculator can give you the answer for any other wave)

Each member has 5 fields. role, tuning, job_level, weight and max_allowed.
* "weight" is optional and defaults to 1. Weight measures the chance this member has to be picked against other member options. 
* "max_allowed" is optional and defaults to 9999. The randomizer will not try to pick this member again if it already spawned this amount of times
* "tuning" is optional, points to a monster_tuning file. Those files can set a bunch of parameters for the entity, such as job, hp, speed, loot, equipments, etc... (vanilla has it too, for more examples)
* "job_level" is optional and defaults to {"min":1, "max":1}. It randomly set the level of the job for each member spawned. Do not use if the member had no job set in its tuning file (or no tuning)
* "role" points to a role in the "swamp_goblins:kingdoms:warrior_hearth" file. It is a kingdom population file. Each role in the population can have male and female variations, each with random uris and names. As long as the role is correctly set in the population file, you can use it in a wave. (check any population file for examples, plenty in vanilla)

Here two new waves added as an example, explanation below it:

{
	"new_wave_1": {
		"bulletin":"i18n(mod:data.monster_tuning.warrior_hearth.new_wave_1)",
		"weight": 9999,
		"at_glory_level": {
			"min":50,
			"max":50
		},
		"members": {
			"member_1_boss": {
				"role": "some_role",
				"tuning":"mod:monster_tuning:warrior_hearth:new_challenger:boss",
				"weight": 9999,
				"job_level":{
					"min":5,
					"max":6
				},
				"max_allowed": 1
			},
			"member_2_henchman": {
				"role": "some_role",
				"tuning":"mod:monster_tuning:warrior_hearth:new_challenger:henchman",
				"weight": 1,
				"job_level":{
					"min":1,
					"max":2
				}
			}
		}
	},
	"new_wave_2": {
		"bulletin":"i18n(mod:data.monster_tuning.warrior_hearth.new_wave_2)",
		"weight": 10,
		"at_glory_level": {
			"min":1,
			"max":100
		},
		"members": {
			"worker": {
				"role": "some_role",
				"tuning":"mod:monster_tuning:warrior_hearth:new_challenger:henchman",
				"weight": 1,
				"job_level":{
					"min":1,
					"max":6
				}
			}
		}
	}
}

When the player first starts, at level 1 glory, the game will pick a wave. The wave picked can't be the "new_wave_1", because our level is below the minimum asked there (50), so "new_wave_2" is picked instead.
Next, it will decide how many member it will spawn. Using the formula above, the first wave spawns just one member. The entity is the one set in the role "some_role", with extra settings from the henchman tuning file, and a random level.
This repeats for many waves, until level 50. Now both waves are eligible, so the game decides randomly based on their weight. As "new_wave_1" has such a high weight (9999), it is almost guarantee that it will be picked over the wave2. This way we can have specific waves, that you want to be sure it will happen at that moment (special stages, like boss fights)
On that wave with that level (50), the game needs to spawn 8 enemies. Each one is randomly decided on their weights. But the "member_1_boss" has such a high weight (9999) that it is guarantee to be picked everytime, which would result in the wave having 8 of those. But, it also has a "max_allowed" value of 1, which means that once the first one is spawned, the next ones can't be it again. This in turn makes this wave spawn one boss and 7 henchman.
After this stage, only the "new_wave_2" is eligible because we now have higher level than what is set as the max in the wave1. Up until level 100, which is the max set in wave2, with 10 enemies spawning.