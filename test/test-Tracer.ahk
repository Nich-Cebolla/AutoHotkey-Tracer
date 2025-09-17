
#include ..\src\Tracer.ahk

test()

class test {
    static __New() {
        this.DeleteProp('__New')
        this.Dir := A_Temp '\tracer'
        this.FileName := 'tracer'
        error.prototype.le := '`r`n'
    }
    static Call() {
        this.CreateDir()
        this.Results := Map()

        ; Only default options
        this.DefaultOnly1()

        ; Starts with only default options then adjusts from there
        ; Verifies that calling `TracerObj.Tools.GetLogFile()` correctly opens the log file at
        ; the individual-level, and verifies that `TraverGroupObj.Tools.GetLogFile()` correctly
        ; opens the log file at the group level.
        this.DefaultOnly2()

        ; Verifies that `Options.Log.ToJson` and `Options.Out.ToJson` correctly influence the
        ; output.
        ; Verifies that the methods for opening, closing, and adding to a json log file
        ; correctly adds commas and brackets where needed.
        ; Also verifies history works for group and tracer objects
        this.Json1()

        ; Verifies `Options.LogFile.MaxFiles` and `Options.LogFile.MaxSize` works
        this.LogMax()

        ; Verifies `Options.Out.ToJson` works
        ; Verifies snapshot works
        this.Json2()
    }
    static DefaultOnly1() {
        result := {}
        this.Results.Set(A_ThisFunc, result)

        ; Get options
        opt := result.opt := TracerOptions()
        ; Get group object
        group := result.group := TracerGroup(opt)
        ; Get tracer object
        t := result.t := group()

        line := A_LineNumber + 2
        ; Call "Out"
        unit := result.unit := t.Out()

        ; Validate
        str := unit.Tools.FormatStrOut.Call(unit)
        expected := '1:1 : ' A_ScriptName '::' line ' : ' t.Out.Name
        if str != expected {
            throw Error('Incorrect string.', -1, 'Expected: ' expected '; Result: ' str)
        }
    }
    static DefaultOnly2() {
        result := { tracers: [], units: [] }
        this.Results.Set(A_ThisFunc, result)

        ; Get options
        opt := result.opt := TracerOptions()
        ; Get group object
        group := result.group := TracerGroup(opt)
        ; Get tracer object
        t := group()
        result.tracers.push(t)

        ; This should fail because we have not supplied `Options.LogFile.Dir` or `Options.LogFile.Name`.
        flag := false
        try {
            t.Log()
            flag := true
        }
        if flag {
            throw Error('Error expected.', -1)
        }

        ; Create `TracerLogFile`
        t.Tools.GetLogFile(this.Dir, this.FileName)

        line := A_LineNumber + 2
        ; Output
        unit := t.Log()
        result.units.Push(unit)

        ; Validate
        lf := t.Tools.LogFile
        f := lf.File
        f.Pos := lf.StartByte
        str := f.Read()
        lf.Close()
        expected := Format('
        (
            Log id: 1:1
            Timestamp: {1}
            Time: {2}
            File: {3} : {4}
            What: {5}


        )', unit.time, unit.nicetime, A_ScriptName, line, t.Log.Name)
        if str != expected {
            CustomErrorWindow(Error('Incorrect string.', -1), 'Expected:`r`n' expected, 'Result:`r`n' str)
        }

        ; Get another tracer object
        t := group()
        result.tracers.Push(t)

        line := A_LineNumber + 2
        ; Output
        unit := t.Log()
        result.units.Push(unit)

        ; Validate
        lf := t.Tools.LogFile
        f := lf.File
        f.Pos := lf.StartByte
        str := f.Read()
        f.Close()

        expected .= Format('
        (
            Log id: 2:1
            Timestamp: {1}
            Time: {2}
            File: {3} : {4}
            What: {5}


        )', unit.time, unit.nicetime, A_ScriptName, line, t.Log.Name)
        if str != expected {
            CustomErrorWindow(Error('Incorrect string.', -1), 'Expected:`r`n' expected, 'Result:`r`n' str)
        }
    }

    static Json1() {
        result := { tracers: [], units: [] }
        this.Results.Set(A_ThisFunc, result)

        ; Get options
        opt := result.opt := TracerOptions({
            Log: {
                ToJson: true
            }
          , LogFile: {
                Dir: this.Dir
              , Name: this.Filename
            }
          , Tracer: {
                HistoryActive: true
            }
          , TracerGroup: {
                HistoryActive: true
            }
        })
        ; Get group object
        group := result.group := TracerGroup(opt)
        ; Get tracer object
        t := group()
        expected := 1
        if group.History.Length !== expected {
            throw Error('Invalid number of history items.', -1, 'Expected: ' expected '; Actual: ' group.History.Length)
        }

        message := 'error'
        line := A_LineNumber + 2
        ; Output
        unit := t.Log(message)
        if t.History.Length !== expected {
            throw Error('Invalid number of history items.', -1, 'Expected: ' expected '; Actual: ' t.History.Length)
        }

        ; Validate
        lf := t.Tools.LogFile
        lf.Close()
        str := FileRead(lf.Path, lf.Encoding)
        ValidateJson(str)
        expected := Format('
        (
            [
                {
                    "Id": "1:1"
                    "File": "{1}"
                    "Line": "{2}"
                    "Message": "{3}"
                    "NiceTime": "{4}"
                    "Stack": "{5}"
                    "Time": "{6}"
                    "What": "{7}"
                }
            ]

        )'
        , Tracer_FormatStr_EscapeJson(A_ScriptFullPath)
        , line
        , message
        , unit.nicetime
        , Tracer_FormatStr_EscapeJson(unit.stack)
        , unit.time
        , t.Log.Name
        )

        if str != expected {
            CustomErrorWindow(Error('Incorrect string.', -1), 'Expected:`r`n' expected, 'Result:`r`n' str)
        }

        line := A_LineNumber + 2
        ; Output
        unit := t.Log(message)
        if t.History.Length !== 2 {
            throw Error('Invalid number of history items.', -1, 'Expected: 2; Actual: ' t.History.Length)
        }

        ; Validate
        lf := t.Tools.LogFile
        lf.Close()
        str := FileRead(lf.Path, lf.Encoding)
        ValidateJson(str)
        expected := SubStr(expected, 1, InStr(expected, '}', , , -1))
        expected .= Format('
        (
            ,
                {
                    "Id": "1:2"
                    "File": "{1}"
                    "Line": "{2}"
                    "Message": "{3}"
                    "NiceTime": "{4}"
                    "Stack": "{5}"
                    "Time": "{6}"
                    "What": "{7}"
                }
            ]

        )'
        , Tracer_FormatStr_EscapeJson(A_ScriptFullPath)
        , line
        , message
        , unit.nicetime
        , Tracer_FormatStr_EscapeJson(unit.stack)
        , unit.time
        , t.Log.Name
        )

        if str != expected {
            CustomErrorWindow(Error('Incorrect string.', -1), 'Expected:`r`n' expected, 'Result:`r`n' str)
        }

        ; Get another tracer obj
        t := group()
        if group.History.Length !== 2 {
            throw Error('Invalid number of history items.', -1, 'Expected: 2; Actual: ' group.History.Length)
        }
    }
    static LogMax() {
        result := { tracers: [], units: [] }
        this.Results.Set(A_ThisFunc, result)

        ; Get options
        opt := result.opt := TracerOptions({
            Log: {
                ToJson: true
            }
          , LogFile: {
                Dir: this.Dir
              , Name: this.Filename
              , MaxFiles: 2
              , MaxSize: 1
            }
        })
        ; Get group object
        group := result.group := TracerGroup(opt)
        ; Get tracer object
        t := group()

        t.Log('test1')
        _CheckFiles(t, 2)
        t.Log('test2')
        _CheckFiles(t, 2)
        t.SetOption('LogFile', 'MaxFiles', 3)
        t.Log('test3')
        _CheckFiles(t, 3)
        t.SetOption('LogFile', 'MaxSize', 100000)
        t.Log('test4')
        t.Log('test5')
        t.Log('test6')
        _CheckFiles(t, 3)
        t.SetOption('LogFile', 'MaxSize', 1)
        t.SetOption('LogFile', 'MaxFiles', 2)
        t.Log('test7')
        _CheckFiles(t, 2)

        _CheckFiles(t, n) {
            files := t.Tools.LogFile.GetFiles()
            if files.Length !== n {
                throw Error('Incorrect number of files.', -1, 'Expected: ' n '; Actual: ' files.Length)
            }
        }

    }
    static Json2() {
        result := { tracers: [], units: [] }
        this.Results.Set(A_ThisFunc, result)

        ; Get options
        options := TracerOptions({
            Out: {
                ToJson: true
              , Snapshot: true
            }
          , LogFile: {
                Dir: this.Dir
              , Name: this.filename
            }
          , Log: {
                ToJson: true
              , Snapshot: true
            }
        })

        snapshotObj := this.snapshotObj := {
            Prop: Map('key', [ 'array val 1', 'array val2', { prop: { prop: 'val' } } ] )
          , prop2: { array: [ Map(), [], {} ] }
        }

        ; Get group
        group := TracerGroup(options)

        ; Get tracer
        t := group()

        ; Write to log. I'm just going to verify this visually for now
        t.Log('error', snapshotObj)
        t.Tools.LogFile.Close()
        OutputDebug(FileRead(t.Tools.LogFile.path, t.Tools.LogFile.Encoding) '`n')

        t.SetOption('Log', 'ToJson', false)
        t.Log('error', snapshotObj)
        t.Tools.LogFile.Close()
        OutputDebug(FileRead(t.Tools.LogFile.path, t.Tools.LogFile.Encoding) '`n')

        ; Write out
        t.Out('error')
        t.Out('error', snapshotObj)
        t.SetOption('Out', 'ToJson', false)
        t.SetOption('Out', 'Format', '{%id% : }%filename%::%line%{ : %what%}{ : %message%}{%le%{%snapshot%}}')
        t.Out('error', snapshotObj)
        t.Out('error')
    }

    static CreateDir() {
        if DirExist(this.dir) {
            DirDelete(this.dir, true)
        }
        DirCreate(this.dir)
        this.SetOnExit()
    }
    static OnExit(*) {
        if DirExist(this.dir) {
            DirDelete(this.dir, true)
        }
    }
    static SetOnExit() {
        this.OnExitCallback := ObjBindMethod(this, 'OnExit')
        OnExit(this.OnExitCallback, 1)
    }
}

CustomErrorWindow(err, expected, actual) {
    path := A_Temp '\tracer-error-window.json'
    obj := { Error: err, expected: expected, actual: actual }
    f := FileOpen(path, 'w', 'utf-8')
    f.Write(StringifyAll(
        obj
        , {
            PropsTypeMap: Map('Error', '-Error', 'Object', '-Object', 'Array', '-Array')
          , EnumTypeMap: 1
        }
    ))
    f.Close()
    command := '"' A_AhkPath '" CustomErrorWindow.ahk "' path '"'
    Run(command)

}

/*
    Github: https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/ValidateJson.ahk
    Author: Nich-Cebolla
    Version: 1.0.0
    License: MIT
*/

class ValidateJson {

