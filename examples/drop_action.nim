import nimclutter
import strutils
import oldgtk3/[gobject, glib]

const
  TARGET_SIZE = 200.0
  HANDLE_SIZE = 128.0

var stage, target1, target2, drag: Actor

var dropSuccessful: bool = false

proc addDragObject(target: Actor)

proc destroyActor(target: Actor) =
  target.destroy()

proc onDragEnd(action: DragAction,
               actor: Actor,
               eventX: cfloat,
               eventY: cfloat,
               modifiers: ModifierType) =
  var handle: Actor = action.getDragHandle()
  echo "Drag ended at: $1, $2" % [$eventX, $eventY]

  actor.saveEasingState()
  actor.setEasingMode(AnimationMode.LINEAR)
  actor.setOpacity(255.cuchar)
  actor.restoreEasingState()

  handle.saveEasingState()

  if not dropSuccessful:
    var parent: Actor = actor.getParent()
    var xPos, yPos: cfloat

    parent.saveEasingState()
    parent.setEasingMode(AnimationMode.LINEAR)
    parent.setOpacity(255.cuchar)
    parent.restoreEasingState()

    actor.getTransformedPosition(xPos.addr, yPos.addr)

    handle.setEasingMode(AnimationMode.EASE_OUT_BOUNCE)
    handle.setPosition(xPos, yPos)
    handle.setOpacity(0.cuchar)
  else:
    handle.setEasingMode(AnimationMode.LINEAR)
    handle.setOpacity(0.cuchar)
  
  handle.restoreEasingState()

  discard handle.gSignalConnect("transitions-completed",
                                cast[GCallback](destroyActor),
                                nil)

proc onDragBegin(action: DragAction,
                 actor: Actor,
                 eventX: cfloat,
                 eventY: cfloat,
                 modifiers: ModifierType) =
  var handle: Actor
  var xPos, yPos: cfloat

  actor.getPosition(xPos.addr, yPos.addr)

  handle = newActor()
  handle.setBackgroundColor(getStatic(SKY_BLUE_DARK))
  handle.setSize(HANDLE_SIZE, HANDLE_SIZE)
  handle.setPosition(eventX - xPos, eventY - yPos)
  stage.addChild(handle)

  action.setDragHandle(handle)

  actor.saveEasingState()
  actor.setEasingMode(AnimationMode.LINEAR)
  actor.setOpacity(128.cuchar)
  actor.restoreEasingState()

  dropSuccessful = false

proc addDragObject(target: Actor) =
  var parent: Actor

  if drag == nil:
    var action: Action

    drag = newActor()
    drag.setBackgroundColor(getStatic(SKY_BLUE_LIGHT))
    drag.setSize(HANDLE_SIZE, HANDLE_SIZE)
    drag.setPosition((TARGET_SIZE - HANDLE_SIZE) / 2.0,
                     (TARGET_SIZE - HANDLE_SIZE) / 2.0)
    drag.setReactive(true)

    action = newDragAction()
    discard action.gSignalConnect("drag-begin",
                                  cast[GCallback](onDragBegin),
                                  nil)
    discard action.gSignalConnect("drag-end",
                                  cast[GCallback](onDragEnd),
                                  nil)    
    drag.addAction(action)
  
  parent = drag.getParent()
  if parent == target:
    target.saveEasingState()
    target.setEasingMode(AnimationMode.LINEAR)
    target.setOpacity(255.cuchar)
    target.restoreEasingState()
    return

  if parent != nil and parent != stage:
    parent.removeChild(drag)

    parent.saveEasingState()
    parent.setEasingMode(AnimationMode.LINEAR)
    parent.setOpacity(64.cuchar)
    parent.restoreEasingState()
  
  target.addChild(drag)

  target.saveEasingState()
  target.setEasingMode(AnimationMode.LINEAR)
  target.setOpacity(255.cuchar)
  target.restoreEasingState()

proc onTargetOver(action: DropAction,
                  actor: Actor,
                  data: pointer) =
  var isOver: bool = cast[bool](data)
  var finalOpacity: cuchar = if isOver: 128.cuchar else: 64.cuchar
  var target: Actor

  target = cast[ActorMeta](action).getActor()

  target.saveEasingState()
  target.setEasingMode(AnimationMode.LINEAR)
  target.setOpacity(finalOpacity)
  target.restoreEasingState()

proc onTargetDrop(action: DropAction,
                  actor: Actor,
                  eventX: cfloat,
                  eventY: cfloat) =
  var actorX, actorY: cfloat = 0.0

  discard actor.transformStagePoint(eventX, eventY, actorX.addr, actorY.addr)
  
  echo "Dropped at $1, $2 (screen: $3, $4)" % [$actorX, $actorY, $eventX, $eventY]
  
  dropSuccessful = true
  actor.addDragObject()

proc main() =
  var dummy: Actor

  if initClutter() != SUCCESS: quit()

  stage = newStage()
  cast[Stage](stage).setTitle("Drop Action")
  discard stage.gSignalConnect("destroy", cast[GCallback](clutterMainQuit), nil)

  target1 = newActor()
  target1.setBackgroundColor(getStatic(SCARLET_RED_LIGHT))
  target1.setSize(TARGET_SIZE, TARGET_SIZE)
  target1.setOpacity(64.cuchar)
  target1.addConstraint(stage.newAlignConstraint(AlignAxis.Y_AXIS, 0.5))
  target1.setX(10)
  target1.setReactive(true)

  target1.addAction("drop", newDropAction())
  discard target1.getAction("drop").gSignalConnect("over-in",
                                                   cast[GCallback](onTargetOver),
                                                   cast[pointer](true))
  discard target1.getAction("drop").gSignalConnect("over-out",
                                                   cast[GCallback](onTargetOver),
                                                   cast[pointer](false))
  discard target1.getAction("drop").gSignalConnect("drop",
                                                   cast[GCallback](onTargetDrop),
                                                   nil)
  
  dummy = newActor()
  dummy.setBackgroundColor(getStatic(ORANGE_DARK))
  dummy.setSize(640 - (2 * 10) - (2 * (TARGET_SIZE + 10)),
                TARGET_SIZE)
  dummy.addConstraint(stage.newAlignConstraint(AlignAxis.X_AXIS, 0.5))
  dummy.addConstraint(stage.newAlignConstraint(AlignAxis.Y_AXIS, 0.5))
  dummy.setReactive(true)

  target2 = newActor()
  target2.setBackgroundColor(getStatic(CHAMELEON_LIGHT))
  target2.setSize(TARGET_SIZE, TARGET_SIZE)
  target2.setOpacity(64.cuchar)
  target2.addConstraint(stage.newAlignConstraint(AlignAxis.Y_AXIS, 0.5))
  target2.setX(640 - TARGET_SIZE - 10)
  target2.setReactive(true)

  target2.addAction("drop", newDropAction())
  discard target2.getAction("drop").gSignalConnect("over-in",
                                                   cast[GCallback](onTargetOver),
                                                   cast[pointer](true))
  discard target2.getAction("drop").gSignalConnect("over-out",
                                                   cast[GCallback](onTargetOver),
                                                   cast[pointer](false))
  discard target2.getAction("drop").gSignalConnect("drop",
                                                   cast[GCallback](onTargetDrop),
                                                   nil)
  
  stage.addChild(target1)
  stage.addChild(dummy)
  stage.addChild(target2)

  target1.addDragObject()

  stage.show()

  clutterMain()

main()