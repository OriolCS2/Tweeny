using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// What happens when a tween reaches the end of a loop cycle.
    /// </summary>
    enum LoopType
    {
        /// <summary>Jump back to the start and play forward again.</summary>
        Restart = 0,
        /// <summary>Alternate between playing forward and backward.</summary>
        Yoyo,
        /// <summary>Add the change value again each cycle, so the tween keeps going further.</summary>
        Incremental
    }

    /// <summary>
    /// Which engine update phase drives a tween.
    /// </summary>
    enum UpdateType
    {
        /// <summary>Driven from Update.</summary>
        Normal = 0,
        /// <summary>Driven from PostUpdate. CometEngine has no LateUpdate, PostUpdate is its equivalent.</summary>
        Late,
        /// <summary>Driven from FixedUpdate, using the fixed delta.</summary>
        Fixed,
        /// <summary>Never driven automatically. Only advances through Tweeny::ManualUpdate.</summary>
        Manual
    }

    /// <summary>
    /// How a goto should treat callbacks. Internal to the tween engine.
    /// </summary>
    enum UpdateMode
    {
        /// <summary>A normal update: every callback fires.</summary>
        Update = 0,
        /// <summary>A seek: step and complete callbacks are suppressed.</summary>
        Goto,
        /// <summary>Everything fires except OnUpdate.</summary>
        IgnoreOnUpdate,
        /// <summary>Everything fires except OnComplete.</summary>
        IgnoreOnComplete
    }

    /// <summary>
    /// Extra information handed to the value writer about the step that just happened.
    /// </summary>
    enum UpdateNotice
    {
        /// <summary>Nothing special.</summary>
        None = 0,
        /// <summary>The tween just wrapped back to the start of a loop.</summary>
        RewindStep
    }

    /// <summary>
    /// Which kinds of tween start playing on their own when created.
    /// </summary>
    enum AutoPlay
    {
        /// <summary>Nothing plays automatically.</summary>
        None = 0,
        /// <summary>Only sequences play automatically.</summary>
        AutoPlaySequences,
        /// <summary>Only plain tweens play automatically.</summary>
        AutoPlayTweeners,
        /// <summary>Everything plays automatically.</summary>
        All
    }

    /// <summary>
    /// Distinguishes the two things the scheduler can hold.
    /// </summary>
    enum TweenType
    {
        /// <summary>A tween that drives a value.</summary>
        Tweener = 0,
        /// <summary>A composition of other tweens.</summary>
        Sequence,
        /// <summary>A callback slot inside a sequence.</summary>
        Callback
    }

    /// <summary>
    /// Restricts which components of a vector a tween is allowed to write.
    /// Values are flags so they can be combined.
    /// </summary>
    enum AxisConstraint
    {
        None = 0,
        X = 2,
        Y = 4,
        Z = 8,
        W = 16
    }

    /// <summary>
    /// How a tween reacts to its linked entity being enabled, disabled or destroyed.
    /// </summary>
    enum LinkBehaviour
    {
        PauseOnDisable = 0,
        PauseOnDisablePlayOnEnable,
        PauseOnDisableRestartOnEnable,
        PlayOnEnable,
        RestartOnEnable,
        KillOnDisable,
        KillOnDestroy,
        CompleteOnDisable,
        CompleteAndKillOnDisable,
        RewindOnDisable,
        RewindAndKillOnDisable
    }

    /// <summary>
    /// How the random directions of a shake are distributed.
    /// </summary>
    enum ShakeRandomnessMode
    {
        /// <summary>Fully random directions.</summary>
        Full = 0,
        /// <summary>Directions stay closer to the previous one, giving a smoother shake.</summary>
        Harmonic
    }

    /// <summary>
    /// The character set used when scrambling a string tween.
    /// </summary>
    enum ScrambleMode
    {
        None = 0,
        All,
        Uppercase,
        Lowercase,
        Numerals,
        Custom
    }

    /// <summary>
    /// How much of the log a tween is allowed to write.
    /// </summary>
    enum LogBehaviour
    {
        /// <summary>Only errors.</summary>
        ErrorsOnly = 0,
        /// <summary>Errors and warnings.</summary>
        Default,
        /// <summary>Everything, including per-tween diagnostics.</summary>
        Verbose
    }

    /// <summary>
    /// What happens to a sequence when one of its children can no longer run.
    /// </summary>
    enum NestedTweenFailureBehaviour
    {
        /// <summary>Drop the failed child and keep the sequence going.</summary>
        TryToPreserveSequence = 0,
        /// <summary>Kill the whole sequence.</summary>
        KillWholeSequence
    }

    /// <summary>
    /// Which tweens a filtered operation applies to.
    /// </summary>
    enum FilterType
    {
        All = 0,
        TargetOrId,
        TargetAndId,
        AllExceptTargetsOrIds
    }
}
