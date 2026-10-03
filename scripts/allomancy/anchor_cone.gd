class_name AnchorCone
## A coin resting on a surface is an anchor for Pushes driven into the surface
## within the cone around its normal; outside the cone it skids and Vin gets
## only partial lift (DESIGN.md 5.2).


## push_dir: direction of the Push on the coin. Returns {anchored, lift, tangent}:
## lift is the share of an anchor's impulse Vin receives, tangent the
## direction the coin skids.
static func classify(push_dir: Vector2, surface_normal: Vector2, cone_degrees: float, partial_lift := 0.5) -> Dictionary:
	var into := push_dir.dot(-surface_normal)
	var angle := rad_to_deg(acos(clampf(into, -1.0, 1.0)))
	if angle <= cone_degrees:
		return {"anchored": true, "lift": 1.0, "tangent": Vector2.ZERO}
	var tangent := push_dir + surface_normal * into
	return {
		"anchored": false,
		"lift": maxf(into, 0.0) * partial_lift,
		"tangent": tangent.normalized() if tangent.length() > 0.001 else Vector2.ZERO,
	}
