/mob/living/carbon/human/emote(var/act,var/m_type=1,var/message = null, player_caused)
	var/param = null
	var/make_langchat = TRUE
	var/comm_paygrade = get_paygrade()
	var/send_message

	if(!species.can_emote)
		return

	if(findtext(act, "-", 1, null))
		var/t1 = findtext(act, "-", 1, null)
		param = copytext(act, t1 + 1, length(act) + 1)
		act = copytext(act, 1, t1)

	if(findtext(act,"s",-1) && !findtext(act,"_",-2))//Removes ending s's unless they are prefixed with a '_'
		act = copytext(act,1,length(act))

	var/muzzled = istype(src.wear_mask, /obj/item/clothing/mask/muzzle)

	for (var/obj/item/implant/I in src)
		if(I.implanted)
			I.trigger(act, src)


	if(act != "help") //you can always use the help emote
		if(stat == DEAD || paralyzed)
			return

		else if(stat && (act != "gasp" || player_caused)) //involuntary gasps can still be emoted when unconscious
			return

	var/Synth = FALSE
	var/Pred = FALSE
	var/Joe = FALSE
	var/Primate = FALSE
	if(isWorkingJoe(src))
		Joe = TRUE
	if(isSpeciesYautja(src))
		Pred = TRUE
	if(isSpeciesMonkey(src))
		Primate = TRUE
	if(isSynth(src))
		Synth = TRUE
	if(!isliving(src))
		return

	switch(act)
		if("me")
			if(player_caused)
				if(src.client)
					if(client.prefs.muted & MUTE_IC)
						to_chat(src, SPAN_DANGER("You cannot send IC messages (muted)."))
						return
					if(src.client.handle_spam_prevention(message,MUTE_IC))
						return
			if(stat)
				return
			if(!(message))
				return
			return custom_emote(m_type, "[message]", player_caused)

		if("blink")
			message = "blinks."
			m_type = 1

		if("blink_r")
			message = "blinks rapidly."
			m_type = 1

		if("bow")
			if(!src.buckled)
				var/M = null
				if(param)
					for (var/mob/A in view(null, null))
						if(param == A.name)
							M = A
							break
				if(!M)
					param = null

				if(param)
					message = "bows to [param]."
				else
					message = "bows."
			m_type = 1

		if("chuckle")
			if(!muzzled)
				message = "chuckles."
				m_type = 2
			else
				message = "makes a noise."
				m_type = 2

		if("clap")
			if(!recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				if(!is_mob_restrained())
					message = "claps."
					m_type = 2
					playsound(src.loc, 'sound/misc/clap.ogg', 25, 0)
					if(player_caused)
						start_audio_emote_cooldown()
			else
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("collapse")
			apply_effect(2, PARALYZE)
			message = "collapses!"
			m_type = 2

		if("cough")
			if(!muzzled)
				message = "coughs!"
				m_type = 2
			else
				message = "makes a strong noise."
				m_type = 2

		if("cry")
			message = "cries."
			m_type = 1

		if("drool")
			message = "drools."
			m_type = 1

		if("eyebrow")
			message = "raises an eyebrow."
			m_type = 1

		if("facepalm")
			message = "facepalms."
			m_type = 1

		if("faint")
			message = "faints!"
			if(src.sleeping)
				return //Can't faint while asleep
			src.sleeping += 10 //Short-short nap
			m_type = 1

		if("frown")
			message = "frowns."
			m_type = 1

		if("gasp")
			if(!muzzled)
				message = "gasps!"
				m_type = 2
			else
				message = "makes a weak noise."
				m_type = 2

		if("giggle")
			if(!muzzled)
				message = "giggles."
				m_type = 2
			else
				message = "makes a noise."
				m_type = 2

		if("glare")
			var/M = null
			if(param)
				for (var/mob/A in view(null, null))
					if(param == A.name)
						M = A
						break
			if(!M)
				param = null
			if(param)
				message = "glares at [param]."
			else
				message = "glares."

		if("golfclap")
			if(!recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				if(!is_mob_restrained())
					message = "claps, clearly unimpressed."
					m_type = 2
					playsound(src.loc, 'sound/misc/golfclap.ogg', 25, 0)
					if(player_caused)
						start_audio_emote_cooldown()
			else
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("grin")
			message = "grins."
			m_type = 1

		if("grumble")
			if(!muzzled)
				message = "grumbles."
				m_type = 2
			else
				message = "makes a noise."
				m_type = 2

		if("handshake")
			m_type = 1
			if(!src.is_mob_restrained() && !src.r_hand)
				var/mob/M = null
				if(param)
					for (var/mob/A in view(1, null))
						if(param == A.name)
							M = A
							break
				if(M == src)
					M = null

				if(M)
					if(M.canmove && !M.r_hand && !M.is_mob_restrained())
						message = "shakes hands with [M]."
					else
						send_message = "<B>[comm_paygrade][src]</B> holds out \his hand to [M]."
						message = "holds out their hand to [M]"

		if("laugh")
			if(!muzzled)
				message = "laughs!"
				m_type = 2
			else
				message = "makes a noise."
				m_type = 2

		if("look")
			var/M = null
			if(param)
				for (var/mob/A in view(null, null))
					if(param == A.name)
						M = A
						break
					if(!M)
						param = null
					if(param)
						message = "looks at [param]."
					else
						message = "looks."
					m_type = 1

		if("medic")
			if(!recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				if(!muzzled && !stat)
					message = "calls for a medic!"
					m_type = 2

					show_speech_bubble("hmedic")

					if(ismonkey(src))
						playsound(loc, 'sound/voice/monkey_whimper.ogg', 50)
					else if(ishuman(src))
						if(src.gender == "male")
							var/medic_sound = pick('sound/voice/human_male_medic.ogg', 5;'sound/voice/human_male_medic_rare_1.ogg', 5;'sound/voice/human_male_medic_rare_2.ogg')
							playsound(src.loc, medic_sound, 25, 0)
						else
							playsound(src.loc, 'sound/voice/human_female_medic.ogg', 25, 0)
						var/list/heard = get_mobs_in_view(7, src)
						var/medic_message = pick("Medic!", "Doc!", "Help!")
						for(var/mob/M in heard)
							if(M.ear_deaf)
								heard -= M
								continue
							var/toggles_langchat = M.client?.prefs.toggles_langchat
							if(toggles_langchat)
								if(!(toggles_langchat & LANGCHAT_SEE_EMOTES))
									heard.Remove(M)
									continue
						langchat_speech(medic_message, heard, GLOB.all_languages, skip_language_check = TRUE, animation_style = LANGCHAT_FAST_POP, additional_styles = list("langchat_bolded"))
						make_langchat = FALSE
					if(player_caused)
						start_audio_emote_cooldown()
			else
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("moan")
			message = "moans."
			m_type = 1

		if("mumble")
			message = "mumbles."
			m_type = 2

		if("jump")
			message = "jumps!"
			m_type = 1

		if("scratch")
			message = "scratches."
			m_type = 1

		if("roll")
			message = "rolls."
			m_type = 1

		if("tail")
			if(Primate)
				message = "swipes their tail."
				m_type = 1

		if("nod")
			message = "nods."
			m_type = 1

		if("pain")
			if(Synth)
				return
			message = "cries out in pain!"
			m_type = 2
			show_speech_bubble("hpain")
			if(!recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				if(isHumanStrict(src))
					if(gender == "male")
						playsound(loc, "male_pain", 50)
					else
						playsound(loc, "female_pain", 50)
					var/list/heard = get_mobs_in_view(7, src)
					var/pain_message = pick("OW!!", "AGH!!", "ARGH!!", "OUCH!!", "ACK!!", "OUF!")
					for(var/mob/M in heard)
						if(M.ear_deaf)
							heard -= M
							continue
						var/toggles_langchat = M.client?.prefs.toggles_langchat
						if(toggles_langchat)
							if(!(toggles_langchat & LANGCHAT_SEE_EMOTES))
								heard.Remove(M)
								continue
					langchat_speech(pain_message, heard, GLOB.all_languages, skip_language_check = TRUE, animation_style = LANGCHAT_FAST_POP, additional_styles = list("langchat_yell"))
				else if(Primate)
					playsound(loc, 'sound/voice/monkey_scream.ogg', 50)
				else if(Pred)
					playsound(loc, "pred_pain", 50)
				if(player_caused)
					start_audio_emote_cooldown()
				track_scream(job)
			else
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("salute")
			if(recent_audio_emote)
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

			if(!buckled)
				var/M = null
				if(param)
					for (var/mob/A in view(null, null))
						if(param == A.name)
							M = A
							break
				if(!M)
					param = null

				if(param)
					message = "salutes to [param]."
				else
					message = "salutes."
				playsound(src.loc, 'sound/misc/salute.ogg', 15, 1)
				start_audio_emote_cooldown()
			m_type = 1

		if("scream")
			if(Synth)
				return
			message = "screams!"
			m_type = 2
			if(!recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				if(isHumanStrict(src))
					if(gender == "male")
						playsound(loc, "male_scream", 50)
					else
						playsound(loc, "female_scream", 50)
					var/list/heard = get_mobs_in_view(7, src)
					var/scream_message = pick("FUCK!!!", "AGH!!!", "ARGH!!!", "AAAA!!!", "HGH!!!", "NGHHH!!!", "NNHH!!!", "SHIT!!!")
					for(var/mob/M in heard)
						if(M.ear_deaf)
							heard -= M
							continue
						var/toggles_langchat = M.client?.prefs.toggles_langchat
						if(toggles_langchat)
							if(!(toggles_langchat & LANGCHAT_SEE_EMOTES))
								heard.Remove(M)
								continue
					langchat_speech(scream_message, heard, GLOB.all_languages, skip_language_check = TRUE, animation_style = LANGCHAT_PANIC_POP, additional_styles = list("langchat_yell"))
					make_langchat = FALSE
				else if(isYautja(src))
					playsound(loc, "pred_pain", 50)
				else if(has_species(src,"Monkey"))
					playsound(loc, 'sound/voice/monkey_scream.ogg', 50)
				if(player_caused)
					start_audio_emote_cooldown()
				track_scream(job)
			else
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("chimper")
			message = "chimpers."
			m_type = 1

			if(Primate && !recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				playsound(loc, pick('sound/voice/monkey_chimper1.ogg', 'sound/voice/monkey_chimper2.ogg'), 25)
				if(player_caused)
					start_audio_emote_cooldown()
			else if(recent_audio_emote && player_caused)
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("whimper")
			message = "whimpers."
			m_type = 1

			show_speech_bubble("hscream")
			if(Primate && !recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
				playsound(loc, 'sound/voice/monkey_whimper.ogg', 25)
				if(player_caused)
					start_audio_emote_cooldown()
			else if(recent_audio_emote && player_caused)
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

		if("shakehead")
			send_message = "<B>[comm_paygrade][src]</B> shakes \his head."
			message = "shakes their head."
			m_type = 1

		if("shiver")
			message = "shivers."
			m_type = 1

		if("shrug")
			message = "shrugs."
			m_type = 1

		if("sigh")
			if(!muzzled)
				message = "sighs."
				m_type = 2
			else
				message = "makes a weak noise."
				m_type = 2

		if("signal")
			if(!src.is_mob_restrained())
				var/t1 = round(text2num(param))
				if(isnum(t1))
					if(t1 <= 5 && (!src.r_hand || !src.l_hand))
						message = "raises [t1] finger\s."
					else if(t1 <= 10 && (!src.r_hand && !src.l_hand))
						message = "raises [t1] finger\s."
			m_type = 1

		if("smile")
			message = "smiles."
			m_type = 1

		if("sneeze")
			message = "sneezes!"
			m_type = 1

		if("snore")
			message = "snores."
			m_type = 1

		if("stare")
			var/M = null
			if(param)
				for (var/mob/A in view(null, null))
					if(param == A.name)
						M = A
						break
			if(!M)
				param = null

			if(param)
				message = "stares at [param]."
			else
				message = "stares."

		if("twitch")
			message = "twitches."
			m_type = 1

		if("wave")
			message = "waves."
			m_type = 1

		if("yawn")
			if(!muzzled)
				message = "yawns."
				m_type = 2

		if("warcry")
			if(recent_audio_emote)
				to_chat(src, "You just did an audible emote. Wait a while.")
				return

			message = "shouts an inspiring cry!"
			m_type = 2

			show_speech_bubble("hwarcry")
			if(isHumanSynthStrict(src))
				if(gender == "male")
					playsound(loc, "male_warcry", 50)
				else
					playsound(loc, "female_warcry", 50)
			else if(ismonkey(src))
				playsound(loc, 'sound/voice/monkey_scream.ogg', 50)
			start_audio_emote_cooldown()

		if("help")
			to_chat(src, "<br><br><b>To use an emote, type an asterix (*) before a following word. Emotes with a sound are <span style='color: green;'>green</span>. Spamming emotes with sound will likely get you banned. Don't do it.<br><br> \
			blink, \
			blink_r, \
			bow-(mob name), \
			chuckle, \
			<span style='color: green;'>clap</span>, \
			collapse, \
			cough, \
			cry, \
			drool, \
			eyebrow, \
			facepalm, \
			faint, \
			frown, \
			gasp, \
			giggle, \
			glare-(mob name), \
			<span style='color: green;'>golfclap</span>, \
			grin, \
			grumble, \
			handshake, \
			laugh, \
			look-(mob name), \
			me, \
			<span style='color: green;'>medic</span>, \
			moan, \
			mumble, \
			nod, \
			<span style='color: green;'>pain</span>, \
			point, \
			<span style='color: green;'>salute</span>, \
			<span style='color: green;'>scream</span>, \
			shakehead, \
			shiver, \
			shrug, \
			sigh, \
			signal-#1-10, \
			smile, \
			sneeze, \
			snore, \
			stare-(mob name), \
			twitch, \
			<span style='color: green;'>warcry</span>, \
			wave, \
			yawn</b><br>")
			if(Synth)
				to_chat(src, "<br><b>As a Synthetic, you do not feel pain, so you cannot use the following emotes.<br>\
				<span style='color: red;'>pain</span>, \
				<span style='color: red;'>scream</span>")
			if(Pred)
				to_chat(src, "<br><b>As a Predator, you have the following additional emotes. Tip: The *medic emote has neither a cooldown nor a visibile origin...<br><br>\
				<span style='color: green;'>anytime</span>, \
				<span style='color: green;'>click</span>, \
				<span style='color: green;'>click2</span>, \
				<span style='color: green;'>helpme</span>, \
				<span style='color: green;'>iseeyou</span>, \
				<span style='color: green;'>itsatrap</span>, \
				<span style='color: green;'>laugh1</span>, \
				<span style='color: green;'>laugh2</span>, \
				<span style='color: green;'>laugh3</span>, \
				<span style='color: green;'>loudroar</span>, \
				<span style='color: green;'>malescream</span>, \
				<span style='color: green;'>femalescream</span>, \
				<span style='color: green;'>overhere</span>, \
				<span style='color: green;'>turnaround</span>, \
				<span style='color: green;'>aliengrowl</span>, \
				<span style='color: green;'>alienhelp</span>, \
				<span style='color: green;'>comeonout</span>, \
				<span style='color: green;'>overthere</span>, \
				<span style='color: green;'>roar</span></b><br>")
			if(Primate)
				to_chat(src, "<br><b>As a Primate, you have the following additional emotes.<br><br>\
				<span style='color: green;'>chimper</span>, \
				<span style='color: green;'>roll</span>, \
				<span style='color: green;'>jump</span>, \
				<span style='color: green;'>scratch</span>, \
				<span style='color: green;'>whimper</span>, \
				<span style='color: green;'>tail</span></b><br>")
			if(Joe)
				to_chat(src, "<br><b>As a Working Joe, you have the following additional emotes.<br><br>\
				<span style='color: green;'>alwaysknow</span>, \
				<span style='color: green;'>workingjoe</span>, \
				<span style='color: green;'>hysterical</span>, \
				<span style='color: green;'>safety</span>, \
				<span style='color: green;'>awful</span>, \
				<span style='color: green;'>mess</span>, \
				<span style='color: green;'>damage</span>, \
				<span style='color: green;'>firearm</span></b><br>")


		// Pred emotes
		if("anytime")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_anytime.ogg', 25, 0)
		if("click")
			if(Pred && src.loc)
				m_type = 1
				spawn(2)
					if(rand(0,100) < 50)
						playsound(src.loc, 'sound/voice/pred_click1.ogg', 25, 1)
					else
						playsound(src.loc, 'sound/voice/pred_click2.ogg', 25, 1)
		if("helpme")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_helpme.ogg', 25, 0)
		if("malescream")
			if(Pred && src.loc)
				m_type = 1
				playsound(loc, "male_scream", 50)
		if("femalescream")
			if(Pred && src.loc)
				m_type = 1
				playsound(loc, "female_scream", 50)
		if("iseeyou")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/hallucinations/i_see_you2.ogg', 25, 0)
		if("itsatrap")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_itsatrap.ogg', 25, 0)
		if("laugh1")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_laugh1.ogg', 25, 0)
		if("laugh2")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_laugh2.ogg', 25, 0)
		if("laugh3")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_laugh3.ogg', 25, 0)
		if("overhere")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_overhere.ogg', 25, 0)
		if("roar")
			if(Pred && src.loc)
				message = "<B>[src] roars!</b>"
				m_type = 1
				spawn(3)
					if(prob(50))
						playsound(src.loc, 'sound/voice/pred_roar1.ogg', 50,1)
					else
						playsound(src.loc, 'sound/voice/pred_roar2.ogg', 50,1)
		if("roar2")
			if(Pred && src.loc)
				message = "<B>[src] roars!</b>"
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_roar3.ogg', 50)

		if ("loudroar")
			if(has_species(src,"Yautja") && src.loc)
				if(!recent_audio_emote || !player_caused)//cooldown only affect emote generated by the player
					message = "<B>[src] roars loudly!</b>"
					m_type = 1
					playsound(src.loc, pick('sound/voice/pred_roar4.ogg', 'sound/voice/pred_roar5.ogg'), 60, 0, 18)
					for(var/mob/M as anything in get_mobs_in_z_level_range(get_turf(src), 18) - src)
						var/relative_dir = get_dir(M, src)
						to_chat(M, SPAN_HIGHDANGER("You hear a loud roar coming from the [dir2text(relative_dir)]!"))
					if(player_caused)
						start_audio_emote_cooldown(120 SECONDS)
				else
					to_chat(src, "You just did an audible emote. Wait a while.")
					return

		if("turnaround")
			if(Pred && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/pred_turnaround.ogg', 25, 0)
		if("click2")
			if(Pred && src.loc)
				m_type = 1
				spawn(2)
					if(prob(50))
						playsound(src.loc, 'sound/voice/pred_click3.ogg', 50)
					else
						playsound(src.loc, 'sound/voice/pred_click4.ogg', 50)
		if("aliengrowl")
			if(Pred && src.loc)
				m_type = 1
				spawn(2)
					if(prob(50))
						playsound(src.loc, 'sound/voice/alien_growl1.ogg', 50)
					else
						playsound(src.loc, 'sound/voice/alien_growl2.ogg', 50)
		if("alienhelp")
			if(Pred && src.loc)
				m_type = 1
				spawn(2)
					if(prob(50))
						playsound(src.loc, 'sound/voice/alien_help1.ogg', 50)
					else
						playsound(src.loc, 'sound/voice/alien_help2.ogg', 50)
		if("comeonout")
			if(Pred && src.loc)
				m_type = 1
				playsound(loc, 'sound/voice/pred_come_on_out.ogg', 50)
		if("overthere")
			if(Pred && src.loc)
				m_type = 1
				playsound(loc, 'sound/voice/pred_over_there.ogg', 50)

		//working joe emotes
		if("alwaysknow", "workingjoe")
			if(Joe && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/joe_alwaysknow.ogg', 75, 0)
				say("You always know a Working Joe.")
		if("hysterical")
			if(Joe && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/joe_hysterical.ogg', 75, 0)
				say("You are becoming hysterical.")
		if("safety")
			if(Joe && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/joe_safety.ogg', 75, 0)
				say("You and I are going to have a talk about safety.")
		if("awful", "mess", "mes") //Since the parser trims the final s...
			if(Joe && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/joe_awful.ogg', 75, 0)
				say("Tut, tut. What an awful mess.")
		if("damage")
			if(Joe && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/joe_damage.ogg', 75, 0)
				say("Do not damage Seegson property.")
		if("firearm")
			if(Joe && src.loc)
				m_type = 1
				playsound(src.loc, 'sound/voice/joe_firearm.ogg', 75, 0)
				say("Firearms can cause serious injury. Let me assist you.")
		else
			to_chat(src, SPAN_NOTICE(" Unusable emote '[act]'. Say *help for a list of emotes."))

	if(message)
		if(!send_message)
			send_message = "<B>[comm_paygrade][src]</B> [message]"
		log_emote("[name]/[key] : [send_message]")

//Hearing gasp and such every five seconds is not good emotes were not global for a reason.
// Maybe some people are okay with that.

		for(var/mob/M in GLOB.dead_mob_list)
			if(!M.client)
				continue //skip monkeys, leavers and new players
			if((M.stat == DEAD || isobserver(M)) && M.client.prefs && (M.client.prefs.toggles_chat & CHAT_GHOSTSIGHT) && !(M in viewers(src,null)))
				M.show_message(send_message)

		if(make_langchat)
			if(m_type & SHOW_MESSAGE_VISIBLE)
				var/viewers = get_mobs_in_view(world_view_size,src)
				for (var/mob/O in viewers)
					O.show_message(send_message, m_type)
				langchat_speech(message, viewers, GLOB.all_languages, skip_language_check = TRUE, additional_styles = list("emote", "langchat_small"))
			else if(m_type & SHOW_MESSAGE_AUDIBLE)
				var/hearing = hearers(src.loc, null)|get_mobs_in_view(world_view_size,src)
				for (var/mob/O in hearing)
					O.show_message(send_message, m_type)
				langchat_speech(message, hearing, GLOB.all_languages, skip_language_check = TRUE, additional_styles = list("emote", "langchat_small"))



/mob/living/carbon/human/verb/pose()
	set name = "Set Pose"
	set desc = "Sets a description which will be shown when someone examines you."
	set category = "IC"

	pose =  strip_html(input(usr, "This is [src]. \He is...", "Pose", null)  as text)

/mob/living/carbon/human/verb/set_flavor()
	set name = "Set Flavour Text"
	set desc = "Sets an extended description of your character's features."
	set category = "IC"

	var/HTML = "<body>"
	HTML += "<tt>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=general'>General:</a> "
	HTML += TextPreview(flavor_texts["general"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=head'>Head:</a> "
	HTML += TextPreview(flavor_texts["head"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=face'>Face:</a> "
	HTML += TextPreview(flavor_texts["face"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=eyes'>Eyes:</a> "
	HTML += TextPreview(flavor_texts["eyes"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=torso'>Body:</a> "
	HTML += TextPreview(flavor_texts["torso"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=arms'>Arms:</a> "
	HTML += TextPreview(flavor_texts["arms"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=hands'>Hands:</a> "
	HTML += TextPreview(flavor_texts["hands"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=legs'>Legs:</a> "
	HTML += TextPreview(flavor_texts["legs"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=feet'>Feet:</a> "
	HTML += TextPreview(flavor_texts["feet"])
	HTML += "<br>"
	HTML += "<hr />"
	HTML +="<a href='?src=\ref[src];flavor_change=done'>\[Done\]</a>"
	HTML += "<tt>"
	show_browser(src, HTML, "Update Flavor Text", "flavor_changes", "size=430x300")
