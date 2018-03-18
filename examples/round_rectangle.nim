# Translation into Nim of C example by ebassi clutter/examples/constraints.c

import nimclutter
import oldgtk3/[glib, gobject, cairo]

proc drawContent(canvas: Canvas, cr: cairo.Context, surfaceWidth, surfaceHeight: int): Gboolean =
  # rounded rectangle taken from:
  #
  # http://cairographics.org/samples/rounded_rectangle/
  #
  # we leave 1 pixel around the edges to avoid jagged edges
  # when rotating thet actor
  #
  var 
    x, y = 1.0'f64  # Parameters like cairo_rectangle
    width, height = surfaceWidth.float64 - 2.0'f64
    aspect: float64 = 1.0 # aspect ratio
    cornerRadius: float64 = height / 20.0
    radius: float64 = cornerRadius / aspect # and corner curvature radius
    degrees: float64 = G_PI / 180.0

  save(cr)
  setOperator(cr, CLEAR)
  paint(cr)
  restore(cr)

  newSubPath(cr)
  arc(cr, x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees)
  arc(cr, x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees)
  arc(cr, x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees)
  arc(cr, x + radius, y + radius, radius, 180 * degrees, 270 * degrees)
  closePath(cr)

  setSourceRgba(cr, 0.5, 0.5, 1.0, 0.95)
  fill(cr)

  result = true

proc main() =
  var 
    stage, actor: Actor
    canvas: nimclutter.Content
    transition: Transition
  
  # initialize Clutter
  if initClutter() != CLUTTER_INIT_SUCCESS: quit()

  # create a stage
  stage = newStage()
  setTitle(cast[Stage](stage), "Rectangle and rounded corners")
  setUseAlpha(cast[Stage](stage), true)
  setBackgroundColor(stage, getStatic(CLUTTER_COLOR_BLACK))
  setSize(stage, 500.0, 500.0)
  setOpacity(stage, 64.cuchar)
  show(stage)

  # our 2D canvas, courtesy of Cairo
  canvas = newCanvas()
  discard setSize(cast[Canvas](canvas), 300, 300)

  # the actor that will display the contents of the canvas
  actor = newActor()
  setContent(actor, canvas)
  setContentGravity(actor, CLUTTER_CONTENT_GRAVITY_CENTER)
  setContentScalingFilters(actor, CLUTTER_SCALING_FILTER_TRILINEAR, CLUTTER_SCALING_FILTER_LINEAR)
  setPivotPoint(actor, 0.5'f32, 0.5'f32)
  addConstraint(actor, newAlignConstraint(stage, CLUTTER_ALIGN_BOTH, 0.5))
  setRequestMode(actor, CLUTTER_REQUEST_CONTENT_SIZE)
  addChild(stage, actor)

  # the actor now owns the canvas
  objectUnref(canvas)

  # create the continuous animation of the actor spinning around its center
  transition = newPropertyTransition("rotation-angle-y")
  setFrom(transition, G_TYPE_DOUBLE, 0.0)
  setTo(transition, G_TYPE_DOUBLE, 360.0)
  setDuration(cast[Timeline](transition), 2_000)
  setRepeatCount(cast[Timeline](transition), -1)
  addTransition(actor, "rotateActor", transition)

  # the actor now owns the transition
  objectUnref(transition)

  # quit on destroy
  discard gSignalConnect(stage, "destroy", cast[GCallback](clutterMainQuit), nil)

  # connect our drawing code
  discard gSignalConnect(canvas, "draw", cast[GCallback](drawContent), nil)

  # invalidate the canvas, so that we can draw before the main loop starts
  invalidate(canvas)

  clutterMain()

main()
