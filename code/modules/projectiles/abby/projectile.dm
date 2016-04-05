
//The actual bullet objects.
/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = 0
	unacidable = 1
	anchored = 1
	flags = FPRINT | TABLEPASS
	pass_flags = PASSTABLE | PASSGRILLE
	mouse_opacity = 0

	var/datum/ammo/ammo //The ammo data which holds most of the actual info.

	var/bumped = 0		//Prevents it from hitting more than one guy at once
	var/def_zone = ""	//Aiming at
	var/atom/firer = null//Who shot it
	var/silenced = 0	//Attack message

	var/yo = null
	var/xo = null

	var/current = null
	var/atom/shot_from = null // the object which shot us
	var/atom/original = null // the original target clicked

	var/turf/target_turf = null
	var/turf/starting = null // the projectile's starting turf

	var/list/turf/path = list()

	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again

	var/paused = 0 //For suspending projectiles. Neat idea! Stolen shamelessly from TG.

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/damage = 10
	var/damage_type = BRUTE //BRUTE, BURN, TOX, OXY, CLONE are the only things that should be in here
//	var/nodamage = 0 //Determines if the projectile will skip any damage inflictions

	var/distance_travelled = 0
	var/in_flight = 0
	var/saved = 0
	var/flight_check = 50

	Del()
		path = null
		permutated = null
		target_turf = null
		starting = null
		return ..()

	proc/each_turf()
		distance_travelled++
		flight_check--
		if(!flight_check) //This is to make sure there's no infinitely-hanging bullets just sitting around looping. Default is 50.
			del(src)
			return

		if(ammo)
			if(distance_travelled == round(ammo.max_range / 2) && loc)
				ammo.do_at_half_range(src)
		return

	proc/get_accuracy()
		var/acc = 70 //Base accuracy.
		if(!ammo) //Oh, it's not a bullet? Or something? Let's leave.
			return acc

		acc += ammo.accuracy //Add the ammo's accuracy bonus/pens

		if(istype(ammo.current_gun,/obj/item/weapon/gun)) //Does our gun exist? If so, add attachable bonuses.
			var/obj/item/weapon/gun/gun = ammo.current_gun
			if(gun.rail && gun.rail.accuracy_mod) acc += gun.rail.accuracy_mod
			if(gun.muzzle && gun.muzzle.accuracy_mod) acc += gun.muzzle.accuracy_mod
			if(gun.under && gun.under.accuracy_mod) acc += gun.under.accuracy_mod

			acc += gun.accuracy

		//These should all be 0 if the bullet is still in the barrel.
		if(ammo.accurate_range < distance_travelled && (ammo.current_gun && !ammo.current_gun.zoom)) //Determine ranged accuracy
			acc -= (distance_travelled * 4)
		else if(ammo.current_gun && !ammo.current_gun.zoom && ammo.accurate_range >= distance_travelled) //Close range bonus
			acc -= (distance_travelled * 3)
		else if(!ammo.current_gun) //Non-gun firers, aka turrets, just get a flat -2 accuracy per turf.
			acc -= (distance_travelled * 2)

		if(acc < 5) acc = 5 //There's always some chance.
		return acc

	//The attack roll. Returns -1 for an IFF-based miss (smartgun), 0 on a regular miss, 1 on a hit.
	proc/roll_to_hit(var/atom/firer,var/atom/target)
		var/hit_chance = get_accuracy() //Get the bullet's pure accuracy.
		if(target == firer) return 1

		if(istype(target,/mob/living))
			var/mob/living/T = target
			if(T.lying && T.stat) hit_chance += 15 //Bonus hit against unconscious people.
			if(istype(T,/mob/living/carbon/Xenomorph))
				if(T:big_xeno)
					hit_chance += 5
				else
					hit_chance -= 5

			if(ammo.skips_marines && ishuman(target))
				var/mob/living/carbon/human/H = target
				if(H.get_marine_id())
					return -1 //Pass straight through.

			if(ammo.skips_xenos && isXeno(target)) return -1 //Mostly some spits.

			if(istype(firer,/mob/living)) //Lower accuracy based on firer's health.
				var/mob/living/M = firer
				hit_chance -= round((M.maxHealth - M.health) / 4)

			if(def_zone in base_miss_chance) //Make sure it's a valid target
				hit_chance -= base_miss_chance[def_zone] //Reduce accuracy based on spot

			var/hit_roll = rand(0,100) //Our randomly generated roll.

			if(hit_chance < hit_roll - 20) //Mega miss!
				if (!target:lying) target.visible_message("\blue \The [src] misses \the [target]!","\blue \The [src] narrowly misses you!")
				return -1
			else if (hit_chance > hit_roll) //You hit!
				return 1
			else
				//You got lucky buddy, you got a second try! Pick a random organ instead.
				if(saved)
					target.visible_message("\blue \The [src] narrowly misses \the [target]!","\blue \The [src] narrowly misses you!")
					return -1
				def_zone = pick(base_miss_chance)
				saved = 1
				return roll_to_hit(firer,target) //Let's try this again.
		return 1 //Pretty hard to miss an object or turf.

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if(air_group || (height==0)) return 1

		if(istype(mover, /obj/item/projectile))
			return prob(95)
		else
			return 1

	Bump(atom/A as mob|obj|turf|area)
		if(!A in permutated)
			if(A.bullet_act(src))
				spawn(-1)
					del(src)


	proc/follow_flightpath(var/speed = 1, var/change_x, var/change_y, var/range) //Everytime we reach the end of the turf list, we slap a new one and keep going.
		set waitfor = 0

		if(!path) //Our path isn't set.
			del(src)
			return

		var/dist_since_sleep = 0
		var/turf/current_turf = get_turf(src)
		var/turf/next_turf

		spawn()
			while(src && loc)
				if(!path.len) continue //Something weird happened. Where's our flightpath?

				next_turf = path[1]
				if(next_turf == current_turf) //We've already here?
					path -= next_turf
					continue

				if(istype(next_turf) && scan_a_turf(next_turf) == 1) //We hit something! Get out of all of this.
					sleep(-1) //Make sure everything else is done.
					if(src) del(src)
					return

				src.loc = next_turf
				each_turf()
				if(!src) return //It might have been deleted.

				path -= next_turf //Remove it!

				dist_since_sleep++
				if(dist_since_sleep >= speed)
					sleep(1)

				if(distance_travelled >= range)
					if(ammo) ammo.do_at_max_range(src)
					if(src) del(src)
					return

				if(!path.len) //No more left!
					current_turf = get_turf(src)
					next_turf = locate(current_turf.x + change_x, current_turf.y + change_y, current_turf.z)
					if(current_turf && next_turf)
						path = getline(current_turf,next_turf) //Build a new flight path.
						if(path.len && src)
							follow_flightpath(speed, change_x, change_y, range) //Onwards!
							return
					del(src)
					return

