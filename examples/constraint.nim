# Translation into Nim of C example by ebassi clutter/examples/constraints.c

import nimclutter
import oldgtk3/[glib, gobject]

proc main() =
  var stage, layer_a, layer_b, layer_c: Actor
 
  if initClutter() != CLUTTER_INIT_SUCCESS: quit()

  # the main container
  stage = newStage()
  stage.setName("stage")
  cast[Stage](stage).setTitle("Snap Constraint")
  stage.setBackgroundColor(getStatic(CLUTTER_COLOR_ALUMINIUM_1))
  cast[Stage](stage).setUserResizable(true)
  discard stage.gSignalConnect("destroy", cast[GCallback](clutterMainQuit),nil)

  # first layer, with a fixed (100, 25) size
  layer_a = newActor()
  layer_a.setBackgroundColor(getStatic(CLUTTER_COLOR_SCARLET_RED))
  layer_a.setName("layerA")
  layer_a.setSize(100.0, 25.0)
  stage.addChild(layer_a)

  # the first layer is anchored to the middle of the stage
  layer_a.addConstraint(stage.newAlignConstraint(CLUTTER_ALIGN_BOTH, 0.5))

  # the second layer, with no explicit size
  layer_b = newActor()
  layer_b.setBackgroundColor(getStatic(CLUTTER_COLOR_BUTTER_DARK))
  layer_b.setName("layerB")
  stage.addChild(layer_b)

  # the second layer tracks the X coordinates and the width of the first layer
  layer_b.addConstraint(layer_a.newBindConstraint(CLUTTER_BIND_X, 0.0))
  layer_b.addConstraint(layer_a.newBindConstraint(CLUTTER_BIND_WIDTH, 0.0))

  # the second layer is snapped between the bottom edge of
  # the first layer, and the bottom edge of the stage; a
  # spacing of 10 pixels in each direction is added for padding
  layer_b.addConstraint(layer_a.newSnapConstraint(CLUTTER_SNAP_EDGE_TOP, CLUTTER_SNAP_EDGE_BOTTOM, 10.0))
  layer_b.addConstraint(stage.newSnapConstraint(CLUTTER_SNAP_EDGE_BOTTOM, CLUTTER_SNAP_EDGE_BOTTOM, -10.0))

  # the third layer, with no explicit size
  layer_c = newActor()
  layer_c.setBackgroundColor(getStatic(CLUTTER_COLOR_CHAMELEON_LIGHT))
  layer_c.setName("layerC")
  stage.addChild(layer_c)

  # as with the second layer, the third layer tracks the X
  # coordinate and width of the first layer
  layer_c.addConstraint(layer_a.newBindConstraint(CLUTTER_BIND_X, 0.0))
  layer_c.addConstraint(layer_a.newBindConstraint(CLUTTER_BIND_WIDTH, 0.0))

  # the third layer is snapped between the top edge of the stage
  # and the tope edge of the first layer; again, a spacing of 10
  # pixels in each direction is added for padding
  layer_c.addConstraint(layer_a.newSnapConstraint(CLUTTER_SNAP_EDGE_BOTTOM, CLUTTER_SNAP_EDGE_TOP, -10.0))
  layer_c.addConstraint(stage.newSnapConstraint(CLUTTER_SNAP_EDGE_TOP, CLUTTER_SNAP_EDGE_TOP, 10.0))

  stage.show()
  clutterMain()

main()