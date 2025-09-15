
Tracer_FormatStrCallback(FormatSpecifierName, Unit, *) {
    return Unit.%FormatSpecifierName%
}

Tracer_FormatStr_EscapeJson(Str, *) {
    return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(Str, '\', '\\'), '`n', '\n'), '`r', '\r'), '"', '\"'), '`t', '\t')
}

Tracer_FormatStr_UnEscapeJson(Str, *) {
    n := 0xFFFD
    while InStr(Str, Chr(n)) {
        n++
    }
    return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(Str, '\\', Chr(n)), '\n', '`n'), '\r', '`r'), '\"', '"'), '\t', '`t'), Chr(n), '\')
}

/**
 * Sorts an array. The returned array is a new array; the original array is not modified.
 *
 * The process used by `QuickSort` makes liberal usage of the system's memory. My tests demonstrated
 * an average memory consumption of over 9x the capacity of the input array. These tests were
 * performed using input arrays with 1000 numbers across an even distribution.
 *
 * Original code is found here: {@link https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/QuickSort.ahk Github}.
 *
 * @param {Array} Arr - The array to be sorted.
 *
 * @param {*} [CompareFn = (a, b) => a - b] - A `Func` or callable object that compares two values.
 *
 * Parameters:
 * 1. A value to be compared.
 * 2. A value to be compared.
 *
 * Returns {Number} - A number to one of the following effects:
 * - If the number is less than zero it indicates the first parameter is less than the second parameter.
 * - If the number is zero it indicates the two parameters are equal.
 * - If the number is greater than zero it indicates the first parameter is greater than the second parameter.
 *
 * @param {Integer} [ArrSizeThreshold = 17] - Sets a threshold at which insertion sort is used to
 * sort the array instead of the core procedure. The default value of 17 was decided by testing various
 * values, but currently more testing is needed to evaluate arrays of various kinds of distributions.
 *
 * @param {Integer} [PivotCandidates = 7] - Note that `PivotCandidates` must be an integer greater
 * than 1.
 *
 * Defines the sample size used when selecting a pivot from a random sample. This seeks to avoid the
 * efficiency cost associated with selecting a low quality pivot. By choosing from a random sample,
 * it is expected that, on average, the number of comparisons required to evaluate the middle pivot
 * in the sample is significantly less than the number of comparisons avoided due to selecting a low
 * quality pivot.
 *
 * The default value of 7 was decided by testing various values. More testing is needed to evaluate
 * arrays of various kinds of distributions.
 *
 * @returns {Array} - The sorted array.
 *
 * @throws {ValueError} - "`PivotCandidates` must be an integer greater than one."
 */
Tracer_QuickSort(Arr, CompareFn := (a, b) => a - b, ArrSizeThreshold := 17, PivotCandidates := 7) {
    if PivotCandidates <= 1 {
        throw ValueError('``PivotCandidates`` must be an integer greater than one.', -1, PivotCandidates)
    }
    halfPivotCandidates := Ceil(PivotCandidates / 2)
    if Arr.Length <= ArrSizeThreshold {
        if Arr.Length == 2 {
            if CompareFn(Arr[1], Arr[2]) > 0 {
                return [Arr[2], Arr[1]]
            }
            return Arr.Clone()
        } else if arr.Length > 1 {
            arr := Arr.Clone()
            ; Insertion sort.
            i := 1
            loop arr.Length - 1 {
                j := i
                current := arr[++i]
                loop j {
                    if CompareFn(arr[j], current) < 0 {
                        break
                    }
                    arr[j + 1] := arr[j--]
                }
                arr[j + 1] := current
            }
            return arr
        } else {
            return arr.Clone()
        }
    }

    return _Proc(Arr)

    _Proc(Arr) {
        if Arr.Length <= ArrSizeThreshold {
            if Arr.Length == 2 {
                if CompareFn(Arr[1], Arr[2]) > 0 {
                    return [Arr[2], Arr[1]]
                }
            } else if Arr.Length > 1 {
                ; Insertion sort.
                i := 1
                loop Arr.Length - 1 {
                    j := i
                    current := Arr[++i]
                    loop j {
                        if CompareFn(Arr[j], current) < 0 {
                            break
                        }
                        Arr[j + 1] := Arr[j--]
                    }
                    Arr[j + 1] := current
                }
            }
            return Arr
        }
        candidates := []
        loop candidates.Capacity := PivotCandidates {
            candidates.Push(Arr[Random(1, Arr.Length)])
        }
        i := 1
        loop candidates.Length - 1 {
            j := i
            current := candidates[++i]
            loop j {
                if CompareFn(candidates[j], current) < 0 {
                    break
                }
                candidates[j + 1] := candidates[j--]
            }
            candidates[j + 1] := current
        }
        pivot := candidates[halfPivotCandidates]
        left := []
        right := []
        left.Capacity := right.Capacity := Arr.Length
        for item in Arr {
            if CompareFn(item, pivot) < 0 {
                left.Push(item)
            } else {
                right.Push(item)
            }
        }
        result := _Proc(left)
        result.Push(_Proc(right)*)

        return result
    }
}

