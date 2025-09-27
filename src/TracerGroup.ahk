
/**
 * Defines a {@link TracerGroup}, which is a set of customization options that are inherited by any
 * {@link Tracer} instances created by calling {@link TracerGroup.Prototype.Call}.
 */
class TracerGroup extends TracerBase {
    /**
     * @param {Object|TracerOptions} [Options] - The options object. See {@link TracerOptions} for
     * details about the available options.
     *
     * If `Options` is not an instance of {@link TracerOptions}, it is passed to
     * {@link TracerOptions.Prototype.__New} and the new instance is used as the options.
     *
     * @param {Integer} [FileAction = 1] - One of the following:
     * - 1 : Does not open the log file until `Tracer.Prototype.Log` is called. When the file is
     *       opened, it is opened with standard processing.
     * - 2 : Does not open the log file until `Tracer.Prototype.Log` is called. When the file is
     *       opened, a new file is created.
     * - 3 : Opens the log file immediately. When the file is opened, it is opened with standard
     *       processing.
     * - 4 : Creates and opens a new log file immediately.
     *
     * See the documentation section "Opening the log file" for a description of "standard processing."
     *
     * `FileAction` is ignored if `Options.LogFile.Dir` and/or `Options.LogFile.Name` are not set.
     */
    __New(Options?, FileAction := 1) {
        if IsSet(Options) {
            if not Options is TracerOptions {
                Options := TracerOptions(Options)
            }
            this.Options := Options
        } else {
            this.Options := TracerOptions()
        }
        this.Index := 0
        if this.HistoryActive {
            this.History := []
        }
        this.Tools := TracerTools(this.Options, FileAction)
    }
    /**
     * Returns an instance of {@link Tracer} which inherits the options from this group.
     *
     * @param {Object} [Options] - Use this parameter if you want to specify a new value for one or
     * more options for just the new instance; these options will not affect the {@link TracerGroup}
     * object. This `Options` object is expected to have one or more properties "FormatStr", "Log",
     * "LogFile", "Out", "StringifyAll", or "Tracer". The value of each property is expected to be
     * an object with options as property : value pairs as descibed by
     * {@link TracerOptions.Prototype.__New}.
     *
     * @param {*} [IdValue] - A value to pass to the second parameter of `Options.TracerGroup.IdCallback`.
     * If unset, no value is passed to that parameter.
     *
     * If your code uses the default `Options.TracerGroup.IdCallback`, you can pass a string or
     * number to `IdValue` and that value is appended to the id.
     *
     * @example
     *  tg := TracerGroup()
     *  t := tg(, "-name")
     *  OutputDebug(t.Id "`n") ; 1-name
     * @
     */
    Call(Options?, IdValue?) {
        _tracer := Tracer(this.IdCallback.Call(this, IdValue ?? unset), this.Options, this.Tools)
        if IsSet(Options) {
            _tracer.SetOptionsObj(Options)
        }
        if this.HistoryActive {
            this.HistoryAdd(_tracer)
        }
        return _tracer
    }

    IdCallback {
        Get => this.Options.TracerGroup.IdCallback
        Set => this.Options.TracerGroup.IdCallback := Value
    }
    OwnOptions => this.Options.TracerGroup
}
