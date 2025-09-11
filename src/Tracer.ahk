
; https://github.com/Nich-Cebolla/AutoHotkey-StringifyAll
; This is only necessary if your application will use Tracer to serialize object properties /
; items when writing to log file.
#include *i <StringifyAll>

; This library is tested and is working, but usage is somewhat complex and I haven't written all
; of the documentation for it. Best to see "test\test-Tracer.ahk" for a usage example.


/**
 * Defines a `TracerGroup`, which is a set of customization options that are inherited by any
 * {@link Tracer} instances created by calling {@link TracerGroup.Prototype.Call}. The {@link TracerGroup}
 * instance will be your primary entrypoint for this library's functionality.
 *
 * To get the most use out of this library, each instance of {@link Tracer} should be constructed to
 * trace a specific sequence of actions. It can be passed around from function to function, or
 * referenced by a global variable, and each function should add some information to it. This process
 * should conclude at some point, and if appropriate for the usage scenario, the information evaluated.
 *
 * To minimize repeated code, {@link TracerGroup} exposes the various customization options
 * used by {@link Tracer}, allowing your code to set the options once and have them persist.
 *
 * Customization options can be set at the group level and at the individual level. When you create
 * an instance of `TracerGroup`, you pass an options object to the constructor, defining the default
 * options for instances of `Tracer` that you create by calling `TracerGroup.Prototype.Call`. Your
 * code can then change any of the customization options for that individual `Tracer` instance.
 * Options set at the individual level do not effect the other objects associated with the group.
 *
 * ## Usage
 *
 * 1. Create the `TracerGroup`, passing options to the only parameter. There is a template options
 * object in file "src\options-template.ahk".
 *
 * 2. Call {@link Tracer.Prototype.SetOutOptions}.
 *
 * This defines the options used when calling {@link Tracer.Prototype.Out}, which is the primary
 * method used to log information.
 *
 * 2. Call {@link Trace.OpenLogFile}.
 *
 *
 */
class TracerGroup {
    __New(Options?) {
        options := TracerGroup.Options(Options ?? unset)
        this.History := []
        this.HistoryActive := options.HistoryActive
        this.__HistoryMaxItems := options.HistoryMaxItems
        this.HistoryReleaseRatio := options.HistoryReleaseRatio
        this.IdCallback := options.IdCallback || ObjBindMethod(this, 'GetId')
        this.Index := 0
        this.Constructor := Class()
        this.Constructor.Base := Tracer
        this.Constructor.Prototype := {}
        ObjSetBase(this.Constructor.Prototype, Tracer.Prototype)
        if options.UseGroup {
            this.Constructor.Prototype.SetOptions(options.GroupOptions, options.GroupName || unset)
        }
    }
    Call(Id?) {
        if this.HistoryActive {
            this.History.Push(this.Constructor.Call(Id ?? this.IdCallback.Call()))
            if this.HistoryMaxItems > 0 && this.History.Length > this.HistoryMaxItems {
                this.History.RemoveAt(1, this.HistoryReleaseCount)
            }
            return this.History[-1]
        } else {
            return this.Constructor.Call(Id ?? this.IdCallback.Call())
        }
    }
    GetId() {
        return ++this.Index
    }
    /**
     * Activates the {@link TracerGroup}'s history functionality. This is separate from the history
     * functionality used by the individual {@link Tracer} objects, which you can set at the
     * group-level by calling {@link TracerGroup.Prototype.TracerHistoryActivate}.
     *
     * @param {Integer} MaxItems - Defines the maximum number of items that may be in the array
     * before removing some. If the item count of array {@link TracerGroup#History} exceeds `MaxItems`,
     * items are removed from the array.
     */
    HistoryActivate(MaxItems?) {
        this.HistoryActive := true
        if IsSet(MaxItems) {
            this.HistorySetMaxItems(MaxItems)
        }
    }
    HistoryAdd(_tracer) {
        this.History.Push(_tracer)
        if this.__HistoryMaxItems > 0 && this.History.Length > this.__HistoryMaxItems {
            this.History.RemoveAt(1, this.HistoryReleaseCount)
        }
    }
    HistoryDeactivate() {
        this.HistoryActive := false
    }
    HistorySetMaxItems(MaxItems) {
        if this.History.Length > MaxItems {
            this.History.RemoveAt(1, this.History.Length - MaxItems - this.HistoryReleaseCount)
        }
        this.History.Capacity := this.__HistoryMaxItems := MaxItems
    }
    /**
     * Defines the ratio that is multiplied by the history array's length to determine the number of
     * items that are removed from the array.
     *
     * @param {Float} Ratio
     */
    HistorySetReleaseRatio(Ratio) {
        this.HistoryReleaseRatio := Ratio
    }
    LogFileClose() {
        this.Constructor.Prototype.LogFile.Close()
    }
    OpenGroupLogFile(Options?) {
        if IsObject(this.Constructor.Prototype.LogFile) {
            this.Constructor.Prototype.LogFile.Close()
        }
        this.Constructor.Prototype.SetFileOptions(Options ?? unset)
    }
    SetOption(Name, Value) {
        list := [
            this.Constructor.Prototype
          , this.Constructor.Prototype.LogFile
          , this.Constructor.Prototype.Options
        ]
        if this.History {
            list.Push(this.History[-1].Constructor)
        }
        for obj in list {
            if HasProp(Obj, Name) {
                Obj.%Name% := Value
            }
        }
    }
    /**
     * Activates the history functionality used by the individual {@link Tracer} objects. This is
     * separate from the {@link TracerGroup}'s history functionality, which you can set by
     * calling {@link TracerGroup.Prototype.HistoryActivate}.
     *
     * @param {Integer} MaxItems - Defines the maximum number of items that may be in the array
     * before removing some. See the description for {@link TracerGroup.Prototype.TracerHistorySetMaxItems}
     * for a disclaimer about data loss.
     */
    TracerHistoryActivate(MaxItems?) {
        this.Constructor.Prototype.HistoryActive := true
        if IsSet(MaxItems) {
            this.TracerHistorySetMaxItems(MaxItems)
        }
    }
    TracerHistoryDeactivate() {
        this.Constructor.Prototype.HistoryActive := false
    }
    /**
     * Defines the maximum number of items that may be in an individual {@link Tracer} object's
     * history array before removing some.
     *
     * The following information can likely be inferred, but since this involves the deletion of data,
     * it is worth making explicitly clear: Changing the `MaxItems` will effect existing {@link Tracer}
     * instances that are associated with this {@link TracerGroup} if all of the following are true:
     * - The {@link Tracer} instance does not have an own property "HistoryMaxItems"
     * - The {@link Tracer} instance does not have an own property "__HistoryMaxItems"
     * - The value returned by properties "HistoryActive" / "__HistoryActive" is nonzero
     * - One of the various log / output methods is called on the {@link Tracer} instance after
     *   the change.
     * - The number of items in the history array exceeds the new maximum.
     * - The {@link Tracer} instance is used again (calling one of the log / output methods).
     *
     * To put into plain language: If you never set any of the history options at the individual
     * object level, and if you use the individual object again, and if the number of items exceeds
     * the new maximum, then items will be removed.
     *
     * @param {Integer} MaxItems - The maximum number of items that may be in the array before removing
     * some.
     */
    TracerHistorySetMaxItems(MaxItems) {
        this.Constructor.Prototype.__HistoryMaxItems := MaxItems
    }
    /**
     * Defines the ratio that is multiplied by the history array's length to determine the number of
     * items that are removed from the array.
     *
     * @param {Float} Ratio
     */
    TracerHistorySetReleaseRatio(Ratio) {
        this.Constructor.Prototype.HistoryReleaseRatio := Ratio
    }

