
#include ..\src\Tracer.ahk

test()

class test {
    static __New() {
        this.DeleteProp('__New')
        this.OptTracer := {
            Dir: A_Temp '\test-Tracer'
          , DefaultWhat: -2
          , Encoding: 'utf-8'
          , Ext: 'log'
          , HistoryActive: true
          , HistoryMaxItems: 2
          , HistoryReleaseRatio: 0.05
          , IndentLen: 4
          , LineEnding: '`n'
          , LogSnapshot: true
          , LogToJson: false
          , MaxFiles: 2
          , MaxSize: 0
          , Name: 'output'
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
        this.OptTracerGroup := {
            GroupOptions: this.OptTracer
          , GroupName: 'test-group'
          , HistoryActive: true
          , HistoryMaxItems: 2
          , HistoryReleaseRatio: 0.05
          , IdCallback: ''
          , UseGroup: true
        }
        this.SnapshotObj := {
            Prop: { Prop: 'value' }
          , Prop2: 'value'
          , Items: [ 1, 2, 3, {}, [], Map('key', 'value') ]
        }
        this.CreateDir()
    }
    static Call() {
        optTracer := this.OptTracer
        optGroup := this.OptTracerGroup
        group := this.group := TracerGroup(optGroup)

        t := this.t1 := group.Call()

        t.Log()
        t.Log('test1')
        _CheckHistory(t)
        t.Log('test2', this.SnapshotObj)
        _CheckHistory(t)
        t.Out('test3')
        _CheckHistory(t)
        t.Out('test4', this.SnapshotObj)

        t := group.Call()
        t := group.Call()
        _CheckHistory(group)

        lf := group.LogFile
        files := lf.CheckDir()
        _CheckFiles(files)
        group.SetOption('MaxSize', 1)
        lf.CheckFile()
        files := lf.CheckDir()
        _CheckFiles(files, 2)

        group.LogFileClose()

        optTracer.LogToJson := optTracer.OutputToJson := true
        group := this.group := TracerGroup(optGroup)
        t := group.Call()
        lf := group.LogFile
        if lf.Index != 1 {
            throw Error('lf.Index != 1', -1, lf.Index)
        }

        t.Log()
        t.Log('test1')
        _CheckHistory(t)
        t.Log('test2', this.SnapshotObj)
        _CheckHistory(t)
        t.Out('test3')
        _CheckHistory(t)
        t.Out('test4', this.SnapshotObj)

        lf.Close()
        lf.Open(1)
        lf.File.Close()
        if SubStr(FileRead(lf.GetPath(), lf.Encoding), -1, 1) !== '}' {
            throw Error('SubStr(FileRead(lf.GetPath(), lf.Encoding), -1, 1) !== "}"', -1, lf.Index)
        }
        path := lf.GetPath()
        lf.File := FileOpen(path, 'a', lf.Encoding)
        t.Log('test5', this.SnapshotObj)
        lf.Close()
        if SubStr(FileRead(lf.GetPath(), lf.Encoding), -1, 1) !== ']' {
            throw Error('SubStr(FileRead(lf.GetPath(), lf.Encoding), -1, 1) !== "}"', -1, lf.Index)
        }

        group.SetOption('MaxSize', 1)
        group.SetOption('MaxFiles', 3)
        lf.Open()
        t.Log()
        files := lf.CheckDir()
        _CheckFiles(files, 3)
        t.Log('test6', this.SnapshotObj)
        group.LogFileClose()

        sleep 1


        _CheckHistory(obj, n := 2) {
            if obj.History.Length !== n {
                throw Error('obj.History.Length !== ' n, -1, Type(obj))
            }
        }
        _CheckFiles(arr, n := 1) {
            if files.Length > n {
                throw Error('arr.Length !== ' n, -1)
            }
        }
    }
    static CreateDir() {
        if DirExist(this.dir) {
            DirDelete(this.dir, true)
        }
        DirCreate(this.dir)
        this.SetOnExit()
    }
    static OnExit(*) {
        this.group.LogFileClose()
        if DirExist(this.dir) {
            DirDelete(this.dir, true)
        }
    }
    static SetOnExit() {
        this.OnExitCallback := ObjBindMethod(this, 'OnExit')
        OnExit(this.OnExitCallback, 1)
    }

    static dir => this.OptTracer.Dir
    static path => this.group.constructor.prototype.logfile.file.GetPath()
}
