# Quick Mobile Testing Script
# This script can be used to quickly test mobile features

extends Node

func _ready():
	print("=== MOBILE PORT TESTING ===")
	print("Platform: ", OS.get_name())
	
	# Test mobile manager
	if has_node("/root/MobileManager"):
		var mobile_manager = get_node("/root/MobileManager")
		print("Mobile Manager available: true")
		print("Is mobile platform: ", mobile_manager.is_mobile())
		print("Touch controls: ", mobile_manager.get_touch_controls())
		
		# Test haptic feedback
		print("Testing haptic feedback...")
		mobile_manager.trigger_haptic_light()
		await get_tree().create_timer(0.5).timeout
		mobile_manager.trigger_haptic_medium()
	else:
		print("Mobile Manager available: false")
	
	# Test touch controls existence
	var touch_controls = get_tree().get_first_node_in_group("touch_controls")
	if touch_controls:
		print("Touch controls found in scene")
		print("Touch controls visible: ", touch_controls.visible)
	else:
		print("Touch controls not found")
	
	print("=== TEST COMPLETE ===")
	
	# Auto quit after test
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()