    HistoryMaxItems {
        Get => this.__HistoryMaxItems
        Set => this.SetHistoryMaxItems(Value)
    }
    HistoryReleaseCount => Round(this.HistoryMaxItems * this.HistoryReleaseRatio, 0) || 1
    LogFile => this.Constructor.Prototype.LogFile


    class Options {
        static Default := {
            GroupOptions: ''
          , GroupName: ''
          , HistoryActive: true
          , HistoryMaxItems: 10000
          , HistoryReleaseRatio: 0.05
          , IdCallback: ''
          , UseGroup: true
        }
        static Call(Options?) {
            if IsSet(Options) {
                o := {}
                d := this.Default
                for prop in d.OwnProps() {
                    o.%prop% := HasProp(Options, prop) ? Options.%prop% : d.%prop%
                }
                return o
            } else {
                return this.Default.Clone()
            }
        }
    }
}

class Tracer {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.GroupName := proto.LogFile := proto.HistoryActive := proto.__HistoryMaxItems := ''
    }
    /**
     * @param {String} Id - An identifier.
     *
     * @param {Object} [Options] - An object with options as property : value pairs. The object must
     * minimally have "Dir" and "Name" properties set. If you are using {@link TracerGroup}, you
     * should not pass an options object. Passing an options object will result in all of
     * the group properties to be overwritten by own properties.
     *
     * @param {String} Options.Dir - The directory in which log files will be created.
     *
     * @param {String} Options.Name - The file name to use.
     *
     * @param {Integer} [Options.DefaultWhat = -2] - The default value to pass to the "What"
     * parameter of `Error.Call` when creating a new {@link Tracer_LogUnit}.
     *
     * @param {String} [Options.Encoding = "utf-8"] - The file encoding to use.
     *
     * @param {String} [Options.Ext = ""] - The file extension to use. "Ext" can be an empty string if no extension
     * is preferred.
     *
     * @param {Boolean} [Options.HistoryActive = true] - If true, the history functionality is
     * enabled.
     *
     * @param {Integer} [Options.HistoryMaxItems = 10000] - The maximum number of items that may be
     * in the history array before removing some.
     *
     * @param {Float} [Options.HistoryReleaseRatio = 0.05] - The ratio that is multiplied by the
     * history array's length to determine the number of items that are removed from the array.
     *
     * @param {Integer} [Options.IndendLen = 4] - The number of space characters to use with one
     * level of indentation. This is options only has an effect when output is produced as json.
     *
     * @param {String} [Options.LineEnding = "`n"] - The literal string to use as line ending.
     * This is options only has an effect when output is produced as json.
     *
     * @param {String} [Options.LogFormat = "Log id: {1}`nTime: {3}`nFile: {6}::{4}`nFunction: {7}`nMessage: {8}`nExtra: {9}`nSnapshot:`n{10}`n".]
     * The format string to use when writing to log file.
     *
     * @param {Boolean} [Options.LogSnapshot = true] - If true, the snapshot string is included
     * in the string when writing to log file. This is options only has an effect when output is
     * produced as json.
     *
     * @param {Boolean} [Options.LogToJson = true] - If true, data is written to log file as a
     * json string. If false, data is written to log file in the format defined by `Options.LogFormat`.
     *
     * @param {Integer} [Options.MaxFiles = 0] - The maximum permissible number of files in the directory specified
     * by `Dir`. After this threshold is passed, files will be deleted in order of oldest to newest.
     *
     * @param {Integer} [Options.MaxSize = 0] - The maximum permissible cumulative size, in bytes, of the files in
     * the directory specified by `Dir`. After this threshold is passed, files will be deleted
     * in order of oldest to newest.
     *
     * @param {String} [Options.OutputFormat = "{1} :: {6} :: {4} :: {7} :: {8}"] - The format string
     * to use when writing to `OutputDebug`.
     *
     * @param {Boolean} [Options.OutputSnapshot = true] - If true, the snapshot string is included
     * in the string when writing to `OutputDebug`. This is options only has an effect when output is
     * produced as json.
     *
     * @param {Boolean} [Options.OutputToJson = true] - If true, data is written to `OutputDebug`as a
     * json string. If false, data is written to `OutputDebug` in the format defined by
     * `Options.OutputFormat`.
     *
     * @param {Boolean} [Options.SetOnExit = true] - If true, an `OnExit` callback is set which will close
     * the file if it is opened at the time the script exits.
     *
     * @param {Object} [Options.StringifyAllOptions] - The options to pass to {@link StringifyAll}
     * when creating a snapshot.
     *
     * @param {String} [Options.TimeFormat = "yyyy-MM-dd HH:mm:ss"] - The time format string to
     * use.
     */
    __New(Id, Options?) {
        this.Id := Id
        this.History := []
        if IsSet(Options) {
            this.SetOptions(Options)
        }
        this.Constructor := Tracer_LogUnitConstructor(this.LogFile, (this.GroupName ? this.GroupName ':' : '') this.Id, this.Options)
    }
    /**
     * Activates the history functionality.
     *
     * @param {Integer} MaxItems - Defines the maximum number of items that may be in the array
     * before removing some.
     */
    HistoryActivate(MaxItems?) {
        this.HistoryActive := true
        if IsSet(MaxItems) {
            this.HistorySetMaxItems(MaxItems)
        }
    }
    HistoryAdd(Unit) {
        this.History.Push(Unit)
        if this.HistoryMaxItems > 0 && this.History.Length > this.HistoryMaxItems {
            this.History.RemoveAt(1, this.HistoryReleaseCount)
        }
    }
    HistoryDeactivate() {
        this.HistoryActive := false
    }
    HistorySetMaxItems(MaxItems) {
        if this.History.Length > MaxItems {
            this.History.RemoveAt(1, this.History.Length - MaxItems + this.HistoryReleaseCount)
        }
        this.History.Capacity := this.__HistoryMaxItems := MaxItems
    }
    /**
     * Defines the ratio that is multiplied by the history array's length to determine the number of
     * items that are removed from the array.
     *
     * @param {Float} Ratio
     */
    HistorySetReleaseRatio(Ratio) {
        this.HistoryReleaseRatio := Ratio
    }
    Log(Message := '', SnapshotObj?, Extra := '', What?) {
        unit := this.Constructor.Call(&Message, SnapshotObj ?? unset, &Extra, What ?? unset)
        unit.Log()
        if this.HistoryActive {
            this.HistoryAdd(unit)
        }
        return unit
    }
    Out(Message := '', SnapshotObj?, Extra := '', What?) {
        unit := this.Constructor.Call(&Message, SnapshotObj ?? unset, &Extra, What ?? unset)
        unit.Out()
        if this.HistoryActive {
            this.HistoryAdd(unit)
        }
        return unit
    }
    SetOptions(Options, GroupName?) {
        options := this.Options := Tracer.Options(Options)
        if !options.Dir || !options.Name {
            throw PropertyError('The options object must minimally have "Dir" and "Name" set.', -1)
        }
        this.HistoryActive := options.HistoryActive
        this.HistoryReleaseRatio := options.HistoryReleaseRatio
        this.__HistoryMaxItems := options.HistoryMaxItems
        this.LogFile := Tracer_LogFile(options)
        if IsSet(GroupName) {
            this.GroupName := GroupName
        }
    }
    HistoryMaxItems {
        Get => this.__HistoryMaxItems
        Set => this.HistorySetMaxItems(Value)
    }
    HistoryReleaseCount => Round(this.__HistoryMaxItems * this.HistoryReleaseRatio, 0) || 1

    class Options {
        static Default := {
            Dir: ''
          , DefaultWhat: -2
          , Encoding: 'utf-8'
          , Ext: ''
          , HistoryActive: true
          , HistoryMaxItems: 10000
          , HistoryReleaseRatio: 0.05
          , IndentLen: 4
          , LineEnding: '`n'
          , LogFormat: 'Log id: {1}`nTime: {3}`nFile: {6}::{4}`nFunction: {7}`nMessage: {8}`nExtra: {9}`nSnapshot:`n{10}`n'
          , LogSnapshot: true
          , LogToJson: true
          , MaxFiles: 0
          , MaxSize: 0
          , Name: ''
          , OutputFormat: '{1} :: {6} :: {4} :: {7} :: {8}'
          , OutputSnapshot: false
          , OutputToJson: false
          , SetOnExit: true
          , StringifyAllOptions: {
                EnumTypeMap: Tracer_MapHelper(false, 2, 'Array', 1)
              , PropsTypeMap: Tracer_MapHelper(false, 1)
              , StopAtTypeMap: Tracer_MapHelper(false, '-Object', 'Class', '-Class', 'Array', '-Array', 'Map', '-Map')
              , ExcludeProps: '__Init,Prototype'
            }
          , TimeFormat: 'yyyy-MM-dd HH:mm:ss'
        }
        static Call(Options) {
            o := {}
            d := this.Default
            for prop in d.OwnProps() {
                o.%prop% := HasProp(Options, prop) ? Options.%prop% : d.%prop%
            }
            return o
        }
    }
}

