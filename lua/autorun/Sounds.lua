sound.Add {
	name = "Concrete.StepLeft",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = { 90, 110 },
	sound = {
		"Footsteps/Concrete/L1.wav",
		"Footsteps/Concrete/L2.wav"
	}
}

sound.Add {
	name = "Concrete.StepRight",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = { 90, 110 },
	sound = {
		"Footsteps/Concrete/R1.wav",
		"Footsteps/Concrete/R2.wav"
	}
}

sound.Add {
	name = "SilencedShot",
	channel = CHAN_WEAPON,
	level = 70,
	pitch = { 90, 110 },
	volume = .2,
	sound = "SilencedShot.wav"
}

sound.Add {
	name = "Bleed",
	channel = CHAN_STATIC,
	volume = 1,
	level = 50,
	pitch = { 90, 110 },
	sound = {
		"ambient/water/distant_drip1.wav",
		"ambient/water/distant_drip2.wav",
		"ambient/water/distant_drip3.wav",
		"ambient/water/distant_drip4.wav"
	}
}

sound.Add {
	name = "FlashlightOn",
	sound = "buttons/lightswitch2.wav",
	level = 40,
	volume = 1,
	channel = CHAN_AUTO
}

sound.Add {
	name = "FlashlightOff",
	sound = "buttons/lightswitch2.wav",
	level = 40,
	volume = 1,
	channel = CHAN_AUTO
}

sound.Add {
	name = "BoneFleshyCrack",
	sound = "physics/body/body_medium_break4.wav",
	level = 80,
	pitch = { 80, 120 },
	volume = .6,
	channel = CHAN_STATIC
}

sound.Add {
	name = "BoneFleshyCrackQ",
	sound = "physics/body/body_medium_break4.wav",
	level = 85,
	pitch = { 80, 120 },
	volume = .4,
	channel = CHAN_STATIC
}

sound.Add {
	name = "BoneFleshyBreak",
	sound = { "physics/body/body_medium_break2.wav", "physics/body/body_medium_break3.wav" },
	level = 85,
	pitch = { 80, 120 },
	volume = .6,
	channel = CHAN_STATIC
}

sound.Add {
	name = "BoneFleshyBreakQ",
	sound = { "physics/body/body_medium_break2.wav", "physics/body/body_medium_break3.wav" },
	level = 85,
	pitch = { 80, 120 },
	volume = .4,
	channel = CHAN_STATIC
}
