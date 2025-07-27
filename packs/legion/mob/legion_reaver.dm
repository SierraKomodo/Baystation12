/mob/living/simple_animal/hostile/legion/reaver
	name = "legion reaver"
	desc = "A hulking mechanical mass of legs and lights, with some kind of chamber filled with activity in its central body. <span class='legion'>You feel some form of malicious intelligence behind its shell...</span>"
	icon = 'packs/legion/icons/reaver.dmi'
	icon_state = "base"
	default_pixel_x = -16
	default_pixel_y = -16
	pixel_x = -16
	pixel_y = -16

	maxHealth = 500
	health = 500
	armor_type = /datum/extension/armor
	natural_armor = list(
		"melee" = ARMOR_MELEE_RESISTANT,
		"bullet" = ARMOR_BALLISTIC_RESISTANT,
		"laser" = ARMOR_LASER_MAJOR,
		"energy" = ARMOR_ENERGY_RESISTANT,
		"bomb" = ARMOR_BOMB_RESISTANT,
		"bio" = 100,
		"rad" = 100
	)

	mob_size = MOB_LARGE

	/// Int (0 to 5). The current 'build' state of the scarab storage.
	var/scarab_state = 0


/mob/living/simple_animal/hostile/legion/reaver/Initialize(mapload, obj/structure/legion/beacon/spawner)
	. = ..()
	update_icon()


/mob/living/simple_animal/hostile/legion/reaver/on_update_icon()
	ClearOverlays()
	..()

	icon_state = "base"
	if (scarab_state)
		AddOverlays("gestating-[scarab_state]")

	AddOverlays(emissive_appearance(icon, "[icon_state]-emissive", FLOAT_LAYER + 1))
	if (scarab_state)
		AddOverlays(emissive_appearance(icon, "gestating-[scarab_state]-emissive", FLOAT_LAYER + 1))


/mob/living/simple_animal/hostile/legion/reaver/proc/deploy_scarab(turf/target_turf)
	if (scarab_state < 1)
		return
