import nimclutter
import math
import oldgtk3/[glib, gobject, cairo]

proc draw_clock(canvas: Canvas, cr: cairo.Context, width: int, height: int): bool =
  var
    now: GDateTime
    hours, minutes, seconds: float32

  # Get the current time and compute the angles
  now = newDateTimeNowUTC()
  seconds = getSeconds(now) * G_PI / 30'f32
  minutes = getMinute(now).float32 * G_PI / 30'f32
  hours = getHour(now).float32 * G_PI / 6'f32

  cr.save()

  # Clear the contents of the canvas to avoidp painting
  # over the previous frame
  cr.setOperator(CLEAR)
  cr.paint()

  cr.restore()

  cr.setOperator(OVER)

  # Scale the modelview to the size of the surface
  cr.scale(width.float64, height.float64)

  cr.setLineCap(LineCap.ROUND)
  cr.setLineWidth(0.1)

  # The black rail that holds the seconds indicator
  cr.setSourceColor(getStatic(BLACK))
  cr.translate(0.5, 0.5)
  cr.arc(0.0, 0.0, 0.4, 0.0, G_PI * 2.0)
  cr.stroke()

  # Seconds indicator
  cr.setSourceColor(getStatic(WHITE))
  cr.moveTo(0.0, 0.0)
  cr.arc(sin(seconds) * 0.4, - cos(seconds) * 0.4, 0.05, 0.0, G_PI * 2.0)
  cr.fill()

  # Minutes hand
  cr.setSourceColor(getStatic(CHAMELEON_DARK))
  cr.moveTo(0.0, 0.0)
  cr.lineTo(sin(minutes) * 0.4, - cos(minutes) * 0.4)
  cr.stroke()

  # Hours hand
  cr.moveTo(0.0, 0.0)
  cr.lineTo(sin(hours) * 0.2, - cos(hours) * 0.2)
  cr.stroke()

  unref(now)

  result = true

proc invalidate_clock(data: Gpointer): bool =
  # Invalidate the contents of the canvas
  cast[nimclutter.Content](data).invalidate()

  # Keep the timeout source
  result = G_SOURCE_CONTINUE

var idle_resize_id: uint32

proc idle_resize(data: Gpointer): bool =
  var
    actor: Actor = cast[Actor](data)
    width, height: float32

  # Match the canvas size to the actor's
  actor.getSize(width.addr, height.addr)
  discard cast[Canvas](actor.getContent()).setSize(ceil(width).cint, ceil(height).cint)

  # Unset the guard
  idle_resize_id = 0

  result = G_SOURCE_REMOVE

proc on_actor_resize(actor: Actor, allocation: ActorBox, flags: AllocationFlags, user_data: Gpointer) =
  # Throttle multiple actor allocations to one canvas resize; we use a guard
  # variable to avoid queueing multiple resize operations
  if idle_resize_id == 0:
    idle_resize_id =  addThreadsTimeout(1_000, cast[GSourceFunc](idle_resize), actor)

proc main() =
  var
    stage, actor: Actor
    canvas: nimclutter.Content

  # initialize Clutter
  if initClutter() != SUCCESS: quit()

  # Create a resizeable stage
  stage = newStage()
  cast[Stage](stage).setTitle("2D Clock")
  cast[Stage](stage).setUserResizable(true)
  stage.setBackgroundColor(getStatic(SKY_BLUE))
  stage.setSize(300, 300)
  stage.show()

  # Our 2D canvas, courtesy of Cairo
  canvas = newCanvas()
  discard cast[Canvas](canvas).setSize(300, 300)

  actor = newActor()
  actor.setContent(canvas)
  actor.setContentScalingFilters(TRILINEAR, LINEAR)
  stage.addChild(actor)

  # The Actor now owns the canvas
  objectUnref(canvas)

  # Bind the size of the actor to that of the stage
  actor.addConstraint(stage.newBindConstraint(BindCoordinate.SIZE, 0))
  
  # Resize the canvas whenever the actor changes size
  discard actor.gSignalConnect("allocation-changed", cast[GCallback](on_actor_resize), nil)

  # Quit on destroy
  discard stage.gSignalConnect("destroy", cast[GCallback](clutterMainQuit), nil)

  # Connect our drawing code
  discard canvas.gSignalConnect("draw", cast[GCallback](draw_clock), nil)

  # Invalidate the canvas, so that we can draw before the main loop starts
  canvas.invalidate()

  # Set up a timer that invalidates the canvas every second
  discard addThreadsTimeout(1_000, cast[GSourceFunc](invalidate_clock), canvas)

  clutterMain()

main()
