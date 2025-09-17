
# AutoHotkey-Tracer - v1.0.1

An AutoHotkey (AHK) class that simplifies sending structured output via OutputDebug and logging to file.

# Introduction

`Tracer` leverages the built-in `Error` class to greatly simplify the process of tracking code execution,
writing details to `OutputDebug`, and writing details to log file. `Tracer` makes it easy to customize
the output text, both with respect to what information is included, and its format.

**Note:** In this documentation, an instance of `Tracer` is called "a `Tracer` object" or `TracerObj`,
an instance of `TracerGroup` is called "a `TracerGroup` object" or `TracerGroupObj`, etc.

# Dependencies

`Tracer` has one required dependency and two optional dependencies.

1. [`FormatStr`](https://github.com/Nich-Cebolla/AutoHotkey-FormatStr) is always required.
2. [`StringifyAll`](https://github.com/Nich-Cebolla/AutoHotkey-StringifyAll) is required if you intend
to use the "Snapshot" functionality (serializing an object to record its properties and items along
with the output). `StringifyAll` itself is dependant on
[`Inheritance`](https://github.com/Nich-Cebolla/AutoHotkey-LibV2/tree/main/inheritance).

# How it works - general logging

`Tracer` is great for general logging to file. It has built-in json support if you use json, or you
can define your own custom format string which allows you to include only the information important
to your poject in the log output.

First you define your options object, then pass it to `Tracer`. Whenever your code needs to log
something to file, it simply calls `TracerObj.Log()`, and `Tracer` handles the rest.

## Tracer.Prototype.Log

`Tracer.Prototype.Log` has four optional parameters.

1. { String } [ `Message = ""` ] - A message string to include in the output.
2. { * } [ `SnapshotObj` ] - An object to have its properties and items serialized and included in the output.
3. { String } [ `Extra = ""` ] - A string with extra information to include in the output separate from `Message`.
4. { String | Number } [ `What` ] - A value to pass to the `What` parameter of `Error.Call`. The default value is `-1`
which typically produces the intended result. The option `Options.DefaultWhat` specifies the default value that
is used when you do not pass a value to `What`. Passing a value to `What` supercedes that default.

**Returns:** { TracerUnit }

# How it works - debugging

`Tracer` shines when used for debugging. By leveraging the features of the `Error` object, `Tracer`
makes it extremely easy to track code execution.

First you define your options object then pass it to `TracerGroup`. The `TracerGroup` object must be
accessible from each subsystem which you intend to investigate, so using a global variable is an
effective choice.

You also will define the starting point(s) at which your code calls `TracerGroupObj.Call` to
instantiate a `Tracer` object.

You also will include `TracerObj.Log()` calls at locations where you want to output information to log,
and/or `TracerObj.Out()` calls at locations where you want to output information to `OutputDebug`.
These two methods use separate formatting options so you can tailor your output for the medium.

Use the "Snapshot" functionality to record state information. `StringifyAll` is exceptional at
enabling your code to programmatically restrict what information gets included when serializing
an object.

# Options

# Defining the format string

`Tracer` uses [`FormatStr`](https://github.com/Nich-Cebolla/AutoHotkey-FormatStr) for its text formatting
logic. If you plan to customize the format of the output text, you will want to review the `FormatStr`
documentation.

The format string used by `Tracer.Prototype.Log` (which writes to log file) and `Tracer.Prototype.Out`
(which writes to `OutputDebug`) use separate format strings. The relevant options are
`Options.Log.Format` and `Options.Out.Format`.

## Format specifiers

A "format specifier" is a keyword enclosed by percent symbols that will be replaced by some data associated
with the keyword. You can use format specifiers to specify what information you want included in the
output text.

The following are the format specifiers used by `Tracer`:

- **ext**: The file extension.
- **extra**: The string your code passed to the "Extra" parameter of `Tracer.Prototype.Log` or `Tracer.Prototype.Out`.
- **id**: The id associated with the `Tracer` instance paired with the unit id. Gets replaced with one of the following:
  - If property `Options.TracerGroup.GroupName` returns an empty string - `TracerObj.Id` ":" `TracerUnitObj.UnitId`
  - If property `Options.TracerGroup.GroupName` does not return an empty string - `Options.TracerGroup.GroupName` ":" `TracerObj.Id` ":" `TracerUnitObj.UnitId`
- **file**: The file path returned by the error object's "File" property.
- **filename**: The file name with extension.
- **filenamenoext**: The file name without extension.
- **le**: The value set to `Options.LineEnding`.
- **line**: The line number returned by the error object's "Line" property.
- **message**: The string your code passed to the "Message" parameter of `Tracer.Prototype.Log` or `Tracer.Prototype.Out`.
- **nicetime**: The formatted timestamp.
- **snapshot**: The json string returned by `TracerUnit.Prototype.GetSnapshot` using the object passed to the "SnapshotObj" parameter of `Tracer.Prototype.Log` or `Tracer.Prototype.Out`.
- **stack**: The string returned by the error object's "Stack" property.
- **time**: The timestamp as it was returned by `A_Now`
- **what**: The string returned by the error object's "What" property. Depending on how you structure your code, you may need to adjust this from the default to get the correct function name. See [`Error`](https://www.autohotkey.com/docs/v2/lib/Error.htm).

For example:

```
formatString := (
    'Message: %message%`n'
    'File: %file%::%line%`n'
    'Time: %nicetime%`n'
    'What: %what%`n'
    'Tracer id: %id%`n'
)
```

## Conditional groups

A conditional group is a segment of text that is only included in the output if one or more of the
format specifiers within the group is replaced with one or more characters. Said in another way, if
all of the format specifiers within the group are replaced with an emtpy string, then none of the
text in the conditional group is included in the output.

To define a conditional group, enclose the segment in a pair of curly braces. See the documentation
for [`FormatStr`](https://github.com/Nich-Cebolla/AutoHotkey-FormatStr) for further details.

For example:

```
formatString := (
    "Message: %message%`n"
    "File: %file%::%line%`n"
    "Time: %nicetime%`n"
    "{What: %what%`n}"      ; Conditional group
    "{Extra: %extra%`n}"    ; Conditional group
    "Tracer id: %id%`n"
)
```

If "%what%" or "%extra%" are replaced with an empty string, then their respective lines are excluded
from the output text completely.

## Format specifier codes

A format specifier code is a string appended to the end of a format specifier with a colon separating
the two. The format specifier code directs `FormatStr` to call a function associated with the
code, typically to modify the text that was returned by `Options.Callback`.

The following are the format specifier codes used by `Tracer`:

- **json**: Directs `FormatStr` to call `Tracer_FormatStr_EscapeJson`, a function which replaces
substrings with their mandatory escape sequences for inclusion within a json string.
- **-json**: Directs `FormatStr` to call `Tracer_FormatStr_UnEscapeJson`, a function which replaces
json escape sequences with their counterpart.

For example, we can format text as json with this format string:

```
formatString := (
    '\{`n'
    '    {"Message": "%message:json%"`n}'
    '    {"What": "%what:json%"`n}'
    '    {"File": "%filename:json%"`n}'
    '    "Line": %line%`n'
    '    {"Extra": "%extra:json%"`n}'
    '    "Time": %time%`n'
    '\}`n'
)
```

## Further customization

`FormatStr` is a library intended to allow the user to define their own text formatting logic using
a system of format strings and callback functions. It is infinitely customizable. `Tracer` provides
basic functionality, but you can expand on this by setting up your own implementation and setting
`Options.FormatStrOptions` with the options object.

# Output json

Writing to log as json is useful when we intend to analyze the output programmatically at a later
time. To direct `Tracer.Prototype.Log` or `Tracer.Prototype.Out` to format as json, set the
relevant option: `Options.Log.ToJson` / `Options.Out.ToJson`.

To specify which properties you want included in the json string, set `Options.Log.JsonProperties`/
`Options.Out.JsonProperties` with an array of strings where each string is one of the
format specifier codes that you want included.

# History

Both `Tracer` and `TracerGroup` have history functionality.

## History - TracerGroup

The `TracerGroup` object's history is an array of `Tracer` objects that were instantiated from a call
to `TracerGroup.Prototype.Call`.

Related options:
  - `Options.TracerGroup.HistoryActive`
  - `Options.TracerGroup.HistoryMaxItems`
  - `Options.TracerGroup.HistoryReleaseRatio`

## History - Tracer

The `Tracer` object's history is an array of `TracerUnit` objects that were instantiate from a
call to `Tracer.Prototype.Log` or `Tracer.Prototype.Out`.

Related options:
  - `Options.Tracer.HistoryActive`
  - `Options.Tracer.HistoryMaxItems`
  - `Options.Tracer.HistoryReleaseRatio`

# Snapshot

Any time you call `Tracer.Prototype.Log` or `Tracer.Prototype.Out` you can pass an object to the
second parameter to have its properties and items serialized and included in the text. This requires
`StringifyAll` to be loaded into the script.

You can fine-tune what gets included in the snapshot with `StringifyAll`'s many options. See
[the documentation](https://github.com/Nich-Cebolla/StringifyAll) for details.

# Customizing the file path

`Tracer` constructs the file path as:

```
if Options.LogFile.Ext {
    path := Options.LogFile.Dir "\" Options.LogFile.Name "-" TracerLogFileObj.Index "." Options.LogFile.Ext
} else {
    path := Options.LogFile.Dir "\" Options.LogFile.Name "-" TracerLogFileObj.Index
}
```

Whenever the file path is needed, the function calls `TracerLogFileObj.GetPath`, which is an own property
on the `TracerLogFile` object. You can overwrite this method directly with your own custom logic.

If you want it to apply to all instances of `TracerLogFile`, you must overwrite `TracerLogFile.Prototype.__GetPath`
and `TracerLogFile.Prototype.__GetPathNoExt`.

If you change `TracerLogFileObj.GetPath`, you will likely need to set `Options.LogFile.FileIndexPattern`
and `Options.LogFile.FilePattern`.

`Options.LogFile.FilePattern` is used to count the files in the directory to determine if files need
to be deleted.

If `Options.LogFile.FileIndexPattern` does not correctly capture the index in the file name,
`TracerLogFile.Prototype.GetFiles` will throw an error. `TracerLogFile.Prototype.GetFiles` is called
from `TracerLogFile.Prototype.__New`, so it is an effective requirement that
`Options.LogFile.FileIndexPattern` matches, or you can disable the functionality by setting
`Options.LogFile.FileIndexPattern := -1`. Disabling this functionality causes
`TracerLogFile.Prototype.Open` to always open a new file.

# Opening the log file

Depending on the value of parameter `FileAction`, the process of opening the log file is intended
to allow the use of one log file across multiple sessions by validating the most recent file and
reopening it if appropriate. The "most recent file" is considered to be the file with the greatest
index in the file name, as evaluated within `TracerLogFile.Prototype.GetFiles` using
`Options.LogFile.FileIndexPattern`. See above section "Customizing the file path".

If all of the following are true, then the most recent file is opened and used:
- If the file begins and ends with open and close square brackets
- If the value of `Options.Log.ToJson` is true
- If the size of the file is less than `Options.LogFile.MaxSizeand

Or, if all of the following are true, then the most recent file is opened and used:
- If the file does not begin with or end with open and close square brackets
- If the value of `Options.Log.ToJson` is false
- If the size of the file is less than `Options.LogFile.MaxSize

# Changelog

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
- Added global variable `Tracer_Flag_OnExitStarted`.
- Changed `TracerUnit.Prototype.Log` - it now adds an extra line break to the end of the file.
- Changed `TracerLogFile.Prototype.SetEncoding` - it now creates two additional own properties:
  - `TracerLogFileObj.LineEndByteCount` - the number of bytes of `Options.Tracer.LineEnding`.
  - `TracerLogFileObj.EndByteCount` - the sum of `TracerLogFileObj.BracketByteCount + TracerLogFileObj.LineEndByteCount * 2`.
- Changed how logging to json is handled. Now, the json array is always closed when `Tracer.Prototype.Log`
writes to the file. With each new addition to the array, the file pointer is moved back to overwrite
the close brace and line end characters.
- Changed `TracerLogFileObj.NewLogFile` to `TracerLogFileObj.flag_newLogFile`.
- Removed `TracerOptionsInheritor`.
- Removed `TracerOptionsBase`.
- Removed `TracerOptions.Prototype.GetInheritor`.
- Removed `TracerToolsBase`.
- Removed `TracerToolsInheritor`.
- Fixed `TracerLogFile.Prototype.SetEncoding` - previously, the value set to property
`TracerLogFileObj.BracketByteCount` was incorrect; this has been fixed.
- Fixed `Tracer.Prototype.OwnOptions` and `TracerGroup.Prototype.OwnOptions` (they were supposed
to exist but did not. Now they exist).
