
//Gun attachable items code. Lets you add various effects to firearms.
//Some attachables are hardcoded in the projectile firing system, like grenade launchers, flamethrowers.
/obj/item/attachable
	name = "attachable item"
	desc = "Its an attachment. You should never see this."
	icon = 'icons/Marine/marine-weapons.dmi'
	icon_state = ""
	item_state = ""
	var/pixel_shift_x = 16 //Determines the amount of pixels to move the icon state for the overlay.
	var/pixel_shift_y = 16 //Uses the bottom left corner of the item.

	flags =  FPRINT | TABLEPASS | CONDUCT
	matter = list("metal" = 2000)
	w_class = 2.0
	force = 1.0
	var/slot = null //"muzzle", "rail", "under", "stock"
	var/list/guns_allowed = list() //what weapons can it be attached to? Note that it must be the FULL path, not parents.
	var/accuracy_mod = 0 //Modifier to firing accuracy % - FLAT
	var/ranged_dmg_mod = 100 //Modifier to ranged damage - PERCENTAGE / 100
	var/melee_mod = 100 //Modifier to melee damage - PERCENTAGE / 100
	var/w_class_mod = 0 //Modifier to weapon's weight class -- FLAT

	//var/list/loaded = list() //Stores an attachable's internal contents, ie. grenades
	var/ammo_type = null //Which type of ammo it uses. If it's not a datum, it'll be a seperate object.
	var/ammo_capacity = 0 //How much ammo it can store
	var/current_ammo = 0
	var/shoot_sound = null //Sound to play when firing it alternately
	var/spew_range = 0 //Determines # of tiles distance the flamethrower can exhale.

	var/twohanded_mod = 0 //If 1, removes two handed, if 2, adds two-handed.
	var/recoil_mod = 0 //If positive, adds recoil, if negative, lowers it. Recoil can't go below 0.
	var/silence_mod = 0 //Adds silenced to weapon
	var/light_mod = 0 //Adds an x-brightness flashlight to the weapon, which can be toggled on and off.

	var/delay_mod = 0 //Changes firing delay. Cannot go below 0.
	var/burst_mod = 0 //Changes burst rate. 1 == 0.
	var/size_mod = 0 //Increases the weight class
	var/activation_sound = 'sound/machines/click.ogg'
	var/can_activate = 0
	var/continuous = 0 //Shootable attachments normally swap back after 1 shot.
	var/passive = 1 //Can't actually be an active attachable, but might still be activatible.

	proc/Attach(var/obj/item/weapon/gun/G)
		if(!istype(G)) return //Guns only
		if(slot == "rail") G.rail = src
		if(slot == "muzzle") G.muzzle = src
		if(slot == "under") G.under = src

		//Now deal with static, non-coded modifiers.
		if(melee_mod != 100)
			G.force = (G.force * melee_mod / 100)
			if(melee_mod >= 200)
				G.attack_verb = null
				G.attack_verb = list("slashed", "stabbed", "speared", "torn", "punctured", "pierced", "gored")
			if(melee_mod > 100 && melee_mod < 200 )
				G.attack_verb = null
				G.attack_verb = list("smashed", "struck", "whacked", "beaten", "cracked")
		if(w_class_mod != 0) G.w_class += w_class_mod