class Tracer_LogUnitConstructor extends Class {
    __New(LogFile, TracerId, Options) {
        this.Index := 0
        this.DefaultWhat := options.DefaultWhat
        this.Prototype := {
            Extra: ''
          , LogFile: LogFile
          , LogFormat: Options.LogFormat
          , LogSnapshot: Options.LogSnapshot
          , LogToJson: Options.LogToJson
          , Message: ''
          , OutputFormat: Options.OutputFormat
          , OutputSnapshot: Options.OutputSnapshot
          , OutputToJson: Options.OutputToJson
          , TimeFormat: Options.TimeFormat
          , TracerId: TracerId
          , __Class: Tracer_LogUnit.Prototype.__Class
          , __Indent: []
          , Snapshot: ''
        }
        ObjSetBase(this.Prototype, Tracer_LogUnit.Prototype)
        this.SetIndent(Options.IndentLen)
        this.SetLineEnding(options.LineEnding)
        this.SetStringifyAllOptions(Options.StringifyAllOptions)
    }
    Call(&Message := '', SnapshotObj?, &Extra := '', What?) {
        t := Error(Message, What ?? this.DefaultWhat, Extra)
        t.Timestamp := A_Now
        ObjSetBase(t, this.Prototype)
        if IsSet(SnapshotObj) {
            t.GetSnapshot(SnapshotObj)
        }
        t.Id := ++this.Index
        return t
    }
    SetIndent(IndentLen) {
        this.Prototype.IndentLen := IndentLen
        indent := this.Prototype.__Indent
        s := ''
        loop IndentLen {
            s .= '`s'
        }
        if !indent.Length {
            indent.Length := 2
        }
        indent[1] := s
        loop indent.Length - 1 {
            indent[A_Index + 1] := indent[A_Index] indent[1]
        }
        if IsObject(this.Prototype.LogFile) {
            this.Prototype.LogFile.IndentLen := IndentLen
        }
    }
    SetLineEnding(LineEnding) {
        this.Prototype.LineEnding := LineEnding
        if IsObject(this.Prototype.LogFile) {
            this.Prototype.LogFile.LineEnding := LineEnding
        }
    }
    SetStringifyAllOptions(StringifyAllOptions) {
        if !IsObject(StringifyAllOptions) {
            StringifyAllOptions := ConfigLibrary.Get(StringifyAllOptions)
        }
        this.Prototype.StringifyAllOptions := { InitialIndent: 0 }
        ObjSetBase(this.Prototype.StringifyAllOptions, StringifyAllOptions)
    }
    Extra {
        Get => this.Prototype.Extra
        Set => this.Prototype.Extra := Value
    }
    LineEnding {
        Get => this.Prototype.LineEnding
        Set => this.SetLineEnding(Value)
    }
    LogFormat {
        Get => this.Prototype.LogFormat
        Set => this.Prototype.LogFormat := Value
    }
    LogSnapshot {
        Get => this.Prototype.LogSnapshot
        Set => this.Prototype.LogSnapshot := Value
    }
    LogToJson {
        Get => this.Prototype.LogToJson
        Set => this.Prototype.LogToJson := Value
    }
    OutputFormat {
        Get => this.Prototype.OutputFormat
        Set => this.Prototype.OutputFormat := Value
    }
    OutputSnapshot {
        Get => this.Prototype.OutputSnapshot
        Set => this.Prototype.OutputSnapshot := Value
    }
    OutputToJson {
        Get => this.Prototype.OutputToJson
        Set => this.Prototype.OutputToJson := Value
    }
    StringifyAllOptions {
        Get => this.Prototype.StringifyAllOptions
        Set => this.SetStringifyAllOptions(Value)
    }
    TimeFormat {
        Get => this.Prototype.TimeFormat
        Set => this.Prototype.TimeFormat := Value
    }
}

