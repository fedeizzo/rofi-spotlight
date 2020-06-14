import yaml/serialization, streams
import os

type
  Directory* = object
    name: string
    path*: string
    pattern*: string
    recursive*: bool
    program*: string
    icon*:string

proc readConfig*(): seq[Directory] =
  var directoryList: seq[Directory]
  let configFolder = os.getEnv("XDG_CONFIG_HOME")
  var s = newFileStream(configFolder & "/rofi-spotlight/config.yaml")
  load(s, directoryList)
  s.close()
  result = directoryList
