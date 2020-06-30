import os
import strutils

var noMatchCommand* = "echo"

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
    name: takeValue(file.readLine()),
    path: takeValue(file.readLine()),
    pattern: takeValue(file.readLine()),
    recursive: takeValue(file.readLine()).parseBool,
    program: takeValue(file.readLine()),
    icon: takeValue(file.readLine())
  )
  result = dir

proc parseConfig(str: string): void =
  let s = str.split(":")
  let config = s[0]
  let value = s[1]
  case config:
    of "no match command":
      noMatchCommand = value

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
