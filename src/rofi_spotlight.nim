import os
from osproc import startProcess, execProcess
import tables
from strutils import replace
from config_parser import Directory, readConfig, noMatchCommand

proc printSeq*[T](s: seq[T]): void =
  echo "sequence:"
  for i in s:
    echo "\t", i

proc printTable*[T](t: Table[T, T]): void =
  echo "table:"
  for k, v in t.pairs:
    echo "\t", k, " → ", v

proc mergeTables*[T](t1, t2: var Table[T, T]): void =
  for k, v in t2.pairs:
    t1.add(k, v)

proc findSubDirs(dir: string, pattern: string, patterns: var Table[string,
                 string], dirsToProgram: var Table[string, string],
                 dirsToIcon: var Table[string, string]): seq[string] =
  for kind, path in dir.walkDir:
    if kind == pcDir:
      dirsToProgram.add(path & pattern, dirsToProgram[dir & pattern])
      dirsToIcon.add(path & pattern, dirsToIcon[dir & pattern])
      result.add(findSubDirs(path, pattern, patterns, dirsToProgram, dirsToIcon))
      patterns.add(path, pattern)
      result.add(path)

proc findFiles(dir, pattern: string, program: string): (Table[string, string], Table[string,
    string], seq[string]) =
  var
    filesToDir = initTable[string, string]()
    filesToExt = initTable[string, string]()
    files: seq[string]

  setCurrentDir(dir)
  if pattern != "":
    for f in pattern.walkFiles:
      let name = f
      filesToDir.add(name, dir)
      filesToExt.add(name, program)
      files.add(name)
  else:
    for f in "*".walkDirs:
      let name = f
      filesToDir.add(name, dir)
      filesToExt.add(name, program)
      files.add(name)

  result = (filesToDir, filesToExt, files)

when isMainModule:
  var config = readConfig()
  var
    dirs: seq[string]
    files: seq[string]
    patterns = initTable[string, string]()
    filesToDir = initTable[string, string]()
    dirsToProgram = initTable[string, string]()
    filesToProgram = initTable[string, string]()
    dirsToIcon = initTable[string, string]()
    isRecursive: seq[bool]

  for c in config:
    dirs.insert(c.path)
    patterns.add(c.path, c.pattern)
    dirsToProgram.add(c.path & c.pattern, c.program)
    dirsToIcon.add(c.path & c.pattern, c.icon)
    isRecursive.insert(c.recursive)

  var
    tmpDirs: seq[string]
    index = 0
  for d in dirs:
    if isRecursive[index]:
      tmpDirs = tmpDirs & findSubDirs(d, patterns[d], patterns, dirsToProgram, dirsToIcon)
  dirs = dirs & tmpDirs

  for d in dirs:
    var tmp = findFiles(d, patterns[d], dirsToProgram[d & patterns[d]])
    mergeTables(filesToDir, tmp[0])
    mergeTables(filesToProgram, tmp[1])
    files = files & tmp[2]


  var filesString: string
  for f in files:
    let dir = filesToDir[f]
    let icon = dirsToIcon[dir & patterns[dir]]
    filesString = filesString & icon & " " & f & "\n"

  var rofiOutput = execProcess("echo \"" & filesString & "\" | rofi -dmenu -p \"\"")
  rofiOutput = replace(rofiOutput, "\n", "")
  var
    flag = 0
    parsedOutput: string

  for i in rofiOutput:
    if flag > 0:
      parsedOutput.add(i)

    if i == ' ':
      flag += 1

  if rofiOutput == "":
    quit 0

  var
    cmd: string
    path: string

  try:
    cmd = filesToProgram[parsedOutput] & " "
    path = filesToDir[parsedOutput] & "/" & parsedOutput & "&"
    path = replace(path, " ", "\\ ")
    path = replace(path, " ", "\\ ")
    discard execShellCmd(cmd & path)
  except: 
    cmd = noMatchCommand & " \'" & rofiOutput & "\'"
    discard execShellCmd(cmd)

  quit 0
