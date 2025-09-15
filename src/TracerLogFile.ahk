
class TracerLogFile {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.NewJsonFile := proto.File := proto.HandlerOnExit := proto.Options := ''
        proto.StartByte := proto.flag__OnExitStarted := 0
    }
    /**
     * @param {TracerOptions} Options - The options object. See {@link TracerOptions}.
     *
     * @param {Boolean} [NewFile = false] - If true, forces {@link TracerLogFile} to open a new
     * file regardless of `Options.LogFile.MaxSize`.
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
            this.Close()
            this.CheckDir(, 1)
            this.NewJsonFile := 1
            ++this.Index
            this.File := FileOpen(this.Path, 'a', this.Encoding)
            this.SetOnExitHandler(1)
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
            if this.ToJson {
                if this.File.Length > this.StartByte + 2 {
                    this.File.Write(this.LineEnding ']')
                }
            }
            this.File.Close()
            this.File := ''
        }
        this.SetOnExitHandler(0)
    }
    GetFiles(&OutGreatestIndex?) {
        OutGreatestIndex := 0
        if this.Ext {
            filePattern := this.Dir '\' this.Name '*.' this.Ext
            indexPattern := '-(\d+)\.' this.Ext '$'
        } else {
            filePattern := this.Dir '\' this.Name '*'
            indexPattern := '-(\d+)$'
        }
        result := []
        loop Files filePattern, 'F' {
            result.Push({ TimeCreated: A_LoopFileTimeCreated, FullPath: A_LoopFileFullPath, Size: A_LoopFileSize })
            if RegExMatch(A_LoopFileName, indexPattern, &Match) {
                if Match[1] > OutGreatestIndex {
                    OutGreatestIndex := Match[1]
                }
            } else {
                throw Error('Unmatched file name', -1, A_LoopFileFullPath)
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
        return result
    }
    /**
     * Disclaimer: Calling this sets a property {@link TracerLogFile#flag__OnExitStarted} which
     * forces {@link Tracer.Prototype.Log} to call {@link TracerLogFile.Prototype.Close} every
     * time. This is necessary to ensure that the log file is closed correctly even when the log
     * file is reopened after {@link TracerLogFile.Prototype.OnExit} executes. However, there
     * is no code that switches this flag off. If there is a possibility {@link TracerLogFile.Prototype.OnExit}
     * is called but then the script does not exit, you may want to include a line of code that
     * sets {@link TracerLogFile#flag__OnExitStarted} to 0.
     */
    OnExit(*) {
        this.Close()
        this.flag__OnExitStarted := 1
    }
    Open(SetOnExit := 1) {
        this.StartByte := this.GetStartByte()
        if FileExist(this.Path) {
            if !this.MaxSize || FileGetSize(this.Path, 'B') < this.MaxSize {
                if this.ToJson {
                    switch this.CheckJsonStart() {
                        case 0:
                            switch this.CheckJsonEnd() {
                                case 0: this.RemoveCloseSquareBracket()
                                case 1: ; do nothing
                                case 2: this.NewJsonFile := true
                                case 3:
                                    this.NewJsonFile := true
                                    ++this.Index
                            }
                        case 1: this.RemoveCloseSquareBracket()
                        case 2: this.NewJsonFile := true
                        case 3:
                            this.NewJsonFile := true
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
                    this.NewJsonFile := true
                }
            }
        } else if this.ToJson {
            this.NewJsonFile := true
        }
        this.File := FileOpen(this.Path, 'a', this.Encoding)
        if SetOnExit {
            this.SetOnExitHandler(SetOnExit)
        }
    }
    /**
     * Removes the closing square bracket from the file. This also deletes any trailing whitespace.
     * If the file has already been opened, the file pointer is moved to the end of the file. If the
     * file has not been already opened, it is opened temporarily and closed before this function
     * exits.
     * @returns {Integer} - 0 if successful, 1 if the file is empty or contains only whitespace.
     * @throws {Error} - "The file's contents does not end with a close square bracket."
     */
    RemoveCloseSquareBracket() {
        if this.File {
            f := this.File
            pos := f.Pos
        } else {
            f := FileOpen(this.Path, 'a', this.Encoding)
        }
        chunkSize := Min(this.BracketByteCount * 10, f.Length)
        r := Mod(f.Length, chunkSize)
        f.Pos := f.Length - chunkSize
        loop Floor(f.Length / chunkSize) {
            if str := RTrim(f.Read(), '`s`r`t`n') {
                return _Check()
            } else {
                f.Length -= chunkSize
                if f.Length >= chunkSize {
                    f.Pos := f.Length - chunkSize
                } else {
                    f.Pos := 0
                }
            }
        }
        if r {
            f.Pos := 0
            if str := RTrim(f.Read(), '`s`r`t`n') {
                return _Check()
            } else {
                f.Length := 0
                if !IsSet(pos) {
                    f.Close()
                }
            }
        } else {
            f.Length := 0
            if !IsSet(pos) {
                f.Close()
            }
        }

        return 1

        _Check() {
            if SubStr(str, -1, 1) == ']' {
                f.Length -= this.BracketByteCount
                if IsSet(pos) {
                    f.Pos := f.Length
                } else {
                    f.Close()
                }
                return 0
            } else {
                if IsSet(pos) {
                    f.Pos := f.Length
                } else {
                    f.Close()
                }
                throw Error('The file`'s contents does not end with a close square bracket.', -1, this.Path)
            }
        }
    }
    SetToJson(Value) {
        this.Options.Log.ToJson := Value
        if !Value {
            this.NewJsonFile := false
        }
    }
    SetEncoding(Encoding) {
        this.Options.LogFile.Encoding := Encoding
        this.BracketByteCount := StrPut('[', Encoding)
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
    LineEnding => this.Options.Tracer.LineEnding
    MaxFiles => this.Options.LogFile.MaxFiles
    MaxSize => this.Options.LogFile.MaxSize
    Name => this.Options.LogFile.Name
    SetOnExit => this.Options.LogFile.SetOnExit
}
