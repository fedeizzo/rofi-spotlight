import os
import strutils

var noMatchCommand* = "google"
var iterateOverPATH* = false

type
  Directory* = object
    name: string
    path*: string
    pattern*: string
    recursive*: bool
    program*: string
    icon*:string

proc takeValue(str: string): string =
  result = str.split(": ")[1]

proc readDirectory(file: File): Directory =
  var dir = Directory(
    name: takeValue(file.readLine().strip()),
    path: takeValue(file.readLine().strip()),
    pattern: takeValue(file.readLine().strip()),
    recursive: takeValue(file.readLine().strip()).parseBool,
    program: takeValue(file.readLine().strip()),
    icon: takeValue(file.readLine().strip())
  )
  result = dir

proc parseConfig(str: string): void =
  let s = str.split(":")
  let config = s[0]
  let value = s[1]
  case config:
    of "no match command":
      noMatchCommand = value.strip()
    of "iterate over PATH":
      iterateOverPATH = value.strip().parseBool

proc readConfig*(): seq[Directory] =
  var directories: seq[Directory]
  let configFolder = os.getEnv("XDG_CONFIG_HOME")
  let configFile = configFolder & "/rofi-spotlight/config.yaml"
  let file = configFile.open()
  while not file.endOfFile:
    let line = file.readLine()
    if line.contains("directory:"):
      directories.add(readDirectory(file))
    else:
      parseConfig(line)

  result = directories
