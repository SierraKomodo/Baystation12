/obj/legion_scarab
	name = "legion scarab"
	desc = "A small-ish, round construct of some kind."
	icon = 'packs/legion/icons/scarab.dmi'
	icon_state = "base"


/obj/legion_scarab/Initialize()
	. = ..()
	update_icon()


/obj/legion_scarab/on_update_icon()
	ClearOverlays()
	..()
	AddOverlays(emissive_appearance(icon, "[icon_state]-emissive", FLOAT_LAYER + 1))
