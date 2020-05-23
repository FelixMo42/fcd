import os
import strutils
import illwill
import sequtils

proc exitProc() {.noconv.} =
    illwillDeinit()
    showCursor()
    quit(0)

var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

var search     = ""
var selected   = 0
var folderPath = normalizedPath(absolutePath("."))
var nameSize   = 40

proc numFilesInDir(path: string): int =
    if not existsDir(path):
        return 1
    else:
        var i = 0

        for _ in walkDir(path, relative=true).toSeq:
            inc i

        return i
  
proc drawFiles(path: string) =
    tb.write(2, 1, resetStyle, " ".repeat(nameSize))
    tb.write(2, 1, fgGreen, path, "/", fgWhite, search)

    for i in 1..100:
        tb.write(2, 3 + i, " ".repeat(nameSize))

    if not existsDir(path):
        tb.write(2, 3, resetStyle, "empty")
    else:
        for i, foundPath in walkDir(path, relative=true).toSeq:
            tb.write(2, 3 + i, resetStyle, " ".repeat(nameSize))
            
            var name = foundPath.path & " ".repeat(nameSize - foundPath.path.len)

            if i == selected:
                tb.write(2, 3 + i, resetStyle, fgBlack, bgCyan, name)
            else:
                tb.write(2, 3 + i, resetStyle, name)

func modIndex(i: int, max: int): int =
    if i >= 0:
        return i mod max
    else:
        return modIndex(max + i, max)

proc getSelectedFile(path: string, selected: int): string =
    if existsDir(path):
        for i, foundPath in walkDir(path, relative=true).toSeq:
            if i == selected:
                return foundPath.path
    
    return ""

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()

drawFiles(folderPath)

while true:
    var key = getKey()
    
    case key
    of Key.None: discard
    of Key.Escape, Key.Enter:
        exitProc()
    of Key.Up:
        selected = modIndex(selected - 1, numFilesInDir(folderPath))
    of Key.Down:
        selected = modIndex(selected + 1, numFilesInDir(folderpath))
    of Key.Left:
        folderPath = parentDir(folderPath)
    of Key.Right:
        folderPath &= "/" & getSelectedFile(folderPath, selected)
    of Key.Delete, Key.Backspace:
        if search.len > 0:
            search = search[.. ^2]
    else:
        search &= (char) key
    
    drawFiles(folderPath)

    tb.display()
    sleep(20)
