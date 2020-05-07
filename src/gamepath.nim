import winregistry, strutils, regex, sequtils, os

let rocketLeagueGameID = 252950

proc checkGameInLibraries(paths: seq[string], gameId: int): string =
    for path in paths:
        let manifestPath = joinPath(path, "steamapps", "appmanifest_" & $gameId & ".acf")
        if existsFile manifestPath:
            return manifestPath

proc parseLibraries(vdf: seq[TaintedString]): seq[string] =
    var re: Regex
    re = re"^(""(?P<qkey>(?:\\.|[^\\""])+)""|(?P<key>#?[a-z0-9\-\_\\\?]+))([ \t]*(""(?P<qval>(?:\\.|[^\\""])*)(?P<vq_end>"")?|(?P<val>[a-z0-9\-\_\\\?\*\.]+)))?"

    var libraries: seq[string]
    for line in vdf:
        let newLine = line.strip(trailing=false)
        var m: RegexMatch
        if newLine.match(re, m):
            try:
                # format is like "1"		"D:\\SteamLibrary", "2"		"E:\\SteamLibrary" etc.
                discard parseFloat m.group("qkey", newLine)[0]
                let libraryPath = m.group("qval", newLine)[0]
                libraries.add(libraryPath.replace("\\\\", "\\"))
            except:
                discard
    return libraries

proc getLibraries(steamInstallDir: string): seq[string] =
    let libraryFoldersPath = joinPath(steamInstallDir, "steamapps", "libraryfolders.vdf")
    if libraryFoldersPath.existsFile:
        try:
            # let libraryFolders = readLines(libraryfoldersPath)
            let parsed = parseLibraries(toSeq libraryFoldersPath.lines)
            return parsed
        except:
            echo "Could not parse libraries"
            return

proc getGamePath(): string =
    var steamInstallDir: string
    try:
        let steamKey = open("HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Valve\\Steam", samRead)
        steamInstallDir = steamKey.readString("InstallPath")
    except RegistryError:
        echo "err: ", getCurrentExceptionMsg()

    if steamInstallDir.isEmptyOrWhitespace:
        echo "Did not find steam installation"
        return

    var libraryDirs = getLibraries(steamInstallDir)

    if libraryDirs.len == 0:
        # return steamInstallDir and no game?
        return

    # add main steam since not in libraryfolders
    libraryDirs.add(joinPath(steamInstallDir, "steamapps"))

    let manifest = checkGameInLibraries(libraryDirs, rocketLeagueGameID)

    if manifest.isEmptyOrWhitespace:
        # return steamInstallDir and no game?
        return

    # Confirmed installed via manifest check

    let finalPath = joinPath((splitPath manifest).head, "common", "rocketleague", "TAGame", "CookedPCConsole")

    if existsDir finalPath:
        return finalPath
    else:
        # what to return?
        echo "Game path does not exist"
        return

type ModsDirResult* = object
    path*: string
    createdModFolder*: bool

proc getModsDir*(): ModsDirResult =
    let gamePath = getGamePath()
    if not gamePath.isEmptyOrWhitespace:
        let modsPath = joinPath(gamePath, "mods")

        if existsOrCreateDir(modsPath):
            return ModsDirResult(path: modsPath, createdModFolder: false)
        else:
            return ModsDirResult(path: modsPath, createdModFolder: true)
    else:
        return

proc copyFiles*(modsDir: string, files: seq[string]): bool =
    for file in files:
        var fileSplit = splitFile file
        var newFile = fileSplit.name & fileSplit.ext
        if fileSplit.ext == ".udk":
            newFile = fileSplit.name & ".upk"

        let modsDirFileName = joinPath(modsDir, newFile)
        try:
            copyFile(file, modsDirFileName)
            return true
        except:
            let
                e = getCurrentException()
                msg = getCurrentExceptionMsg()
            echo "Got exception ", repr(e), " with message ", msg
