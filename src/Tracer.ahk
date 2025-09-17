/*
    Github: https://github.com/Nich-Cebolla/AutoHotkey-Tracer
    Author: Nich-Cebolla
    License: MIT
*/

; https://github.com/Nich-Cebolla/AutoHotkey-StringifyAll
; This is only necessary if your application will use Tracer to serialize object properties /
; items when writing to log file.
#include *i <StringifyAll>

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
     * @param {Integer} [FileAction = 1] - `FileAction` is ignored if `Options.LogFile.Dir` and/or
     * `Options.LogFile.Name` are not set. `FileAction` is also ignored if `Tools` is set.
     *
     * One of the following:
     * - 1 : Does not open the log file until `Tracer.Prototype.Log` is called. When the file is
     *       opened, it is opened with standard processing.
     * - 2 : Does not open the log file until `Tracer.Prototype.Log` is called. When the file is
     *       opened, a new file is created.
     * - 3 : Opens the log file immediately. When the file is opened, it is opened with standard
     *       processing.
     * - 4 : Creates and opens a new log file immediately.
     *
     * See the documentation section "Opening the log file" for a description of "standard processing."
     */
    __New(Id, Options?, Tools?, FileAction := 1) {
        this.Id := Id
        this.Options := Options ?? TracerOptions()
        if this.HistoryActive {
            this.History := []
        }
        if IsSet(Tools) {
            this.Tools := Tools
        } else {
            this.Tools := TracerTools(Options, FileAction)
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
    Close() {
        this.Tools.Close()
    }
    Log(Message := '', SnapshotObj?, Extra := '', What?) {
        if !this.Tools.LogFileOpen {
            this.Tools.GetLogFile()
        }
        if IsObject(this.Options.Log.ConditionCallback) {
            if !this.Options.Log.ConditionCallback.Call(this) {
                return 0
            }
        }
        if this.Options.Log.Critical {
            previousCritical := Critical(this.Options.Log.Critical)
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
        if this.Options.Log.Critical {
            Critical(previousCritical)
        }
        return unit
    }
    Open(NewFile := false) {
        this.Tools.Open(NewFile)
    }
    Out(Message := '', SnapshotObj?, Extra := '', What?) {
        if this.Options.Out.Critical {
            previousCritical := Critical(this.Options.Log.Critical)
        }
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
        if this.Options.Out.Critical {
            Critical(previousCritical)
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
    OwnOptions => this.Options.Tracer
    PathLog => this.Tools.LogFile.Path
}
