
#include ..\src\Tracer.ahk

test_Levels()

class test_Levels {
    static __New() {
        this.DeleteProp('__New')
        this.Dir := A_Temp '\Tracer'
    }
    static Call() {
        OutputDebug('============Readme==================`n')
        this.ReadmeExample()
        OutputDebug('============Json==================`n')
        this.Json()
        if DirExist(this.Dir) {
            DirDelete(this.Dir, 1)
        }
    }
    static Json() {
        options := {
            Log: { ToJson: true }
          , LogFile: { Dir: this.Dir, Name: 'example' }
          , Out: {
                ToJson: true
              , LevelJsonProperties: Map(
                    'debug', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message', 'extra', 'stack', 'snapshot' ]
                  , 'error', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message', 'extra', 'stack', 'snapshot' ]
                  , 'warn', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message' ]
                )
            }
        }
        t := Tracer(, options, , 2)
        t.LogL('info', 'info message')
        t.LogL('error', 'error message', { prop: 'val' })
        t.OutL('debug', 'debug message')
        t.OutL('error', 'error message', options)
        t.BothL('warn', 'warn message')
        t.Tools.LogFile.Close()
        content := FileRead(t.Tools.LogFile.Path, t.Options.LogFile.Encoding)
        OutputDebug(content '`n')
    }
    static ReadmeExample() {
        options := {
            Log: {
                DefaultLevel: 'warn'
              , LevelFormat: Map(
                    'debug', (
                        'Level: %level%%le%'
                        '{Log id: {%id%}%le%}'
                        '{Timestamp: {%time%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                        '{Extra: {%extra%}%le%}'
                        'Stack: %stack%%le%'
                        '{Snapshot:%le%{%snapshot%}%le%}'
                    )
                  , 'info', (
                        '{Log id: {%id%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                    )
                  , 'warn', (
                        'Level: %level%%le%'
                        '{Log id: {%id%}%le%}'
                        '{Timestamp: {%time%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                    )
                  , 'error', (
                        'Level: %level%%le%'
                        '{Log id: {%id%}%le%}'
                        '{Timestamp: {%time%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                        '{Extra: {%extra%}%le%}'
                        'Stack: %stack%%le%'
                        '{Snapshot:%le%{%snapshot%}%le%}'
                    )
                  , 'fatal', (
                        'Level: %level%%le%'
                        '{Log id: {%id%}%le%}'
                        '{Timestamp: {%time%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                        '{Extra: {%extra%}%le%}'
                        'Stack: %stack%%le%'
                        '{Snapshot:%le%{%snapshot%}%le%}'
                    )
                )
              , LevelJsonProperties: Map(
                    'debug', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message', 'extra', 'stack', 'snapshot' ]
                  , 'info', [ 'id', 'nicetime', 'filename', 'line', 'what', 'message' ]
                  , 'warn', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message' ]
                  , 'error', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message', 'extra', 'stack', 'snapshot' ]
                  , 'fatal', [ 'level', 'id', 'time', 'nicetime', 'filename', 'line', 'what', 'message', 'extra', 'stack', 'snapshot' ]
                )
            }
          , Out: {
                DefaultLevel: 'warn'
              , LevelFormat: Map(
                    'info', (
                        '{Log id: {%id%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                    )
                  , 'warn', (
                        'Level: %level%%le%'
                        '{Log id: {%id%}%le%}'
                        '{Timestamp: {%time%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                    )
                  , 'error', (
                        'Level: %level%%le%'
                        '{Log id: {%id%}%le%}'
                        '{Timestamp: {%time%}%le%}'
                        '{Time: {%nicetime%}%le%}'
                        'File: %filename% : %line%%le%'
                        '{What: {%what%}%le%}'
                        '{Message: {%message%}%le%}'
                        '{Extra: {%extra%}%le%}'
                    )
                )
            }
        }
        options.LogFile := { Dir: this.Dir, Name: 'example' }
        t := Tracer(, options, , 2)
        t.OutL(, 'my message to send to OutputDebug') ; Uses `Options.Out.DefaultLevel`
        t.LogL('info', 'my message to log') ; Uses 'info'
        t.BothL(, 'my message for both outputs') ; Uses the appropriate default for both Log and Out output.
        obj := options.Out
        t.LogL('error', , obj)
        t.Tools.LogFile.Close()
        content := FileRead(t.Tools.LogFile.Path, t.Options.LogFile.Encoding)
        OutputDebug(content '`n')
    }
}