Tracer_GetId(Self) {
    return ++Self.Index
}

/**
 * @description - Recursively copies an object's properties onto a new object. For all new objects,
 * `ObjDeepClone` attempts to set the new object's base to the same base as the subject. For objects
 * that inherit from `Map` or `Array`, clones the items in addition to the properties.
 * @param {*} Self - The object to be deep cloned. If calling this method from an instance,
 * exclude this parameter.
 * @param {Map} [ConstructorParams] - A map of constructor parameters, where the key is the class
 * name (use `ObjToBeCloned.__Class` as the key), and the value is an array of values that will be
 * passed to the constructor. Using `ConstructorParams` can allow `ObjDeepClone` to create correctly-
 * typed objects in cases where normally AHK will not allow setting the type using `ObjSetBase()`.
 * @param {Integer} [Depth = 0] - The maximum depth to clone. A value equal to or less than 0 will
 * result in no limit.
 * @returns {*}
 */
Tracer_ObjDeepClone(Self, ConstructorParams?, Depth := 0) {
    GetTarget := IsSet(ConstructorParams) ? _GetTarget2 : _GetTarget1
    PtrList := Map(ObjPtr(Self), Result := GetTarget(Self))
    CurrentDepth := 0
    return _Recurse(Result, Self)

    _Recurse(Target, Subject) {
        CurrentDepth++
        for Prop in Subject.OwnProps() {
            Desc := Subject.GetOwnPropDesc(Prop)
            if Desc.HasOwnProp('Value') {
                Target.DefineProp(Prop, { Value: IsObject(Desc.Value) ? _ProcessValue(Desc.Value) : Desc.Value })
            } else {
                Target.DefineProp(Prop, Desc)
            }
        }
        if Target is Array {
            Target.Length := Subject.Length
            for item in Subject {
                if IsSet(item) {
                    Target[A_Index] := IsObject(item) ? _ProcessValue(item) : item
                }
            }
        } else if Target is Map {
            Target.Capacity := Subject.Capacity
            for Key, Val in Subject {
                if IsObject(Key) {
                    Target.Set(_ProcessValue(Key), IsObject(Val) ? _ProcessValue(Val) : Val)
                } else {
                    Target.Set(Key, IsObject(Val) ? _ProcessValue(Val) : Val)
                }
            }
        }
        CurrentDepth--
        return Target
    }
    _GetTarget1(Subject) {
        if Subject is Func {
            Target := Tracer_Functor(Subject)
        } else {
            try {
                Target := GetObjectFromString(Subject.__Class)()
            } catch {
                if Subject Is Map {
                    Target := Map()
                } else if Subject is Array {
                    Target := Array()
                } else {
                    Target := Object()
                }
            }
            try {
                ObjSetBase(Target, Subject.Base)
            }
        }
        return Target
    }
    _GetTarget2(Subject) {
        if Subject is Func {
            Target := Tracer_Functor(Subject)
        } if ConstructorParams.Has(Subject.__Class) {
            Target := GetObjectFromString(Subject.__Class)(ConstructorParams.Get(Subject.__Class)*)
        } else {
            try {
                Target := GetObjectFromString(Subject.__Class)()
            } catch {
                if Subject Is Map {
                    Target := Map()
                } else if Subject is Array {
                    Target := Array()
                } else {
                    Target := Object()
                }
            }
            try {
                ObjSetBase(Target, Subject.Base)
            }
        }
        return Target
    }
    _ProcessValue(Val) {
        if Type(Val) == 'ComValue' || Type(Val) == 'ComObject' {
            return Val
        }
        if PtrList.Has(ObjPtr(Val)) {
            return PtrList.Get(ObjPtr(Val))
        }
        if CurrentDepth == Depth {
            return Val
        } else {
            PtrList.Set(ObjPtr(Val), _Target := GetTarget(Val))
            return _Recurse(_Target, Val)
        }
    }

    /**
     * @description -
     * Use this function when you need to convert a string to an object reference, and the object
     * is nested within an object path. For example, we cannot get a reference to the class `Gui.Control`
     * by setting the string in double derefs like this: `obj := %'Gui.Control'%. Instead, we have to
     * traverse the path to get each object along the way, which is what this function does.
     * @param {String} Path - The object path.
     * @returns {*} - The object if it exists in the scope. Else, returns an empty string.
     * @example
     *  class MyClass {
     *      class MyNestedClass {
     *          static MyStaticProp := {prop1_1: 1, prop1_2: {prop2_1: {prop3_1: 'Hello, World!'}}}
     *      }
     *  }
     *  obj := GetObjectFromString('MyClass.MyNestedClass.MyStaticProp.prop1_2.prop2_1')
     *  OutputDebug(obj.prop3_1) ; Hello, World!
     * @
     */
    GetObjectFromString(Path) {
        Split := StrSplit(Path, '.')
        if !IsSet(%Split[1]%)
            return
        OutObj := %Split[1]%
        i := 1
        while ++i <= Split.Length {
            if !OutObj.HasOwnProp(Split[i])
                return
            OutObj := OutObj.%Split[i]%
        }
        return OutObj
    }

    _Call(FuncObj, Self, Params*) {
        return FuncObj(Params*)
    }
}

