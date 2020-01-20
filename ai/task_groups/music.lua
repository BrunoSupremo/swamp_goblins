local SwampGoblinMusicTaskGroup = class()
SwampGoblinMusicTaskGroup.name = 'music'
SwampGoblinMusicTaskGroup.does = 'stonehearth:free_time'
SwampGoblinMusicTaskGroup.priority = 0.9

return stonehearth.ai:create_task_group(SwampGoblinMusicTaskGroup)
:declare_permanent_task('swamp_goblins:play_music', {}, 1)
:declare_permanent_task('swamp_goblins:goto_music', {}, {0.4,0.6})