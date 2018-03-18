import clutter
import oldgtk3/[glib, gobject]

proc main() =
  var stage: ptr GObject
  var error: ptr ptr GError = nil

  if initClutter() != CLUTTER_INIT_SUCCESS: quit()

  var script = newScript()
  discard script.loadFromFile("rectangle.json", error)
  script.connectSignals(script)
  stage = script.getObject("stage")
  cast[Actor](stage).show()
  clutterMain()

main()