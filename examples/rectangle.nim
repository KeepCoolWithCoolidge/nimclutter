import nimclutter
import oldgtk3/[glib, gobject]

proc main() =
  var stage: ptr GObject
  var error: ptr ptr GError = nil

  if initClutter() != SUCCESS: quit()

  var script = newScript()
  discard script.loadFromFile("rectangle.json", error)
  script.connectSignals(script)
  stage = script.getObject("stage")
  cast[Actor](stage).show()
  clutterMain()

main()