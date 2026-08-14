using namespace CometEngine;

namespace Tweeny
{
    /// The single manager instance. Created lazily on first use rather than as an initialised global, so
    /// it never depends on script global-variable initialisation order.
    TweenyManager@ g_manager;

    /// <summary>
    /// The tween manager, creating it on first use.
    /// </summary>
    /// <returns>Returns the manager. Never null.</returns>
    TweenyManager@ Manager()
    {
        if (g_manager is null) {
            @g_manager = TweenyManager();
        }
        return g_manager;
    }

    /// <summary>
    /// Applies the manager defaults to a freshly created tween and registers it.
    /// </summary>
    /// <param name="tween">The tween to register.</param>
    void Register(ITween@ tween)
    {
        Manager().Add(tween);
    }

    // =================================================================================================
    // Driving
    // =================================================================================================

    /// <summary>
    /// Advances every tween on the Manual update queue. This is the entry point used by tests and by the
    /// editor preview, and it is what makes deterministic playback possible: the caller decides the delta
    /// instead of the engine clock.
    /// </summary>
    /// <param name="deltaTime">Scaled seconds to advance.</param>
    /// <param name="unscaledDeltaTime">Unscaled seconds to advance.</param>
    void ManualUpdate(float deltaTime, float unscaledDeltaTime)
    {
        Manager().Tick(UpdateType::Manual, deltaTime, unscaledDeltaTime);
    }

    /// <summary>
    /// Advances one update phase. Called by the runtime driver; games rarely call this directly.
    /// </summary>
    /// <param name="phase">The phase to advance.</param>
    /// <param name="deltaTime">Scaled seconds since the last tick.</param>
    /// <param name="unscaledDeltaTime">Unscaled seconds since the last tick.</param>
    void TickPhase(UpdateType phase, float deltaTime, float unscaledDeltaTime)
    {
        Manager().Tick(phase, deltaTime, unscaledDeltaTime);
    }

    // =================================================================================================
    // Global state
    // =================================================================================================

    /// <summary>The multiplier applied to every scaled tween.</summary>
    /// <returns>Returns the global time scale.</returns>
    float GetTimeScale() { return Manager().globalTimeScale; }

    /// <summary>Sets the multiplier applied to every scaled tween.</summary>
    /// <param name="value">The new global time scale.</param>
    void SetTimeScale(float value) { Manager().globalTimeScale = value; }

    /// <summary>The number of live tweens.</summary>
    /// <returns>Returns the active tween count.</returns>
    int TotalActiveTweens() { return Manager().TotalActiveTweens(); }

    /// <summary>The number of tweens currently advancing.</summary>
    /// <returns>Returns the playing tween count.</returns>
    int TotalPlayingTweens() { return Manager().TotalPlayingTweens(); }

    /// <summary>
    /// Kills every tween.
    /// </summary>
    /// <param name="complete">Whether each tween jumps to its end value first.</param>
    /// <returns>Returns how many tweens were killed.</returns>
    int Clear(bool complete = false) { return Manager().Clear(complete); }

    // =================================================================================================
    // Filtered operations
    // =================================================================================================

    /// The operation a filtered call performs on each matching tween.
    enum TweenOperation
    {
        OpPlay = 0,
        OpPause,
        OpTogglePause,
        OpPlayForward,
        OpPlayBackwards,
        OpRewind,
        OpSmoothRewind,
        OpRestart,
        OpComplete,
        OpKill,
        OpFlip,
        OpGoto,
        OpIsTweening
    }

    /// <summary>
    /// Runs one operation over every tween matching a filter.
    /// </summary>
    /// <param name="operation">What to do to each match.</param>
    /// <param name="filter">Which tweens to touch.</param>
    /// <param name="target">The target to match on, when the filter uses one.</param>
    /// <param name="stringId">The string id to match, empty to ignore.</param>
    /// <param name="intId">The integer id to match, -999 to ignore.</param>
    /// <param name="gotoPosition">The position used by the Goto operation.</param>
    /// <param name="flag">Complete-on-kill, include-delay or and-play, depending on the operation.</param>
    /// <returns>Returns how many tweens matched.</returns>
    int Apply(TweenOperation operation, FilterType filter, Object@ target, const string&in stringId,
        int intId, float gotoPosition = 0.0f, bool flag = false)
    {
        array<ITween@>@ matches = Manager().Collect(filter, target, stringId, intId);
        for (uint i = 0; i < matches.length(); i++) {
            ITween@ tween = matches[i];
            switch (operation) {
            case TweenOperation::OpPlay:          tween.Play(); break;
            case TweenOperation::OpPause:         tween.Pause(); break;
            case TweenOperation::OpTogglePause:   tween.TogglePause(); break;
            case TweenOperation::OpPlayForward:   tween.PlayForward(); break;
            case TweenOperation::OpPlayBackwards: tween.PlayBackwards(); break;
            case TweenOperation::OpRewind:        tween.Rewind(flag); break;
            case TweenOperation::OpSmoothRewind:  tween.SmoothRewind(); break;
            case TweenOperation::OpRestart:       tween.Restart(flag); break;
            case TweenOperation::OpComplete:      tween.Complete(flag); break;
            case TweenOperation::OpKill:          tween.Kill(flag); break;
            case TweenOperation::OpFlip:          tween.Flip(); break;
            case TweenOperation::OpGoto:          tween.Goto(gotoPosition, flag, false); break;
            case TweenOperation::OpIsTweening:    break;
            }
        }
        Manager().MarkDirty();
        return int(matches.length());
    }

