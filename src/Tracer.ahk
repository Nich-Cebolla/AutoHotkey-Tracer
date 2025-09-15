
; https://github.com/Nich-Cebolla/AutoHotkey-StringifyAll
; This is only necessary if your application will use Tracer to serialize object properties /
; items when writing to log file.
#include *i <StringifyAll>

; This library is tested and is working, but usage is somewhat complex and I haven't written all
; of the documentation for it. Best to see "test\test-Tracer.ahk" for a usage example.

; Also check out "FillStr" which would pair nicely with this library
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/FillStr.ahk

; https://github.com/Nich-Cebolla/AutoHotkey-FormatStr
#include <FormatStr>

#include lib.ahk
#include TracerBase.ahk
#include TracerGroup.ahk
#include TracerLogFile.ahk
#include TracerOptions.ahk
#include TracerTools.ahk
#include TracerUnit.ahk


class Tracer extends TracerBase {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.Options := proto.Id := proto.Tools := proto.History :=
        proto.Index := ''
    }
    /**
     * @param {String} Id - A unique identifier.
     *
     * @param {TracerOptions|TracerOptionsInheritor} [Options] - The options object. See
     * {@link TracerOptions} and {@link TracerOptionsInheritor} for details about the available
     * options.
     *
     * @param {TracerTools} [Tools] - If set, the {@link TracerTools} object that this instance
     * of {@link Tracer} will use. If unset, a new {@link TracerTools} instance will be created
     * and set to property {@link Tracer#Tools}.
     *
     * @param {Boolean} [NewFile = false] - If true, forces {@link TracerLogFile} to open a new
     * file regardless of `Options.LogFile.MaxSize`.
     */
    __New(Id, Options?, Tools?, NewFile := false) {
        this.Id := Id
        this.Options := Options ?? TracerOptions()
        if this.HistoryActive {
            this.History := []
        }
        if IsSet(Tools) {
            this.Tools := Tools
        } else {
            this.Tools := TracerTools(Options, NewFile)
        }
        this.Index := 0
        this.Prototype := {
            Options: Options
          , Tools: this.Tools
          , TracerId: Id
          , __Class: TracerUnit.Prototype.__Class
        }
        if this.GroupName {
            this.Prototype.DefineProp('Id', TracerUnit.Prototype.GetOwnPropDesc('__FullId1'))
        } else {
            this.Prototype.DefineProp('Id', TracerUnit.Prototype.GetOwnPropDesc('__FullId2'))
        }
        ObjSetBase(this.Prototype, TracerUnit.Prototype)
    }
    Log(Message := '', SnapshotObj?, Extra := '', What?) {
        if !this.Tools.LogFileOpen {
            flag_onExitStarted := this.Tools.LogFile.__OnExitStarted
            this.Tools.GetLogFile()
            this.Tools.LogFile.__OnExitStarted := flag_onExitStarted
        }
        if IsObject(this.Options.Log.ConditionCallback) {
            if !this.Options.Log.ConditionCallback.Call(this) {
                return 0
            }
        }
        unit := Error(Message, What ?? this.DefaultWhat, Extra)
        unit.Time := A_Now
        ObjSetBase(unit, this.Prototype)
        if IsSet(SnapshotObj) {
            if this.Options.Log.ToJson {
                unit.GetSnapshot(SnapshotObj, 2)
            } else {
                unit.GetSnapshot(SnapshotObj, 0)
            }
        }
        unit.UnitId := this.IdCallback.Call(this)
        unit.Log()
        if this.HistoryActive {
            this.HistoryAdd(unit)
        }
        if this.Tools.LogFile.__OnExitStarted {
            this.Tools.LogFile.Close()
        }
        return unit
    }
    Out(Message := '', SnapshotObj?, Extra := '', What?) {
        if IsObject(this.Options.Out.ConditionCallback) {
            if !this.Options.Out.ConditionCallback.Call(this) {
                return 0
            }
        }
        unit := Error(Message, What ?? this.DefaultWhat, Extra)
        unit.Time := A_Now
        ObjSetBase(unit, this.Prototype)
        if IsSet(SnapshotObj) {
            if this.Options.Out.ToJson {
                unit.GetSnapshot(SnapshotObj, 2)
            } else {
                unit.GetSnapshot(SnapshotObj, 0)
            }
        }
        unit.UnitId := this.IdCallback.Call(this)
        unit.Out()
        if this.HistoryActive {
            this.HistoryAdd(unit)
        }
        return unit
    }

    DefaultWhat {
        Get => this.Options.Tracer.DefaultWhat
        Set => this.Options.Tracer.DefaultWhat := Value
    }
    IdCallback {
        Get => this.Options.Tracer.IdCallback
        Set => this.Options.Tracer.IdCallback := Value
    }
    GroupName => this.Options.TracerGroup.GroupName
    PathLog => this.Tools.LogFile.Path
}