    /**
     * @description - Validates a JSON string.
     * @param {String} [Str] - The string to parse.
     * @param {String} [Path] - The path to the file that contains the JSON content to parse.
     * @param {String} [Encoding] - The file encoding to use if calling `ValidateJson` with `Path`.
     */
    static Call(Str?, Path?, Encoding?) {
        ;@region Initialization
        static ArrayItem := ValidateJson.Patterns.ArrayItem
        , ObjectPropName := ValidateJson.Patterns.ObjectPropName
        , ArrayNumber := ValidateJson.Patterns.ArrayNumber
        , ArrayString := ValidateJson.Patterns.ArrayString
        , ArrayFalse := ValidateJson.Patterns.ArrayFalse
        , ArrayTrue := ValidateJson.Patterns.ArrayTrue
        , ArrayNull := ValidateJson.Patterns.ArrayNull
        , ArrayNextChar := ValidateJson.Patterns.ArrayNextChar
        , ObjectNumber := ValidateJson.Patterns.ObjectNumber
        , ObjectString := ValidateJson.Patterns.ObjectString
        , ObjectFalse := ValidateJson.Patterns.ObjectFalse
        , ObjectTrue := ValidateJson.Patterns.ObjectTrue
        , ObjectNull := ValidateJson.Patterns.ObjectNull
        , ObjectNextChar := ValidateJson.Patterns.ObjectNextChar
        , ObjectInitialCheck := ValidateJson.Patterns.ObjectInitialCheck

        if !IsSet(Str) {
            If IsSet(Path) {
                Str := FileRead(Path, Encoding ?? unset)
            } else {
                Str := A_Clipboard
            }
        }
        Str := Trim(Str, '`r`n`s`t')

        if RegExMatch(Str, '[[{]', &Match) {
            if Match.Pos !== 1 {
                return Error('The first non-whitespace character is not an open bracket.', -1)
            }
        } else {
            return Error('The string is missing an open brace.', -1)
        }
        if Match[0] == '[' {
            Pattern := ArrayItem
        } else {
            Pattern := ObjectPropName
        }
        Pos := 2
        Stack := []
        Len := StrLen(Str)
        err := ''
        ;@endregion

        while RegExMatch(Str, Pattern, &Match, Pos) {
            continue
        }
        result := err ? err : Pos >= Len ? '' : Error('Invalid JSON.', -1, 'Near pos: ' Pos)
        return result

        ;@region Array Callbacks
        OnQuoteArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ArrayString, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextArr(MatchValue)
        }
        OnSquareOpenArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            Stack.Push({ __Handler: _GetContextArray })
            Pattern := ArrayItem
            Pos++
        }
        OnCurlyOpenArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectInitialCheck, &MatchCheck, Pos) || MatchCheck.Pos !== Pos + 1 {
                err := _Error(Pos)
                return -1
            }
            if MatchCheck['char'] == '}' {
                Pos := MatchCheck.Pos + MatchCheck.Len
                _GetContextArray()
            } else {
                Pos++
                Pattern := ObjectPropName
                Stack.Push({ __Handler: _GetContextArray })
            }
        }
        OnFalseArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ArrayFalse, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextArr(MatchValue)
        }
        OnTrueArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ArrayTrue, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextArr(MatchValue)
        }
        OnNullArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ArrayNull, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextArr(MatchValue)
        }
        OnNumberArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ArrayNumber, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Match.Pos)
                return -1
            }
            _PrepareNextArr(MatchValue)
        }
        OnSquareCloseArr(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len
            if Stack.Length {
                Active := Stack.Pop()
                Active.__Handler.Call()
            }
        }
        ;@endregion

        ;@region Object Callbacks
        OnQuoteObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectString, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextObj(MatchValue)
        }
        OnSquareOpenObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            Stack.Push({ __Handler: _GetContextObject })
            Pattern := ArrayItem
            Pos++
        }
        OnCurlyOpenObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectInitialCheck, &MatchCheck, Pos) || MatchCheck.Pos !== Pos + 1 {
                err := _Error(Pos)
                return -1
            }
            if MatchCheck['char'] == '}' {
                Pos := MatchCheck.Pos + MatchCheck.Len
                _GetContextObject()
            } else {
                Pos++
                Stack.Push({ __Handler: _GetContextObject })
            }
        }
        OnFalseObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectFalse, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextObj(MatchValue)
        }
        OnTrueObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectTrue, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextObj(MatchValue)
        }
        OnNullObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectNull, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            _PrepareNextObj(MatchValue)
        }
        OnNumberObj(Match, *) {
            if Match.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := Match.Pos + Match.Len - 1
            if !RegExMatch(Str, ObjectNumber, &MatchValue, Pos) || MatchValue.Pos !== Pos {
                err := _Error(Match.Pos)
                return -1
            }
            _PrepareNextObj(MatchValue)
        }
        ;@endregion

        ;@region Helper Funcs
        _GetContextArray() {
            if !RegExMatch(Str, ArrayNextChar, &MatchCheck, Pos) || MatchCheck.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := MatchCheck.Pos + MatchCheck.Len
            if MatchCheck['char'] == ',' {
                Pattern := ArrayItem
            } else if MatchCheck['char'] == ']' {
                if Stack.Length {
                    Stack.Pop().__Handler.Call()
                }
            }
        }
        _GetContextObject() {
            if !RegExMatch(Str, ObjectNextChar, &MatchCheck, Pos) || MatchCheck.Pos !== Pos {
                err := _Error(Pos)
                return -1
            }
            Pos := MatchCheck.Pos + MatchCheck.Len
            if MatchCheck['char'] == ',' {
                Pattern := ObjectPropName
            } else if MatchCheck['char'] == '}' {
                if Stack.Length {
                    Stack.Pop().__Handler.Call()
                }
            }
        }
        _PrepareNextArr(MatchValue) {
            Pos := MatchValue.Pos + MatchValue.Len
            if MatchValue['char'] == ']' {
                if Stack.Length {
                    Stack.Pop().__Handler.Call()
                } else {
                    Pos := MatchValue.Pos + MatchValue.Len
                }
            }
        }
        _PrepareNextObj(MatchValue) {
            Pos := MatchValue.Pos + MatchValue.Len
            if MatchValue['char'] == '}' {
                if Stack.Length {
                    Stack.Pop().__Handler.Call()
                } else {
                    Pos := MatchValue.Pos + MatchValue.Len
                }
            }
        }
        _Error(Extra?, n := -2) {
            return Error('There is an error in the JSON string.', n, IsSet(Extra) ? 'Near pos: ' Extra : '')
        }
        ;@endregion
    }
    static __New() {
        this.DeleteProp('__New')
        ; SignficantChars := '["{[ftn\d{}-]'
        NextChar := '(?:\s*(?<char>,|\{}))'
        ArrayNextChar := Format(NextChar, ']')
        ObjectNextChar := Format(NextChar, '}')
        this.Patterns := {
            ArrayItem: 'JS)\s*(?:(?<char>")(?COnQuoteArr)|(?<char>\{)(?COnCurlyOpenArr)|(?<char>\[)(?COnSquareOpenArr)|(?<char>f)(?COnFalseArr)|(?<char>t)(?COnTrueArr)|(?<char>n)(?COnNullArr)|(?<char>[\d-])(?COnNumberArr)|(?<char>\])(?COnSquareCloseArr))'
          , ArrayNumber: 'S)(?<value>(?<n>(?:-?\d++(?:\.\d++)?)(?:[eE][+-]?\d++)?))' ArrayNextChar
          , ArrayString: 'S)(?<=[,:[{\s])"(?<value>.*?(?<!\\)(?:\\\\)*+)"(*COMMIT)' ArrayNextChar
          , ArrayFalse: 'S)(?<value>false)' ArrayNextChar
          , ArrayTrue: 'S)(?<value>true)' ArrayNextChar
          , ArrayNull: 'S)(?<value>null)' ArrayNextChar
          , ArrayNextChar: ArrayNextChar
          , ObjectPropName: 'JS)\s*"(?<name>.*?(?<!\\)(?:\\\\)*+)"(*COMMIT):\s*(?:(?<char>")(?COnQuoteObj)|(?<char>\{)(?COnCurlyOpenObj)|(?<char>\[)(?COnSquareOpenObj)|(?<char>f)(?COnFalseObj)|(?<char>t)(?COnTrueObj)|(?<char>n)(?COnNullObj)|(?<char>[\d-])(?COnNumberObj))'
          , ObjectNumber: 'S)(?<value>(?<n>-?\d++(?:\.\d++)?)(?<e>[eE][+-]?\d++)?)' ObjectNextChar
          , ObjectString: 'S)(?<=[,:[{\s])"(?<value>.*?(?<!\\)(?:\\\\)*+)"(*COMMIT)' ObjectNextChar
          , ObjectFalse: 'S)(?<value>false)' ObjectNextChar
          , ObjectTrue: 'S)(?<value>true)' ObjectNextChar
          , ObjectNull: 'S)(?<value>null)' ObjectNextChar
          , ObjectNextChar: ObjectNextChar
          , ObjectInitialCheck: 'S)(*MARK:novalue)\s*(?<char>"|\})'
        }
    }
}

