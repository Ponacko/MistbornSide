class_name CanvasLayers
## Draw order of the screen-space layers. The mist shader covers the world
## below LINES; blue lines and Steelsight previews sit above it; the HUD above
## everything gameplay draws.

const MIST := 2
const LINES := 5
const FLASH := 8
const HUD := 10
const DIALOGUE := 20
const MENU := 50
const DEBUG := 100