//		if(istype(G,/obj/item/weapon/gun/projectile))
//			if(capacity_mod != 100) G:max_shells = (G:max_shells * capacity_mod / 100)
		if(recoil_mod)
			G.recoil += recoil_mod
			if(G.recoil < 0) G.recoil = 0
		if(twohanded_mod == 1) G.twohanded = 1
		if(twohanded_mod == 2) G.twohanded = 0
		if(silence_mod) G.silenced = 1
		if(light_mod)
			G.flash_lum = light_mod
		if(delay_mod)
			G.fire_delay += delay_mod
			if(G.fire_delay < 0)
				G.fire_delay = 1
				G.burst_amount++

		if(burst_mod)
			G.burst_amount += burst_mod
			if(G.burst_amount < 2) G.burst_amount = 0

		if(size_mod)
			G.w_class += size_mod

	proc/Detach(var/obj/item/weapon/gun/G)
		if(!istype(G)) return //Guns only
		if(slot == "rail") G.rail = null
		if(slot == "muzzle") G.muzzle = null
		if(slot == "under") G.under = null

		if(G.wielded)
			G.unwield()

		//Now deal with static, non-coded modifiers.
		if(melee_mod != 100)
			G.force = initial(G.force)
			G.attack_verb = initial(G.attack_verb)
		if(w_class_mod != 0) G.w_class -= w_class_mod
//		if(istype(G,/obj/item/weapon/gun/projectile))
//			if(capacity_mod != 100)
//				var/obj/item/weapon/gun/projectile/P = G
//				P.max_shells = initial(P.max_shells)
		if(recoil_mod) G.recoil = initial(G.recoil)
		if(twohanded_mod) G.twohanded = initial(G.twohanded)
		if(silence_mod) G.silenced = initial(G.silenced)
		if(delay_mod)
			G.fire_delay = initial(G.fire_delay)
			G.burst_amount = initial(G.burst_amount)
		if(light_mod)  //Remember to turn the lights off
			if(G.flashlight_on && G.flash_lum)
				if(!ismob(G.loc))
					G.SetLuminosity(0)
				else
					var/mob/M = G.loc
					M.SetLuminosity(-light_mod) //Lights are on and we removed the flashlight, so turn it off
			G.flash_lum = initial(G.flash_lum)
			G.flashlight_on = 0
		if(burst_mod) G.burst_amount = initial(G.burst_amount)

	proc/activate_attachment(var/atom/target, var/mob/user) //This is for activating stuff like flamethrowers, or switching weapon modes.
		return

	proc/fire_attachment(var/atom/target,var/obj/item/weapon/gun/gun, var/mob/user) //For actually shooting those guns.
		return 0

/obj/item/attachable/suppressor
	name = "suppressor"
	desc = "A small tube with exhaust ports to expel noise and gas.\nDoes not completely silence a weapon, but does make it much quieter."
	icon_state = "suppressor"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/c99,
						/obj/item/weapon/gun/pistol/m1911,
						/obj/item/weapon/gun/pistol/holdout,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70
						)
	accuracy_mod = -5
	slot = "muzzle"
	silence_mod = 1

	New()
		..()
		icon_state = pick("suppressor","suppressor2")

/obj/item/attachable/bayonet
	name = "bayonet"
	desc = "A sharp blade for mounting on a weapon. It can be used to stab manually."
	icon_state = "bayonet"
	force = 18
	throwforce = 10
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/revolver/m44,
						/obj/item/weapon/gun/shotgun/pump/combat,
						/obj/item/weapon/gun/shotgun/pump,
						/obj/item/weapon/gun/shotgun/pump/double
	)
	melee_mod = 300 //30 brute for those 3 guns, normally do 10
	accuracy_mod = -10
	slot = "muzzle"

	attackby(obj/item/I as obj, mob/user as mob)
		if(istype(I,/obj/item/weapon/screwdriver))
			user << "You modify the bayonet back into a combat knife."
			if(src.loc == user)
				user.drop_from_inventory(src)
			var/obj/item/weapon/combat_knife/F = new(src.loc)
			user.put_in_hands(F) //This proc tries right, left, then drops it all-in-one.
			if(F.loc != user) //It ended up on the floor, put it whereever the old flashlight is.
				F.loc = src.loc
			del(src) //Delete da old bayonet
		else
			..()

