import os
import hashes
from osproc import startProcess, execProcess
import parseopt
import tables
from strutils import replace

proc printErr(msg: string): void =
  stderr.write("error\n\t" & msg & "\n")

proc helpMsg(): void =
  stdout.write("usage: rofi-terminal <direcory> --pattern:<pattern> ...\n")

proc findSubDirs(dir: string, pattern: var string, patterns: var Table[string,
    string]): seq[string] =
  for kind, path in dir.walkDir:
    if kind == pcDir:
      result.add(findSubDirs(path, pattern, patterns))
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

proc findFiles(dir, pattern: string): (Table[string, string], Table[string,
    string], seq[string]) =
  var
    filesToDir = initTable[string, string]()
    filesToExt = initTable[string, string]()
    files: seq[string]

  setCurrentDir(dir)
  if pattern != "":
    for f in pattern.walkFiles:
      let name = f.splitFile.name
      let ext = f.splitFile.ext
      filesToDir.add(name, dir)
      filesToExt.add(name, ext)
      files.add(name)
  else:
    for f in "*".walkDirs:
      let name = f.splitFile.name
      let ext = f.splitFile.ext
      filesToDir.add(name, dir)
      filesToExt.add(name, ext)
      files.add(name)

  result = (filesToDir, filesToExt, files)


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


when isMainModule:
  if paramCount() == 0:
    printErr("insert at least one folder and pattern")
    helpMsg()
    quit 2

  let parsedOpt = parseOption()
  var
    dirs = parsedOpt[0]
    files: seq[string]
    patterns = parsedOpt[1]
    filesToDir = initTable[string, string]()
    filesToExt = initTable[string, string]()

  var tmpDirs: seq[string]
  for d in dirs:
    tmpDirs = tmpDirs & findSubDirs(d, patterns[d], patterns)
  dirs = dirs & tmpDirs

  for d in dirs:
    var tmp = findFiles(d, patterns[d])
    mergeTables(filesToDir, tmp[0])
    mergeTables(filesToExt, tmp[1])
    files = files & tmp[2]

  var filesString: string
  for f in files:
    filesString = filesString & f & "\n"

  var rofiOutput = execProcess("echo \"" & filesString & "\" | rofi -dmenu")
  rofiOutput = replace(rofiOutput, "\n", "")


  if rofiOutput == "":
    quit 0

  var
    cmd: string
    path: string

  if filesToExt[rofiOutput] == ".pdf":
    cmd = "zathura "
    path = filesToDir[rofiOutput] & "/" & rofiOutput & filesToExt[rofiOutput] & "&"
    discard execShellCmd(cmd & path)
  elif filesToExt[rofiOutput] == "":
    cmd = "alacritty --working-directory "
    path = filesToDir[rofiOutput] & "/" & "&"

    discard execShellCmd(cmd & path)

  quit 0
