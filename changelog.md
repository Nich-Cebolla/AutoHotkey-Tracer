
**2025-09-27**: v1.0.2
- Added parameter `IdValue` to `Tracer_GetId`, `TracerGroup.Prototype.Call`, `Tracer.Prototype.Log`, and `Tracer.Prototype.Out`.
- Changed `Tracer_GetId` to handle the new parameter.
- Changed how `TracerGroup.Prototype.__New` and `Tracer.Prototype.__New` handles the options. It is
now no longer required to get an instance of `TracerOptions`. If `TracerGroup.Prototype.__New` or
`Tracer.Prototype.__New` are called passing a regular object to `Options`, the object is passed
to `TracerOptions.Prototype.__New`.
- Removed global variable `Tracer_Flag_OnExitStarted` (it was no longer in use).

**2025-09-16**: v1.0.1
- Added `Options.Log.Critical`.
- Added `Options.LogFile.Critical`.
- Added `Options.LogFile.FileIndexPattern`.
- Added `Options.LogFile.FilePattern`.
- Added `Options.Out.Critical`.
- Added `Tracer.Prototype.Open`, `Tracer.Prototype.Close`, `TracerTools.Prototype.Open`, and `TracerTools.Prototype.Close`.
- Added `TracerLogFile.Prototype.StandardizeEnding`.
- Added parameter `FileAction` to `TracerGroup.Prototype.__New`, `Tracer.Prototype.__New`, `TracerTools.Prototype.__New`.
- Added parameter `NewFile` to `TracerLogFile.Prototype.__New`.
- Changed `TracerUnit.Prototype.Log` - it now adds an extra line break to the end of the file.
- Changed `TracerLogFile.Prototype.SetEncoding` - it now creates two additional own properties:
  - `TracerLogFileObj.LineEndByteCount` - the number of bytes of `Options.Tracer.LineEnding`.
  - `TracerLogFileObj.EndByteCount` - the sum of `TracerLogFileObj.BracketByteCount + TracerLogFileObj.LineEndByteCount * 2`.
- Changed how logging to json is handled. Now, the json array is always closed when `Tracer.Prototype.Log`
writes to the file. With each new addition to the array, the file pointer is moved back to overwrite
the close brace and line end characters.
- Changed `TracerLogFileObj.NewLogFile` to `TracerLogFileObj.flag_newLogFile`.
- Removed `TracerLogFileObj.flag__onExitStarted`. The logic which it supported is no longer used.
- Removed `TracerOptionsInheritor`.
- Removed `TracerOptionsBase`.
- Removed `TracerOptions.Prototype.GetInheritor`.
- Fixed `TracerLogFile.Prototype.SetEncoding` - previously, the value set to property
`TracerLogFileObj.BracketByteCount` was incorrect; this has been fixed.
- Fixed `Tracer.Prototype.OwnOptions` and `TracerGroup.Prototype.OwnOptions` (they were supposed
to exist but did not. Now they exist).
