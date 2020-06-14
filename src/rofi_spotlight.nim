import os
from osproc import startProcess, execProcess
import parseopt
import tables
from strutils import replace
from config_parser import Directory, readConfig

proc printErr(msg: string): void =
  stderr.write("error\n\t" & msg & "\n")

proc helpMsg(): void =
  stdout.write("usage: rofi-terminal <direcory> --pattern:<pattern> ...\n")

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


proc parseOption(): (seq[string], Table[string, string]) =
  var
    lastDir: string
    dirs: seq[string]
    patterns = initTable[string, string]()
  var opt = initOptParser()

  for kind, key, val in opt.getopt:
    case opt.kind
    of cmdEnd: break
    of cmdShortOption:
      if opt.key == "p":
        patterns.add(lastDir, opt.val)
      elif opt.key == "d":
        dirs.add(opt.val)
        lastDir = opt.val
      else:
        printErr(opt.key & " is not an opt")
        helpMsg()
        quit 3
    of cmdLongOption:
      if opt.key == "pattern":
        patterns.add(lastDir, opt.val)
      elif opt.key == "directory":
        dirs.add(opt.val)
        lastDir = opt.val
      else:
        printErr(opt.key & " is not an opt")
        helpMsg()
        quit 3
    of cmdArgument:
      if not dirExists(opt.key):
        printErr(opt.key & " not argument allowed")
        helpMsg()
        quit 3

  if dirs.len != patterns.len:
    printErr("there must be a pattern for every folder")
    helpMsg()
    quit 4

  result = (dirs, patterns)

proc findFiles(dir, pattern: string, program: string): (Table[string, string], Table[string,
    string], seq[string]) =
  var
    filesToDir = initTable[string, string]()
    filesToExt = initTable[string, string]()
    files: seq[string]

  setCurrentDir(dir)
  if pattern != "":
    for f in pattern.walkFiles:
      # let name = f.splitFile.name
      # let ext = f.splitFile.ext
      let name = f
      filesToDir.add(name, dir)
      filesToExt.add(name, program)
      files.add(name)
  else:
    for f in "*".walkDirs:
      # let name = f.splitFile.name
      # let ext = f.splitFile.ext
      let name = f
      filesToDir.add(name, dir)
      filesToExt.add(name, program)
      files.add(name)

  result = (filesToDir, filesToExt, files)

when isMainModule:
  var config = readConfig()
  # if paramCount() == 0:
  #   printErr("insert at least one folder and pattern")
  #   helpMsg()
  #   quit 2

  # let parsedOpt = parseOption()
  # echo parsedOpt
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

  var rofiOutput = execProcess("echo \"" & filesString & "\" | rofi -dmenu")
  rofiOutput = replace(rofiOutput, "\n", "")
  var
    tmp: string
    flag = false
  for i in rofiOutput:
    if flag:
      tmp.add(i)

    if i == ' ':
      flag = true
  rofiOutput = tmp

  if rofiOutput == "":
    quit 0

  var
    cmd: string
    path: string

  cmd = filesToProgram[rofiOutput] & " "
  path = filesToDir[rofiOutput] & "/" & rofiOutput & "&"
  path = replace(path, " ", "\\ ")
  path = replace(path, " ", "\\ ")
  discard execShellCmd(cmd & path)
  # if filesToProgram[rofiOutput] == ".pdf":
  #   cmd = "zathura "
  #   path = filesToDir[rofiOutput] & "/" & rofiOutput & filesToProgram[rofiOutput] & "&"
  #   discard execShellCmd(cmd & path)
  # elif filesToProgram[rofiOutput] == "":
  #   cmd = "alacritty --working-directory "
  #   path = filesToDir[rofiOutput] & "/" & "&"

  #   discard execShellCmd(cmd & path)

  quit 0
