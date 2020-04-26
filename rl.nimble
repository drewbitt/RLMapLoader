# Package

version       = "0.1.0"
author        = "drewbitt"
description   = "RL Map Loader"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["main"]


# Dependencies

requires "nim >= 1.0.2", "wNim >= 0.11.0, winregistry >= 0.2.1, regex >=0.14.1"
