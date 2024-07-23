/mob/living/simple_animal/hostile/legion/harvester
	name = "legion harvester"
	maxHealth = 200

	/// The current atom selected for harvesting.
	var/atom/harvest_target

	/**
	 * LAZYLIST (Instances of `/obj/item/organ/internal/brain` and `/obj/item/organ/internal/posibrain`). The brains
	 * this harvester has collected. These should also be within `contents`.
	 */
	var/list/harvested_brains

	/// Integer (One of `src.HARVESTER_STATE_*`). The current activity state of the harvester.
	var/harvester_state

	/// The harvester is currently not doing anything special.
	var/const/HARVESTER_STATE_DEFAULT = 1
	/// The harvester is currently extracting a brain from `harvest_target`.
	var/const/HARVESTER_STATE_EXTRACTING = 2
	/// The harvester is currently storing an extracted brain.
	var/const/HARVESTER_STATE_STORING = 3


/mob/living/simple_animal/hostile/legion/harvester/loaded/Initialize(mapload, obj/structure/legion/beacon/spawner, brain_count)
	. = ..()

	// Preloaded with brains for extra pinata
	if (!brain_count)
		brain_count = rand(1, 10)
	for (var/i = 1 to brain_count)
		var/brain_type = rand(0, 1) ? /obj/item/organ/internal/brain : /obj/item/organ/internal/posibrain
		harvested_brains += new brain_type(src)


/mob/living/simple_animal/hostile/legion/harvester/Destroy()
	QDEL_NULL_LIST(harvested_brains)
	harvest_target = null
	return ..()


/mob/living/simple_animal/hostile/legion/harvester/examine(mob/user, distance, is_adjacent, infix, suffix)
	. = ..()

	switch (harvester_state)
		if (HARVESTER_STATE_DEFAULT)
			if (harvest_target)
				if (harvest_target == user)
					to_chat(user, FONT_LARGE(SPAN_DANGER("It seems focused on <b>you</b>.")))
				else
					to_chat(user, SPAN_WARNING("It seems focused on \the [harvest_target]."))
			else
				to_chat(user, SPAN_WARNING("It seems to be searching for something..."))

		if (HARVESTER_STATE_EXTRACTING)
			to_chat(user, SPAN_WARNING("It is currently cutting into \the [harvest_target]..."))

		if (HARVESTER_STATE_STORING)
			to_chat(user, SPAN_WARNING("It is currently drawing \the [harvest_target] into its storage compartment..."))


/mob/living/simple_animal/hostile/legion/harvester/on_death()
	if (!length(harvested_brains))
		visible_message(
			SPAN_DANGER("\The [src] blows apart!")
		)
	else
		visible_message(
			SPAN_DANGER("\The [src] blows apart, spewing the contents of its internal storage unit everywhere!")
		)
		explosion(get_turf(src), 2, EX_ACT_LIGHT)
		for (var/atom/movable/harvested_brain in harvested_brains)
			harvested_brain.forceMove(get_turf(src))
			harvested_brain.throw_at_random(FALSE, 4, 3)
		harvested_brains.Cut()
	qdel(src)


/**
 * Sets the harvester's harvesting state. Primarily used to synchronize the harvester's AI busy state.
 *
 * Includes validation to ensure `new_state` is a valid state, otherwise crashes without updating.
 *
 * **Parameters**:
 * - `new_state` (Integer - One of `HARVESTER_STATE_*`, default `HARVESTER_STATE_DEFAULT`) - The new state to set.
 *
 * Has no return value.
 */
/mob/living/simple_animal/hostile/legion/harvester/proc/set_harvester_state(new_state = HARVESTER_STATE_DEFAULT)
	if (harvester_state == new_state)
		return

	switch (new_state)
		if (HARVESTER_STATE_DEFAULT)
			ai_holder.set_busy(FALSE)
		if (HARVESTER_STATE_EXTRACTING)
			ai_holder.set_busy(TRUE)
		if (HARVESTER_STATE_STORING)
			ai_holder.set_busy(TRUE)
		else
			crash_with("Invalid harvester state [new_state]")
			return

	harvester_state = new_state


/**
 * Whether or not the target is valid for harvesting a brain from. Legion have fancy sensors that can detect the presence of a brain from a distance or something like that.
 *
 * Does not include adjacency checks as this is also intended for selecting a target to move to.
 *
 * **Parameters**:
 * - `target` - The atom to validate.
 *
 * Returns boolean. If `TRUE`, `target` is a valid target for `harvest_brain()`.
 */