//Target, firer, shot from. Ie the gun
	proc/fire_at(atom/target,atom/F, atom/S, range = 30,speed = 1)
		if(!target)
			del(src)
			return 0

		if(!original || isnull(original)) original = target

		starting = get_turf(src)
		if(!starting) return //Horribly wrong
		src.loc = starting //Put us on the turf.
		target_turf = get_turf(target)
		firer = F
		if(F) permutated.Add(F) //Don't hit the shooter (firer)
		shot_from = S
		in_flight = 1

		path = getline(starting,target_turf)

		var/change_x = target_turf.x - starting.x
		var/change_y = target_turf.y - starting.y

//		var/dist_since_sleep = 0
		var/angle = round(Get_Angle(starting,target_turf))

		var/matrix/rotate = matrix() //Change the bullet angle.
		rotate.Turn(angle)
		src.transform = rotate

		if(ammo)
			follow_flightpath(speed,change_x,change_y,ammo.max_range) //pyew!
		else
			follow_flightpath(speed,change_x,change_y,30)

	proc/scan_a_turf(var/turf/T)
		if(!istype(T)) return 0
		if(T.density) //Shit, we hit a wall.
			T.bullet_act(src)
			return 1
		if(firer && T == firer.loc) return 0 //Never.
		if(!T.contents.len) return 0 //Nothing here.

		for(var/atom/A in T)
			if(!A || A == src || A == firer || A in permutated || !A.density ) continue
			if(A == firer) continue
			var/hitroll = roll_to_hit(firer,A)
			if(ismob(A) && A == original && hitroll == 1) //Oh hey our original target's here. Shoot them. Could be someone lying down, etc.
				A.bullet_act(src)
				return 1
			if(!A.density) continue //Nondense stuff aren't even checked.
			if(ismob(A))
				if(A:lying) continue //If it's not the target, and is lying down, skip them.

			if(firer && get_adj_simple(firer,A))  //Always skip over adjacents.
				permutated.Add(A)
				return 0

			if(firer && hitroll == -1)
				permutated.Add(A)
				return 0//Missed!

			if (A.bullet_act(src) != 0)
				bumped = 1
				return 1

		return 0 //Found nothing.

	proc/bullet_ping(var/atom/target)
		if(!target) return

		var/image/ping = image('icons/obj/projectiles.dmi',target,"ping",10) //Layer 10, above most things but not the HUD.
		var/angle = round(rand(1,359))

		if(src.firer && prob(60))
			angle = round(Get_Angle(src.firer,target))

		var/matrix/rotate = matrix()

		rotate.Turn(angle)
		ping.transform = rotate

		for(var/mob/M in viewers(target))
			M << ping

		spawn(3) del(ping)

