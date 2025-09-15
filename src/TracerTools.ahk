
class TracerTools extends TracerToolsBase {
    /**
     * @param {TracerOptions} Options - The {@link TracerOptions} object.
     * @param {Boolean} [NewFile = false] - If true, forces {@link TracerLogFile} to open a new
     * file regardless of `Options.LogFile.MaxSize`.
     */
    __New(Options, NewFile := false) {
        this.Options := Options
        this.GetFormatStrConstructor()
        if Options.HasValidLogFileOptions {
            this.GetLogFile(, , NewFile)
        }
        this.SetIndentLen(Options.Tracer.IndentLen)
        this.SetJsonPropertiesLog()
        this.SetJsonPropertiesOut()
    }
}

class TracerToolsInheritor extends TracerToolsBase {
    __New(TracerToolsObj, Options) {
        ObjSetBase(this, TracerToolsObj)
        this.Options := Options
        ObjSetBase(this.Options, TracerToolsObj.Options)
        if IsObject(this.LogFile) {
            this.LogFile := { Options: Options }
            ObjSetBase(this.LogFile, TracerToolsObj.LogFile)
        }
        for toolName in [ 'FormatStrConstructor', 'FormatStrLog', 'FormatStrOut', 'Indent' ] {
            if IsObject(TracerToolsObj.%toolName%) {
                if tracerToolsObj.%toolName% is Array {
                    this.%toolName% := []
                } else {
                    this.%toolName% := { }
                }
                ObjSetBase(this.%toolName%, tracerToolsObj.%toolName%)
            }
        }
    }
}

class TracerToolsBase {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.LogFile := proto.FormatStrConstructor := proto.FormatStrOut := proto.FormatStrLog := proto.Indent := ''
    }
    GetFormatStrConstructor() {
        this.FormatStrConstructor := FormatStrConstructor(this.Options.FormatStr.FormatSpecifierNames, this.Options.FormatStr)
        if this.Options.HasValidLogFileOptions {
            this.FormatStrLog := this.FormatStrConstructor.Call(this.Options.Log.Format)
        }
        this.FormatStrOut := this.FormatStrConstructor.Call(this.Options.Out.Format)
    }
    GetFormatStrLog() {
        if this.Options.HasValidLogFileOptions {
            this.FormatStrLog := this.FormatStrConstructor.Call(this.Options.Log.Format)
        } else {
            Tracer_ThrowInvalidLogFileOptions()
        }
    }
    GetFormatStrOut() {
        this.FormatStrOut := this.FormatStrConstructor.Call(this.Options.Out.Format)
    }
    GetLogFile(Dir?, Name?, NewFile := false) {
        if IsSet(Dir) {
            this.Options.LogFile.Dir := Dir
        }
        if IsSet(Name) {
            this.Options.LogFile.Name := Name
        }
        if !this.Options.HasValidLogFileOptions {
            Tracer_ThrowInvalidLogFileOptions()
        }
        if this.LogFile {
            this.LogFile.Close()
        }
        this.LogFile := TracerLogFile(this.Options, NewFile)
        this.GetFormatStrLog()
    }
    SetIndentLen(IndentLen) {
        this.Options.Tracer.IndentLen := IndentLen
        this.Indent := Tracer_IndentHelper(IndentLen)
    }
    SetJsonPropertiesLog(JsonProperties?) {
        if IsSet(JsonProperties) {
            this.Options.Log.JsonProperties := JsonProperties
        }
        this.JsonPropertiesLog := Tracer_GetJsonPropertiesFormatString(this.Options.Log.JsonProperties, this.IndentLen, 1)
        this.FormatStrJsonLog := this.FormatStrConstructor.Call(this.JsonPropertiesLog)
    }
    SetJsonPropertiesOut(JsonProperties?) {
        if IsSet(JsonProperties) {
            this.Options.Out.JsonProperties := JsonProperties
        }
        this.JsonPropertiesOut := Tracer_GetJsonPropertiesFormatString(this.Options.Out.JsonProperties, this.IndentLen, 0)
        this.FormatStrJsonOut := this.FormatStrConstructor.Call(this.JsonPropertiesOut)
    }

    IndentLen {
        Get => this.Options.Tracer.IndentLen
        Set => this.SetIndentLen(Value)
    }
    LogFileOpen => IsObject(this.LogFile.File)
}

class Tracer_IndentHelper extends Array {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.__IndentLen := ''
        proto.DefineProp('ItemHelper', { Call: Array.Prototype.GetOwnPropDesc('__Item').Get })
    }
    __New(IndentLen, IndentChar := '`s') {
        this.__IndentChar := IndentChar
        this.SetIndentLen(IndentLen)
    }
    Expand(Index) {
        s := this[1]
        loop Index - this.Length {
            this.Push(this[-1] s)
        }
    }
    Initialize() {
        c := this.__IndentChar
        this.Length := 1
        s := ''
        loop this.__IndentLen {
            s .= c
        }
        this[1] := s
        this.Expand(4)
    }
    SetIndentChar(IndentChar) {
        this.__IndentChar := IndentChar
        this.Initialize()
    }
    SetIndentLen(IndentLen) {
        this.__IndentLen := IndentLen
        this.Initialize()
    }

    __Item[Index] {
        Get {
            if Index {
                if Abs(Index) > this.Length {
                    this.Expand(Abs(Index))
                }
                return this.ItemHelper(Index)
            } else {
                return ''
            }
        }
    }
    IndentChar {
        Get => this.__IndentChar
        Set => this.SetIndentChar(Value)
    }
    IndentLen {
        Get => this.__IndentLen
        Set => this.SetIndentLen(Value)
    }
}