/obj/item/attachable/reddot
	name = "red-dot sight"
	desc = "A red-dot sight for short to medium range. Does not have a zoom feature, but does greatly increase weapon accuracy."
	icon_state = "reddot"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/c99,
						/obj/item/weapon/gun/pistol/m1911,
						/obj/item/weapon/gun/pistol/holdout,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70,
						/obj/item/weapon/gun/revolver,
						/obj/item/weapon/gun/revolver/cmb,
						/obj/item/weapon/gun/revolver/mateba,
						/obj/item/weapon/gun/pistol/heavy,
						/obj/item/weapon/gun/shotgun/pump,
						/obj/item/weapon/gun/shotgun/pump/combat,
						/obj/item/weapon/gun/shotgun/pump/cmb,
						/obj/item/weapon/gun/shotgun/pump/double
						)
	accuracy_mod = 20 //20% accuracy bonus
	slot = "rail"

/obj/item/attachable/foregrip
	name = "forward grip"
	desc = "A custom-built improved foregrip for maximum accuracy. However, it also changes the weapon to two-handed and increases weapon size."
	icon_state = "sparemag"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/shotgun/pump/combat
					)
	accuracy_mod = 15
	ranged_dmg_mod = 105
	twohanded_mod = 1
	w_class_mod = 1
	recoil_mod = -1
	slot = "under"

/obj/item/attachable/gyro
	name = "gyroscopic stabilizer"
	desc = "A set of weights and balances to allow a two handed weapon to be fired with one hand. Greatly reduces accuracy, however."
	icon_state = "gyro"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/shotgun/pump,
						/obj/item/weapon/gun/shotgun/pump/combat,
						/obj/item/weapon/gun/shotgun/pump/cmb,
						/obj/item/weapon/gun/shotgun/pump/double)
	twohanded_mod = 2
	recoil_mod = 1
	accuracy_mod = -15
	slot = "under"

/obj/item/attachable/flashlight
	name = "rail flashlight"
	desc = "A simple flashlight used for mounting on a firearm. Has no drawbacks."
	icon_state = "flashlight"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/c99,
						/obj/item/weapon/gun/pistol/m1911,
						/obj/item/weapon/gun/pistol/holdout,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70,
						/obj/item/weapon/gun/revolver,
						/obj/item/weapon/gun/revolver/cmb,
						/obj/item/weapon/gun/revolver/mateba,
						/obj/item/weapon/gun/pistol/heavy,
						/obj/item/weapon/gun/shotgun/pump,
						/obj/item/weapon/gun/shotgun/pump/combat,
						/obj/item/weapon/gun/shotgun/pump/cmb,
						/obj/item/weapon/gun/shotgun/pump/double
					)
	light_mod = 5
	slot = "rail"
	var/flashlight_on = 0
	can_activate = 1 //This is needed on all activateable attachments.

	activate_attachment(obj/item/weapon/gun/target,mob/living/user)
		flashlight_on = !flashlight_on
		var/positive = 1
		if(!flashlight_on)
			positive = 0
		if(user && src.loc.loc == user)
			user.SetLuminosity(light_mod * positive)
		else if(target)
			target.SetLuminosity(light_mod * positive)
		target.flashlight_on = flashlight_on
		target.update_attachables()
		return 0

	attackby(obj/item/I as obj, mob/user as mob)
		if(istype(I,/obj/item/weapon/screwdriver))
			user << "You modify the rail flashlight back into a normal flashlight."
			if(src.loc == user)
				user.drop_from_inventory(src)
			var/obj/item/device/flashlight/F = new(src.loc)
			user.put_in_hands(F) //This proc tries right, left, then drops it all-in-one.
			if(F.loc != user) //It ended up on the floor, put it whereever the old flashlight is.
				F.loc = src.loc
			del(src) //Delete da old flashlight
		else
			..()

/obj/item/attachable/bipod
	name = "bipod"
	desc = "A simple set of telescopic poles to keep a weapon stabilized during firing. Greatly increases accuracy and reduces recoil, but also increases weapon size and slows firing speed."
	icon_state = "bipod"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/sniper
					)
	recoil_mod = -1
	accuracy_mod = 30
	slot = "under"
	w_class_mod = 2
	melee_mod = 50 //50% melee damage. Can't swing it around as easily.
	delay_mod = 1

