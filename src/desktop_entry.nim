import os
import strutils
import tables
from osproc import startProcess, execProcess

type
  Entry* = object
    name*: string
    icon*: string
    exec*: string

proc newEntry(name, icon, exec: string):Entry =
  result = Entry(name: name, icon: icon, exec: exec)

proc parseEntry(path: string):Entry =
  let f = open(path, fmRead)
  var
    name = ""
    exec = ""
    icon = ""

  for l in f.lines:
    if name == "" and l.startsWith("Name") and not l.startsWith("Name["):
      name = l.split("=")[1]
    elif exec == "" and l.startsWith("Exec"):
      exec = l.split("=")[1]
    elif icon == "" and l.startsWith("Icon"):
      icon = l.split("=")[1]
      # icon = "/usr/share/icons/hicolor/16x16/apps/" & l.split("=")[1] & ".png"
      # if not icon.existsFile:
      #   icon = ""


  result = newEntry(name, icon, exec)

proc parseEntries*(): seq[Entry] =
  result = newSeq[Entry]()
  for f in "/usr/share/applications".walkDir:
    if f.kind == pcFile:
      result.add(f.path.parseEntry)

when isMainModule:
  var entries = parseEntries()
  var entryToExec = initTable[string, string]()

  var s = ""
  for e in entries:
    if e.name != "":
      s = s & e.name & "\n"
      entryToExec[e.name] = e.exec

  var rofiOutput = execProcess("echo \"" & s & "\" | rofi -dmenu -i -p \"\"")
  rofiOutput = replace(rofiOutput, "\n", "")
  let cmd = "sh -c " & entryToExec[rofiOutput]
  echo rofiOutput & " " & entryToExec[rofiOutput]
  discard execShellCmd(cmd)

