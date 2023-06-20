extends Node

# Player Test DoT
func initialize(spell,source,target):
	if spell["auratype"] == "damage" or spell["auratype"] == "heal":
		initialize_tick(spell,source,target)
	elif spell["auratype"] == "buff" or spell["auratype"] == "debuff":
		initialize_buff(spell,source,target)

func initialize_tick(spell,source,target):
	# set node name in parentparent script aura_dict
	target.aura_dict["%s %s"%[source.stats_curr["name"],spell["name"]]] = self
	# start tick timer
	tick(spell,source,target)
	# start timer with duration, if duration is finite
	if spell["duration"] > 0:
		duration(spell,source,target)

func initialize_buff(spell,source,target):
	# set node name in parentparent script aura_dict
	target.aura_dict[spell["name"]] = self
	# modify parentparent stat modifiers
	for s in range(spell["modifies"].size()):
		var statkey = spell["modifies"][s] # the modified stat
		if spell["modify_type"][s] == "mult":
			target.stats_base["stat_mult"][statkey][spell["name"]] = \
				spell["modify_values"][s]
		if spell["modify_type"][s] == "add":
			target.stats_base["stat_add"][statkey][spell["name"]] = \
				spell["modify_values"][s]
		# single stat calculation
		Combat.single_stat_calculation(target,statkey)
	# start timer with duration, if duration is finite
	if spell["duration"] > 0:
		duration(spell,source,target)

func tick(spell,source,target):
	# set up tick timer
	var tick_timer = Timer.new()
	tick_timer.one_shot = false
	tick_timer.wait_time = float(spell["tick"])
	tick_timer.connect("timeout",tick_expires.bind(spell,source,target))
	add_child(tick_timer)
	tick_timer.start()

func tick_expires(spell,source,target):
	# send combat event on tick
	Combat.aura_tick_event(spell,source,target)

func duration(spell,source,target):
	var exp_timer = Timer.new()
	# start timer
	exp_timer.one_shot = true
	exp_timer.wait_time = float(spell["duration"])
	exp_timer.connect("timeout",remove_aura.bind(spell,source,target))
	add_child(exp_timer)
	exp_timer.start()

func remove_aura(spell,source,target):
	# if dot or hot
	if spell["auratype"] == "damage" or spell["auratype"] == "heal":
		# remove from aura dict and remove scene
		target.aura_dict.erase("%s %s"%[source.stats_curr["name"],spell["name"]])
		print("%s's %s faded from %s"%[source.stats_curr["name"],spell["name"],target.stats_curr["name"]])
		queue_free()
	# if buff or debuff
	elif spell["auratype"] == "buff" or spell["auratype"] == "debuff":
		# remove from aura dict
		target.aura_dict.erase(spell["name"])
		# remove from stat_mult and stat_add
		for s in range(spell["modifies"].size()):
			var statkey = spell["modifies"][s] # the modified stat
			if spell["modify_type"][s] == "mult":
				target.stats_base["stat_mult"][statkey].erase(spell["name"])
			if spell["modify_type"][s] == "add":
				target.stats_base["stat_add"][statkey].erase(spell["name"])
		# 	force stat caclulatio
			Combat.single_stat_calculation(target,statkey)
		print("%s's %s faded from %s"%[source.stats_curr["name"],spell["name"],target.stats_curr["name"]])
		queue_free()
