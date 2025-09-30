
class TracerUnit extends Error {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.Extra := proto.Message := proto.Options := proto.Snapshot := proto.Stack :=
        proto.Tools := proto.TracerId := proto.What := proto.__Indent := ''
    }
    GetSnapshot(Obj, InitialIndent := 0) {
        _options := { InitialIndent: InitialIndent }
        ObjSetBase(_options, this.Options.StringifyAll)
        this.Snapshot := StringifyAll(Obj, _options)
    }
    Log() {
        if this.Options.Log.ToJson {
            if this.Tools.LogFile.flag_newJsonFile {
                this.Tools.LogFile.File.Write('[')
                this.Tools.LogFile.flag_newJsonFile := false
            } else {
                this.Tools.LogFile.File.Pos -= this.Tools.LogFile.EndByteCount
                this.Tools.LogFile.File.Write(',')
            }
            this.Tools.LogFile.File.Write(this.Le this.Tools.FormatStrJsonLog.Call(this) this.Le ']' this.Le)
        } else {
            this.Tools.LogFile.File.Write(this.Tools.FormatStrLog.Call(this) this.Le)
        }
        this.Tools.LogFile.CheckFile()
    }
    LogL() {
        if this.Options.Log.ToJson {
            if this.Tools.LogFile.flag_newJsonFile {
                this.Tools.LogFile.File.Write('[')
                this.Tools.LogFile.flag_newJsonFile := false
            } else {
                this.Tools.LogFile.File.Pos -= this.Tools.LogFile.EndByteCount
                this.Tools.LogFile.File.Write(',')
            }
            this.Tools.LogFile.File.Write(this.Le this.Tools.LevelFormatJsonLog.Get(this.Level).Call(this) this.Le ']' this.Le)
        } else {
            this.Tools.LogFile.File.Write(this.Tools.LevelFormatLog.Get(this.Level).Call(this) this.Le)
        }
        this.Tools.LogFile.CheckFile()
    }
    Out() {
        if this.Options.Out.ToJson {
            OutputDebug(this.Tools.FormatStrJsonOut.Call(this) this.Le)
        } else {
            OutputDebug(this.Tools.FormatStrOut.Call(this) this.Le)
        }
    }
    OutL() {
        if this.Options.Out.ToJson {
            OutputDebug(this.Tools.LevelFormatJsonOut.Get(this.Level).Call(this) this.Le)
        } else {
            OutputDebug(this.Tools.LevelFormatOut.Get(this.Level).Call(this) this.Le)
        }
    }
    Ext {
        Get {
            SplitPath(this.File, , , &ext)
            return ext
        }
    }
    Id => (this.Options.TracerGroup.GroupName ? this.Options.TracerGroup.GroupName ':' : '') this.TracerId ':' this.UnitId
    FileName {
        Get {
            this.DefineProp('FileName', { Value: SubStr(this.File, InStr(this.File, '\', , , -1) + 1) })
            return this.FileName
        }
    }
    FileNameNoExt {
        Get {
            SplitPath(this.File, , , , &namenoext)
            return namenoext
        }
    }
    Le => this.Options.Tracer.LineEnding
    NiceTime => FormatTime(this.Time, this.Options.Tracer.TimeFormat)
    __FullId1 => this.Options.TracerGroup.GroupName ':' this.Tracerid ':' this.UnitId
    __FullId2 => this.TracerId ':' this.UnitId
    __FullId3 => this.Options.TracerGroup.GroupName ':' this.UnitId
    __FullId4 => this.UnitId
}
