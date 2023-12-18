extends CanvasLayer

# signals
signal cutscene_finished
signal cutscene_full_dark

# refs
@onready var blackout_rect = $blackout_rect
@onready var full_dark_timer = $full_dark_timer
@onready var blackout_labels = $blackout_labels

# cutscene state
var cutscene_play_flag = false

# transition vars
var is_transition_dark = false
var is_transition_light = false
var is_full_dark = false
var is_full_light = true

# full dark iterations
var full_dark_mode_iterations = 0

# constants
const transition_speed = 0.8
const full_dark_time = 2.0


func _ready():

	# make default invisible
	self.visible = false

	# blackout labels invisible
	self._make_blackout_labels_invisible()


# --
# public functions

func cutscene_play():

	# leave cases
	if cutscene_play_flag: return

	# flag
	cutscene_play_flag = true

	# init transition
	is_transition_dark = true

	# make it visible
	self.visible = true


# --
# private functions

func _make_blackout_labels_invisible():

	# make blackout labels unvisible
	blackout_labels.visible = false
	for child in blackout_labels.get_children(): child.visible = false


func _transit_to_light():

	# init transition
	is_transition_light = true

	# invisible labels
	self._make_blackout_labels_invisible()


func _full_dark_rached():

	# set flags
	is_transition_dark = false
	is_full_dark = true

	# full dark timer signal connections
	full_dark_timer.timeout.connect(self._full_dark_mode)
	
	# call full dark mode first time
	self._full_dark_mode()

	# emit a signal
	cutscene_full_dark.emit()


func _full_dark_mode():

	# visible labels
	blackout_labels.visible = true

	# restart timer
	full_dark_timer.start(full_dark_time)

	# child visible
	if full_dark_mode_iterations < blackout_labels.get_child_count():
		var child = blackout_labels.get_child(full_dark_mode_iterations)
		child.visible = true
		full_dark_mode_iterations += 1
		return

	# stop timer and disconnect
	full_dark_timer.stop()
	full_dark_timer.timeout.disconnect(self._full_dark_mode)

	# call transit to light
	self._transit_to_light()

	# end of full dark mode
	full_dark_mode_iterations = 0


func _full_light_rached():

	# set flags
	is_transition_light = false
	is_full_light = true

	# full play done
	cutscene_play_flag = false
	self.visible = false

	# signal
	cutscene_finished.emit()


func _process(delta):

	# do something if cutscene runs
	if not cutscene_play_flag: return

	# no transition marked
	if not is_transition_dark and not is_transition_light: return

	# get actual alpha
	var alpha = blackout_rect.color.a

	# do transition (transition dark is positive)
	alpha += delta * transition_speed * (1 if is_transition_dark else -1)

	# fulliness not guaranteed
	is_full_dark = false
	is_full_light = false

	# limits
	if alpha < 0.0:
		alpha = 0.0
		self._full_light_rached()

	elif alpha > 1.0:
		alpha = 1.0
		self._full_dark_rached()

	# set alpha value
	blackout_rect.color.a = alpha