/obj/item/attachable/extended_barrel
	name = "extended barrel"
	desc = "A lengthened barrel allows for greater accuracy, particularly at long range.\nHowever, natural resistance also slows the bullet, leading to reduced damage."
	slot = "muzzle"
	icon_state = "ebarrel"
	accuracy_mod = 20
	ranged_dmg_mod = 95
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70,
						/obj/item/weapon/gun/revolver,
						/obj/item/weapon/gun/revolver/cmb,
						/obj/item/weapon/gun/pistol/heavy
					)

/obj/item/attachable/heavy_barrel
	name = "barrel charger"
	desc = "A fitted barrel extender that goes on the muzzle, with a small shaped charge that propels a bullet much faster.\nGreatly increases projectile damage at the cost of accuracy and firing speed."
	slot = "muzzle"
	icon_state = "hbarrel"
	accuracy_mod = -45
	ranged_dmg_mod = 140
	delay_mod = 3
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/smartgun,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/c99,
						/obj/item/weapon/gun/pistol/m1911,
						/obj/item/weapon/gun/pistol/holdout,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70,
						/obj/item/weapon/gun/revolver,
						/obj/item/weapon/gun/revolver/cmb,
						/obj/item/weapon/gun/revolver/mateba,
						/obj/item/weapon/gun/pistol/heavy
					)

/obj/item/attachable/quickfire
	name = "quickfire adapter"
	desc = "An enhanced and upgraded autoloading mechanism to fire rounds more quickly. However, greatly reduces accuracy and increases weapon recoil."
	slot = "rail"
	icon_state = "autoloader"
	accuracy_mod = -25
	delay_mod = -3
	recoil_mod = 1
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/smartgun,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/c99,
						/obj/item/weapon/gun/pistol/m1911,
						/obj/item/weapon/gun/pistol/holdout,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70,
						/obj/item/weapon/gun/revolver,
						/obj/item/weapon/gun/revolver/cmb,
						/obj/item/weapon/gun/revolver/mateba,
						/obj/item/weapon/gun/pistol/heavy
					)

/obj/item/attachable/compensator
	name = "recoil compensator"
	desc = "A muzzle attachment that reduces recoil by diverting expelled gasses upwards. Increases accuracy and reduces recoil, at the cost of a small amount of weapon damage."
	slot = "muzzle"
	icon_state = "comp"
	accuracy_mod = 20
	ranged_dmg_mod = 90
	recoil_mod = -3
	guns_allowed = list(
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/revolver,
						/obj/item/weapon/gun/revolver/upp,
						/obj/item/weapon/gun/revolver/cmb,
						/obj/item/weapon/gun/revolver/mateba,
						/obj/item/weapon/gun/pistol/heavy,
						/obj/item/weapon/gun/shotgun/pump,
						/obj/item/weapon/gun/shotgun/pump/combat,
						/obj/item/weapon/gun/shotgun/pump/cmb,
						/obj/item/weapon/gun/shotgun/pump/double
					)

/obj/item/attachable/burstfire_assembly
	name = "burst fire assembly"
	desc = "A mechanism re-assembly kit that allows for automatic fire, or more shots per burst if the weapon already has the ability."
	icon_state = "rapidfire"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/smartgun,
						/obj/item/weapon/gun/pistol/m4a3,
						/obj/item/weapon/gun/pistol/c99,
						/obj/item/weapon/gun/pistol/holdout,
						/obj/item/weapon/gun/pistol/vp78,
						/obj/item/weapon/gun/pistol/vp70
						)
	accuracy_mod = -25
	slot = "under"
	burst_mod = 2

