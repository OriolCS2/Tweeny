using namespace CometEngine;

namespace Tweeny
{
    /// <summary>Reads the current value of whatever an int tween drives.</summary>
    /// <returns>Returns the current value.</returns>
    funcdef int IntGetter();

    /// <summary>Writes a new value to whatever an int tween drives.</summary>
    /// <param name="value">The value to write.</param>
    funcdef void IntSetter(int value);

    /// <summary>
    /// Animates a whole number. Interpolation happens in floating point and is rounded on the way out, so a
    /// counter climbing from 0 to 100 passes through every intermediate value rather than jumping.
    /// </summary>
    class TweenInt : ITween, TweenCore
    {
        private IntGetter@ getter;
        private IntSetter@ setter;
        private float startValue = 0.0f;
        private float endValue = 0.0f;
        private float changeValue = 0.0f;
        private bool hasGivenFromValue = false;
        private int givenFromValue = 0;

        /// <summary>Binds the tween to a value.</summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="to">The value to reach.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(IntGetter@ valueGetter, IntSetter@ valueSetter, int to, float tweenDuration)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            endValue = float(to);
            duration = tweenDuration < 0.0f ? 0.0f : tweenDuration;
        }

        bool TweenStartup()
        {
            if (getter is null || setter is null) {
                return false;
            }
            startValue = float(getter());

            if (isRelative && !isFrom) {
                endValue = startValue + endValue;
            }
            if (isFrom) {
                float realEnd = startValue;
                float realStart = hasGivenFromValue ? float(givenFromValue) : endValue;
                if (isRelative) {
                    realStart = realEnd + realStart;
                }
                startValue = realStart;
                endValue = realEnd;
                setter(Math::RoundToInt(startValue));
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

        void TweenApply(float eased, UpdateNotice notice)
        {
            if (setter is null) {
                return;
            }
            setter(Math::RoundToInt(startValue + changeValue * eased));
        }

        void TweenReleaseReferences()
        {
            @getter = null;
            @setter = null;
            @tweenTarget = null;
            @onStart = null; @onPlay = null; @onPause = null; @onRewind = null;
            @onUpdate = null; @onStepComplete = null; @onComplete = null; @onKill = null;
            @onWaypointChange = null; @customEase = null;
        }

        void ReleaseReferences() { TweenReleaseReferences(); }

        /// <summary>The value the tween started from.</summary>
        /// <returns>Returns the start value.</returns>
        int GetStartValue() const { return Math::RoundToInt(startValue); }

        /// <summary>The value the tween is heading to.</summary>
        /// <returns>Returns the end value.</returns>
        int GetEndValue() const { return Math::RoundToInt(endValue); }

        /// <summary>Replaces the end value and rewinds the tween.</summary>
        /// <param name="to">The new end value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenInt@ ChangeEndValue(int to, float newDuration = -1.0f)
        {
            endValue = float(to);
            isRelative = false;
            if (newDuration >= 0.0f) { duration = newDuration; }
            if (startupDone) { changeValue = endValue - startValue; }
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        TweenInt@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenInt@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenInt@ SetEase(Ease value, float amplitude, float period) { CoreSetEaseParams(value, amplitude, period); return this; }
        TweenInt@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenInt@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenInt@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenInt@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenInt@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenInt@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenInt@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenInt@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenInt@ SetUpdate(bool independent) { CoreSetUpdate(updateType, independent); return this; }
        TweenInt@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenInt@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenInt@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenInt@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenInt@ SetInverted(bool value = true) { CoreSetInverted(value); return this; }
        TweenInt@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Plays the tween from the end value back to the target's current value.</summary>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenInt@ From(bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = false;
            return this;
        }

        /// <summary>Plays the tween from an explicit value back to the target's current value.</summary>
        /// <param name="from">The value to start from.</param>
        /// <param name="setImmediately">Whether the target jumps to the from value right away.</param>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenInt@ From(int from, bool setImmediately = true, bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = true;
            givenFromValue = from;
            if (setImmediately) { ForceInit(); }
            return this;
        }

        TweenInt@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenInt@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenInt@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenInt@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenInt@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenInt@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenInt@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenInt@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
