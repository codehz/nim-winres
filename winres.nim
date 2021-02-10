import std/[streams, strformat]
import winres/[encoder, types]
export FixedVersionInfo, FileFlag, FileKind

template output*(filename: string; body: untyped) =
  mixin init, encodeResource
  block:
    let enc {.inject.} = Encoder.init(openFileStream(filename, fmWrite))
    discard enc.encodeResource(Resource())
    body

func genLanguageCodeName(lang, code: uint16): string =
  fmt"{lang:04x}{code:04x}"

template injectKV*() =
  template `:=`(name: untyped; value: untyped) =
    enc.encodeKeyValue(astToStr name, value)

template RT_VERSION*(id, langname, code: static uint16; fixed: FixedVersionInfo; strbody, varbody: untyped) =
  mixin encodeResource, encode, toUnicodeOrId, encodeVersionInfo, fixupValueLength, encodeBlock
  let resr {.gensym.} = enc.encodeResource(Resource(
    kind: toUnicodeOrId resVersion,
    name: toUnicodeOrId id,
    lang: langname
  ))
  let vinf {.gensym.} = enc.encodeVersionInfo()
  enc.encode(fixed)
  enc.fixupValueLength(vinf)
  let strtable {.gensym.} = enc.encodeBlock(Block(name: "StringFileInfo", kind: blkText))
  let lngtable {.gensym.} = enc.encodeBlock(Block(name: genLanguageCodeName(langname, code), kind: blkText))
  block:
    injectKV()
    strbody
  enc.fixupLength(lngtable)
  enc.fixupLength(strtable)
  let vartable {.gensym.} = enc.encodeBlock(Block(name: "VarFileInfo", kind: blkText))
  enc.encodeKeyValue("Translation", langname, code)
  block:
    injectKV()
    varbody
  enc.fixupLength(vartable)
  enc.fixupLength(vinf)
  enc.fixupLength(resr)

template RT_MANIFEST*(id, langname: uint16; body: static string) =
  mixin encodeResource, writeRaw, fixupLength, toUnicodeOrId
  let resr {.gensym.} = enc.encodeResource(Resource(
    kind: toUnicodeOrId resManifest,
    name: toUnicodeOrId id,
    lang: langname
  ))
  enc.writeRaw(body)
  enc.fixupLength(resr)
