
/**
 * Defines a {@link TracerGroup}, which is a set of customization options that are inherited by any
 * {@link Tracer} instances created by calling {@link TracerGroup.Prototype.Call}.
 *
 * Customization options can be set at the group level and at the individual level. When set at
 * the group level, all instances of {@link Tracer} that were created from this object are
 * effected.
 *
 * When set at the individual level, the value of that option is only changed for the individual.
 * This overrides the group's value, which could later be exposed again by deleting the own
 * property.
 */
class TracerGroup extends TracerBase {
    /**
     * @param {TracerOptions} Options - The {@link TracerOptions} object.
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
        this.Options := Options ?? TracerOptions()
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
     * You can also update options at the individual level from the new {@link Tracer} object itself.
     * This parameter is provided as a convenience to reduce two method calls to one.
     */
    Call(Options?) {
        inheritorOpt := this.Options.GetInheritor()
        _tracer := Tracer(this.IdCallback.Call(this), inheritorOpt, TracerToolsInheritor(this.Tools, inheritorOpt))
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
}
