
class TracerLogFile {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.flag_newJsonFile := proto.File := proto.HandlerOnExit := proto.Options := proto.flag_newFile := ''
        proto.StartByte := proto.BracketByteCount := proto.LineEndByteCount := proto.EndByteCount := 0
    }
    /**
     * @param {TracerOptions} Options - The options object. See {@link TracerOptions}.
     *
     * @param {Boolean} [NewFile = false] - If true, the file is opened as a new file. If false,
     * the most recent file in the directory (as indicated by its index in the file name) is
     * evaluated:
     *
     * If all of the following are true, then the most recent file is opened and used:
     * - If the file begins and ends with open and close square brackets
     * - If the value of `Options.Log.ToJson` is true
     * - If the size of the file is less than `Options.LogFile.MaxSizeand
     *
     * Or, if all of the following are true, then the most recent file is opened and used:
     * - If the file does not begin with or end with open and close square brackets
     * - If the value of `Options.Log.ToJson` is false
     * - If the size of the file is less than `Options.LogFile.MaxSize
     */
    __New(Options, NewFile := false) {
        if !Options.HasValidLogFileOptions {
            throw PropertyError('``Options.LogFile.Dir`` and ``Options.LogFile.Name`` are required to call ``TracerLogFile.Prototype.__New``.', -1)
        }
        this.Options := Options
        this.SetExt(this.Options.LogFile.Ext)
        if !DirExist(this.Options.LogFile.Dir) {
            DirCreate(this.Options.LogFile.Dir)
        }
        this.SetEncoding(this.Options.LogFile.Encoding)
        this.CheckDir(&greatestIndex)
        this.Index := greatestIndex
        if NewFile {
            ++this.Index
        }
        this.flag_newFile := NewFile
        this.Open(this.Options.LogFile.SetOnExit)
    }
    CheckDir(&OutGreatestIndex?, RemoveAdditionalFiles := 0) {
        result := this.GetFiles(&OutGreatestIndex)
        if this.MaxFiles > 0 && result.Length {
            if result.Length + RemoveAdditionalFiles > this.MaxFiles {
                result := Tracer_QuickSort(result, (a, b) => DateDiff(b.TimeCreated, a.TimeCreated, 'S'))
                loop result.Length - this.MaxFiles + RemoveAdditionalFiles {
                    FileDelete(result.Pop().FullPath)
                }
            }
        }
        return result
    }
    CheckFile() {
        if this.MaxSize > 0 && this.File.Length > this.MaxSize {
            this.File.Close()
            this.CheckDir(, 1)
            ++this.Index
            if this.ToJson {
                this.flag_newJsonFile := true
            }
            this.File := FileOpen(this.Path, 'a', this.Encoding)
            return 1
        }
    }
    /**
     * @returns {Integer} - One of the following:
     * - 0: The file ends with a line-feed or carriage-return character followed by a close square
     *   bracket, indicating the file's contents is likely a valid, closed json array.
     * - 1: The file ends with a line-feed or carriage-return character followed by one level of
     *   indentation (defined as the value of {@link TracerLogFile#IndentLen}) followed by a closing
     *   curly bracket, OR the file is 1 character in length and that character is an open square
     *   bracket, indicating the file's contents is likely a valid json array and the array needs
     *   to be closed.
     * - 2: The file is empty OR the file only contains whitespace characters.
     * - 3: The file cannot be characterized by any of the above, indicating the file likely does
     *   not contain a valid json array created by this library.
     */
    CheckJsonEnd() {
        if this.File {
            f := this.File
            pos := f.Pos
        } else {
            f := FileOpen(this.Path, 'r', this.Encoding)
        }
        if f.Length == this.Startbyte {
            result := 2
        } else if f.Length == 2 + this.StartByte {
            f.Pos := this.StartByte
            if f.Read() == '[' {
                result := 1
            } else {
                result := 3
            }
        } else if f.Length == 4 + this.StartByte {
            f.Pos := this.StartByte
            if f.Read() == '[]' {
                result := 0
            } else {
                result := 3
            }
        } else {
            f.Pos := f.Length - Min(20, f.Length - this.StartByte)
            content := LTRim(f.Read(Min(20, f.Length - this.StartByte)), '`s`r`t`n')
            if !content {
                f.Pos := this.StartByte
                content := f.Read()
            }
            if content {
                if RegExMatch(content, '(?<=[\r\n])(?<indent>[ \t]*).+$', &match) {
                    switch SubStr(match[0], -1, 1) {
                        case ']':
                            if match.Len > 1 {
                                result := 3
                            } else {
                                result := 0
                            }
                        case '}':
                            if match.Len['indent'] == this.Options.Tracer.IndentLen {
                                result := 1
                            } else {
                                result := 3
                            }
                        default: result := 3
                    }
                } else {
                    result := 3
                }
            } else {
                result := 2
            }
        }
        if IsSet(pos) {
            f.Pos := pos
        } else {
            f.Close()
        }
        return result
    }
    /**
     * Note this ignores any leading whitespace.
     * @returns {Integer} - One of the following:
     * - 0: The file begins with an open square bracket.
     * - 1: The file is 4 bytes in length consisting of an open and close square bracket.
     * - 2: The file is empty or contains only whitespce.
     * - 3: The file cannot be characterized by any of the above, indicating the file likely does
     *   not contain a valid json array created by this library.
     */
    CheckJsonStart() {
        if this.File {
            f := this.File
            pos := f.Pos
        } else {
            f := FileOpen(this.Path, 'r', this.Encoding)
        }
        f.Pos := this.StartByte
        if f.Length == this.StartByte {
            result := 2
        } else if f.Length == this.BracketByteCount + this.StartByte {
            if f.Read() == '[' {
                result := 0
            } else {
                result := 3
            }
        } else if f.Length == this.BracketByteCount * 2 + this.StartByte {
            if f.Read() == '[]' {
                result := 1
            } else {
                result := 3
            }
        } else {
            pattern := '^(?:\[|\s*(?<=[\r\n])\[)'
            if content := RTrim(f.Read(Min(this.BracketByteCount * 10, f.Length)), '`s`t`r`n') {
                if RegExMatch(content, pattern, &match) {
                    result := 0
                } else {
                    result := 3
                }
            } else {
                f.Pos := this.StartByte
                if RegExMatch(f.Read(), pattern, &match) {
                    result := 0
                } else {
                    result := 3
                }
            }
        }
        if IsSet(pos) {
            f.Pos := pos
        } else {
            f.Close()
        }
        return result
    }
    Close(*) {
        if this.File {
            this.File.Close()
            this.File := ''
        }
        if IsObject(this.HandlerOnExit) {
            this.SetOnExitHandler(0)
        }
    }
    GetFiles(&OutGreatestIndex?) {
        OutGreatestIndex := 0
        if this.Ext {
            filePattern := this.FilePattern || this.Dir '\' this.Name '*.' this.Ext
            indexPattern := this.FileIndexPattern || '-(?<index>\d+)\.' this.Ext '$'
        } else {
            filePattern := this.FilePattern || this.Dir '\' this.Name '*'
            indexPattern := this.FileIndexPattern || '-(?<index>\d+)$'
        }
        result := []
        if indexPattern = -1 {
            loop Files filePattern, 'F' {
                result.Push({ TimeCreated: A_LoopFileTimeCreated, FullPath: A_LoopFileFullPath, Size: A_LoopFileSize })
            }
        } else {
            loop Files filePattern, 'F' {
                result.Push({ TimeCreated: A_LoopFileTimeCreated, FullPath: A_LoopFileFullPath, Size: A_LoopFileSize })
                if RegExMatch(A_LoopFileName, indexPattern, &Match) {
                    if Match['index'] > OutGreatestIndex {
                        OutGreatestIndex := Match['index']
                    }
                } else {
                    ; If you get this error it means you overrode `TracerLogFileObj.GetPath`. You
                    ; can either define `Options.LogFile.FileIndexPattern` with a pattern that
                    ; correctly captures the indx, or disable this functionality altogether by
                    ; setting `Options.LogFile.FileIndexPattern := -1`. Disabling this
                    ; functionality causes `TracerLogFile.Prototype.Open` to always open a new
                    ; file.
                    throw Error('Unmatched file name', -1, A_LoopFileFullPath)
                }
            }
        }
        return result
    }
    /**
     * Returns the file path.
     *
     * @param {Integer} [Index] - Set with an integer to get the file path for a specific file. Else,
     * leave unset to get the file path for the current file.
     */
    GetPath(Index?) {
        ; This is overridden
    }
    GetStartByte() {
        path := A_Temp '\tracer-ahk.temp'
        f := FileOpen(path, 'w', this.Encoding)
        result := f.Length
        f.Close()
        FileDelete(path)
        return result
    }
    OnExit(*) {
        if this.Options.LogFile.OnExitCritical {
            previousCritical := Critical(this.Options.LogFile.OnExitCritical)
        }
        this.Close()
        if this.Options.LogFile.OnExitCritical {
            Critical(previousCritical)
        }
    }
    Open(SetOnExit := true) {
        this.StartByte := this.GetStartByte()
        if FileExist(this.Path) && !this.flag_newFile && this.FileIndexPattern != -1 {
            if !this.MaxSize || FileGetSize(this.Path, 'B') < this.MaxSize {
                if this.ToJson {
                    switch this.CheckJsonStart() {
                        case 0:
                            switch this.CheckJsonEnd() {
                                case 0: this.StandardizeEnding()
                                case 1: ; do nothing
                                case 2: this.flag_newJsonFile := true
                                case 3:
                                    this.flag_newJsonFile := true
                                    ++this.Index
                            }
                        case 1: this.StandardizeEnding()
                        case 2: this.flag_newJsonFile := true
                        case 3:
                            this.flag_newJsonFile := true
                            ++this.Index
                    }
                } else {
                    switch this.CheckJsonStart() {
                        case 0, 1: ++this.Index
                    }
                }
            } else {
                ++this.Index
                if this.ToJson {
                    this.flag_newJsonFile := true
                }
            }
        } else if this.ToJson {
            this.flag_newJsonFile := true
        }
        this.flag_newFile := 0
        this.File := FileOpen(this.Path, 'a', this.Encoding)
        if SetOnExit {
            this.SetOnExitHandler(SetOnExit)
        }
    }
    /**
     * Removes the closing square bracket from the file. This also deletes any trailing whitespace.
     * If the file has not been already opened, it is opened temporarily and closed before this
     * function exits. If the file has already been opened, the file pointer is moved to the end
     * of the file.
     *
     * @returns {Integer} - 0 if successful, 1 if the file is empty or contains only whitespace.
     * @throws {Error} - "The file's contents does not end with a close square bracket."
     */
    StandardizeEnding() {
        if this.File {
            f := this.File
        } else {
            f := FileOpen(this.Path, 'a', this.Encoding)
        }
        chunkSize := this.BracketByteCount * 10
        len := f.Length - this.StartByte
        if chunkSize > len {
            return _Check()
        } else {
            loop Floor(len / chunkSize) {
                f.Pos -= chunkSize * A_Index
                if !_Check() {
                    return 0
                }
            }
            if r := Mod(len, chunkSize) {
                f.Pos := this.StartByte
                return _Check()
            }
            return 1
        }

        _Check() {
            str := f.Read()
            ; If it's not all whitespace
            if RegExMatch(str, '\S') {
                ; If the file ends with a square bracket with 0 indentation
                if RegExMatch(str, this.LineEnding '\]' this.LineEnding '(\s*)$', &match) {
                    ; Leave only one line break after the close bracket.
                    f.Length := f.Length - StrPut(match[1], this.Encoding) + StrPut('', this.Encoding)
                    if !this.File {
                        f.Close()
                    }
                    return 0
                } else {
                    throw Error('The file`'s contents does not end with a close square bracket.', -1)
                }
            }
            return 1
        }
    }
    SetToJson(Value) {
        this.Options.Log.ToJson := Value
        if !Value {
            this.flag_newJsonFile := false
        }
    }
    SetEncoding(Encoding) {
        this.Options.LogFile.Encoding := Encoding
        ; This information is used to move the file pointer when adding new items to the json array
        ; when `Options.Log.ToJson` is true. When `Tracer.Prototype.Log` is called, and if
        ; `TracerLogFileObj.flag_newJsonFile` is false, `Tracer.Prototype.Log` moves the file pointer
        ; to overwrite the closing square bracket and line end characters, adds a comma, adds the
        ; new log item, then closes the json array again. The number of bytes varies depending
        ; on encoding.
        this.BracketByteCount := StrPut('[', Encoding) - StrPut('', Encoding)
        this.LineEndByteCount := StrPut(this.LineEnding, Encoding) - StrPut('', Encoding)
        this.EndByteCount := this.BracketByteCount + this.LineEndByteCount * 2
        this.StartByte := this.GetStartByte()
    }
    SetExt(Ext) {
        if this.Options.LogFile.Ext := Ext {
            this.DefineProp('GetPath', TracerLogFile.Prototype.GetOwnPropDesc('__GetPath'))
        } else {
            this.DefineProp('GetPath', TracerLogFile.Prototype.GetOwnPropDesc('__GetPathNoExt'))
        }
    }
    SetOnExitHandler(Value := 1) {
        if Value {
            if !IsObject(this.HandlerOnExit) {
                ; This creates a reference cycle.
                this.HandlerOnExit := ObjBindMethod(this, 'OnExit')
                ObjRelease(ObjPtr(this))
            }
            OnExit(this.HandlerOnExit, Value)
        } else if IsObject(this.HandlerOnExit) {
            OnExit(this.HandlerOnExit, Value)
            if this.HasOwnProp('HandlerOnExit') {
                ObjPtrAddRef(this)
                this.DeleteProp('HandlerOnExit')
            }
        }
    }
    __Delete() {
        if this.HasOwnProp('HandlerOnExit') && IsObject(this.HandlerOnExit) {
            ObjPtrAddRef(this)
            this.DeleteProp('HandlerOnExit')
        }
    }
    __GetPath(Index?) {
        return this.Dir '\' this.Name '-' (Index ?? this.Index) '.' this.Ext
    }
    __GetPathNoExt(Index?) {
        return this.Dir '\' this.Name '-' (Index ?? this.Index)
    }

    ToJson {
        Get => this.Options.Log.ToJson
        Set => this.SetToJson(Value)
    }
    Path => this.GetPath(this.Index)
    Dir => this.Options.LogFile.Dir
    Encoding => this.Options.LogFile.Encoding
    Ext => this.Options.LogFile.Ext
    FileIndexPattern => this.Options.LogFile.FileIndexPattern
    FilePattern => this.Options.LogFile.FilePattern
    LineEnding => this.Options.Tracer.LineEnding
    MaxFiles => this.Options.LogFile.MaxFiles
    MaxSize => this.Options.LogFile.MaxSize
    Name => this.Options.LogFile.Name
    SetOnExit => this.Options.LogFile.SetOnExit
}
