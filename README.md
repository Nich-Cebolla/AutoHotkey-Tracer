
# AutoHotkey-Tracer

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
  - If property `TracerObj.GroupName` returns an empty string - `TracerObj.Id` ":" `TracerUnitObj.Id`
  - If property `TracerObj.GroupName` does not return an empty string - `TracerObj.GroupName` ":" `TracerObj.Id` ":" `TracerUnitObj.Id`
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
