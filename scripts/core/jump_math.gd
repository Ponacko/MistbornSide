class_name JumpMath
## Turns designer-facing "reach this height in this time" values into physics
## constants, in the manner of the GDC "Building a Better Jump" talk.


static func gravity_for(height: float, time_to_apex: float) -> float:
	return 2.0 * height / (time_to_apex * time_to_apex)


static func launch_speed_for(height: float, time_to_apex: float) -> float:
	return 2.0 * height / time_to_apex