/atom/proc/bullet_act(obj/item/projectile/P)
	return density

/mob/proc/bullet_message(obj/item/projectile/P)
	if(!P || !P.ammo) return

	if(P.ammo.silenced)
		src << "\red You've been shot in the [parse_zone(P.def_zone)] by \the [P.name]!"
	else
		visible_message("\red [name] is hit by the [P.name] in the [parse_zone(P.def_zone)]!")

	if(istype(P.firer, /mob))
		attack_log += "\[[time_stamp()]\] <b>[P.firer]/[P.firer:ckey]</b> shot <b>[src]/[src.ckey]</b> with a <b>[P]</b>"
		P.firer:attack_log += "\[[time_stamp()]\] <b>[P.firer]/[P.firer:ckey]</b> shot <b>[src]/[src.ckey]</b> with a <b>[P]</b>"
		msg_admin_attack("[P.firer] ([P.firer:ckey]) shot [src] ([src.ckey]) with a [src] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[P.firer.x];Y=[P.firer.y];Z=[P.firer.z]'>JMP</a>)")
	else if(P.firer)
		attack_log += "\[[time_stamp()]\] <b>[P.firer]</b> shot <b>[src]/[src.ckey]</b> with a <b>[P]</b>"
		msg_admin_attack("[P.firer] shot [src] ([src.ckey]) with a [P] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[P.firer.x];Y=[P.firer.y];Z=[P.firer.z]'>JMP</a>)")
	else
		attack_log += "\[[time_stamp()]\] <b>SOMETHING??</b> shot <b>[src]/[src.ckey]</b> with a <b>[P]</b>"
		msg_admin_attack("SOMETHING?? shot [src] ([src.ckey]) with a [P])")
	return

/mob/living/bullet_act(obj/item/projectile/P)
	if(!P || !istype(P) || !P.ammo) return 0 //Somehow. Just some logic.

	var/damage = P.damage - (P.distance_travelled * P.ammo.damage_bleed)
	if(damage < 0) damage = 0 //NO HEALING


	if(stat != DEAD) //Not on deads please
		//Apply happy funtime effects! Based on the ammo datum attached to the bullet.
		apply_effects(P.ammo.stun,P.ammo.weaken,P.ammo.paralyze,P.ammo.irradiate,P.ammo.stutter,P.ammo.eyeblur,P.ammo.drowsy,P.ammo.agony)

	if(src && P && damage > 0)
		apply_damage(damage, P.ammo.damage_type, P.def_zone, 0, 0, 0, P)

	if(!src || !P || !P.ammo) return

	bullet_message(P)
	P.ammo.on_hit_mob(src,P) //Deal with special effects.

	if(P.ammo && damage > 0 && P.ammo.incendiary)
		adjust_fire_stacks(rand(6,10))
		IgniteMob()
//		emote("scream")
		src << "\red <B>You burst into flames!! Stop drop and roll!</b>"


