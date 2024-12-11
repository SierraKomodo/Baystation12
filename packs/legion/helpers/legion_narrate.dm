/**
 * Adds a player's last words to the legion's pool. `origin` can be a living mob, a mind datum, or a brain.
 */
/proc/legion_add_voice(datum/origin)
	var/origin_name
	var/message

	if (is_type_in_list(origin, list(/obj/item/organ/internal/brain, /obj/item/organ/internal/posibrain)))
		var/obj/item/organ/internal/brain/brain = origin
		if (!brain.brainmob?.mind)
			return
		origin = brain.brainmob.mind

	if (isliving(origin))
		var/mob/living/living = origin
		if (!living.mind)
			return
		origin = living.mind

	if (istype(origin, /datum/mind))
		var/datum/mind/mind = origin
		if (!mind.last_words)
			return
		origin_name = mind.name
		message = mind.last_words

	if (!origin_name || !message)
		return

	GLOB.legion_last_words_player[origin_name] = message
	log_debug("Added [origin_name]'s last words of '[message]' to the legion message pool.")


/**
 * Displays a randomly chosen legion message to synthetic mobs in z-levels connected to the given level(s)
 */
/proc/show_legion_messages(list/z_levels = list())
	if (!islist(z_levels))
		z_levels = list(z_levels)
	if (!length(z_levels))
		return

	var/list/connected_z_levels = list()
	for (var/z_level in z_levels)
		if (z_level in connected_z_levels)
			continue
		connected_z_levels |= GetConnectedZlevels(z_level)

	var/message
	// Choose a message to display
	if (rand(0, 100) <= 20)
		if (!length(GLOB.legion_last_words_player) || rand(0, 1))
			message = "A voice rises above the chorus, \"[pick(GLOB.legion_last_words_generic)]\""
		else
			var/message_origin = pick(GLOB.legion_last_words_player)
			var/message_contents = GLOB.legion_last_words_player[message_origin]
			message = "[message_origin]'s voice rises above the chorus, \"[message_contents]\""
	else
		message = pick(GLOB.legion_narrations)

	var/count = 0
	var/sound_to_play = pick(GLOB.legion_voices_sounds)
	for (var/mob/player in GLOB.player_list)
		if (!(get_z(player) in connected_z_levels))
			continue
		if (!player.isSynthetic() && !isobserver(player))
			continue
		to_chat(player, SPAN_LEGION(message))
		sound_to(player, sound_to_play)
		count++

	log_debug("Displayed legion message to [count] mob\s across [length(connected_z_levels)] z-level\s.")


/client/proc/cmd_admin_legion_narrate()
	set category = "Special Verbs"
	set name = "Legion Narrate"
	set desc = "Manually triggers a legion narration on specific z-levels."

	if(!check_rights(R_ADMIN))
		return

	var/z_level = input(usr, "Which z-level? Your own z-level is entered by default.", "Legion Narrate", get_z(usr)) as null | num
	if (!z_level)
		return

	show_legion_messages(z_level)
	log_and_message_staff(" - Manual Legion Narrate to z-levels connected to [z_level].")
