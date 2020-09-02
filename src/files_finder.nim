import os
import tables
from config_parser import Directory, readConfig, noMatchCommand

proc mergeTables[T](t1, t2: var Table[T, T]): void =
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

proc getFiles*(files: var seq[string], filesToDir: var Table[string, string], dirsToIcon: var Table[string, string], patterns: var Table[string, string], filesToProgram: var Table[string, string]): void  =
  var conf = readConfig()
  var
    dirs: seq[string]
    dirsToProgram = initTable[string, string]()
    isRecursive: seq[bool]

  for c in conf:
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
