extends Node
signal minute_changed(total_minutes: int)
signal hour_changed(hour: int)
signal day_started(day_index: int)
signal season_changed(season_index: int)
signal forced_sleep_triggered
signal pause_requested(reason: String, paused: bool)
signal sleep_requested
signal weather_changed(weather_id: String)
signal environment_changed(state: Dictionary)
signal item_added(item_id: String, amount: int)
signal inventory_changed
signal map_entered(map_id: String)
signal save_requested(slot: int)
signal load_requested(slot: int)
signal state_save_requested(state: Dictionary)
signal state_validate_requested(state: Dictionary, errors: Array)
signal state_load_requested(state: Dictionary)
signal save_finished(success: bool, message: String)
signal inventory_transaction_requested(request: Dictionary, response: Dictionary)
signal crop_harvested(crop_id: String, quality: int)
signal state_restored
signal notice_requested(text: String)
signal interacted_with(persistent_id: String)
signal map_change_requested(map_id: String, position: Vector2)
signal flag_unlocked(flag: String)
signal npc_talk_requested(npc_id: String)
signal npc_gift_requested(npc_id: String)
signal npc_talked(npc_id: String)
signal dialogue_requested(npc_id: String, cue: String)
signal quests_changed
signal friendship_changed(values: Dictionary)
signal resident_xp_awarded(amount: int)
