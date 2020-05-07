#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                (c) Copyright 2017-2020 Ward
#
#====================================================================

import strutils, sequtils, os

import wNim/[wApp, wDataObject, wAcceleratorTable, wUtils,
  wFrame, wPanel, wMessageDialog, wMenuBar, wMenu, wIcon,
  wDirDialog, wStatusBar, wStaticText]

import gamepath

type
  MenuID = enum
    idText = wIdUser, idFile, idExit, idPaste

# const defaultText = "Drag and drop .udk or .upk map files to load"
# const defaultFile = ["dragdrop.exe"]
# # const defaultImage = staticRead(r"images/logo.png")

let app = App()
# var data = DataObject(defaultText)
var data = DataObject("")

var modsDir: ModsDirResult

let frame = Frame(title="Rocket League Map Loader", size=(600, 350),
  style=wDefaultFrameStyle or wDoubleBuffered)
#frame.icon = Icon("", 0) # load icon from exe file.

let menuBar = MenuBar(frame)
let panel = Panel(frame)

let menu = Menu(menuBar, "&File")
# menu.append(idText, "Load &Text", "Loads default text as current data.")
# menu.append(idFile, "Load &File", "Loads exefile as current data.")
# menu.append(idImage, "Load &Image", "Loads default image as current data.")
# menu.appendSeparator()
# menu.append(idPaste, "&Paste\tCtrl+V", "Paste data from clipboard.")
# menu.appendSeparator()
# menu.append(idExit, "E&xit", "Exit the program.")

menu.append(idFile, "Load &File", "Load file")
menu.appendSeparator()
menu.append(idExit, "E&xit", "Exit the program.")

let accel = AcceleratorTable()
accel.add(wAccelCtrl, wKey_V, idPaste)
frame.acceleratorTable = accel

let target = StaticText(panel, label="Drag and drop .udk or .upk map files to load",
  style=wBorderStatic or wAlignCentre or wAlignMiddle)
target.setDropTarget()

proc layout() =
  panel.autolayout """
    spacing: 20
    H:|-[target]-|
    V:|-[target]-|
  """

  # proc layout() =
  # panel.autolayout """
  #   spacing: 20
  #   H:|-[target]-[dataText,dataList,dataBitmap]-|
  #   V:|-[target]-|
  #   V:|-[dataText,dataList,dataBitmap]-|
  # """
proc modDirSelection() =
    let dir = DirDialog(frame, message="Choose Rocket League directory", style=wDdDirMustExist).display()
    # validate Rocket League Directory and make it something I can use
    if dir.len != 0:
      echo dir

      # need to see if need to create mod dir or not
      modsDir = ModsDirResult(path: dir, createdModFolder: false)
    # else recursion?

proc loadModsDir() =
  if modsDir.path.isEmptyOrWhitespace or not existsDir modsDir.path:
    modsDir = getModsDir()

  if modsDir.path.isEmptyOrWhitespace:
    MessageDialog(frame, "Cannot find mod directory", caption="Error", wIconErr).display()
    modDirSelection()

proc handleFiles() =
    let files = data.getFiles().filterIt((splitFile it).ext == ".upk" or (splitFile it).ext == ".udk")
    if files.len == 0:
      MessageDialog(frame, "No map files loaded", caption="Error", wIconErr).display()
      return

    let copyBool = copyFiles(modsDir.path, data.getFiles().filterIt((splitFile it).ext == ".upk" or (splitFile it).ext == ".udk"))
    if copyBool:
      MessageDialog(frame, "Copied file(s) to mod directory", caption="", wIconInformation).display()
    else:
      MessageDialog(frame, "Could not copy files to mod directory", caption="Error", wIconErr).display()

    # file dialog to choose, don't let them continue until chosen and valid

target.wEvent_DragEnter do (event: wEvent):
  var dataObject = event.getDataObject()
  if dataObject.isText() or dataObject.isFiles() or dataObject.isBitmap():
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
  var dataObject = event.getDataObject()
  if dataObject.isFiles():
    # use copy constructor to copy the data.
    data = DataObject(dataObject)

    handleFiles()
    # displayData()
  else:
    event.setEffect(wDragNone)

frame.idExit do ():
  delete frame

frame.idFile do ():
  data = DataObject("")
  # data = DataObject(defaultFile)
  # displayData()

# frame.idPaste do ():
#   data = wGetClipboard()
#   # displayData()

panel.wEvent_Size do ():
  layout()

layout()
# displayData()
loadModsDir()
frame.center()
frame.show()
app.mainLoop()