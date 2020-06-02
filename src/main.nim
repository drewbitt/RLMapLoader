import strutils, sequtils, os

import wNim/[wApp, wDataObject, wAcceleratorTable, wUtils,
  wFrame, wPanel, wMessageDialog, wMenuBar, wMenu, wIcon,
  wDirDialog, wFileDialog, wStaticText, wFont]

import gamepath

type
  MenuID = enum
    idText = wIdUser, idFile, idExit, idPaste

let app = App()
var data = DataObject("")
var modsDir: ModsDirResult
# used to determine whether to show manual mod dir setting success
var failLoadModDir = false

var frame = Frame(title = "Rocket League Map Loader", size = (600, 350),
  style = wDefaultFrameStyle or wDoubleBuffered)
frame.setFont(Font(14))
# text color
frame.setForegroundColor(wWhite)
#frame.icon = Icon("", 0) # load icon from exe file.

let menuBar = MenuBar(frame)
var panel = Panel(frame)
panel.setBackgroundColor(wDarkGrey)

let menu = Menu(menuBar, "&File")
menu.append(idPaste, "&Paste\tCtrl+V file", "Paste file from clipboard.")
menu.append(idFile, "Load &File", "Load file")
menu.appendSeparator()
menu.append(idExit, "E&xit", "Exit the program.")

let accel = AcceleratorTable()
accel.add(wAccelCtrl, wKey_V, idPaste)
frame.acceleratorTable = accel

let target = StaticText(panel, label = "Paste or drag and drop .udk or .upk map files to load",
  style = wTransparentWindow or wAlignCentre or wAlignMiddle)
target.setDropTarget()

proc layout() =
  panel.autolayout """
    H:|-[target]-|
    V:|-[target]-|
  """

proc modDirSelection()

proc checkModDir() =
  if modsDir.path.isEmptyOrWhitespace:
    failLoadModDir = true
    MessageDialog(frame, "Cannot find mod directory", caption = "Error",
        wIconErr).display()
    modDirSelection()
  else:
    if failLoadModDir:
      MessageDialog(frame, "Set mod directory", caption = "Success",
          wIconInformation).display()
      failLoadModDir = false

proc modDirSelection() =
  ## Manual selection of mods dir
  let dir = DirDialog(frame, message = "Choose Rocket League directory",
      style = wDdDirMustExist).display()
  # validate Rocket League Directory and make it something I can use
  if dir.len != 0:
    modsDir = getModsDirManual(dir)
    checkModDir()
  else:
    # quit if they exit out
    delete frame

proc loadModsDir() =
  ## Auto load mods dir using vdf file lookup. If can't find, display manual selection window
  if modsDir.path.isEmptyOrWhitespace or not existsDir modsDir.path:
    modsDir = getModsDir()

  checkModDir()

proc handleFiles() =
  let files = data.getFiles().filterIt((splitFile it).ext == ".upk" or (
      splitFile it).ext == ".udk")
  if files.len == 0:
    MessageDialog(frame, "No map files loaded", caption = "Error",
        wIconErr).display()
    return

  let copyBool = copyFiles(modsDir.path, data.getFiles().filterIt((
      splitFile it).ext == ".upk" or (splitFile it).ext == ".udk"))
  if copyBool:
    MessageDialog(frame, "Copied file(s) to mod directory", caption = "Success",
        wIconInformation).display()
  else:
    MessageDialog(frame, "Could not copy files to mod directory",
        caption = "Error", wIconErr).display()

target.wEvent_DragEnter do (event: wEvent):
  let dataObject = event.getDataObject()
  if dataObject.isFiles():
    event.setEffect(wDragCopy)
  else:
    event.setEffect(wDragNone)

target.wEvent_DragOver do (event: wEvent):
  if event.getEffect() != wDragNone:
    if event.ctrlDown:
      event.setEffect(wDragMove)
    else:
      event.setEffect(wDragCopy)

target.wEvent_Drop do (event: wEvent):
  let dataObject = event.getDataObject()
  if dataObject.isFiles():
    data = DataObject(dataObject)
    handleFiles()
  else:
    event.setEffect(wDragNone)

frame.idExit do ():
  delete frame

frame.idFile do ():
  let files = FileDialog(frame, "Choose .upk or .udk map files",
      style = wFdMultiple, wildcard = "(*.upk, *.udk)").display()
  if files.len != 0:
    data = DataObject(files)
    handleFiles()
  else:
    discard

frame.idPaste do ():
  let dataObject = wGetClipboard()
  let files = dataObject.getFiles().filterIt(existsFile it)

  if files.len != 0:
    data = DataObject(files)
    handleFiles()

panel.wEvent_Size do ():
  layout()

layout()
frame.center()
frame.show()
loadModsDir()
app.mainLoop()
