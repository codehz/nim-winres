import std/streams
import ./types, ./version_code

type
  Encoder* = object
    stream: Stream

proc init*(_: type Encoder; stream: sink Stream): Encoder =
  result.stream = stream

proc fixPadding*(self: Encoder) {.inline.} =
  let pos = self.stream.getPosition()
  let dif = pos mod 4
  if dif != 0:
    for it in 0..<(4 - dif):
      self.stream.write(uint8 0)

proc writeRaw*(self: Encoder; data: pointer; size: int) {.inline.} =
  self.stream.writeData(data, size)
proc writeRaw*(self: Encoder; data: string) {.inline.} =
  self.stream.write(data)

proc encode*(self: Encoder; val: uint64 | uint32 | uint16 | uint8) {.inline.} =
  self.stream.write(val)

proc encode*(self: Encoder; val: string, fix: bool = true) {.inline.} =
  let wstr = newWideCString(val)
  let alen = wstr.len + 1
  for i in 0..<alen:
    self.encode(uint16 wstr[i])
  if fix:
    self.fixPadding()

proc encode*(self: Encoder; val: UnicodeOrId) {.inline.} =
  if val.isStr:
    self.encode(val.str)
  else:
    self.encode(uint16 0xFFFF)
    self.encode(val.id)

proc encodeResource*(self: Encoder; val: Resource): ResourceRecall {.inline.} =
  result.offset = self.stream.getPosition()
  self.encode(uint32 0) # DataSize
  self.encode(uint32 0) # HeaderSize
  self.encode(val.kind) # Type
  self.encode(val.name) # Name
  self.encode(uint32 0) # DataVersion (ignored)
  self.encode(uint16 0) # MemoryFlags (ignored)
  self.encode(val.lang) # LanguageId
  self.encode(uint32 0) # Version (ignored)
  self.encode(uint32 0) # Characteristics (ignored)
  result.header = self.stream.getPosition()
  let hl = result.header - result.offset
  self.stream.setPosition(result.offset + 4)
  self.encode(uint32 hl)
  self.stream.setPosition(result.header)

proc encodeBlock*(self: Encoder; val: Block): BlockRecall {.inline.} =
  result.offset = self.stream.getPosition()
  self.encode(uint16 0) # Length
  self.encode(uint16 0) # ValueLength
  self.encode(uint16 val.kind) # Type
  self.encode(val.name) # Key
  result.istext = val.kind == blkText
  result.header = self.stream.getPosition()

proc fixupValueLength*(self: Encoder; recall: BlockRecall) {.inline.} =
  let tmp = self.stream.getPosition()
  let len = tmp - recall.header
  self.stream.setPosition(recall.offset + 2)
  if recall.istext:
    self.encode(uint16 len div 2)
  else:
    self.encode(uint16 len)
  self.stream.setPosition(tmp)
  self.fixPadding()

proc fixupLength*(self: Encoder; recall: BlockRecall) {.inline.} =
  let tmp = self.stream.getPosition()
  let len = tmp - recall.offset
  self.stream.setPosition(recall.offset)
  self.encode(uint16 len)
  self.stream.setPosition(tmp)
  self.fixPadding()

proc fixupLength*(self: Encoder; recall: ResourceRecall) {.inline.} =
  let tmp = self.stream.getPosition()
  let len = tmp - recall.header
  self.stream.setPosition(recall.offset)
  self.encode(uint32 len)
  self.stream.setPosition(tmp)
  self.fixPadding()

proc encodeKeyValue*(self: Encoder; key: string; list: varargs[string]) {.inline.} =
  let kv = self.encodeBlock(Block(name: key, kind: blkText))
  for item in list:
    self.encode(item, false)
  self.fixupValueLength(kv)
  self.fixPadding()
  self.fixupLength(kv)

proc encodeKeyValue*(self: Encoder; key: string; list: varargs[uint16]) {.inline.} =
  let kv = self.encodeBlock(Block(name: key, kind: blkBinary))
  for item in list:
    self.encode(item)
  self.fixupValueLength(kv)
  self.fixupLength(kv)

proc encodeVersionInfo*(self: Encoder): BlockRecall {.inline.} =
  self.encodeBlock(Block(name: "VS_VERSION_INFO", kind: blkBinary))

proc encode*(self: Encoder; val: VersionCode) {.inline.} =
  self.encode(val.minor)
  self.encode(val.major)
  self.encode(val.build)
  self.encode(val.revision)

proc encode*(self: Encoder; val: FixedVersionInfo) {.inline.} =
  self.encode(uint32 0xFEEF04BD) # Signature
  self.encode(uint32 1 shl 16) # StruVersion
  self.encode(val.file) # FileVersion
  self.encode(val.product) # ProductVersion
  self.encode(uint32 0x3F) # FileFlagsMask
  self.encode(cast[uint32](val.flags)) # FileFlags
  self.encode(uint32 0) # OS
  self.encode(cast[uint32](val.kind)) # FileType
  self.encode(uint32 0) # SubType
  self.encode(val.date) # Date

