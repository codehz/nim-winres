Nim windows resource generator
==============================

Generate windows res file with nim syntax.

Example:

```nim
import winres/[helper, version_code]

let version = parseVersionCode("0.1.2.0")

output(fmt"target.res"):
  RT_VERSION(1, 1033, 1200, FixedVersionInfo(file: version, product: version, kind: ftDll)) do:
    # \StringFileInfo\XXXXXXXX\
    FileDescription := "awesome nim project"
    FileVersion := $version
    ProductVersion := $version
  do:
    # \VarFileInfo\
    # "Translation" value is automatically generated
    AnyCustomKey := "custom data"
    AnotherCustomKey := [1, 2, 3, 4]

  RT_MANIFEST 1, 1033, """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    </windowsSettings>
  </application>
</assembly>
  """
```

Currently only support RT_VERSION, RT_ICON and RT_MANIFEST