/mob/living/carbon/human/bullet_act(obj/item/projectile/P)
	if(!P || !istype(P) || !P.ammo) return 0 //Somehow. Just some logic.

	flash_weak_pain()

	var/damage = P.damage - (P.distance_travelled * P.ammo.damage_bleed)
	if(damage < 0) damage = 0 //NO HEALING

	//Any projectile can decloak a predator. It does defeat one free bullet though.
	if(gloves)
		var/obj/item/clothing/gloves/yautja/Y = gloves
		if(istype(Y) && Y.cloaked && rand(0,100) < 20 )
			Y.decloak(src)
			return 0

	var/datum/organ/external/organ = get_organ(check_zone(P.def_zone)) //Let's finally get what organ we actually hit.

	if(!organ) return 0//Nope. Gotta shoot something!

	//Run armor check
	//Shields
	if(check_shields(P.damage, "the [P.name]"))
		P.ammo.on_shield_block(src)
		return 1

	var/armor = 0 //Why are damage types different from armor types? Who the fuck knows. Let's merge them anyway.
	var/absorbed = 0

	if(!P.ammo.ignores_armor)
		if(P.damage_type == "BRUTE")
			armor = getarmor_organ(organ, "bullet")
		else if(P.damage_type == "TOX") //Mostly some acid spits. These use "BIO" armor value from now on.
			armor = getarmor_organ(organ, "bio")
		else if(P.damage_type == "BURN")  //Sizzle!
			armor = getarmor_organ(organ, "laser")
		else
			armor = getarmor_organ(organ, "energy") //Everything else. Bullet act should probably not use this except for exotic bullets.

		if(armor) damage = damage - round(damage * (armor / 300)) //Armor automatically absorbs some damage no matter what. Not a lot though

		armor -= P.ammo.armor_pen //Armor piercing weapons!

		if(prob(armor)) //Yay we absorbed more!
			damage = damage - (armor / 10)
			absorbed = 1
			if(prob(armor)) //Let's go one more time.
				damage = round(damage / 10) //Nice!
				absorbed = 2
			if(absorbed == 1 && !stat)
				src << "\red Your armor softens the impact of \the [P]!"
			else if (absorbed == 2 && !stat)
				src << "\red Your armor absorbs the force of \the [P]!"

	if(stat != DEAD && absorbed == 0) //Not on deads please
		//Apply happy funtime effects! Based on the ammo datum attached to the bullet.
		apply_effects(P.ammo.stun,P.ammo.weaken,P.ammo.paralyze,P.ammo.irradiate,P.ammo.stutter,P.ammo.eyeblur,P.ammo.drowsy,P.ammo.agony)

	if(src && P && damage > 0)
		apply_damage(damage, P.ammo.damage_type, P.def_zone, 0, 0, 0, P)

	if(!src || !P || !P.ammo) return

	bullet_message(P)
	P.ammo.on_hit_mob(src,P) //Deal with special effects.

	if (P && P.ammo && src && absorbed == 0 && damage > 0 && P.ammo.shrapnel_chance > 0)
		if(prob(P.ammo.shrapnel_chance + round(damage / 10)))
			embed_shrapnel(P,organ)

	if(P.ammo && !damage > 0 && absorbed == 0 && P.ammo.incendiary)
		adjust_fire_stacks(rand(6,11))
		IgniteMob()
		emote("scream")
		src << "\red <B>You burst into flames!! Stop drop and roll!</b>"

	return 1

/mob/living/carbon/human/proc/embed_shrapnel(var/obj/item/projectile/P, var/datum/organ/external/organ)
	var/obj/item/weapon/shard/shrapnel/SP = new()
	SP.name = "[P.name] shrapnel"
	SP.desc = "[SP.desc] It looks like it was fired from [P.shot_from]."
	SP.loc = organ
	organ.embed(SP)
	if(!stat)
		src << "\red You scream in pain as the impact sends <B>shrapnel</b> into the wound!"
		emote("scream")

