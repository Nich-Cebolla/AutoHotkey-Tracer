
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
 *
 * When you pass the options object to {@link TracerGroup}, the {@link TracerGroup} object
 * maintains a reference to the original instance of {@link TracerOptions}. When you call a function
 * to change an option at the group level, the value of the relevant property is changed on the
 * original object.
 *
 * When you call {@link TracerGroup.Prototype.Call} to get an instance of {@link Tracer}, the
 * {@link Tracer} object gets a reference to an object which inherits from the original {@link TracerGroup}.
 * When you call a method to update an option from the {@link Tracer} object, the value is updated
 * on the object which inherits from the original, not on the original itself. This creates the
 * needed separation to facilitate the use of both group-level options and individual-level options.
 *
 * The root options object is a container for a number of other options objects. The inheritance
 * logic accounts for this by replicating the structure of the root object where each property is set
 * with a plain object that inherits from the associated child object from the original.
 *
 * The following is a simplification of the process for illustration purposes.
 *
 * @example
 *  originalOptions := {
 *      TracerGroup: {
 *          HistoryActive: false
 *      }
 *    , LogFile: {
 *          MaxFiles: 10
 *        , Dir: 'tracer'
 *      }
 *  }
 *
 *  inheritor := {
 *      TracerGroup: {}
 *    , LogFile: {}
 *  }
 *
 *  ObjSetBase(inheritor.TracerGroup, originalOptions.TracerGroup)
 *  ObjSetBase(inheritor.LogFile, originalOptions.LogFile)
 * @
 *
 * The root object does not actually inherit from the original; the child objects inherit from the
 * original's child objects.
 */
class TracerOptions extends TracerOptionsBase {
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
        this.DefaultOutFormat := '{%id% : }%filename%::%line%{ : %what%}{ : %message%}'
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
          , Format: this.DefaultLogFormat
          , ToJson: false
          , JsonProperties: this.DefaultJsonProperties
        }
        this.DefaultLogFile := {
            Dir: ''
          , Encoding: 'utf-8'
          , Ext: ''
          , MaxFiles: 0
          , MaxSize: 0
          , Name: ''
          , SetOnExit: true
        }
        this.DefaultOut := {
            ConditionCallback: ''
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
     * {@link TracerGroup#Tools.GetLogFile} or {@link Tracer#Tools.GetLogFile} depending if
     * you want it opened at the group level or individual level.
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
     * @param {Boolean} [Options.LogFile.SetOnExit = true] - If true, every time a file is opened by
     * {@link TracerLogFile}, an `OnExit` callback is set which will close the log file if it is
     * still open at the time the script exits.
     *
     * ## Options.Out
     *
     * @param {Object} [Options.Out] - An options object specifying options related to
     * {@link Tracer.Prototype.Out}, which is used to write text to `OutputDebug`.
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
     * Returns an object with properties { FormatStr, Log, LogFile, Out, StringifyAll, Tracer, TracerGroup }.
     * Each property is set with an object with 0 own properties, and those blank objects have their base
     * set to associated options object from this {@link TracerGroup} instance.
     *
     * For those still learning about AutoHotkey's object model, this means that all of the properties
     * from this {@link TracerGroup} instance and its nested objects are also accessible from the
     * returned object. Additionally, those poperties can be overridden without affecting this
     * original object. This is how {@link TracerGroup} and {@link Tracer} facilitates the ability
     * to set options at the group- and individual-level.
     *
     * @example
     *  MyOptions := TracerOptions({ Tracer: { HistoryActive: true } })
     *  OutputDebug(MyOptions.Tracer.HistoryActive "`n") ; 1
     *  inheritor := MyOptions.GetInheritor()
     *  OutputDebug(inheritor.Tracer.HistoryActive "`n") ; 1
     *  inheritor.SetTracer("HistoryActive", false)
     *  OutputDebug(inheritor.Tracer.HistoryActive "`n") ; 0
     *  ; The original is unaffected
     *  OutputDebug(MyOptions.Tracer.HistoryActive "`n") ; 1
     *  inheritor.Tracer.DeleteProp("HistoryActive")
     *  ; Even though we deleted the property, only the own property
     *  ; was deleted, so the base object's property is still
     *  ; there, unchanged.
     *  OutputDebug(inheritor.Tracer.HistoryActive "`n") ; 1
     * @
     *
     * Keep in mind that if an option is an object, and if you change a property value for
     * that option on the inheritor, that change IS reflected on the original. Currently, only
     * `Options.StringifyAll` has any properties that are objects.
     *
     * @example
     *  MyOptions := TracerOptions({ StringifyAll: { PropsTypeMap: Tracer_MapHelper(false, 1) } })
     *  OutputDebug(MyOptions.StringifyAll.PropsTypeMap.Count "`n") ; 0
     *  inheritor := MyOptions.GetInheritor()
     *  OutputDebug(inheritor.StringifyAll.PropsTypeMap.Count "`n") ; 0
     *  inheritor.StringifyAll.PropsTypeMap.Set("Array", 0)
     *  ; Now the count is 1
     *  OutputDebug(inheritor.StringifyAll.PropsTypeMap.Count "`n") ; 1
     *  ; The original is also effected, because `inheritor.StringifyAll` inherits the
     *  ; property values from `MyOptions.StringifyAll`, so when I access
     *  ; properties from either object, I'm accessing the same value.
     *  OutputDebug(MyOptions.StringifyAll.PropsTypeMap.Count "`n") ; 1
     * @
     *
     * @returns {TracerOptionsInheritor}
     */
    GetInheritor() {
        return TracerOptionsInheritor(this)
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
}

class TracerOptionsInheritor extends TracerOptionsBase {
    __New(TracerOptionsObj) {
        for optCategory in TracerOptions.DefaultOptions.OwnProps() {
            ObjSetBase(this.%optCategory% := {}, TracerOptionsObj.%optCategory%)
        }
    }
    /**
     * Deletes all own properties for the options object for the indicated category.
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
        obj := this.%OptCategory%
        list := []
        list.Capacity := ObjOwnPropCount(obj)
        for name in obj.OwnProps() {
            list.Push(name)
        }
        for name in list {
            obj.DeleteProp(name)
        }
    }
}

class TracerOptionsBase {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.FormatStr := proto.Log := proto.LogFile := proto.Out := proto.StringifyAll :=
        proto.Tracer := proto.TracerGroup := ''
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
