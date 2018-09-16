import nimclutter
import oldgtk3/[pango, gobject]

proc main() =

  var stage, hello: Actor
  var color: nimclutter.Color

  # initialize Clutter
  if initClutter() != SUCCESS: quit()

  # Create stage and set its properties
  stage = newStage()
  stage.setBackgroundColor(getStatic(BLACK))
  stage.setSize(500.0, 400.0)
  cast[Stage](stage).setTitle("Clutter Hello Worlds")

  # Create label and set its properties
  color = newColor(0xff.cuchar, 
                   0xcc.cuchar, 
                   0xcc.cuchar, 
                   0xdd.cuchar)
  hello = newText("Monospace 32px", "Hello There!", color)
  hello.setPosition(100.0, 200.0)

  # Add label to stage
  stage.addChild(hello)

  # Quit on destroy
  discard stage.gSignalConnect("destroy", cast[GCallback](clutterMainQuit), nil)

  # Start main clutter loop.
  stage.show()
  clutterMain()

# Run program.
main()