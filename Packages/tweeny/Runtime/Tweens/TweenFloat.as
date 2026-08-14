using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Reads the current value of whatever a float tween drives.
    /// </summary>
    /// <returns>Returns the current value.</returns>
    funcdef float FloatGetter();

    /// <summary>
    /// Writes a new value to whatever a float tween drives.
    /// </summary>
    /// <param name="value">The value to write.</param>
    funcdef void FloatSetter(float value);

    /// <summary>
    /// Animates a single float between two values.
    /// </summary>
    class TweenFloat : ITween, TweenCore
    {
        private FloatGetter@ getter;
        private FloatSetter@ setter;
        private float startValue = 0.0f;
        private float endValue = 0.0f;
        private float changeValue = 0.0f;
        private bool snapping = false;
        private bool hasGivenFromValue = false;
        private float givenFromValue = 0.0f;

        /// <summary>
        /// Binds the tween to a value.
        /// </summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="to">The value to reach.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(FloatGetter@ valueGetter, FloatSetter@ valueSetter, float to, float tweenDuration)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            endValue = to;
            duration = tweenDuration < 0.0f ? 0.0f : tweenDuration;
        }

        // ---- required by TweenCore ------------------------------------------------------------------

        /// <summary>
        /// Captures the start value and resolves relative, from and speed-based settings.
        /// </summary>
        /// <returns>Returns false when the tween has no value to drive.</returns>
        bool TweenStartup()
        {
            if (getter is null || setter is null) {
                return false;
            }

            startValue = getter();

            if (isRelative && !isFrom) {
                endValue = startValue + endValue;
            }

            if (isFrom) {
                float realEnd = startValue;
                float realStart = hasGivenFromValue ? givenFromValue : endValue;
                if (isRelative) {
                    realStart = realEnd + realStart;
                }
                startValue = realStart;
                endValue = realEnd;
                setter(startValue);
            }

            changeValue = endValue - startValue;

            if (isSpeedBased) {
                float speed = duration;
                duration = speed <= 0.0f ? 0.0f : Math::Abs(changeValue / speed);
                if (duration <= 0.0f) {
                    easeType = Ease::INTERNAL_Zero;
                }
            }

            return true;
        }

        /// <summary>
        /// Writes the interpolated value.
        /// </summary>
        /// <param name="eased">The eased progress, which may leave 0..1 for overshooting curves.</param>
        /// <param name="notice">Extra information about the step that just happened.</param>
        void TweenApply(float eased, UpdateNotice notice)
        {
            if (setter is null) {
                return;
            }
            float value = startValue + changeValue * eased;
            if (snapping) {
                value = float(Math::RoundToInt(value));
            }
            setter(value);
        }

        /// <summary>
        /// Drops the handles so the tween stops keeping its target alive.
        /// </summary>
        void TweenReleaseReferences()
        {
            @getter = null;
            @setter = null;
            @tweenTarget = null;
            @onStart = null;
            @onPlay = null;
            @onPause = null;
            @onRewind = null;
            @onUpdate = null;
            @onStepComplete = null;
            @onComplete = null;
            @onKill = null;
            @onWaypointChange = null;
            @customEase = null;
        }

        /// <summary>
        /// Releases every handle held by the tween.
        /// </summary>
        void ReleaseReferences()
        {
            TweenReleaseReferences();
        }

        // ---- values ---------------------------------------------------------------------------------

        /// <summary>The value the tween started from.</summary>
        /// <returns>Returns the start value, valid once the tween has started.</returns>
        float GetStartValue() const { return startValue; }

        /// <summary>The value the tween is heading to.</summary>
        /// <returns>Returns the end value.</returns>
        float GetEndValue() const { return endValue; }

        /// <summary>
        /// Replaces the end value and rewinds the tween so the new target is honoured.
        /// </summary>
        /// <param name="to">The new end value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenFloat@ ChangeEndValue(float to, float newDuration = -1.0f)
        {
            endValue = to;
            isRelative = false;
            if (newDuration >= 0.0f) {
                duration = newDuration;
            }
            if (startupDone) {
                changeValue = endValue - startValue;
            }
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        /// <summary>
        /// Replaces the start value and rewinds the tween.
        /// </summary>
        /// <param name="from">The new start value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenFloat@ ChangeStartValue(float from, float newDuration = -1.0f)
        {
            ForceInit();
            startValue = from;
            if (newDuration >= 0.0f) {
                duration = newDuration;
            }
            changeValue = endValue - startValue;
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        /// <summary>
        /// Replaces both ends and rewinds the tween.
        /// </summary>
        /// <param name="from">The new start value.</param>
        /// <param name="to">The new end value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenFloat@ ChangeValues(float from, float to, float newDuration = -1.0f)
        {
            ForceInit();
            startValue = from;
            endValue = to;
            isRelative = false;
            if (newDuration >= 0.0f) {
                duration = newDuration;
            }
            changeValue = endValue - startValue;
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        // ---- fluent settings ------------------------------------------------------------------------

        TweenFloat@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenFloat@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenFloat@ SetEase(Ease value, float amplitude, float period) { CoreSetEaseParams(value, amplitude, period); return this; }
        TweenFloat@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenFloat@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenFloat@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenFloat@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenFloat@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenFloat@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenFloat@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenFloat@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenFloat@ SetUpdate(bool independent) { CoreSetUpdate(updateType, independent); return this; }
        TweenFloat@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenFloat@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenFloat@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenFloat@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenFloat@ SetInverted(bool value = true) { CoreSetInverted(value); return this; }
        TweenFloat@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>
        /// Rounds every written value to the nearest whole number.
        /// </summary>
        /// <param name="value">Whether snapping is enabled.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenFloat@ SetSnapping(bool value = true) { snapping = value; return this; }

        /// <summary>
        /// Plays the tween from the end value back to the target's current value.
        /// </summary>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenFloat@ From(bool relative = false)
        {
            if (creationLocked || noFromAllowed) {
                return this;
            }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = false;
            return this;
        }

        /// <summary>
        /// Plays the tween from an explicit value back to the target's current value.
        /// </summary>
        /// <param name="from">The value to start from.</param>
        /// <param name="setImmediately">Whether the target jumps to the from value right away.</param>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenFloat@ From(float from, bool setImmediately = true, bool relative = false)
        {
            if (creationLocked || noFromAllowed) {
                return this;
            }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = true;
            givenFromValue = from;
            if (setImmediately) {
                // Startup captures the target's current value as the tween's END and writes the from
                // value itself, so it has to run before anything touches the target.
                ForceInit();
            }
            return this;
        }

        // ---- fluent callbacks -----------------------------------------------------------------------

        TweenFloat@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenFloat@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenFloat@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenFloat@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenFloat@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenFloat@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenFloat@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenFloat@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
