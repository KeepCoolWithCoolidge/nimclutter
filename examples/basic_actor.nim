# Translation into Nim of C example by ebassi clutter/examples/basic_actor.c

import nimclutter
import oldgtk3/[gobject]

const SIZE = 128

proc animateColor(actor: Actor, event: Event): bool =
  var toggled {.global.}: bool = true
  var end_color: Color
  
  end_color = if toggled: getStatic(BLUE) else: getStatic(RED)

  actor.saveEasingState()
  actor.setEasingDuration(500)
  actor.setEasingMode(AnimationMode.LINEAR)
  actor.setBackgroundColor(end_color)
  actor.restoreEasingState()

  toggled = not toggled

  result = CLUTTER_EVENT_STOP

proc onCrossing(actor: Actor, event: Event): bool =
  var isEnter: bool = getEventType(event) == EventType.ENTER
  var zpos: float

  zpos = if isEnter: -250.0 else: 0.0

  actor.saveEasingState()
  actor.setEasingDuration(500)
  actor.setEasingMode(AnimationMode.EASE_OUT_BOUNCE)
  actor.setZPosition(zpos)
  actor.restoreEasingState()

  result = CLUTTER_EVENT_STOP

proc onTransitionStopped(actor: Actor, transition_name: cstring, isFinished: bool) =
  actor.saveEasingState()
  actor.setRotationAngle(RotateAxis.Y_AXIS, 0.0)
  actor.restoreEasingState()

  # disconnect so we don't get multiple notifications
  discard actor.gSignalHandlersDisconnectByFunc(onTransitionStopped, nil)

proc animateRotation(actor: Actor, event: Event): bool =
  actor.saveEasingState()
  actor.setEasingDuration(1000)
  actor.setRotationAngle(RotateAxis.Y_AXIS, 360.0)
  actor.restoreEasingState()

  # get a notification when the rotation-angle-y transition ends
  discard actor.gSignalConnect("transition-stopped::rotation-angle-y", 
                               cast[GCallback](onTransitionStopped), 
                               nil)
  result = CLUTTER_EVENT_STOP

proc main() =
  var stage, vase: Actor
  var flowers: array[3, Actor]

  if initClutter() != SUCCESS: quit()

  stage = newStage()
  discard stage.gSignalConnect("destroy", cast[GCallback](clutterMainQuit), nil)
  cast[Stage](stage).setTitle("Three Flowers in a Vase")
  cast[Stage](stage).setUserResizable(true)

  # there are three flowers in a vase
  vase = newActor()
  vase.setName("vase")
  vase.setLayoutManager(newBoxLayout())
  vase.setBackgroundColor(getStatic(SKY_BLUE_LIGHT))
  vase.addConstraint(stage.newAlignConstraint(AlignAxis.BOTH, 0.5))
  stage.addChild(vase)

  flowers[0] = newActor()
  flowers[0].setName("flower.1")
  flowers[0].setSize(SIZE, SIZE)
  flowers[0].setMarginLeft(12)
  flowers[0].setBackgroundColor(getStatic(RED))
  flowers[0].setReactive(true)
  vase.addChild(flowers[0])
  discard flowers[0].gSignalConnect("button-press-event",
                                    cast[GCallback](animateColor),
                                    nil)
  
  flowers[1] = newActor()
  flowers[1].setName("flower.2")
  flowers[1].setSize(SIZE, SIZE)
  flowers[1].setMarginTop(12)
  flowers[1].setMarginLeft(6)
  flowers[1].setMarginRight(6)
  flowers[1].setMarginBottom(12)
  flowers[1].setBackgroundColor(getStatic(YELLOW))
  flowers[1].setReactive(true)
  vase.addChild(flowers[1])
  discard flowers[1].gSignalConnect("enter-event",
                                    cast[GCallback](onCrossing),
                                    nil)
  discard flowers[1].gSignalConnect("leave-event",
                                    cast[GCallback](onCrossing),
                                    nil)

  # the third one is green
  flowers[2] = newActor()
  flowers[2].setName("flower.3")
  flowers[2].setSize(SIZE, SIZE)
  flowers[2].setMarginRight(12)
  flowers[2].setBackgroundColor(getStatic(GREEN))
  flowers[2].setPivotPoint(0.5, 0.5)
  flowers[2].setReactive(true)
  vase.addChild(flowers[2])
  discard flowers[2].gSignalConnect("button-press-event",
                                    cast[GCallback](animateRotation),
                                    nil)
  
  stage.show()
  clutterMain()

main()