/mob/living/simple_animal/hostile/legion/harvester/proc/can_harvest_brain(atom/movable/target)
	// Raw brains and positronics
	if (istype(target, /obj/item/organ/internal/brain) || istype(target, /obj/item/organ/internal/posibrain))
		return TRUE

	// Heads/raw body parts that might have juicy brains
	if (istype(target, /obj/item/organ/external))
		var/found_brain = locate(/obj/item/organ/internal/brain) in target
		if (!found_brain)
			found_brain = locate(/obj/item/organ/internal/posibrain) in target
		if (!found_brain)
			return FALSE
		return TRUE

	// Human mobs
	if (ishuman(target))
		var/mob/living/carbon/human/human_target = target
		var/obj/item/organ/internal/brain = human_target.internal_organs_by_name[BP_BRAIN]
		if (!brain)
			return FALSE
		// TODO: Check if target is prone. Being incapacitated/prone is a required part of extraction.
		return TRUE

	return FALSE



/**
 * Attempts to 'harvest' the target's brain into this harvester's internal storage.
 *
 * Does not perform `can_harvest_brain()` checks as it's assumed this was already checked before calling this proc.
 *
 * **Parameters**:
 *  - `target` - The atom being harvested. Currently valid types include:
 *  	- `/obj/item/organ/internal/brain` - Collects the brain
 *  	- `/obj/item/organ/internal/posibrain` - Collects the brain
 *  	- `/obj/item/organ/external` - Will attempt to extract a brain if present
 *  	- `/mob/living/carbon/human` - Will attempt to extract a brain if present
 *
 * Returns boolean. Whether or not a brain was successfully harvested.
 */
/mob/living/simple_animal/hostile/legion/harvester/proc/harvest_brain(atom/movable/target)
	if (!Adjacent(target))
		return FALSE


	// Raw brains and positronics
	if (istype(target, /obj/item/organ/internal/brain) || istype(target, /obj/item/organ/internal/posibrain))
		visible_message(
			SPAN_WARNING("\The [src] starts scooping up \the [target] into its internal storage...")
		)
		set_harvester_state(HARVESTER_STATE_STORING)
		if (!do_after(src, 5 SECONDS, target, DO_PUBLIC_UNIQUE) || !use_sanity_check(target))
			set_harvester_state(HARVESTER_STATE_DEFAULT)
			return FALSE
		visible_message(
			SPAN_WARNING("\The [src] scoopes up \the [target] into its internal storage!")
		)
		set_harvester_state(HARVESTER_STATE_DEFAULT)
		target.forceMove(src)
		harvested_brains += target
		return TRUE


	// Heads/raw body parts that might have juicy brains
	if (istype(target, /obj/item/organ/external))
		var/obj/item/organ/internal/found_brain = locate(/obj/item/organ/internal/brain) in target
		if (!found_brain)
			found_brain = locate(/obj/item/organ/internal/posibrain) in target
		if (!found_brain)
			return FALSE // Runtime protection. This theoretically shouldn't be possible but you never know.

		visible_message(
			SPAN_WARNING("\The [src] starts cutting into \the [target] ravenously...")
		)
		set_harvester_state(HARVESTER_STATE_EXTRACTING)
		if (!do_after(src, 5 SECONDS, target, DO_PUBLIC_UNIQUE) || !use_sanity_check(target) || !(found_brain in target))
			set_harvester_state(HARVESTER_STATE_DEFAULT)
			return FALSE

		visible_message(
			SPAN_WARNING("\The [src] cuts open \the [target] and starts pulling \the [found_brain] into its internal storage...")
		)
		set_harvester_state(HARVESTER_STATE_STORING)
		// TODO: Crack open the body par and move the brain to turf
		if (!do_after(src, 5 SECONDS, target, DO_PUBLIC_UNIQUE) || !use_sanity_check(target) || !(found_brain in target))
			set_harvester_state(HARVESTER_STATE_DEFAULT)
			return FALSE

		visible_message(
			SPAN_WARNING("\The [src] scoops up \the [target]'s [found_brain.name] into its internal storage!")
		)
		set_harvester_state(HARVESTER_STATE_DEFAULT)
		found_brain.forceMove(src)
		harvested_brains += found_brain
		return TRUE


	// Human mobs
	if (ishuman(target))
		var/mob/living/carbon/human/human_target = target
		var/obj/item/organ/internal/brain = human_target.internal_organs_by_name[BP_BRAIN]
		var/obj/item/organ/external/external_organ = human_target.organs_by_name[brain.parent_organ]
		// TODO: Check if target is prone. Being incapacitated/prone is a required part of extraction.


	// Anything else. We theoretically shouldn't be here, but byond be byond.
	return FALSE
