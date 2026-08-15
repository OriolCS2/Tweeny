using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// The whole tween state machine, shared by every concrete tween type.
    ///
    /// AngelScript has no generics, so instead of one templated tween class there is one class per value
    /// type, each including this mixin. The mixin carries all the timing, looping, easing and callback
    /// logic; the including class only has to supply three things:
    ///
    ///   bool TweenStartup()                              -- capture the start value, resolve relative/from/speed-based
    ///   void TweenApply(float eased, UpdateNotice notice) -- write the interpolated value to the target
    ///   void TweenReleaseReferences()                     -- drop the getter, setter and target handles
    ///
    /// One rule holds the design together: the POSITION is authoritative and the delta is only an
    /// input. Everything -- ticking, Goto, Rewind, Complete, Restart and sequence playback -- funnels
    /// through DoGotoInternal, so there is a single place where callbacks and loop accounting happen.
    /// </summary>
    mixin class TweenCore
    {
        // ---- identity -------------------------------------------------------------------------------
        protected string tweenStringId = "";
        protected int tweenIntId = -999;
        protected Object@ tweenTarget;

        // ---- timing ---------------------------------------------------------------------------------
        protected float duration = 0.0f;
        protected float position = 0.0f;
        protected float delay = 0.0f;
        protected float elapsedDelay = 0.0f;
        protected bool delayComplete = true;
        protected int loops = 1;
        protected int completedLoops = 0;
        protected LoopType loopType = LoopType::Restart;
        protected float timeScale = 1.0f;

        // ---- easing ---------------------------------------------------------------------------------
        protected Ease easeType = Ease::Unset;
        protected EaseFunc@ customEase;
        protected float easeOvershootOrAmplitude = DEFAULT_OVERSHOOT;
        protected float easePeriod = DEFAULT_PERIOD;

        // ---- state ----------------------------------------------------------------------------------
        protected bool active = true;
        protected bool isPlaying = false;
        protected bool isComplete = false;
        protected bool isBackwards = false;
        protected bool isInverted = false;
        protected bool playedOnce = false;
        protected bool startupDone = false;
        protected bool creationLocked = false;
        protected bool autoKill = true;
        protected bool isRelative = false;
        protected bool isSpeedBased = false;
        protected bool isFrom = false;
        protected bool noFromAllowed = false;
        protected bool isBlendable = false;
        protected bool isSequenced = false;
        protected bool killPending = false;
        protected UpdateType updateType = UpdateType::Normal;
        protected bool independentUpdate = false;
        protected TweenType tweenType = TweenType::Tweener;

        // ---- callbacks ------------------------------------------------------------------------------
        protected TweenCallback@ onStart;
        protected TweenCallback@ onPlay;
        protected TweenCallback@ onPause;
        protected TweenCallback@ onRewind;
        protected TweenCallback@ onUpdate;
        protected TweenCallback@ onStepComplete;
        protected TweenCallback@ onComplete;
        protected TweenCallback@ onKill;
        protected TweenCallbackInt@ onWaypointChange;

        // =============================================================================================
        // Scheduler entry point
        // =============================================================================================

        /// <summary>
        /// Advances the tween by one frame: it turns the delta into a target position and loop count, then
        /// hands both to DoGotoInternal, which is the only place that actually moves the tween.
        /// </summary>
        /// <param name="deltaTime">Scaled seconds since the last tick.</param>
        /// <param name="unscaledDeltaTime">Unscaled seconds since the last tick.</param>
        /// <returns>Returns true when the tween must be removed from the active list.</returns>
        bool TweenTick(float deltaTime, float unscaledDeltaTime)
        {
            if (!active) {
                return true;
            }
            if (!isPlaying) {
                return false;
            }

            creationLocked = true;

            float step = (independentUpdate ? unscaledDeltaTime : deltaTime) * timeScale;
            const float EPSILON = 0.000001f;
            if (step < EPSILON && step > -EPSILON) {
                return false;
            }

            if (!delayComplete) {
                step = ConsumeDelay(elapsedDelay + step);
                if (step <= 0.0f) {
                    return false;
                }
                if (playedOnce && onPlay !is null) {
                    onPlay();
                    if (!active) {
                        return true;
                    }
                }
            }

            if (!startupDone) {
                if (!DoStartup()) {
                    return true;
                }
            }

            float toPosition = position;
            bool wasEndPosition = toPosition >= duration;
            int toCompletedLoops = completedLoops;

            if (duration <= 0.0f) {
                toPosition = 0.0f;
                toCompletedLoops = loops == -1 ? completedLoops + 1 : loops;
            }
            else {
                if (isBackwards) {
                    toPosition -= step;
                    while (toPosition < 0.0f && toCompletedLoops > -1) {
                        toPosition += duration;
                        toCompletedLoops--;
                    }
                    if (toCompletedLoops < 0 || (wasEndPosition && toCompletedLoops < 1)) {
                        toPosition = 0.0f;
                        toCompletedLoops = wasEndPosition ? 1 : 0;
                    }
                }
                else {
                    toPosition += step;
                    while (toPosition >= duration && (loops == -1 || toCompletedLoops < loops)) {
                        toPosition -= duration;
                        toCompletedLoops++;
                    }
                }
                if (wasEndPosition) {
                    toCompletedLoops--;
                }
                if (loops != -1 && toCompletedLoops >= loops) {
                    toPosition = duration;
                }
            }

            return DoGotoInternal(toPosition, toCompletedLoops, UpdateMode::Update);
        }

        /// <summary>
        /// Places the tween at an exact position and loop count and fires whatever callbacks that implies.
        /// This is the single code path every other operation goes through.
        /// </summary>
        /// <param name="toPosition">Target position inside the loop, in seconds.</param>
        /// <param name="toCompletedLoops">Target number of finished loops.</param>
        /// <param name="updateMode">Which callbacks are allowed to fire.</param>
        /// <returns>Returns true when the tween must be removed from the active list.</returns>
        bool DoGotoInternal(float toPosition, int toCompletedLoops, UpdateMode updateMode)
        {
            if (!startupDone) {
                if (!DoStartup()) {
                    return true;
                }
            }

            if (!playedOnce && updateMode == UpdateMode::Update) {
                playedOnce = true;
                if (onStart !is null) {
                    onStart();
                    if (!active) {
                        return true;
                    }
                }
                if (onPlay !is null) {
                    onPlay();
                    if (!active) {
                        return true;
                    }
                }
            }

            float prevPosition = position;
            int prevCompletedLoops = completedLoops;
            completedLoops = toCompletedLoops;
            bool wasRewinded = position <= 0.0f && prevCompletedLoops <= 0;
            bool wasComplete = isComplete;

            if (loops != -1) {
                isComplete = completedLoops == loops;
            }

            int newCompletedSteps = 0;
            if (updateMode == UpdateMode::Update) {
                if (isBackwards) {
                    newCompletedSteps = completedLoops < prevCompletedLoops
                        ? prevCompletedLoops - completedLoops
                        : ((toPosition <= 0.0f && !wasRewinded) ? 1 : 0);
                    if (wasComplete) {
                        newCompletedSteps--;
                    }
                }
                else {
                    newCompletedSteps = completedLoops > prevCompletedLoops
                        ? completedLoops - prevCompletedLoops
                        : 0;
                }
            }
            else if (tweenType == TweenType::Sequence) {
                newCompletedSteps = prevCompletedLoops - toCompletedLoops;
                if (newCompletedSteps < 0) {
                    newCompletedSteps = -newCompletedSteps;
                }
            }

            position = toPosition;
            if (position > duration) {
                position = duration;
            }
            else if (position <= 0.0f) {
                position = (completedLoops > 0 || isComplete) ? duration : 0.0f;
            }

            bool wasPlaying = isPlaying;
            if (isPlaying) {
                if (!isBackwards) {
                    isPlaying = !isComplete;
                }
                else {
                    isPlaying = !(completedLoops == 0 && position <= 0.0f);
                }
            }

            bool useInversePosition = HasLoops() && loopType == LoopType::Yoyo
                && (position < duration ? completedLoops % 2 != 0 : completedLoops % 2 == 0);
            if (isInverted) {
                useInversePosition = !useInversePosition;
            }

            bool isRewindStep = !wasRewinded && (
                (loopType == LoopType::Restart && completedLoops != prevCompletedLoops
                    && (loops == -1 || completedLoops < loops))
                || (position <= 0.0f && completedLoops <= 0));
            UpdateNotice notice = isRewindStep ? UpdateNotice::RewindStep : UpdateNotice::None;

            TweenApply(ComputeEasedValue(useInversePosition), notice);

            if (onUpdate !is null && updateMode != UpdateMode::IgnoreOnUpdate) {
                onUpdate();
                if (!active) {
                    return true;
                }
            }
            if (position <= 0.0f && completedLoops <= 0 && !wasRewinded && onRewind !is null) {
                onRewind();
                if (!active) {
                    return true;
                }
            }
            if (newCompletedSteps > 0 && updateMode == UpdateMode::Update && onStepComplete !is null) {
                for (int i = 0; i < newCompletedSteps; i++) {
                    onStepComplete();
                    if (!active) {
                        break;
                    }
                }
            }
            if (isComplete && !wasComplete && updateMode != UpdateMode::IgnoreOnComplete && onComplete !is null) {
                onComplete();
                if (!active) {
                    return true;
                }
            }
            if (!isPlaying && wasPlaying && (!isComplete || !autoKill) && onPause !is null) {
                onPause();
                if (!active) {
                    return true;
                }
            }

            return autoKill && isComplete;
        }

        /// <summary>
        /// Evaluates the easing curve at the current position, adding the finished loops when the loop type
        /// is Incremental so the value keeps climbing past 1.
        /// </summary>
        /// <param name="useInversePosition">Whether this cycle plays the curve backwards, as Yoyo does.</param>
        /// <returns>Returns the eased progress.</returns>
        float ComputeEasedValue(bool useInversePosition)
        {
            if (duration <= 0.0f) {
                return 1.0f;
            }
            float pos = useInversePosition ? duration - position : position;
            float eased = EaseManager::Evaluate(easeType, customEase, pos, duration,
                easeOvershootOrAmplitude, easePeriod);
            if (loopType == LoopType::Incremental) {
                eased += float(isComplete ? completedLoops - 1 : completedLoops);
            }
            return eased;
        }

        /// <summary>
        /// Consumes part of the delay and reports how much of the step is left for the tween itself.
        /// </summary>
        /// <param name="elapsed">The delay elapsed so far plus this frame's step.</param>
        /// <returns>Returns the leftover step in seconds, or 0 while the delay is still running.</returns>
        float ConsumeDelay(float elapsed)
        {
            if (elapsed > delay) {
                elapsedDelay = delay;
                delayComplete = true;
                return elapsed - delay;
            }
            elapsedDelay = elapsed;
            return 0.0f;
        }

        /// <summary>
        /// Runs the concrete type's startup once, resolving the duration for speed-based tweens.
        /// </summary>
        /// <returns>Returns false when the tween cannot run and must be killed.</returns>
        bool DoStartup()
        {
            startupDone = true;
            if (easeType == Ease::Unset) {
                easeType = Ease::OutQuad;
            }
            if (duration <= 0.0f) {
                easeType = Ease::INTERNAL_Zero;
            }
            if (!TweenStartup()) {
                active = false;
                return false;
            }
            return true;
        }

        /// <summary>Whether the tween runs more than one cycle.</summary>
        /// <returns>Returns true when the loop count is not exactly 1.</returns>
        bool HasLoops() const
        {
            return loops > 1 || loops == -1;
        }

        // =============================================================================================
        // Control
        // =============================================================================================

        void Play()
        {
            if (!active) {
                return;
            }
            bool canPlay = !isBackwards ? !isComplete : (completedLoops > 0 || position > 0.0f);
            if (!isPlaying && canPlay) {
                isPlaying = true;
                if (playedOnce && delayComplete && onPlay !is null) {
                    onPlay();
                }
            }
        }

        void Pause()
        {
            if (!active || !isPlaying) {
                return;
            }
            isPlaying = false;
            if (onPause !is null) {
                onPause();
            }
        }

        void TogglePause()
        {
            if (isPlaying) {
                Pause();
            }
            else {
                Play();
            }
        }

        void PlayForward()
        {
            if (!active) {
                return;
            }
            isBackwards = false;
            Play();
        }

        void PlayBackwards()
        {
            if (!active) {
                return;
            }
            if (completedLoops == 0 && position <= 0.0f) {
                isBackwards = true;
                isPlaying = false;
                return;
            }
            isBackwards = true;
            Play();
        }

        void Rewind(bool includeDelay = true)
        {
            if (!active) {
                return;
            }
            isPlaying = false;
            bool wasRewound = completedLoops == 0 && position <= 0.0f;
            if (includeDelay) {
                elapsedDelay = 0.0f;
                delayComplete = delay <= 0.0f;
            }
            else {
                elapsedDelay = delay;
                delayComplete = true;
            }
            if (!wasRewound || !startupDone) {
                DoGotoInternal(0.0f, 0, UpdateMode::Goto);
            }
        }

        void SmoothRewind()
        {
            if (!active) {
                return;
            }
            if (loopType == LoopType::Incremental) {
                PlayBackwards();
                return;
            }
            Goto(GetElapsedDirectionalPercentage() * duration, false, false);
            PlayBackwards();
        }

        void Restart(bool includeDelay = true)
        {
            if (!active) {
                return;
            }
            isBackwards = false;
            if (includeDelay) {
                elapsedDelay = 0.0f;
                delayComplete = delay <= 0.0f;
            }
            else {
                elapsedDelay = delay;
                delayComplete = true;
            }
            isComplete = false;
            DoGotoInternal(0.0f, 0, UpdateMode::Goto);
            isPlaying = true;
        }

        void Complete(bool withCallbacks = false)
        {
            if (!active || loops == -1) {
                return;
            }
            DoGotoInternal(duration, loops, withCallbacks ? UpdateMode::Update : UpdateMode::Goto);
            isPlaying = false;
            if (autoKill) {
                Kill(false);
            }
        }

        void Kill(bool complete = false)
        {
            if (!active) {
                return;
            }
            if (complete) {
                bool previousAutoKill = autoKill;
                autoKill = false;
                Complete(false);
                autoKill = previousAutoKill;
            }
            active = false;
            isPlaying = false;
            killPending = true;
            if (onKill !is null) {
                onKill();
            }
        }

        void Flip()
        {
            if (!active) {
                return;
            }
            isBackwards = !isBackwards;
        }

        void Goto(float to, bool andPlay = false, bool withCallbacks = false)
        {
            if (!active) {
                return;
            }
            if (!startupDone) {
                ForceInit();
            }

            float target = to < 0.0f ? 0.0f : to;
            int toCompletedLoops = 0;
            float toPosition = target;

            if (duration > 0.0f) {
                toCompletedLoops = Math::FloorToInt(target / duration);
                toPosition = target - float(toCompletedLoops) * duration;
                if (loops != -1 && toCompletedLoops >= loops) {
                    toCompletedLoops = loops;
                    toPosition = duration;
                }
            }
            else {
                toCompletedLoops = loops == -1 ? 1 : loops;
                toPosition = 0.0f;
            }

            isComplete = false;
            DoGotoInternal(toPosition, toCompletedLoops, withCallbacks ? UpdateMode::Update : UpdateMode::Goto);
            isPlaying = andPlay;
        }

        void ForceInit()
        {
            if (!startupDone) {
                DoStartup();
            }
        }

        // =============================================================================================
        // Getters
        // =============================================================================================

        bool IsActive() const { return active; }
        bool IsPlaying() const { return isPlaying; }
        bool IsComplete() const { return isComplete; }
        bool IsInitialized() const { return startupDone; }
        bool IsBackwards() const { return isBackwards; }
        bool IsSequenced() const { return isSequenced; }
        UpdateType GetUpdateType() const { return updateType; }
        bool IsIndependentUpdate() const { return independentUpdate; }
        string GetStringId() const { return tweenStringId; }
        int GetIntId() const { return tweenIntId; }
        Object@ GetTarget() const { return tweenTarget; }
        float GetPosition() const { return position; }
        float GetDuration() const { return duration; }
        int GetCompletedLoops() const { return completedLoops; }
        int GetLoops() const { return loops; }
        float GetDelay() const { return delay; }
        float GetElapsedDelay() const { return elapsedDelay; }

        /// <summary>
        /// Total elapsed time.
        /// </summary>
        /// <param name="includeLoops">Whether finished loops are counted in.</param>
        /// <returns>Returns the elapsed seconds.</returns>
        float GetElapsed(bool includeLoops = true) const
        {
            if (!includeLoops) {
                return position;
            }
            int fullLoops = completedLoops - (position >= duration ? 1 : 0);
            if (fullLoops < 0) {
                fullLoops = 0;
            }
            return float(fullLoops) * duration + position;
        }

        /// <summary>
        /// Total duration.
        /// </summary>
        /// <param name="includeLoops">Whether the loop count is multiplied in.</param>
        /// <returns>Returns the duration in seconds, or a very large number for infinite loops.</returns>
        float GetFullDuration(bool includeLoops = true) const
        {
            if (!includeLoops) {
                return duration;
            }
            return loops == -1 ? Math::FLT_MAX : duration * float(loops);
        }

        /// <summary>
        /// Progress across the whole tween including loops.
        /// </summary>
        /// <returns>Returns a value between 0 and 1.</returns>
        float GetElapsedPercentage() const
        {
            float full = GetFullDuration(true);
            if (full <= 0.0f) {
                return 0.0f;
            }
            return GetElapsed(true) / full;
        }

        /// <summary>
        /// Progress inside the current loop, mirrored on backwards Yoyo cycles so it always reads as
        /// "how far towards the current destination".
        /// </summary>
        /// <returns>Returns a value between 0 and 1.</returns>
        float GetElapsedDirectionalPercentage() const
        {
            if (duration <= 0.0f) {
                return 0.0f;
            }
            float perc = position / duration;
            bool inverted = HasLoops() && loopType == LoopType::Yoyo && completedLoops % 2 != 0;
            return inverted ? 1.0f - perc : perc;
        }

        // =============================================================================================
        // Settings
        //
        // These carry the validation; each concrete tween type wraps them in one-line fluent methods that
        // return its own type, because AngelScript resolves chained calls on the static type and an
        // interface cannot refine a return type.
        // =============================================================================================

        void CoreSetEase(Ease value)
        {
            easeType = value;
            @customEase = null;
        }

        void CoreSetEaseParams(Ease value, float overshootOrAmplitude, float period)
        {
            easeType = value;
            @customEase = null;
            easeOvershootOrAmplitude = overshootOrAmplitude;
            easePeriod = period;
        }

        void CoreSetEaseFunc(EaseFunc@ value)
        {
            if (value is null) {
                return;
            }
            easeType = Ease::INTERNAL_Custom;
            @customEase = value;
        }

        void CoreSetLoops(int count, LoopType kind)
        {
            if (creationLocked) {
                return;
            }
            loops = count < -1 ? -1 : (count == 0 ? 1 : count);
            loopType = kind;
        }

        void CoreSetDelay(float value)
        {
            if (creationLocked) {
                return;
            }
            delay = value < 0.0f ? 0.0f : value;
            elapsedDelay = 0.0f;
            delayComplete = delay <= 0.0f;
        }

        void CoreSetRelative(bool value)
        {
            if (creationLocked || isFrom || isBlendable) {
                return;
            }
            isRelative = value;
        }

        void CoreSetSpeedBased(bool value)
        {
            if (creationLocked || isSequenced) {
                return;
            }
            isSpeedBased = value;
        }

        void CoreSetAutoKill(bool value)
        {
            if (creationLocked) {
                return;
            }
            autoKill = value;
        }

        void CoreSetUpdate(UpdateType kind, bool independent)
        {
            updateType = kind;
            independentUpdate = independent;
        }

        void CoreSetStringId(const string&in value)
        {
            tweenStringId = value;
        }

        void CoreSetIntId(int value)
        {
            tweenIntId = value;
        }

        void CoreSetTarget(Object@ value)
        {
            @tweenTarget = value;
        }

        void CoreSetInverted(bool value)
        {
            if (creationLocked || isSequenced) {
                return;
            }
            isInverted = value;
        }

        void CoreSetTimeScale(float value)
        {
            timeScale = value;
        }

        /// <summary>Whether the tween plays from its end value towards the target's original one.</summary>
        /// <returns>Returns true for a From tween.</returns>
        bool IsFromTween() const { return isFrom; }

        /// <summary>
        /// Makes the tween safe to run inside the editor.
        ///
        /// Callbacks are cleared because a preview must never fire game logic, and auto-kill is turned off
        /// because the preview needs the tween to still be there when it stops so it can rewind it.
        /// </summary>
        void PrepareForPreview()
        {
            updateType = UpdateType::Manual;
            independentUpdate = true;
            autoKill = false;
            @onStart = null;
            @onPlay = null;
            @onPause = null;
            @onRewind = null;
            @onUpdate = null;
            @onStepComplete = null;
            @onComplete = null;
            @onKill = null;
            @onWaypointChange = null;
        }

        /// <summary>
        /// Puts the target back to the value it held before this tween first touched it.
        ///
        /// This is the preview's undo, and it belongs here because only the tween knows where that value
        /// went. An ordinary tween keeps it as its start value, so the target goes back to position zero.
        ///
        /// A From tween is the other way round: it was built to play towards the value the target already
        /// had, so the original is its end value, at the close of the first forward pass. That is asked for
        /// as loop one rather than loop zero because sitting exactly on the duration flips how a Yoyo reads
        /// the loop counter -- at loop zero it would take the pose as the start of the way back and hand
        /// over the from value instead of the original.
        ///
        /// It writes unconditionally, because neither of the obvious alternatives can be trusted to. Rewind
        /// skips the write when the tween looks untouched, and Complete refuses outright on an endless one,
        /// so a From animation set to loop forever was never being put back at all.
        /// </summary>
        void RestorePreTweenState()
        {
            if (!active || !startupDone) {
                return;
            }
            if (isFrom) {
                DoGotoInternal(duration, 1, UpdateMode::Goto);
            }
            else {
                DoGotoInternal(0.0f, 0, UpdateMode::Goto);
            }
        }

        /// <summary>
        /// Hands the tween over to a sequence. The sequence becomes the only thing that advances it, so the
        /// tween gives up its delay (the sequence expresses that as an offset instead), its auto-kill and
        /// any further configuration.
        /// </summary>
        void PrepareAsSequenced()
        {
            isSequenced = true;
            creationLocked = true;
            autoKill = false;
            isSpeedBased = false;
            delay = 0.0f;
            elapsedDelay = 0.0f;
            delayComplete = true;
            isPlaying = false;
        }

        /// <summary>
        /// The span this tween occupies inside a sequence.
        /// </summary>
        /// <returns>Returns one loop times the loop count, in seconds.</returns>
        float GetSequencedSpan() const
        {
            int effectiveLoops = loops == -1 ? 1 : loops;
            return duration * float(effectiveLoops);
        }

        /// <summary>
        /// Copies the project-wide defaults onto a freshly created tween. Called once, at creation, before
        /// the user has had a chance to chain any setting, so nothing here overrides an explicit choice.
        /// </summary>
        /// <param name="ease">The default easing curve.</param>
        /// <param name="overshoot">The default overshoot or amplitude.</param>
        /// <param name="period">The default period.</param>
        /// <param name="killOnComplete">Whether tweens are removed once finished.</param>
        /// <param name="defaultLoopType">The default loop style.</param>
        /// <param name="defaultUpdateType">The default update phase.</param>
        /// <param name="independent">Whether tweens ignore the game time scale by default.</param>
        void ApplyManagerDefaults(Ease ease, float overshoot, float period, bool killOnComplete,
            LoopType defaultLoopType, UpdateType defaultUpdateType, bool independent)
        {
            easeType = ease;
            easeOvershootOrAmplitude = overshoot;
            easePeriod = period;
            autoKill = killOnComplete;
            loopType = defaultLoopType;
            updateType = defaultUpdateType;
            independentUpdate = independent;
        }
    }
}