/obj/item/attachable/magnetic_harness
	name = "magnetic harness"
	desc = "A magnetically attached harness kit that attaches to the rail mount of a weapon. When dropped, the weapon will sling to a USCM armor."
	icon_state = "magnetic"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,
						/obj/item/weapon/gun/rifle/m41a/elite,
						/obj/item/weapon/gun/rifle/lmg,
						/obj/item/weapon/gun/smg/,
						/obj/item/weapon/gun/sniper,
						/obj/item/weapon/gun/revolver/mateba,
						/obj/item/weapon/gun/shotgun/pump,
						/obj/item/weapon/gun/shotgun/pump/combat,
						/obj/item/weapon/gun/shotgun/pump/cmb,
						/obj/item/weapon/gun/shotgun/pump/double
						)
	accuracy_mod = -15
	slot = "rail"

/obj/item/attachable/compensator/stock
	name = "M37 Wooden Stock"
	desc = "A non-standard heavy wooden stock for the M37 Shotgun. Less quick and more cumbersome than the standard issue stakeout, but reduces recoil and improves accuracy. Allegedly makes a pretty good club in a fight too.."
	slot = "stock"
	icon_state = "stock"
	recoil_mod = -1
	accuracy_mod = 10
	melee_mod = 150
	size_mod = 2
	delay_mod = 3
	pixel_shift_x = 33 //Determines the amount of pixels to move the icon state for the overlay.
	pixel_shift_y = 16 //Uses the bottom left corner of the item.
	guns_allowed = list(/obj/item/weapon/gun/shotgun/pump)

/obj/item/attachable/compensator/riflestock
	name = "M41A Marksman Stock"
	desc = "A rare stock distributed in small numbers to USCM forces. Compatible with the M41A, this stock reduces recoil and improves accuracy, but at a reduction to handling and agility. Seemingly a bit more effective in a brawl"
	slot = "stock"
	recoil_mod = -1
	accuracy_mod = 10
	melee_mod = 120
	size_mod = 1
	delay_mod = 3
	icon_state = "riflestock"
	pixel_shift_x = 35 //Determines the amount of pixels to move the icon state for the overlay.
	pixel_shift_y = 12 //Uses the bottom left corner of the item.
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,/obj/item/weapon/gun/rifle/m41a/elite)

/obj/item/attachable/compensator/revolverstock
	name = "44 Magnum Sharpshooter Stock"
	desc = "A wooden stock modified for use on a 44-magnum. Increases accuracy and reduces recoil at the expense of handling and agility. Less effective in melee as well"
	slot = "stock"
	recoil_mod = -1
	accuracy_mod = 20
	melee_mod = 80
	size_mod = 1
	delay_mod = 3
	w_class_mod = 2
	icon_state = "44stock"
	pixel_shift_x = 36 //Determines the amount of pixels to move the icon state for the overlay.
	pixel_shift_y = 16 //Uses the bottom left corner of the item.
	guns_allowed = list(/obj/item/weapon/gun/revolver/m44)

//The requirement for an attachable being alt fire is AMMO CAPACITY > 0.
/obj/item/attachable/grenade
	name = "underslung grenade launcher"
	desc = "A weapon-mounted, two-shot grenade launcher. It cannot be reloaded."
	icon_state = "grenade"
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a)
	ammo_capacity = 2
	current_ammo = 2
	slot = "under"
	passive = 0 //This tells the gun that this needs to remain "active" until fired.
	can_activate = 1

	//"Readying" the gun for the grenade launch is not needed. Just point & click
	activate_attachment(target,user)
		user << "\blue Your next shot will fire an explosive grenade."
		return 1

	fire_attachment(atom/target,obj/item/weapon/gun/gun,mob/living/user)
		if(current_ammo > 0)
			var/obj/item/weapon/grenade/explosive/G = new(get_turf(gun))
			playsound(user.loc,'sound/weapons/grenadelaunch.ogg', 50, 1)
			message_admins("[key_name_admin(user)] fired an underslung grenade launcher.")
			log_game("[key_name_admin(user)] used an underslung grenade launcher.")
			G.active = 1
			G.icon_state = initial(icon_state) + "_active"
			G.throw_range = 10
			G.throw_at(target, 10, 1, user)
			spawn(12) //~1 second.
				if(G) //If somehow got deleted since then
					G.prime()
			return 1
		else

			if(user) user << "\icon[gun] The [src.name] is empty!"
			return 1


