
#include ..\src\Tracer.ahk
#include <QuickParse>

class CustomErrorWindow {
    static __New() {
        this.DeleteProp('__New')
        this.DefaultFormatSpecifierNames := [ 'extra', 'file', 'le', 'line', 'message', 'stack', 'what' ]
        this.DefaultFormat := (
            '{Message: {%message%}%le%}'
            'File: %file% : %line%%le%'
            '{What: {%what%}%le%}'
            '{Extra: {%extra%}%le%}'
            '{Stack:%le%{%stack%}%le%}'
        )
        proto := this.Prototype
        proto.FormatStrConstructor := FormatStrConstructor(this.DefaultFormatSpecifierNames, { Callback: Tracer_FormatStrCallback })
        proto.FormatStr := proto.FormatStrConstructor.Call(this.DefaultFormat)
    }
    __New(err, expected, actual) {
        g := this.g := Gui('+Resize')
        g.SetFont('s11 q5')
        g.Add('Edit', 'w600 +HScroll -wrap', RegExReplace(this.FormatStr.Call(err), '\R', '`r`n'))
        labels := [ 'Expected', 'Actual' ]
        g.Add('Text', 'w600', 'Expected')
        g.Add('Edit', 'w600 r15 +HScroll -wrap', RegExReplace(expected, '\R', '`r`n'))
        g.Add('Text', 'w600', 'Actual')
        g.Add('Edit', 'w600 r15 +HScroll -wrap', RegExReplace(actual, '\R', '`r`n'))
        g.Add('Button', , 'Exit').OnEvent('Click', (*) => ExitApp())
        g.Show()
        sleep 1
    }
}
path := A_Args[1]
obj := QuickParse(FileRead(path, 'utf-8'))
FileDelete(path)
CustomErrorWindow(obj.Error, obj.Expected, obj.Actual)