    int PlayAll()                          { return Apply(TweenOperation::OpPlay, FilterType::All, null, "", -999); }
    int PauseAll()                         { return Apply(TweenOperation::OpPause, FilterType::All, null, "", -999); }
    int TogglePauseAll()                   { return Apply(TweenOperation::OpTogglePause, FilterType::All, null, "", -999); }
    int PlayForwardAll()                   { return Apply(TweenOperation::OpPlayForward, FilterType::All, null, "", -999); }
    int PlayBackwardsAll()                 { return Apply(TweenOperation::OpPlayBackwards, FilterType::All, null, "", -999); }
    int RewindAll(bool includeDelay = true){ return Apply(TweenOperation::OpRewind, FilterType::All, null, "", -999, 0.0f, includeDelay); }
    int SmoothRewindAll()                  { return Apply(TweenOperation::OpSmoothRewind, FilterType::All, null, "", -999); }
    int RestartAll(bool includeDelay = true){ return Apply(TweenOperation::OpRestart, FilterType::All, null, "", -999, 0.0f, includeDelay); }
    int CompleteAll(bool withCallbacks = false){ return Apply(TweenOperation::OpComplete, FilterType::All, null, "", -999, 0.0f, withCallbacks); }
    int KillAll(bool complete = false)     { return Apply(TweenOperation::OpKill, FilterType::All, null, "", -999, 0.0f, complete); }
    int FlipAll()                          { return Apply(TweenOperation::OpFlip, FilterType::All, null, "", -999); }
    int GotoAll(float to, bool andPlay = false){ return Apply(TweenOperation::OpGoto, FilterType::All, null, "", -999, to, andPlay); }

    int Play(Object@ target)               { return Apply(TweenOperation::OpPlay, FilterType::TargetOrId, target, "", -999); }
    int Play(const string&in id)           { return Apply(TweenOperation::OpPlay, FilterType::TargetOrId, null, id, -999); }
    int Play(int id)                       { return Apply(TweenOperation::OpPlay, FilterType::TargetOrId, null, "", id); }
    int Pause(Object@ target)              { return Apply(TweenOperation::OpPause, FilterType::TargetOrId, target, "", -999); }
    int Pause(const string&in id)          { return Apply(TweenOperation::OpPause, FilterType::TargetOrId, null, id, -999); }
    int Pause(int id)                      { return Apply(TweenOperation::OpPause, FilterType::TargetOrId, null, "", id); }
    int TogglePause(Object@ target)        { return Apply(TweenOperation::OpTogglePause, FilterType::TargetOrId, target, "", -999); }
    int PlayForward(Object@ target)        { return Apply(TweenOperation::OpPlayForward, FilterType::TargetOrId, target, "", -999); }
    int PlayBackwards(Object@ target)      { return Apply(TweenOperation::OpPlayBackwards, FilterType::TargetOrId, target, "", -999); }
    int Rewind(Object@ target, bool includeDelay = true){ return Apply(TweenOperation::OpRewind, FilterType::TargetOrId, target, "", -999, 0.0f, includeDelay); }
    int SmoothRewind(Object@ target)       { return Apply(TweenOperation::OpSmoothRewind, FilterType::TargetOrId, target, "", -999); }
    int Restart(Object@ target, bool includeDelay = true){ return Apply(TweenOperation::OpRestart, FilterType::TargetOrId, target, "", -999, 0.0f, includeDelay); }
    int Complete(Object@ target, bool withCallbacks = false){ return Apply(TweenOperation::OpComplete, FilterType::TargetOrId, target, "", -999, 0.0f, withCallbacks); }
    int Flip(Object@ target)               { return Apply(TweenOperation::OpFlip, FilterType::TargetOrId, target, "", -999); }
    int Goto(Object@ target, float to, bool andPlay = false){ return Apply(TweenOperation::OpGoto, FilterType::TargetOrId, target, "", -999, to, andPlay); }

    int Kill(Object@ target, bool complete = false)    { return Apply(TweenOperation::OpKill, FilterType::TargetOrId, target, "", -999, 0.0f, complete); }
    int Kill(const string&in id, bool complete = false){ return Apply(TweenOperation::OpKill, FilterType::TargetOrId, null, id, -999, 0.0f, complete); }
    int Kill(int id, bool complete = false)            { return Apply(TweenOperation::OpKill, FilterType::TargetOrId, null, "", id, 0.0f, complete); }

