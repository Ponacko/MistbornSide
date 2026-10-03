---
status: accepted
---
# High-resolution pixel art with dynamic 2D lighting

The game needs a trilogy's worth of locations from a very small team, plus convincing lantern, limelight and red-sun lighting, with the mists and blue lines layered on top. We commit to pixel art at a 640 by 360 internal resolution, integer scaled, with normal-mapped sprites lit by Godot 2D lights. Hand-painted 2D (Ori style) was rejected on art cost; low-resolution pixel art (320 by 180) was rejected because Vin at about 24 pixels cannot carry the mistcloak, faces, stained glass or spires. Consequence: every sprite needs a normal map, and the mist, ash and line effects are shaders rather than drawn art.
