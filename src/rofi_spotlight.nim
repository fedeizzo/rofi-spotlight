import os
from osproc import startProcess, execProcess
import tables
from strutils import replace, toLowerAscii
from config_parser import Directory, readConfig, noMatchCommand
from config import defaultNoMatch
from files_finder import getFiles
from desktop_entry import Entry, parseEntries


when isMainModule:
  var
    files = newSeq[string]()
    filesToDir = initTable[string, string]()
    dirsToIcon = initTable[string, string]()
    patterns = initTable[string, string]()
    filesToProgram = initTable[string, string]()

  var
    entries: seq[Entry]
    entryToExec = initTable[string, string]()


  getFiles(files, filesToDir, dirsToIcon, patterns, filesToProgram)
  entries = parseEntries()

  var filesString: string
  var isDesktopEntry = initTable[string, bool]()
  for f in files:
    let dir = filesToDir[f]
    let icon = dirsToIcon[dir & patterns[dir]]
    filesString = filesString & icon & " " & f & "\n"
    isDesktopEntry[f] = false

  for e in entries:
    if e.name != "":
      filesString = filesString & e.name & r"\0icon\x1f" & e.icon & "\n"
      entryToExec[e.name] = e.exec
      isDesktopEntry[e.name] = true

  var rofiOutput = execProcess("echo -en \"" & filesString & "\" | rofi -dmenu -i -p \"\"")
  rofiOutput = replace(rofiOutput, "\n", "")
  var
    flag = 0
    parsedOutput: string

  for i in rofiOutput:
    if flag > 0:
      parsedOutput.add(i)

    if i == ' ':
      flag += 1

  if not filesToDir.hasKey(parsedOutput):
    parsedOutput = rofiOutput

  if rofiOutput == "":
    quit 0

  if parsedOutput == "":
    parsedOutput = rofiOutput

  var
    cmd = ""
    path = ""


  if isDesktopEntry.hasKey(parsedOutput) and isDesktopEntry[parsedOutput]:
    cmd = "sh -c " & entryToExec[parsedOutput] &  " &"
  elif filesToProgram.hasKey(parsedOutput):
    cmd = filesToProgram[parsedOutput] & " "
    path = filesToDir[parsedOutput] & "/" & parsedOutput & "&"
    path = replace(path, " ", "\\ ")
    path = replace(path, " ", "\\ ")
  else:
    cmd = noMatchCommand & " \'" & rofiOutput & "\'"
    if defaultNoMatch.hasKey(noMatchCommand):
      cmd = defaultNoMatch[noMatchCommand] & rofiOutput & "' &"

  if path != "" and cmd != "":
    discard execShellCmd(cmd & path)
  elif cmd != "":
    discard execShellCmd(cmd)

  quit 0
