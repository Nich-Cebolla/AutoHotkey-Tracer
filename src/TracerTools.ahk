
class TracerTools {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.LogFile := proto.FormatStrConstructor := proto.FormatStrOut := proto.FormatStrLog :=
        proto.Indent := proto.flag_fileAction := ''
    }
    /**
     * @param {TracerOptions} Options - The {@link TracerOptions} object.
     *
     * @param {Integer} [FileAction = 1] - One of the following:
     * - 1 : Does not open the log file until `Tracer.Prototype.Log` is called. When the file is
     *       opened, it is opened with standard processing.
     * - 2 : Does not open the log file until `Tracer.Prototype.Log` is called. When the file is
     *       opened, a new file is created.
     * - 3 : Opens the log file immediately. When the file is opened, it is opened with standard
     *       processing.
     * - 4 : Creates and opens a new log file immediately.
     *
     * See the documentation section "Opening the log file" for a description of "standard processing."
     *
     * `FileAction` is ignored if `Options.LogFile.Dir` and/or `Options.LogFile.Name` are not set.
     */
    __New(Options, FileAction := 1) {
        this.Options := Options
        this.GetFormatStrConstructor()
        this.flag_fileAction := FileAction
        if Options.HasValidLogFileOptions {
            switch FileAction, 0 {
                case 1, 2: ; do nothing
                case 3, 4: this.GetLogFile()
                default: throw ValueError('Unexpected value of ``FileAction``.', -1, FileAction)
            }
        }
        this.SetIndentLen(Options.Tracer.IndentLen)
        this.SetJsonPropertiesLog()
        this.SetJsonPropertiesOut()
    }
    Close() {
        this.LogFile.Close()
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
    /**
     * @param {String} [Dir] - The name of the directory. Setting `Dir` overwrites the value of
     * `Options.LogFile.Dir`.
     *
     * @param {String} [Name] - The name of the directory. Setting `Name` overwrites the value of
     * `Options.LogFile.Name`.
     */
    GetLogFile(Dir?, Name?) {
        if IsSet(Dir) {
            this.Options.LogFile.Dir := Dir
        }
        if IsSet(Name) {
            this.Options.LogFile.Name := Name
        }
        if !this.Options.HasValidLogFileOptions {
            Tracer_ThrowInvalidLogFileOptions()
        }
        this.LogFile := TracerLogFile(this.Options, this.flag_fileAction = 2 || this.flag_fileAction = 4)
        this.flag_fileAction := 0
        this.GetFormatStrLog()
    }
    Open(NewFile := false) {
        if IsObject(this.LogFile) {
            if IsObject(this.LogFile.File) {
                this.LogFile.Close()
            }
        }
        this.LogFile := TracerLogFile(this.Options, NewFile)
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
    LogFileOpen => IsObject(this.LogFile) && IsObject(this.LogFile.File)
}

class Tracer_IndentHelper extends Array {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.__IndentLen := proto.FileAction := ''
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