//Deal with xeno bullets.
/mob/living/carbon/Xenomorph/bullet_act(obj/item/projectile/P)
	if(!istype(P) || !P.ammo) return 0

	flash_weak_pain()

	var/damage = P.damage - (P.distance_travelled * P.ammo.damage_bleed)
	if(damage < 0) damage = 0 //NO HEALING

	var/armor = armor_deflection - P.ammo.armor_pen


	if(istype(src,/mob/living/carbon/Xenomorph/Crusher)) //Crusher resistances - more depending on facing.
		armor += (src:momentum / 3) //Up to +15% armor deflection all-around when charging.
		if(P.dir == src.dir) //Both facing same way -- ie. shooting from behind.
			armor -= 70 //Ouch.
		else if(P.dir == reverse_direction(src.dir)) //We are facing the bullet.
			armor += 45
		//Otherwise use the standard armor deflection for crushers.

	if(guard_aura) //Yay bonus armor!
		armor += (guard_aura * 3)
	if(P.ammo.ignores_armor) armor = 0 //Nope

	if(prob(armor - damage))
		P.bullet_ping(src)
		visible_message("\blue The [src]'s thick exoskeleton deflects \the [P]!","\blue Your thick exoskeleton deflected \the [P]!")
		return 1

	bullet_message(P)
	P.ammo.on_hit_mob(src)

	if(src && P && damage > 0)
		apply_damage(damage,P.ammo.damage_type, P.def_zone, 0, P,0,0)	//Deal the damage.
		if(prob(10 + round(damage / 4)) && !stat)
			if(prob(70))
				emote("hiss")
			else
				emote("roar")

	if(P.ammo.incendiary)
		if(fire_immune)
			src << "You shrug off some persistent flames."
		else
			adjust_fire_stacks(rand(2,6) + round(damage / 8))
			IgniteMob()
			src.visible_message("\red <B>\The [src] bursts into flames!</b>","\red <B>You burst into flames!! Auuugh! Stop drop and roll!</b>")

	updatehealth()
	return 1

/turf/bullet_act(obj/item/projectile/P)
	if(!src.density || !P || !P.ammo)
		return 0 //It's just an empty turf

	P.bullet_ping(src)

	var/turf/target_turf = P.loc
	if(!istype(target_turf)) return 0 //The bullet's not on a turf somehow.

	var/list/mobs_list = list() //Let's built a list of mobs on the bullet turf and grab one.
	for(var/mob/living/L in target_turf)
		if(L in P.permutated) continue
		mobs_list += L

	if(mobs_list.len)
		var/mob/living/picked_mob = pick(mobs_list) //Hit a mob, if there is one.
		if(istype(picked_mob))
			picked_mob.bullet_act(P)
			return 1

	if(src.can_bullets && src.bullet_holes < 5 ) //Pop a bullet hole on that fucker. 5 max per turf
		var/image/I = image('icons/effects/effects.dmi',src,"dent")
		I.pixel_x = P.p_x
		I.pixel_y = P.p_y
		if(P.damage > 30)
			I.icon_state = "bhole"
		//I.dir = pick(NORTH,SOUTH,EAST,WEST) // random scorch design
		overlays += I
		bullet_holes++

	P.ammo.on_hit_turf(src)

	return 1

//Simulated walls can get shot and damaged, but bullets (vs energy guns) do much less.
/turf/simulated/wall/bullet_act(obj/item/projectile/P)
	..()
	if(!P.ammo) return

	var/D = P.damage
	if(D < 1) return

	if(P.damage_type == "BRUTE") D = round(D/2) //Bullets do much less to walls and such.
	if(P.damage_type == "TOX") return 1
	P.bullet_ping(src)
	take_damage(P.damage)
	if(prob(30 + D))
		P.visible_message("\The [src] is damaged by [P]!")
	return 1

//Hitting an object. These are too numerous so they're staying in their files.
/obj/bullet_act(obj/item/projectile/P)
	if(!CanPass(P,get_turf(src),src.layer))
		P.ammo.on_hit_obj(src)
		P.bullet_ping(src)
		return 1
	else
		return 0

/obj/structure/table/bullet_act(obj/item/projectile/P)
	return !(check_cover(P,get_turf(P)))


//Abby -- Just check if they're 1 tile horizontal or vertical, no diagonals
/proc/get_adj_simple(atom/Loc1 as turf|mob|obj,atom/Loc2 as turf|mob|obj)
	var/dx = Loc1.x - Loc2.x
	var/dy = Loc1.y - Loc2.y

	if(dx == 0) //left or down of you
		if(dy == -1 || dy == 1)
			return 1
	if(dy == 0) //above or below you
		if(dx == -1 || dx == 1)
			return 1

	return 0
