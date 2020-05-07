#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                (c) Copyright 2017-2020 Ward
#
#====================================================================

import strutils, sequtils, os

import wNim/[wApp, wDataObject, wAcceleratorTable, wUtils,
  wFrame, wPanel, wMessageDialog, wMenuBar, wMenu, wIcon, wBitmap,
  wStatusBar, wStaticText, wTextCtrl, wListBox, wStaticBitmap]

import gamepath

type
  MenuID = enum
    idText = wIdUser, idFile, idImage, idPaste, idExit

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

# let statusBar = StatusBar(frame)
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

# let dataText = TextCtrl(panel,
#   style=wInvisible or wBorderStatic or wTeMultiLine or wTeReadOnly or
#   wTeRich or wTeDontWrap)

# let dataList = ListBox(panel,
#   style=wInvisible or wLbNoSel or wLbNeededScroll)

# let dataBitmap = StaticBitmap(panel,
#   style=wInvisible or wSbFit)

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

proc loadModsDir() =
  modsDir = getModsDir()
  if modsDir.path.isEmptyOrWhitespace:
    MessageDialog(frame, "Cannot find mod directory", caption="Error", wIconErr).display()

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

# proc displayData() =
#   if data.isText():
#     let text = data.getText()
#     dataText.setValue(text)
#     statusBar.setStatusText(fmt"Got {text.len} characters.")

#     dataText.show()
#     dataList.hide()
#     dataBitmap.hide()

#   elif data.isFiles():
#     dataList.clear()
#     for file in data.getFiles():
#       dataList.append(file)
#     statusBar.setStatusText(fmt"Got {dataList.len} files.")

#     dataList.show()
#     dataText.hide()
#     dataBitmap.hide()

#   elif data.isBitmap():
#     let bmp = data.getBitmap()
#     dataBitmap.setBitmap(bmp)
#     statusBar.setStatusText(fmt"Got a {bmp.width}x{bmp.height} image.")

#     dataBitmap.show()
#     dataList.hide()
#     dataText.hide()

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

# frame.idText do ():
#   data = DataObject(defaultText)
#   # displayData()

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