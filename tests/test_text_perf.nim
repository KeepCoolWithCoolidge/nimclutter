import nimclutter
import oldgtk3/[glib, gobject]
import strutils, os

const STAGE_WIDTH = 800'f32
const STAGE_HEIGHT = 600'f32

var fontSize: int
var nChars: int
var rows, cols: int

type
  rangeStruct = object
    firstLetter: Gunichar
    nLetters: uint32

let ranges: array[5, rangeStruct] = [rangeStruct(firstLetter: cast[uint32]('a'), nLetters: 26), # Lower case letters
                                     rangeStruct(firstLetter: cast[uint32]('A'), nLetters: 26), # Upper case letters
                                     rangeStruct(firstLetter: cast[uint32]('0'), nLetters: 10), # Digits
                                     rangeStruct(firstLetter: 0x410, nLetters: 0x40),           # Cyrillic alphabet
                                     rangeStruct(firstLetter: 0x3b1, nLetters: 18)]             # Greek alphabet

proc onPaint(actor: Actor, data: ptr GConstpointer) =
  var timer {.global.}: GTimer = nil
  var fps {.global.}: int = 0

  if timer == nil:
    timer = newTimer()
    start(timer)
  
  if elapsed(timer, nil) >= 1:
    echo "fps=$1, strings/sec=$2, chars/sec=$3" % [$fps, $(fps * rows * cols), $(fps * rows * cols * nChars)]
    start(timer)
    fps = 0
  inc(fps)

proc queueRedraw(stage: GPointer): Gboolean =
  queueRedraw(cast[Actor](stage))
  result = G_SOURCE_CONTINUE

proc getCharacter(character: uint32): Gunichar =
  var totalLetters = 0'u32
  var ch: uint32 = character
  var i = 0
  for i in 0..<ranges.len:
    totalLetters += ranges[i].nLetters
  ch = ch mod totalLetters
  for i in 0..<(ranges.len - 1):
    if ch < ranges[i].nLetters:
      return ch + ranges[i].firstLetter
    else:
      ch -= ranges[i].nLetters
  return ch + ranges[i].firstLetter

proc createLabel(): Actor =
  var label: Actor
  var fontName: cstring
  var str: GString

  fontName = dupPrintf("Monospace %dpx", cast[uint32](fontSize))

  str = newGString(nil)
  for i in 0..<nChars:
    discard appendUnichar(str, getCharacter(cast[uint32](i)))
  
  label = newText(fontName, str.str)
  setColor(cast[nimclutter.Text](label), getStatic(CLUTTER_COLOR_WHITE))

  result = label

proc main() =
  var 
    stage: Actor
    label: Actor
    w, h: float32
    rows, cols: float32
    scale: float32 = 1.0
  
  discard setEnv("CLUTTER_VBLANK", "none", false)
  discard setEnv("CLUTTER_DEFAULTS_FPS", "1000", false)

  if initClutter() != CLUTTER_INIT_SUCCESS: quit()

  if paramCount() != 2:
    echo "Usage test_text_perf FONT_SIZE N_CHARS"
    quit()
  
  fontSize = paramStr(1).parseInt()
  nChars = paramStr(2).parseInt()

  echo "Monospace $1px, string length = $2" % [$fontSize, $nChars]

  stage = newStage()
  setSize(stage, STAGE_WIDTH, STAGE_HEIGHT)
  setBackgroundColor(stage, getStatic(CLUTTER_COLOR_BLACK))
  setTitle(cast[Stage](stage), "Text Performace")
  discard gSignalConnect(stage, "paint", cast[GCallback](onPaint), nil)
  discard gSignalConnect(stage, "destroy", clutterMainQuit, nil)

  label = createLabel()
  w = getWidth(label)
  h = getHeight(label)

  # If the label is too big to fit on the stage then scale it so that it will fit
  if w > STAGE_WIDTH or h > STAGE_HEIGHT:
    var xScale: float32 = STAGE_WIDTH / w
    var yScale: float32 = STAGE_HEIGHT / h

    if xScale < yScale:
      scale = xScale
      cols = 1
      rows = STAGE_HEIGHT / (h * scale)
    else:
      scale = yScale
      cols = STAGE_WIDTH / (w * scale)
      rows = 1
    
    echo "Text scaled by $1 to fit on the stage" % [scale.formatFloat(ffDecimal, 4)]
  else:
    cols = STAGE_WIDTH / w
    rows = STAGE_HEIGHT / h
  
  destroy(label)

  for row in 0..<rows.int:
    for col in 0..<cols.int:
      label = createLabel()
      setScale(label, scale, scale)
      setPosition(label, w * col.float32 * scale, h * row.float32 * scale)
      addChild(stage, label)
  
  show(stage)
  
  discard addThreadsIdle(cast[GSourceFunc](test_text_perf.queueRedraw), stage)

  clutterMain()

main()