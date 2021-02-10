import ./version_code

type
  ResourceKind* = enum
    resCursor = 1
    resBitmap = 2
    resIcon = 3
    resMenu = 4
    resDialog = 5
    resString = 6
    resFontDir = 7
    resFont = 8
    resAccelerator = 9
    resRawData = 10
    resMessageTable = 11
    resGroupCursor = 12
    resGroupIcon = 14
    resVersion = 16
    resDlgInclude = 17
    resPlugPlay = 19
    resVXD = 20
    resAnimatedCursor = 21
    resAnimatedIcon = 22
    resHTML = 23
    resManifest = 24
  UnicodeOrId* = object
    case isStr*: bool
    of true: str*: string
    of false: id*: uint16
  Resource* = object
    kind*: UnicodeOrId
    name*: UnicodeOrId
    lang*: uint16
  ResourceRecall* = object
    offset*: int
    header*: int
  FileFlag* = enum
    ffDebug = "debug"
    ffPrerelease = "prerelease"
    ffPatched = "patched"
    ffPrivateBuild = "private"
    ffInfoInferred = "inferred"
    ffSpecialBuild = "special"
  FileKind* = enum
    ftUnknown = 0
    ftApp = 1
    ftDll = 2
    ftStaticLib = 7
  FixedVersionInfo* = object
    file*, product*: VersionCode
    flags*: set[FileFlag]
    kind*: FileKind
    date*: uint64
  BlockKind* = enum
    blkBinary = 0
    blkText = 1
  Block* = object
    name*: string
    kind*: BlockKind
  BlockRecall* = object
    offset*: int
    header*: int
    istext*: bool

converter toUnicodeOrId*(res: ResourceKind): UnicodeOrId = UnicodeOrId(isStr: false, id: cast[uint16](res))
converter toUnicodeOrId*(id: uint16): UnicodeOrId = UnicodeOrId(isStr: false, id: id)
converter toUnicodeOrId*(str: string): UnicodeOrId = UnicodeOrId(isStr: true, str: str)
