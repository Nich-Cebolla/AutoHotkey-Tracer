
/**
 * {@link TracerOptions} is intended to simplify the management of user-selectable options exposed
 * by {@link Tracer} and its dependencies.
 *
 * The constructors for {@link TracerGroup} and {@link Tracer} both have a required parameter that
 * expects an instance of {@link TracerOptions}.
 *
 * When calling {@link TracerOptions.Prototype.__New} you can pass the entire options object, or
 * you can pass just the root object and call the various "Set" methods to add on the other
 * options objects that get nested under the root object.
 *
 * {@link TracerOptions} copies the property values from your input; {@link TracerOptions} neither
 * changes your input object nor caches a reference to it.
 */
class TracerOptions {
    static __New() {
        this.DeleteProp('__New')
        this.DefaultFormatSpecifierNames := [ 'ext', 'extra', 'id', 'file', 'filename', 'filenamenoext', 'le', 'line', 'message', 'nicetime', 'snapshot', 'stack', 'time', 'what' ]
        this.DefaultFormatCodes := ''
        this.DefaultSpecifierCodes := Map(
            'json', Tracer_FormatStr_EscapeJson
          , '-json', Tracer_FormatStr_UnEscapeJson
        )
        this.DefaultLogFormat := (
            '{Log id: {%id%}%le%}'
            '{Timestamp: {%time%}%le%}'
            '{Time: {%nicetime%}%le%}'
            'File: %filename% : %line%%le%'
            '{What: {%what%}%le%}'
            '{Message: {%message%}%le%}'
            '{Extra: {%extra%}%le%}'
            '{Snapshot:%le%{%snapshot%}%le%}'
        )
        this.DefaultOutFormat := '{%id% : }%filename%::%line%{ : %what%}{ : %message%}{%le%{%snapshot%}}'
        this.DefaultJsonProperties := [ 'id', 'file', 'line', 'message', 'nicetime', 'snapshot', 'stack', 'time', 'what' ]
        this.JsonPropertiesMap := Tracer_MapHelper( , 0, 'filename', 'FileName', 'filenamenoext', 'FileNameNoExt', 'nicetime', 'NiceTime')

        this.DefaultFormatStr := {
            Callback: Tracer_FormatStrCallback
          , CaseSense: false
          , FormatCodes: ''
          , FormatSpecifierNames: this.DefaultFormatSpecifierNames
          , SpecifierCodes: this.DefaultSpecifierCodes
          , StrCapacity: 1024
        }
        this.DefaultLog := {
            ConditionCallback: ''
          , Critical: -1
          , Format: this.DefaultLogFormat
          , ToJson: false
          , JsonProperties: this.DefaultJsonProperties
        }
        this.DefaultLogFile := {
            Dir: ''
          , Encoding: 'utf-8'
          , FileIndexPattern: ''
          , FilePattern: ''
          , Ext: ''
          , MaxFiles: 0
          , MaxSize: 0
          , Name: ''
          , OnExitCritical: -1
          , SetOnExit: 1
        }
        this.DefaultOut := {
            ConditionCallback: ''
          , Critical: -1
          , Format: this.DefaultOutFormat
          , ToJson: false
          , JsonProperties: this.DefaultJsonProperties
        }
        this.DefaultStringifyAll := {
            EnumTypeMap: Tracer_MapHelper(false, 2, 'Array', 1)
          , PropsTypeMap: Tracer_MapHelper(false, 1)
          , StopAtTypeMap: Tracer_MapHelper(false, '-Object', 'Class', '-Class', 'Array', '-Array', 'Map', '-Map')
          , ExcludeProps: '__Init,Prototype'
        }
        this.DefaultTracer := {
            DefaultWhat: -1
          , HistoryActive: false
          , HistoryMaxItems: 10000
          , HistoryReleaseRatio: 0.05
          , IdCallback: Tracer_GetId
          , IndentLen: 4
          , LineEnding: '`n'
          , TimeFormat: 'yyyy-MM-dd HH:mm:ss'
        }
        this.DefaultTracerGroup := {
            GroupName: ''
          , HistoryActive: false
          , HistoryMaxItems: 10000
          , HistoryReleaseRatio: 0.05
          , IdCallback: Tracer_GetId
        }
        this.DefaultOptions := {
            FormatStr: this.DefaultFormatStr
          , Log: this.DefaultLog
          , LogFile: this.DefaultLogFile
          , Out: this.DefaultOut
          , StringifyAll: this.DefaultStringifyAll
          , Tracer: this.DefaultTracer
          , TracerGroup: this.DefaultTracerGroup
        }
        proto := this.Prototype
        proto.FormatStr := proto.Log := proto.LogFile := proto.Out := proto.StringifyAll :=
        proto.Tracer := proto.TracerGroup := proto.flag_onExitStarted := ''
    }
    /**
     * Returns a {@link TracerOptions} object which is shared across this library's classes. You
     * can pass this object to either {@link TracerGroup.Prototype.__New} or {@link Tracer.Prototype.__New}.
     *
     * When calling {@link TracerOptions.Prototype.__New}, you have the option of passing your options
     * object in and allowing the constructor to process your options. This is not required; you
     * can call {@link TracerOptions.Prototype.__New} with no parameters which returns an object with
     * only the default values, then call the individual "Set<category name>" or "Set<category name>Obj"
     * methods to add your options.
     *
     * Options are divided into categories named after the class / method for which they are associated.
     * - FormatStr: Options related to {@link FormatStr}.
     * - Log: Options related to {@link Tracer.Prototype.Log}.
     * - LogFile: Options related to {@link TracerLogFile}.
     * - Out: Options related to {@link Tracer.Prototype.Out}.
     * - StringifyAll: Options related to {@link StringifyAll}.
     * - Tracer: Options related to {@link Tracer}.
     * - TracerGroup: Options related to {@link TracerGroup}.
     *
     * The object you pass to the parameter `Options` is expected to be an object with zero or more
     * properties { FormatStr, Log, LogFile, Out, StringifyAll, Tracer, TracerGroup }. For each property,
     * the value is expected to be an object with property : value pairs representing the options for
     * that category.
     *
     * If your input `Options` does not have one of those properties, a deep clone of the default
     * options is used instead. This allows you to make changes to any values without affecting
     * the original default values.
     *
     * The same is true for any individual options that expect a value that is an object. For
     * example, `Options.TracerGroup.IdCallback` expects a `Func` or callable object. If your
     * `Options` include `Options.TracerGroup`, but `Options.TracerGroup` does not include
     * `Options.TracerGroup.IdCallback`, a deep clone of the default value is used.
     *
     * Note that for `Func` objects, a deep clone is not possible so instead the value is set as
     * a {@link Tracer_Functor} which will behave like a clone of a `Func` but isn't actually a `Func`.
     *
     * If your code will not be using {@link Tracer} to write to log file, do not include
     * `Options.LogFile`. This will disable {@link Tracer.Prototype.Log} until you call either
     * {@link TracerGroup#Tools.GetLogFile} or {@link Tracer#Tools.GetLogFile}.
     *
     * If your code will be using {@link Tracer.Prototype.Log}, you must minimally include
     * `Options.LogFile.Dir` and `Options.LogFile.Name`, or call {@link TracerOptions.Pototype.SetLogFile}
     * / {@link TracerOptions.Prototype.SetLogFileObj} with those values.
     *
     * Here is an example of an input options object:
     *
     * @example
     *  tracerOpt := {
     *      Log: {
     *          ToJson: true
     *        , JsonProperties: [ "time", "nicetime", "file", "filename", "line", "message", "what", "stack" ]
     *      }
     *    , LogFile: {
     *          Dir: "logs"
     *        , Name: "project-log"
     *        , Ext: "json"
     *      }
     *    , TracerGroup: {
     *          GroupName: "project"
     *      }
     *  }
     *  MyOptions := TracerOptions(tracerOpt)
     * @
     *
     * @param {Object} Options - An object with option categories as property : value pairs.
     * If unset, the default values are used.
     *
     * ## Options.FormatStr
     *
     * @param {Object} [Options.FormatStr] - An options object for {@link FormatStrConstructor} and
     * {@link FormatStr}. See {@link FormatStrConstructor.Prototype.__New} and the documentation
     * for options details.
     *
     * When defining your `Options.FormatStr` options object, the property name should correspond
     * to the option name as described in FormatStr's documentation. Additionally, the first
     * parameter `FormatSpecifierNames` of {@link FormatStrConstructor} can be included
     * as an option here as well.
     *
     * This is the default object:
     *
     * @example
     *  TracerOptions.DefaultFormatStr := {
     *      Callback: Tracer_FormatStrCallback
     *    , CaseSense: false
     *    , FormatCodes: ''
     *    , FormatSpecifierNames: TracerOptions.DefaultFormatSpecifierNames
     *    , SpecifierCodes: TracerOptions.DefaultSpecifierCodes
     *    , StrCapacity: 1024
     *  }
     * @
     *
     * ## Options.Log
     *
     * @param {Object} [Options.Log] - An options object specifying options related to
     * {@link Tracer.Prototype.Log}, which is used to write text to log file.
     *
     * @param {String} [Options.Log.Critical = -1] - If nonzero, this value is passed to `Critical`
     * when entering {@link Tracer.Prototype.Log}. When the function exits, `Critical` is set back
     * to its original value. If zero, `Critical` is not called.
     *
     * @param {*} [Options.Log.ConditionCallback = ""] - If set, a `Func` or callable object that
     * is called every time {@link Tracer.Prototype.Log} is called. The function is expected to return
     * a nonzero value if {@link Tracer.Prototype.Log} should complete the log action, or the function
     * should return zero or an empty string if {@link Tracer.Prototype.Log} should skip the log action.
     *
     * @param {String} [Options.Log.Format = TracerOptions.DefaultLogFormat] - The log format
     * string. See the documentation for more details.
     *
     * @param {Boolean} [Options.Log.ToJson = false] - If true, the log file is written as a json
     * array of objects, where each object represents one call to {@link Tracer.Prototype.Log}. When
     * true, `Options.Log.Format` is ignored. If false, the log file is written to in blocks of
     * text produced with `Options.Log.Format`.
     *
     * @param {String[]} [Options.Log.JsonProperties = TracerOptions.DefaultJsonProperties] -
     * an array of strings where each string is a format specifier name, indicating that that data
     * should be included as a property in the json object.
     *
     * ## Options.LogFile
     *
     * @param {Object} [Options.LogFile] - An options object specifying options related to
     * {@link TracerLogFile}.
     *
     * @param {String} [Options.LogFile.Dir = ""] - The path to the directory where the log files
     * will be created.
     *
     * @param {String} [Options.LogFile.Encoding = "utf-8"] - The encoding to use when working
     * with the log files.
     *
     * @param {String} [Options.LogFile.Ext = ""] - The log file's file extension. If an empty
     * string, no extension is used.
     *
     * @param {String} [Options.LogFile.FileIndexPattern = ""] - {@link TracerLogFile} manages
     * an own property {@link TracerLogFile#Index} which it uses when constructing the file path.
     * The index is incremented each time a new file is opened. When {@link TracerLogFile.Prototype.__New}
     * constructs a new instance, it iterates the files in `Options.LogFile.Dir` and while doing so it
     * identifies the greatest index within the directory, then sets `TracerLogFileObj.Index := greatestIndex`.
     * If `Options.LogFile.FileIndexPattern` is unset, the default pattern is used.
     *
     * You should only change this if you overwrite `TracerLogFileObj.GetPath`. The
     * pattern must have a subcapture group "index" that returns the index.
     *
     * Set to "-1" to disable the functionality.
     *
     * @param {String} [Options.LogFile.FilePattern = ""] - The file patern is used when checking
     * `Options.LogFile.Dir` to count the number of files present in the directory. If unset,
     * the default pattern is used.
     *
     * You should only change this if you overwrite the file path logic with custom logic.
     *
     * @param {Integer} [Options.LogFile.MaxFiles = 0] - If an integer greater than zero, the
     * maximum number of files permitted to exist conccurently in `Options.LogFile.Dir`. When
     * the threshold is reached, files are deleted in order of oldest to newest. If another
     * integer, no maximum is enforced.
     *
     * @param {Integer} [Options.LogFile.MaxSize = 0] - If an integer greater than zero, the
     * maximum size in bytes of one log file. WHen the threshold is reached, the log file is closed
     * and a new file opened. If another integer, no maximum is enforced.
     *
     * @param {String} [Options.LogFile.Name = ""] - The file name to use for the log files. Files
     * are differentiated with an integer appended to the end of the file name preceded by a hyphen.
     * The integer increments with each created file.
     *
     * @param {Integer} [Options.LogFile.OnExitCritical = -1] - If nonzero, this value is passed to
     * `Critical` when entering {@link TracerLogFile.Prototype.OnExit}. When the function exits,
     * `Critical` is set back to its original value. If zero, `Critical` is not called.
     *
     * @param {Integer} [Options.LogFile.SetOnExit = 1] - If nonzero, this value is passed to
     * `OnExit` to set a callback function which closes the log file if it is open at the time the
     * script exits.
     *
     * ## Options.Out
     *
     * @param {Object} [Options.Out] - An options object specifying options related to
     * {@link Tracer.Prototype.Out}, which is used to write text to `OutputDebug`.
     *
     * @param {String} [Options.Out.Critical = -1] - If nonzero, this value is passed to `Critical`
     * when entering {@link Tracer.Prototype.Log}. When the function exits, `Critical` is set back
     * to its original value. If zero, `Critical` is not called.
     *
     * @param {*} [Options.Out.ConditionCallback = ""] - If set, a `Func` or callable object that
     * is called every time {@link Tracer.Prototype.Out} is called. The function is expected to return
     * a nonzero value if {@link Tracer.Prototype.Out} should complete the output action, or the function
     * should return zero or an empty string if {@link Tracer.Prototype.Out} should skip the output action.
     *
     * @param {String} [Options.Out.Format = TracerOptions.DefaultLogFormat] - The format
     * string used with {@link Tracer.Prototype.Out`}. See the documentation for more details.
     *
     * @param {Boolean} [Options.Out.ToJson = false] - If true, {@link Tracer.Prototype.Out} writes
     * a json string to `OutputDebug`. When true, `Options.Out.Format` is ignored. If false,
     * {@link Tracer.Prototype.Out} writes formatted text to `OutputDebug`.
     *
     * @param {String[]} [Options.Out.JsonProperties = TracerOptions.DefaultJsonProperties] -
     * an array of strings where each string is a format specifier name, indicating that that data
     * should be included as a property in the json object.
     *
     * ## Options.StringifyAll
     *
     * @param {Object} [Options.StringifyAll] - An options object used when calling
     * {@link StringifyAll} to serialize an object's properties and items. This must be an object;
     * it cannot be a {@link ConfigLibrary} key.
     *
     * See {@link StringifyAll} and the documentation for details.
     *
     * When defining your `Options.StringifyAll` options object, the property name should correspond
     * to the option name as described in StringifyAll's documentation.
     *
     * This is the default object:
     *
     * @example
     *  TracerOptions.DefaultStringifyAll := {
     *      EnumTypeMap: Tracer_MapHelper(false, 2, 'Array', 1)
     *    , PropsTypeMap: Tracer_MapHelper(false, 1)
     *    , StopAtTypeMap: Tracer_MapHelper(false, '-Object', 'Class', '-Class', 'Array', '-Array', 'Map', '-Map')
     *    , ExcludeProps: '__Init,Prototype'
     *  }
     * @
     *
     * ## Options.Tracer
     *
     * @param {Object} [Options.Tracer] - An options object specifying options related to
     * {@link Tracer}.
     *
     * @param {Integer|String} [Options.Tracer.DefaultWhat = -1] The default value to pass to the
     * `What` parameter of `Error.Call` when your code calls {@link Tracer.Prototype.Log} and
     * {@link Tracer.Prototype.Out}. Both methods also expose the option as the fourth parameter.
     * If the fourth parameter is set, that value is passed to `Error.Call`. If the fourth
     * parameter is unset, then `Options.Tracer.DefaultWhat` is passed to `Error.Call`.
     *
     * @param {Boolean} [Options.Tracer.HistoryActive = true] - If true, the history functionality is
     * enabled.
     *
     * @param {Integer} [Options.Tracer.HistoryMaxItems = 10000] - The maximum number of items that may be
     * in the history array before removing some.
     *
     * @param {Float} [Options.Tracer.HistoryReleaseRatio = 0.05] - The ratio that is multiplied by the
     * history array's length to determine the number of items that are removed from the array after
     * surpassing `Options.Tracer.HistoryMaxItems` items.
     *
     * @param {*} [Options.Tracer.IdCallback = Tracer_GetId] - If set, a `Func` or callable
     * object that, when called, returns a unique identifier to assign to an instance of {@link TracerUnit}.
     * When not in use, {@link Tracer_GetId} is used.
     * - Parameters:
     *   1. The {@link Tracer} object.
     *   2. A value which your code passes to {@link Tracer.Prototype.Log} or {@link Tracer.Prototype.Out}
     *   to be passed to this function.
     * - Returns {String|Number} - The id.
     *
     * @param {Integer} [Options.Tracer.IndendLen = 4] - The number of space characters to use with
     * one level of indentation. This is option only has an effect when output is produced as json.
     *
     * @param {String} [Options.Tracer.LineEnding = "`n"] - The literal string to use as line ending.
     *
     * @param {String} [Options.Tracer.TimeFormat = "yyyy-MM-dd HH:mm:ss"] - The time format string to
     * use.
     *
     * ## Options.TracerGroup
     *
     * @param {Object} [Options.TracerGroup] - An options object specifying options related to
     * {@link TracerGroup}.
     *
     * @param {String} [Options.TracerGroup.GroupName = ""] - The group name.
     *
     * @param {Boolean} [Options.TracerGroup.HistoryActive = false] - If true, the history
     * functionality is enabled.
     *
     * @param {Integer} [Options.TracerGroup.HistoryMaxItems = 10000] - The maximum number of items
     * that may be in the history array before removing some.
     *
     * @param {Float} [Options.TracerGroup.HistoryReleaseRatio = 0.05] - The ratio that is multiplied by
     * the history array's length to determine the number of items that are removed from the array
     * after surpassing `Options.TracerGroup.HistoryMaxItems` items.
     *
     * @param {*} [Options.TracerGroup.IdCallback = Tracer_GetId] - If set, a `Func` or callable
     * object that, when called, returns a unique identifier to assign to an instance of {@link Tracer}.
     * When not in use, {@link Tracer_GetId} is used.
     * - Parameters:
     *   1. The {@link TracerGroup} object.
     *   2. A value which your code passes to {@link TracerGroup.Prototype.Call} to be passed to
     *   this function.
     * - Returns {String|Number} - The id.
     */
    __New(Options?) {
        if IsSet(Options) {
            for optCategory, defaultObj in TracerOptions.DefaultOptions.OwnProps() {
                if HasProp(Options, optCategory) && IsObject(Options.%optCategory%) {
                    obj := this.%optCategory% := {}
                    inputObj := Options.%optCategory%
                    for name in defaultObj.OwnProps() {
                        if HasProp(inputObj, name) {
                            obj.%name% := inputObj.%name%
                        } else if IsObject(defaultObj.%name%) {
                            obj.%name% := Tracer_ObjDeepClone(defaultObj.%name%)
                        } else {
                            obj.%name% := defaultObj.%name%
                        }
                    }
                } else {
                    this.%optCategory% := Tracer_ObjDeepClone(defaultObj)
                }
            }
        } else {
            for optCategory, defaultObj in TracerOptions.DefaultOptions.OwnProps() {
                this.%optCategory% := Tracer_ObjDeepClone(defaultObj)
            }
        }
    }
    /**
     * Returns a deep clone of this object.
     *
     * Note that if a property has a value that is a `Func` object, the value on the clone will
     * be a {@link Tracer_Functor} object, which will behave the same way but allows your code
     * to set new property values without changing the original.
     */
    Clone() {
        return Tracer_ObjDeepClone(this)
    }
    /**
     * Overwrites the options object for the indicated category with a deep clone of the default.
     *
     * @param {String} OptCategory - The options category name:
     * - FormatStr
     * - Log
     * - LogFile
     * - Out
     * - StringifyAll
     * - Tracer
     * - TracerGroup
     */
    ResetCategory(OptCategory) {
        this.%OptCategory% := Tracer_ObjDeepClone(TracerOptions.DefaultOptions.%OptCategory%)
    }
    ResetAll() {
        for optCategory in TracerOptions.DefaultOptions.OwnProps() {
            this.ResetCategory(optCategory)
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetFormatStr(Name, Value) {
        if HasProp(this.FormatStr, Name) {
            this.FormatStr.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {Object} Obj - An object with options as property : value pairs.
     */
    SetFormatStrObj(Obj) {
        optFormatStr := this.FormatStr
        for name in TracerOptions.DefaultFormatStr.OwnProps() {
            if HasProp(Obj, name) {
                optFormatStr.%name% := Obj.%name%
            }
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetLog(Name, Value) {
        if HasProp(this.Log, Name) {
            this.Log.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetLogFile(Name, Value) {
        if HasProp(this.LogFile, Name) {
            this.LogFile.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {Object} Obj - An object with options as nameerty : value pairs.
     */
    SetLogFileObj(Obj) {
        optLogFile := this.LogFile
        for name in TracerOptions.DefaultLogFile.OwnProps() {
            if HasProp(Obj, name) {
                optLogFile.%name% := Obj.%name%
            }
        }
    }
    /**
     * @param {Object} Obj - An object with options as nameerty : value pairs.
     */
    SetLogObj(Obj) {
        optLog := this.Log
        for name in TracerOptions.DefaultLog.OwnProps() {
            if HasProp(Obj, name) {
                optLog.%name% := Obj.%name%
            }
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetOut(Name, Value) {
        if HasProp(this.Out, Name) {
            this.Out.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {Object} Obj - An object with options as nameerty : value pairs.
     */
    SetOutObj(Obj) {
        optOut := this.Out
        for name in TracerOptions.DefaultOut.OwnProps() {
            if HasProp(Obj, name) {
                optOut.%name% := Obj.%name%
            }
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetStringifyAll(Name, Value) {
        if HasProp(this.StringifyAll, Name) {
            this.StringifyAll.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {Object} Obj - An object with options as nameerty : value pairs.
     */
    SetStringifyAllObj(Obj) {
        optStringifyAll := this.StringifyAll
        for name in TracerOptions.DefaultStringifyAll.OwnProps() {
            if HasProp(Obj, name) {
                optStringifyAll.%name% := Obj.%name%
            }
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetTracer(Name, Value) {
        if HasProp(this.Tracer, Name) {
            this.Tracer.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {String} Name - The option name.
     * @param {*} Value - The option value.
     */
    SetTracerGroup(Name, Value) {
        if HasProp(this.TracerGroup, Name) {
            this.TracerGroup.%Name% := Value
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * @param {Object} Obj - An object with options as nameerty : value pairs.
     */
    SetTracerGroupObj(Obj) {
        optTracerGroup := this.TracerGroup
        for name in TracerOptions.DefaultTracerGroup.OwnProps() {
            if HasProp(Obj, name) {
                optTracerGroup.%name% := Obj.%name%
            }
        }
    }
    /**
     * @param {Object} Obj - An object with options as nameerty : value pairs.
     */
    SetTracerObj(Obj) {
        optTracer := this.Tracer
        for name in TracerOptions.DefaultTracer.OwnProps() {
            if HasProp(Obj, name) {
                optTracer.%name% := Obj.%name%
            }
        }
    }

    HasValidLogFileOptions => this.LogFile && this.LogFile.Dir && this.LogFile.Name
}