Tracer_ThrowInvalidLogFileOptions(n := -2) {
    throw Error('``Options.LogFile.Dir`` and ``Options.LogFile.Name`` must be set to create an instance of ``TracerLogFile``.', n)
}

Tracer_ThrowUnexpectedOptionName(Name, n := 2) {
    throw PropertyError('Unexpected option name.', n, Name)
}

Tracer_SetOnExitHandler(FileObj) {
    handler := Tracer_FileCloseOnExit.Bind(FileObj)
    OnExit(handler, 1)
    return handler
}

Tracer_FileCloseOnExit(FileObj, *) {
    FileObj.Close()
}

Tracer_GetJsonPropertiesFormatString(JsonProperties, IndentLen, InitialIndent) {
    ind := ''
    loop indentLen {
        ind .= '`s'
    }
    baseIndent := ''
    if initialIndent {
        loop initialIndent {
            baseIndent .= ind
        }
    }
    s := ''
    VarSetStrCapacity(&s, 256)
    s .= baseIndent '\{%le%'
    propsMap := TracerOptions.JsonPropertiesMap
    for prop in JsonProperties {
        s .= '{' baseIndent ind '"'
        if propsMap.Has(prop) {
            s .= propsMap.Get(prop)
        } else {
            s .= StrTitle(prop)
        }
        s .= '": "{%' prop ':json%}"%le%}'
    }
    return s baseIndent '\}'
}

class Tracer_MapHelper extends Map {
    __New(CaseSense := false, Default?, Values*) {
        this.CaseSense := CaseSense
        if IsSet(Default) {
            this.Default := Default
        }
        if Values.Length {
            this.Set(Values*)
        }
    }
}

/**
 * The purpose of {@link Tracer_Functor} is to maintain consistency in how options values are handled.
 * I designed {@link TracerOptions} to always return a deep clone for any option values that is
 * an object. This is so the caller can make changes to the values without affecting the defaults.
 *
 * `Func` objects cannot be cloned this way. Though uncommon, there are occasions where modfiying
 * the properties of a `Func` object is useful. To ensure consistency across all scenarios,
 * {@link Tracer_ObjDeepClone}, upon encountering a `Func` object, will return an instance of
 * {@link Tracer_Functor} which behaves near-identically to the original `Func`, except setting
 * property values on this object will not change the original `Func`.
 */
class Tracer_Functor {
    __New(FuncObj) {
        this.Func := FuncObj
    }
    Call(Params*) {
        return this.Func.Call(Params*)
    }
    __Get(Name, Params) {
        if Params.Length {
            return this.Func.%Name%[Params*]
        } else {
            return this.Func.%Name%
        }
    }
    __Call(Name, Params) {
        return this.Func.Call(Params*)
    }
}