    /// <summary>
    /// Whether anything is currently tweening a target or id.
    /// </summary>
    /// <param name="target">The target to look for.</param>
    /// <param name="playingOnly">Whether paused tweens are ignored.</param>
    /// <returns>Returns true when at least one tween matches.</returns>
    bool IsTweening(Object@ target, bool playingOnly = false)
    {
        return Manager().Collect(FilterType::TargetOrId, target, "", -999, playingOnly).length() > 0;
    }

    /// <summary>
    /// Whether anything is currently tweening under a string id.
    /// </summary>
    /// <param name="id">The id to look for.</param>
    /// <param name="playingOnly">Whether paused tweens are ignored.</param>
    /// <returns>Returns true when at least one tween matches.</returns>
    bool IsTweening(const string&in id, bool playingOnly = false)
    {
        return Manager().Collect(FilterType::TargetOrId, null, id, -999, playingOnly).length() > 0;
    }

    /// <summary>
    /// Every live tween driving a target.
    /// </summary>
    /// <param name="target">The target to look for.</param>
    /// <param name="playingOnly">Whether paused tweens are ignored.</param>
    /// <returns>Returns the matching tweens, empty when there are none.</returns>
    array<ITween@>@ TweensByTarget(Object@ target, bool playingOnly = false)
    {
        return Manager().Collect(FilterType::TargetOrId, target, "", -999, playingOnly);
    }

    /// <summary>
    /// Every live tween carrying a string id.
    /// </summary>
    /// <param name="id">The id to look for.</param>
    /// <param name="playingOnly">Whether paused tweens are ignored.</param>
    /// <returns>Returns the matching tweens, empty when there are none.</returns>
    array<ITween@>@ TweensById(const string&in id, bool playingOnly = false)
    {
        return Manager().Collect(FilterType::TargetOrId, null, id, -999, playingOnly);
    }

    /// <summary>Every tween that is currently advancing.</summary>
    /// <returns>Returns the playing tweens.</returns>
    array<ITween@>@ PlayingTweens()
    {
        return Manager().Collect(FilterType::All, null, "", -999, true);
    }

    // =================================================================================================
    // Creation
    // =================================================================================================

    /// <summary>
    /// Animates a float between its current value and a target value.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ To(FloatGetter@ getter, FloatSetter@ setter, float to, float duration)
    {
        TweenFloat@ tween = TweenFloat();
        tween.Bind(getter, setter, to, duration);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Animates a Vector2 between its current value and a target value.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ To(Vector2Getter@ getter, Vector2Setter@ setter, Vector2 to, float duration)
    {
        TweenVector2@ tween = TweenVector2();
        tween.Bind(getter, setter, to, duration);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Animates a Vector3 between its current value and a target value.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ To(Vector3Getter@ getter, Vector3Setter@ setter, Vector3 to, float duration)
    {
        TweenVector3@ tween = TweenVector3();
        tween.Bind(getter, setter, to, duration);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Animates a colour between its current value and a target value.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ To(ColorGetter@ getter, ColorSetter@ setter, Color to, float duration)
    {
        TweenColor@ tween = TweenColor();
        tween.Bind(getter, setter, to, duration);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Animates only the alpha channel of a colour, leaving the hue alone.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="toAlpha">The alpha to reach.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ ToAlpha(ColorGetter@ getter, ColorSetter@ setter, float toAlpha, float duration)
    {
        TweenColor@ tween = TweenColor();
        tween.Bind(getter, setter, Color(0.0f, 0.0f, 0.0f, toAlpha), duration);
        tween.SetAlphaOnly(true);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Animates a rotation expressed as a scalar angle in degrees.
    /// </summary>
    /// <param name="getter">Reads the current angle.</param>
    /// <param name="setter">Writes the new angle.</param>
    /// <param name="toDegrees">The angle to reach.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenAngle@ ToAngle(FloatGetter@ getter, FloatSetter@ setter, float toDegrees, float duration)
    {
        TweenAngle@ tween = TweenAngle();
        tween.Bind(getter, setter, toDegrees, duration);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Copies the manager defaults onto a new tween and starts it if auto-play is on.
    /// </summary>
    /// <param name="tween">The tween being created.</param>
    void ApplyDefaults(ITween@ tween)
    {
        TweenyManager@ manager = Manager();
        tween.ApplyManagerDefaults(manager.defaultEase, manager.defaultEaseOvershoot,
            manager.defaultEasePeriod, manager.defaultAutoKill, manager.defaultLoopType,
            manager.defaultUpdateType, manager.defaultTimeScaleIndependent);
        if (manager.defaultAutoPlay == AutoPlay::All || manager.defaultAutoPlay == AutoPlay::AutoPlayTweeners) {
            tween.Play();
        }
    }
}
