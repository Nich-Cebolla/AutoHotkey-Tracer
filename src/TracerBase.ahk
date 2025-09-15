
class TracerBase {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.Options := proto.Index := proto.Tools := proto.History := ''
    }
    /**
     * When called from an instance of {@link Tracer}, activates the history functionality for
     * the object.
     *
     * When called from an instance of {@link TracerGroup}, activates the history functionality
     * for the group object. Does not change the history settings for any {@link Tracer} instances.
     *
     * @param {Integer} [MaxItems] - Defines the maximum number of items that may be in the array
     * before removing some. If the item count of array {@link TracerGroup#History} exceeds `MaxItems`,
     * items are removed from the array.
     */
    HistoryActivate(MaxItems?) {
        this.OwnOptions.HistoryActive := true
        if !this.IsObject(this.History) {
            this.History := []
        }
        if IsSet(MaxItems) {
            this.HistorySetMaxItems(MaxItems)
        }
    }
    HistoryAdd(Value) {
        this.History.Push(Value)
        if this.HistoryMaxItems > 0 && this.History.Length > this.HistoryMaxItems {
            this.History.RemoveAt(1, this.HistoryReleaseCount)
        }
    }
    /**
     * When called from an instance of {@link Tracer}, deactivates the history functionality for
     * the object.
     *
     * When called from an instance of {@link TracerGroup}, deactivates the history functionality
     * for the group object. Does not change the history settings for any {@link Tracer} instances.
     */
    HistoryDeactivate(ClearHistory := false) {
        this.OwnOptions.HistoryActive := false
        if ClearHistory {
            this.History.Length := 0
        }
    }
    /**
     * When called from an instance of {@link TracerGroup}, sets an option at the group level.
     * When called from an instance of {@link Tracer}, sets an option at the individual level.
     *
     * For a list and description of the options, see {@link TracerOptions}.
     *
     * @param {String} OptionCategory - One of the following:
     * - FormatStr : Options related to {@link FormatStr}.
     * - Log : Options related to {@link Tracer.Prototype.Log}.
     * - LogFile : Options related to {@link TracerLogFile}.
     * - Out : Options related to {@link Tracer.Prototype.Out}.
     * - StringifyAll : Options related to {@link StringifyAll}.
     * - Tracer : Options related to {@link Tracer}.
     * - TracerGroup : Options related to {@link TracerGroup}.
     *
     * @param {String} Name - The option name.
     *
     * @param {*} Value - The new option value.
     */
    SetOption(OptionCategory, Name, Value) {
        if HasProp(this.Options.%OptionCategory%, Name) {
            this.SetOptionsObj({ %OptionCategory%: { %Name%: Value } })
        } else {
            Tracer_ThrowUnexpectedOptionName(Name)
        }
    }
    /**
     * When called from an instance of {@link TracerGroup}, sets options at the group level.
     * When called from an instance of {@link Tracer}, sets options at the individual level.
     *
     * Updates options from an input object. This only changes option values that are included
     * as properties on the input object; all other option values will remain their current
     * value.
     *
     * @param {Object} Options - An object with option categories as property : value pairs:
     * - FormatStr: Options related to {@link FormatStr}.
     * - Log: Options related to {@link Tracer.Prototype.Log}.
     * - LogFile: Options related to {@link TracerLogFile}.
     * - Out: Options related to {@link Tracer.Prototype.Out}.
     * - StringifyAll: Options related to {@link StringifyAll}.
     * - Tracer: Options related to {@link Tracer}.
     * - TracerGroup: Options related to {@link TracerGroup}.
     */
    SetOptionsObj(Options) {
        if this is TracerGroup {
            _Proc('TracerGroup', this)
            if !_Proc('Tracer', '') {
                if HasProp(Options.Tracer, 'IndentLen') {
                    this.Tools.SetIndentLen(Options.Tracer.IndentLen)
                }
            }
        } else {
            if HasProp(Options, 'TracerGroup') {
                throw TypeError('``Options.TracerGroup`` options may only be updated from an instance of ``TracerGroup``.', -1)
            }
            _Proc('Tracer', this)
        }
        flag_GetFormatStrConstructor := false
        if !_Proc('FormatStr', '') {
            this.Tools.GetFormatStrConstructor()
        }
        _Proc('LogFile', '')
        _Proc('StringifyAll', '')
        _ProcOutputOptions('Log')
        _ProcOutputOptions('Out')
        if flag_GetFormatStrConstructor {
            this.Tools.GetFormatStrConstructor()
        }

        _Proc(optCategory, subject) {
            if !HasProp(Options, optCategory) {
                return 1
            }
            inputObj := Options.%optCategory%
            optionsObj := this.Options.%optCategory%
            for name in TracerOptions.DefaultOptions.%optCategory%.OwnProps() {
                if HasProp(inputObj, name) {
                    ; A number of options require some extra code to invoke the change.
                    ; This ensures that the method which handles the change is executed.
                    if subject && HasProp(subject, name) {
                        subject.%name% := optionsObj.%name% := inputObj.%name%
                    } else {
                        optionsObj.%name% := inputObj.%name%
                    }
                }
            }
        }
        _ProcOutputOptions(optCategory) {
            if !HasProp(Options, optCategory) {
                return
            }
            inputObj := Options.%optCategory%
            optionsObj := this.Options.%optCategory%
            _Set('ConditionCallback')
            if _Set('Format') {
                this.Tools.GetFormatStr%optCategory%()
            }
            if HasProp(inputObj, 'ToJson') {
                if optCategory = 'Log' {
                    this.Tools.LogFile.SetToJson(inputObj.ToJson)
                } else {
                    optionsObj.ToJson := inputObj.ToJson
                }
            }
            if HasProp(inputObj, 'JsonProperties') {
                this.Tools.SetJsonProperties%optCategory%(inputObj.JsonProperties)
            }
            _Set(name) {
                if HasProp(inputObj, name) {
                    optionsObj.%name% := inputObj.%name%
                    return 1
                }
            }
        }
    }

    HistoryActive {
        Get => this.Options.%this.__Class%.HistoryActive
        Set {
            this.Options.%this.__Class%.HistoryActive := Value
            if !this.HasOwnProp('History') {
                this.History := []
            }
        }
    }
    HistoryMaxItems {
        Get => this.Options.%this.__Class%.HistoryMaxItems
        Set => this.Options.%this.__Class%.HistoryMaxItems := Value
    }
    HistoryReleaseRatio {
        Get => this.Options.%this.__Class%.HistoryReleaseRatio
        Set => this.Options.%this.__Class%.HistoryReleaseRatio := Value
    }
    HistoryReleaseCount => Round(this.HistoryMaxItems * this.HistoryReleaseRatio, 0) || 1
    IndentLen {
        Get => this.Options.Tracer.IndentLen
        Set => this.Tools.SetIndentLen(Value)
    }
}
