// Hijacked SABR units
/mob/living/simple_animal/hostile/legion/sabr
	name = "hijacked S.A.B.R. Unit"
	desc = "An advanced, top-of-the-line solarian combat robot. Known by those in in the fifth as a SABR, or Sol Advanced Battle Robot. <span class=\"warning\">This one seems... Off somehow.</span>"
	icon = 'packs/legion/icons/sabr.dmi'
	icon_state = "base"

	/// Integer (One of `SABR_MODE_*`). The SABR units current module mode.
	var/sabr_mode = SABR_MODE_DEFAULT

	/// Default state. No specific moduels are active and the SABR unit is fully deployed.
	var/const/SABR_MODE_DEFAULT = 1
	/// Mobility mode. The SABR unit is folded up for extra speed but can't attack.
	var/const/SABR_MODE_MOBILITY = 2
	/// Shield mode. The SABR unit is fully deployed and has activated its shield.
	var/const/SABR_MODE_SHIELD = 3


/mob/living/simple_animal/hostile/legion/sabr/Initialize(mapload, obj/structure/legion/beacon/spawner)
	. = ..()
	update_icon()


/mob/living/simple_animal/hostile/legion/sabr/on_update_icon()
	ClearOverlays()

	switch (sabr_mode)
		if (SABR_MODE_DEFAULT)
			icon_state = "base"
			AddOverlays(emissive_appearance(icon, "base_emissive"))
			AddOverlays("base_lights")

		if (SABR_MODE_MOBILITY)
			icon_state = "mobility"
			AddOverlays(emissive_appearance(icon, "mobility_emissive"))
			AddOverlays("mobility_lights")

		if (SABR_MODE_SHIELD)
			icon_state = "base"
			AddOverlays(emissive_appearance(icon, "base_emissive"))
			AddOverlays("base_lights")
			AddOverlays(emissive_appearance(icon, "shield_emissive"))
			AddOverlays("shield")


/// Updates `sabr_mode` to the new mode.
/mob/living/simple_animal/hostile/legion/sabr/proc/set_sabr_mode(new_mode)
	if (new_mode == sabr_mode)
		return
	sabr_mode = new_mode
	update_icon()
