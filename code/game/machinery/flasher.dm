// It is a gizmo that flashes a small area

/obj/machinery/flasher
	name = "Mounted flash"
	desc = "A wall-mounted flashbulb device."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "mflash1"
	var/id = null
	var/range = 2 //this is roughly the size of brig cell
	var/disable = 0
	var/last_flash = 0 //Don't want it getting spammed like regular flashes
	var/strength = 5 //How weakened targets are when flashed.
	var/base_state = "mflash"
	anchored = 1

/obj/machinery/flasher/portable //Portable version of the flasher. Only flashes when anchored
	name = "portable flasher"
	desc = "A portable flashing device. Wrench to activate and deactivate. Cannot detect slow movements."
	icon_state = "pflash1"
	strength = 4
	anchored = 0
	base_state = "pflash"
	density = 1

/*
/obj/machinery/flasher/New()
	sleep(4)					//<--- What the fuck are you doing? D=
	sd_set_light(2)
*/
/obj/machinery/flasher/power_change()
	if( powered() )
		stat &= ~NOPOWER
		icon_state = "[base_state]1"
//		sd_set_light(2)
	else
		stat |= ~NOPOWER
		icon_state = "[base_state]1-p"
//		sd_set_light(0)

//Don't want to render prison breaks impossible
/obj/machinery/flasher/attackby(obj/item/weapon/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/weapon/wirecutters))
		add_fingerprint(user)
		disable = !disable
		if(disable)
			user.visible_message("\red [user] has disconnected the [src]'s flashbulb!", "\red You disconnect the [src]'s flashbulb!")
		if(!disable)
			user.visible_message("\red [user] has connected the [src]'s flashbulb!", "\red You connect the [src]'s flashbulb!")

//Let the AI trigger them directly.
/obj/machinery/flasher/attack_ai()
	if(anchored)
		return flash()
	else
		return

/obj/machinery/flasher/proc/flash()
	if(!(powered()))
		return

	if((disable) || (last_flash && world.time < last_flash + 150))
		return

	playsound(loc, 'sound/weapons/flash.ogg', 100, 1)
	flick("[base_state]_flash", src)
	last_flash = world.time
	use_power(1000)

	for(var/mob/living/L in viewers(src, null))
		if(get_dist(src, L) > range)
			continue

		if(L.flash_eyes(affect_silicon = 1))
			L.Weaken(strength)
			if(L.weakeyes)
				L.Weaken(strength * 1.5)
				L.visible_message("<span class='disarm'><b>[L]</b> gasps and shields their eyes!</span>")

/obj/machinery/flasher/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return
	if(prob(75/severity))
		flash()
	..(severity)

/obj/machinery/flasher/portable/HasProximity(atom/movable/AM as mob|obj)
	if((disable) || (last_flash && world.time < last_flash + 150))
		return

	if(istype(AM, /mob/living/carbon))
		var/mob/living/carbon/M = AM
		if((M.m_intent != "walk") && (anchored))
			flash()

/obj/machinery/flasher/portable/attackby(obj/item/weapon/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/weapon/wrench))
		add_fingerprint(user)
		anchored = !anchored

		if(!anchored)
			user.show_message(text("\red [src] can now be moved."))
			overlays.Cut()

		else if(anchored)
			user.show_message(text("\red [src] is now secured."))
			overlays += "[base_state]-s"

// Flasher button
/obj/machinery/flasher_button
	name = "flasher button"
	desc = "A remote control switch for a mounted flasher."
	icon = 'icons/obj/objects.dmi'
	icon_state = "launcherbtt"
	var/id = null
	var/active = 0
	anchored = 1.0
	use_power = 1
	idle_power_usage = 2
	active_power_usage = 4			
			
/obj/machinery/flasher_button/attack_ai(mob/user as mob)
	return attack_hand(user)
	
/obj/machinery/flasher_button/attack_ghost(mob/user)
	if(user.can_admin_interact())
		return attack_hand(user)

/obj/machinery/flasher_button/attackby(obj/item/weapon/W, mob/user as mob, params)
	return attack_hand(user)

/obj/machinery/flasher_button/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return
	if(active)
		return

	use_power(5)

	active = 1
	icon_state = "launcheract"

	for(var/obj/machinery/flasher/M in world)
		if(M.id == id)
			spawn()
				M.flash()

	sleep(50)

	icon_state = "launcherbtt"
	active = 0