/obj/item/attachable/shotgun
	name = "masterkey shotgun"
	icon_state = "masterkey"
	desc = "A weapon-mounted, four-shot shotgun. Mostly used in emergencies. It cannot be reloaded."
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a,/obj/item/weapon/gun/rifle/mar40)
	ammo_capacity = 4
	current_ammo = 4
	ammo_type = /datum/ammo/bullet/shotgun //Slugs.
	slot = "under"
	shoot_sound = 'sound/weapons/shotgun.ogg'
	passive = 0
	continuous = 1
	can_activate = 1

	//Because it's got an ammo_type, everything is taken care of when the gun shoots.
	activate_attachment(atom/target,mob/living/carbon/user)
		user << "\blue You will now shoot shotgun shells from the [src.name]."
		return 1

//Ditto here. "ammo/flamethrower" is a bullet.
/obj/item/attachable/flamer
	name = "mini flamethrower"
	icon_state = "grenade" //Placeholder
	desc = "A weapon-mounted flamethrower attachment.\nIt is designed for short bursts and must be discarded after it is empty."
	guns_allowed = list(/obj/item/weapon/gun/rifle/m41a)
	ammo_capacity = 9
	current_ammo = 9
	slot = "under"
	shoot_sound = 'sound/weapons/flamethrower_shoot.ogg'
	continuous = 0
	passive = 0
	can_activate = 1

	activate_attachment(atom/target,mob/living/carbon/user)
		user << "\blue Your next shot will fire from the [src.name]."
		return 1

	fire_attachment(atom/target,obj/item/weapon/gun/gun,mob/living/user)
		if(!user || !target || !gun) return 0

		if(get_dist(user,target) <= 0)
			user << "Too close to fire the attached flamethrower!"
			return 1


		if(current_ammo > 0)
			var/list/turf/turfs = list()
			var/distance = 0
			turfs = getline(user,target)
			var/obj/structure/window/W

			for(var/turf/T in turfs)
				distance++
				current_ammo--
				if(current_ammo == 0) break
				if(distance > 3) break
				if(DirBlocked(T,usr.dir))
					break
				else if(DirBlocked(T,turn(usr.dir,180)))
					break
				if(locate(/obj/effect/alien/resin/wall,T) || locate(/obj/structure/mineral_door/resin,T) || locate(/obj/effect/alien/resin/membrane,T))
					break
				W = locate() in T
				if(W)
					if(W.is_full_window()) break
					if(W.dir == src.dir)
						break
				flame_turf(T)
				continue
		else

			if(user) user << "\icon[gun] The [src.name] is empty!"
		return 1

	proc/flame_turf(var/turf/T)
		if(istype(T)) return 0

		if(!locate(/obj/flamer_fire) in T) // No stacking flames!
			var/obj/flamer_fire/F =  new/obj/flamer_fire(T)
			processing_objects.Add(F)

		for(var/mob/living/carbon/M in T) //Deal bonus damage if someone's caught directly in initial stream
			if(M.stat == DEAD) continue
			if(T == usr) continue

			if(istype(M,/mob/living/carbon/Xenomorph))
				if(M:fire_immune) continue
			if(istype(M,/mob/living/carbon/human))
				if(istype(M:wear_suit, /obj/item/clothing/suit/fire) || istype(M:wear_suit,/obj/item/clothing/suit/space/rig/atmos))
					continue
			M.adjustFireLoss(rand(20,50))  //fwoom!
			M << "\red Augh! You are roasted by the flames!"

		return 1