class Tracer_LogUnit extends Error {
    static Call(Id, Message := '', SnapshotObj?, Extra := '', What := -1) {
        t := Error(Message, What, Extra)
        t.Timestamp := A_Now
        ObjSetBase(t, this.Prototype)
        if IsSet(SnapshotObj) {
            t.GetSnapshot(SnapshotObj)
        }
        t.Id := Id
        return t
    }
    GetFormatStr(FormatStr, IncludeSnapshot) {
        return Format(
            FormatStr
          , this.TracerId ':' this.Id   ; 1
          , this.Timestamp              ; 2
          , this.NiceTime               ; 3
          , this.Line                   ; 4
          , this.File                   ; 5
          , this.FileName               ; 6
          , this.What                   ; 7
          , this.Message                ; 8
          , this.Extra                  ; 9
          , IncludeSnapshot ? (this.Snapshot || unset) : '' ; 10
        )
    }
    GetJson(IncludeSnapshot) {
        i1 := this.Indent[1]
        i2 := this.Indent[2]
        le := this.LineEnding
        return (
            i1 '{' le
                i2 '"TracerId": "' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(this.TracerId, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t')  '",' le
                i2 '"LogId": "' this.TracerId ':' this.Id '",' le
                i2 '"Timestamp": "' this.Timestamp '",' le
                i2 '"NiceTime": "' this.NiceTime '",' le
                i2 '"Line": "' this.Line '",' le
                i2 '"File": "' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(this.File, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t') '",' le
                i2 '"FileName": "' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(this.FileName, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t') '",' le
                i2 '"What": "' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(this.What, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t') '",' le
                i2 '"Message": "' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(this.Message, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t') '",' le
                i2 '"Extra": "' (this.Extra ? StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(this.Extra, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t') : '') '",' le
                i2 '"Snapshot": ' (IncludeSnapshot ? this.GetSnapshotStr(2) : '""') '' le
            i1 '}'
        )
    }
    GetLogStr() {
        return this.GetFormatStr(this.LogFormat, this.LogSnapshot)
    }
    GetOutputStr() {
        return this.GetFormatStr(this.OutputFormat, this.OutputSnapshot)
    }
    GetSnapshot(Obj, Options?) {
        if IsSet(Options) {
            _options := { InitialIndent: 0 }
            ObjSetBase(_options, Options)
            this.Snapshot := StringifyAll(Obj, _options)
        } else {
            this.Snapshot := StringifyAll(Obj, this.StringifyAllOptions)
        }
    }
    GetSnapshotStr(Indent := 0) {
        if this.Snapshot {
            if Indent {
                split := StrSplit(this.Snapshot, '`n', '`r')
                s := split.RemoveAt(1) '`n'
                i := this.Indent[Indent]
                for item in split {
                    s .= i item '`n'
                }
                return SubStr(s, 1, -1)
            } else {
                return this.Snapshot
            }
        } else {
            return '""'
        }
    }
    Log() {
        if this.LogToJson {
            if this.LogFile.NewJsonFile {
                this.LogFile.File.Write('[')
                this.LogFile.NewJsonFile := false
            } else {
                this.LogFile.File.Write(',')
            }
            this.LogFile.File.Write(this.LineEnding this.GetJson(this.LogSnapshot))
        } else {
            this.LogFile.File.Write(this.GetLogStr() this.LineEnding)
        }
        this.LogFile.CheckFile()
    }
    Out() {
        if this.OutputToJson {
            OutputDebug(this.GetJson(this.OutputSnapshot) '`n')
        } else {
            OutputDebug(this.GetOutputStr() '`n')
        }
    }
    FileName {
        Get {
            this.DefineProp('FileName', { Value: SubStr(this.File, InStr(this.File, '\', , , -1) + 1) })
            return this.FileName
        }
    }
    Indent[Index?] {
        Get {
            if IsSet(Index) {
                if Index {
                    if Index < 0 {
                        throw IndexError('Invalid index.', -1, Index)
                    }
                    if Index > this.__Indent.Length {
                        indent := this.__Indent
                        i := indent.Length
                        indent.Length := Index
                        loop Index - i {
                            indent[++i] := indent[i - 1] indent[1]
                        }
                        return indent[Index]
                    } else {
                        return this.__indent[Index]
                    }
                } else {
                    return ''
                }
            } else {
                return this.__Indent
            }
        }
    }
    NiceTime => FormatTime(this.Timestamp, this.TimeFormat)
}

class Tracer_LogFile {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.NewJsonFile := proto.File := proto.HandlerOnExit := ''
        proto.StartByte := 0
    }
    /**
     * The expected usage is to get an instance of {@link Tracer_LogFile} by creating an instance
     * of {@link Tracer}.
     *
     * @param {Object} Options - The options object. This should have already been processed by
     * {@link Tracer.Options.Call}.
     */
    __New(Options) {
        this.Name := options.Name
        this.SetExt(options.Ext)
        this.Dir := options.Dir
        if !DirExist(options.Dir) {
            DirCreate(options.Dir)
        }
        this.MaxSize := options.MaxSize
        this.MaxFiles := options.MaxFiles
        this.LineEnding := options.LineEnding
        this.__IsJson := options.LogToJson
        this.SetEncoding(options.Encoding)
        this.IndentLen := options.IndentLen
        this.CheckDir(&greatestIndex)
        this.Index := greatestIndex
        this.Open(options.SetOnExit)
    }
    CheckDir(&OutGreatestIndex?) {
        OutGreatestIndex := 0
        if this.Ext {
            filePattern := this.Dir '\' this.Name '*.' this.Ext
            indexPattern := '-(\d+)\.' this.Ext '$'
        } else {
            filePattern := this.Dir '\' this.Name '*'
            indexPattern := '-(\d+)$'
        }
        result := []
        loop Files filePattern, 'F' {
            result.Push({ TimeCreated: A_LoopFileTimeCreated, FullPath: A_LoopFileFullPath, Size: A_LoopFileSize })
            if RegExMatch(A_LoopFileName, indexPattern, &Match) {
                if Match[1] > OutGreatestIndex {
                    OutGreatestIndex := Match[1]
                }
            } else {
                throw Error('Unmatched file name', -1, A_LoopFileFullPath)
            }
        }
        if this.MaxFiles > 0 && result.Length {
            result := Tracer_QuickSort(result, (a, b) => DateDiff(b.TimeCreated, a.TimeCreated, 'S'))
            if result.Length > this.MaxFiles {
                loop result.Length - this.MaxFiles + 1 {
                    FileDelete(result.Pop().FullPath)
                }
            }
        }
        return result
    }
    CheckFile() {
        if this.MaxSize > 0 && this.File.Length > this.MaxSize {
            this.Close()
            this.CheckDir()
            this.NewJsonFile := 1
            ++this.Index
            this.File := FileOpen(this.Path, 'a', this.Encoding)
            this.SetOnExit(1)
            return 1
        }
    }
    /**
     * @returns {Integer} - One of the following:
     * - 0: The file ends with a line-feed or carriage-return character followed by a close square
     *   bracket, indicating the file's contents is likely a valid, closed json array.
     * - 1: The file ends with a line-feed or carriage-return character followed by one level of
     *   indentation (defined as the value of {@link Tracer_LogFile#IndentLen}) followed by a closing
     *   curly bracket, OR the file is 1 character in length and that character is an open square
     *   bracket, indicating the file's contents is likely a valid json array and the array needs
     *   to be closed.
     * - 2: The file is empty OR the file only contains whitespace characters.
     * - 3: The file cannot be characterized by any of the above, indicating the file likely does
     *   not contain a valid json array created by this library.
     */
    CheckJsonEnd() {
        if this.File {
            f := this.File
            pos := f.Pos
        } else {
            f := FileOpen(this.Path, 'r', this.Encoding)
        }
        if f.Length == this.Startbyte {
            result := 2
        } else if f.Length == 2 + this.StartByte {
            f.Pos := this.StartByte
            if f.Read() == '[' {
                result := 1
            } else {
                result := 3
            }
        } else if f.Length == 4 + this.StartByte {
            f.Pos := this.StartByte
            if f.Read() == '[]' {
                result := 0
            } else {
                result := 3
            }
        } else {
            f.Pos := f.Length - Min(20, f.Length - this.StartByte)
            content := LTRim(f.Read(Min(20, f.Length - this.StartByte)), '`s`r`t`n')
            if !content {
                f.Pos := this.StartByte
                content := f.Read()
            }
            if content {
                if RegExMatch(content, '(?<=[\r\n])(?<indent>[ \t]*).+$', &match) {
                    switch SubStr(match[0], -1, 1) {
                        case ']':
                            if match.Len > 1 {
                                result := 3
                            } else {
                                result := 0
                            }
                        case '}':
                            if match.Len['indent'] == this.IndentLen {
                                result := 1
                            } else {
                                result := 3
                            }
                        default: result := 3
                    }
                } else {
                    result := 3
                }
            } else {
                result := 2
            }
        }
        if IsSet(pos) {
            f.Pos := pos
        } else {
            f.Close()
        }
        return result
    }
    /**
     * Note this ignores any leading whitespace.
     * @returns {Integer} - One of the following:
     * - 0: The file begins with an open square bracket.
     * - 1: The file is 4 bytes in length consisting of an open and close square bracket.
     * - 2: The file is empty or contains only whitespce.
     * - 3: The file cannot be characterized by any of the above, indicating the file likely does
     *   not contain a valid json array created by this library.
     */
    CheckJsonStart() {
        if this.File {
            f := this.File
            pos := f.Pos
        } else {
            f := FileOpen(this.Path, 'r', this.Encoding)
        }
        f.Pos := this.StartByte
        if f.Length == this.StartByte {
            result := 2
        } else if f.Length == this.BracketByteCount + this.StartByte {
            if f.Read() == '[' {
                result := 0
            } else {
                result := 3
            }
        } else if f.Length == this.BracketByteCount * 2 + this.StartByte {
            if f.Read() == '[]' {
                result := 1
            } else {
                result := 3
            }
        } else {
            pattern := '^(?:\[|\s*(?<=[\r\n])\[)'
            if content := RTrim(f.Read(Min(this.BracketByteCount * 10, f.Length)), '`s`t`r`n') {
                if RegExMatch(content, pattern, &match) {
                    result := 0
                } else {
                    result := 3
                }
            } else {
                f.Pos := this.StartByte
                if RegExMatch(f.Read(), pattern, &match) {
                    result := 0
                } else {
                    result := 3
                }
            }
        }
        if IsSet(pos) {
            f.Pos := pos
        } else {
            f.Close()
        }
        return result
    }
    Close(*) {
        if this.File {
            if this.IsJson {
                if this.File.Length > this.StartByte + 2 {
                    this.File.Write(this.LineEnding ']')
                }
            }
            this.File.Close()
            this.File := ''
        }
        this.SetOnExit(0)
    }
    GetStartByte() {
        path := A_Temp '\tracer-ahk.temp'
        f := FileOpen(path, 'w', this.Encoding)
        result := f.Length
        f.Close()
        return result
    }
    Open(SetOnExit := 1) {
        this.StartByte := this.GetStartByte()
        if FileExist(this.Path) {
            if !this.MaxSize || FileGetSize(this.Path, 'B') < this.MaxSize {
                if this.IsJson {
                    switch this.CheckJsonStart() {
                        case 0:
                            switch this.CheckJsonEnd() {
                                case 0: this.RemoveCloseSquareBracket()
                                case 1: ; do nothing
                                case 2: this.NewJsonFile := true
                                case 3:
                                    this.NewJsonFile := true
                                    ++this.Index
                            }
                        case 1: this.RemoveCloseSquareBracket()
                        case 2: this.NewJsonFile := true
                        case 3:
                            this.NewJsonFile := true
                            ++this.Index
                    }
                }
            } else {
                ++this.Index
                if this.IsJson {
                    this.NewJsonFile := true
                }
            }
        } else if this.IsJson {
            this.NewJsonFile := true
        }
        this.File := FileOpen(this.Path, 'a', this.Encoding)
        if SetOnExit {
            this.SetOnExit(1)
        }
    }
    /**
     * Removes the closing square bracket from the file. This also deletes any trailing whitespace.
     * If the file has already been opened, the file pointer is moved to the end of the file. If the
     * file has not been already opened, it is opened temporarily and closed before this function
     * exits.
     * @returns {Integer} - 0 if successful, 1 if the file is empty or contains only whitespace.
     * @throws {Error} - "The file's contents does not end with a close square bracket."
     */
    RemoveCloseSquareBracket() {
        if this.File {
            f := this.File
            pos := f.Pos
        } else {
            f := FileOpen(this.Path, 'a', this.Encoding)
        }
        chunkSize := Min(this.BracketByteCount * 10, f.Length)
        r := Mod(f.Length, chunkSize)
        f.Pos := f.Length - chunkSize
        loop Floor(f.Length / chunkSize) {
            if str := RTrim(f.Read(), '`s`r`t`n') {
                return _Check()
            } else {
                f.Length -= chunkSize
                if f.Length >= chunkSize {
                    f.Pos := f.Length - chunkSize
                } else {
                    f.Pos := 0
                }
            }
        }
        if r {
            f.Pos := 0
            if str := RTrim(f.Read(), '`s`r`t`n') {
                return _Check()
            } else {
                f.Length := 0
                if !IsSet(pos) {
                    f.Close()
                }
            }
        } else {
            f.Length := 0
            if !IsSet(pos) {
                f.Close()
            }
        }

        return 1

        _Check() {
            if SubStr(str, -1, 1) == ']' {
                f.Length -= this.BracketByteCount
                if IsSet(pos) {
                    f.Pos := f.Length
                } else {
                    f.Close()
                }
                return 0
            } else {
                if IsSet(pos) {
                    f.Pos := f.Length
                } else {
                    f.Close()
                }
                throw Error('The file`'s contents does not end with a close square bracket.', -1, this.Path)
            }
        }
    }
    SetAsJson(Value) {
        this.__IsJson := Value
        if !Value {
            this.NewJsonFile := false
        }
    }
    SetEncoding(Encoding) {
        this.__Encoding := Encoding
        this.BracketByteCount := StrPut('[', Encoding)
        this.StartByte := this.GetStartByte()
    }
    SetExt(Ext) {
        if this.__Ext := Ext {
            this.DefineProp('GetPath', Tracer_LogFile.Prototype.GetOwnPropDesc('__GetPath'))
        } else {
            this.DefineProp('GetPath', Tracer_LogFile.Prototype.GetOwnPropDesc('__GetPathNoExt'))
        }
    }
    SetOnExit(Value := 1) {
        if !IsObject(this.HandlerOnExit) {
            this.HandlerOnExit := ObjBindMethod(this, 'Close')
        }
        OnExit(this.HandlerOnExit, Value)
    }
    __GetPath(Index?) {
        return this.Dir '\' this.Name '-' (Index ?? this.Index) '.' this.Ext
    }
    __GetPathNoExt(Index?) {
        return this.Dir '\' this.Name '-' (Index ?? this.Index)
    }
    Encoding {
        Get => this.__Encoding
        Set => this.SetEncoding(Value)
    }
    Ext {
        Get => this.__Ext
        Set => this.SetExt(Value)
    }
    IsJson {
        Get => this.__IsJson
        Set => this.SetAsJson(Value)
    }
    Path => this.GetPath(this.Index)
}

class Tracer_MapHelper extends Map {
    __New(CaseSense := false, Default?, Values*) {
        this.CaseSense := CaseSense
        if IsSet(Default) {
            this.Default := Default
        }
        if Values.Length {
            this.Set(Values*)
        }
    }
}

/**
 * Sorts an array. The returned array is a new array; the original array is not modified.
 *
 * The process used by `QuickSort` makes liberal usage of the system's memory. My tests demonstrated
 * an average memory consumption of over 9x the capacity of the input array. These tests were
 * performed using input arrays with 1000 numbers across an even distribution.
 *
 * Original code is found here: {@link https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/QuickSort.ahk Github}.
 *
 * @param {Array} Arr - The array to be sorted.
 *
 * @param {*} [CompareFn = (a, b) => a - b] - A `Func` or callable object that compares two values.
 *
 * Parameters:
 * 1. A value to be compared.
 * 2. A value to be compared.
 *
 * Returns {Number} - A number to one of the following effects:
 * - If the number is less than zero it indicates the first parameter is less than the second parameter.
 * - If the number is zero it indicates the two parameters are equal.
 * - If the number is greater than zero it indicates the first parameter is greater than the second parameter.
 *
 * @param {Integer} [ArrSizeThreshold = 17] - Sets a threshold at which insertion sort is used to
 * sort the array instead of the core procedure. The default value of 17 was decided by testing various
 * values, but currently more testing is needed to evaluate arrays of various kinds of distributions.
 *
 * @param {Integer} [PivotCandidates = 7] - Note that `PivotCandidates` must be an integer greater
 * than 1.
 *
 * Defines the sample size used when selecting a pivot from a random sample. This seeks to avoid the
 * efficiency cost associated with selecting a low quality pivot. By choosing from a random sample,
 * it is expected that, on average, the number of comparisons required to evaluate the middle pivot
 * in the sample is significantly less than the number of comparisons avoided due to selecting a low
 * quality pivot.
 *
 * The default value of 7 was decided by testing various values. More testing is needed to evaluate
 * arrays of various kinds of distributions.
 *
 * @returns {Array} - The sorted array.
 *
 * @throws {ValueError} - "`PivotCandidates` must be an integer greater than one."
 */
Tracer_QuickSort(Arr, CompareFn := (a, b) => a - b, ArrSizeThreshold := 17, PivotCandidates := 7) {
    if PivotCandidates <= 1 {
        throw ValueError('``PivotCandidates`` must be an integer greater than one.', -1, PivotCandidates)
    }
    halfPivotCandidates := Ceil(PivotCandidates / 2)
    if Arr.Length <= ArrSizeThreshold {
        if Arr.Length == 2 {
            if CompareFn(Arr[1], Arr[2]) > 0 {
                return [Arr[2], Arr[1]]
            }
            return Arr.Clone()
        } else if arr.Length > 1 {
            arr := Arr.Clone()
            ; Insertion sort.
            i := 1
            loop arr.Length - 1 {
                j := i
                current := arr[++i]
                loop j {
                    if CompareFn(arr[j], current) < 0 {
                        break
                    }
                    arr[j + 1] := arr[j--]
                }
                arr[j + 1] := current
            }
            return arr
        } else {
            return arr.Clone()
        }
    }

    return _Proc(Arr)

    _Proc(Arr) {
        if Arr.Length <= ArrSizeThreshold {
            if Arr.Length == 2 {
                if CompareFn(Arr[1], Arr[2]) > 0 {
                    return [Arr[2], Arr[1]]
                }
            } else if Arr.Length > 1 {
                ; Insertion sort.
                i := 1
                loop Arr.Length - 1 {
                    j := i
                    current := Arr[++i]
                    loop j {
                        if CompareFn(Arr[j], current) < 0 {
                            break
                        }
                        Arr[j + 1] := Arr[j--]
                    }
                    Arr[j + 1] := current
                }
            }
            return Arr
        }
        candidates := []
        loop candidates.Capacity := PivotCandidates {
            candidates.Push(Arr[Random(1, Arr.Length)])
        }
        i := 1
        loop candidates.Length - 1 {
            j := i
            current := candidates[++i]
            loop j {
                if CompareFn(candidates[j], current) < 0 {
                    break
                }
                candidates[j + 1] := candidates[j--]
            }
            candidates[j + 1] := current
        }
        pivot := candidates[halfPivotCandidates]
        left := []
        right := []
        left.Capacity := right.Capacity := Arr.Length
        for item in Arr {
            if CompareFn(item, pivot) < 0 {
                left.Push(item)
            } else {
                right.Push(item)
            }
        }
        result := _Proc(left)
        result.Push(_Proc(right)*)

        return result
    }
}
