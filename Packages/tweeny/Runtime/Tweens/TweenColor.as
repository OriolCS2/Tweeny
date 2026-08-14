using namespace CometEngine;

namespace Tweeny
{
    /// <summary>Reads the current value of whatever a Color tween drives.</summary>
    /// <returns>Returns the current value.</returns>
    funcdef Color ColorGetter();

    /// <summary>Writes a new value to whatever a Color tween drives.</summary>
    /// <param name="value">The value to write.</param>
    funcdef void ColorSetter(Color value);

    /// <summary>
    /// Animates a colour between two values, optionally touching only the alpha channel so a fade does not
    /// fight a separate tint tween running on the same renderer.
    ///
    /// Comet's Color has no Lerp of its own, so the interpolation lives here.
    /// </summary>
    class TweenColor : ITween, TweenCore
    {
        private ColorGetter@ getter;
        private ColorSetter@ setter;
        private Color startValue;
        private Color endValue;
        private Color changeValue;
        private bool alphaOnly = false;
        private bool hasGivenFromValue = false;
        private Color givenFromValue;

        /// <summary>Binds the tween to a value.</summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="to">The value to reach.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(ColorGetter@ valueGetter, ColorSetter@ valueSetter, Color to, float tweenDuration)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            endValue = to;
            duration = tweenDuration < 0.0f ? 0.0f : tweenDuration;
        }

        bool TweenStartup()
        {
            if (getter is null || setter is null) {
                return false;
            }
            startValue = getter();

            if (isRelative && !isFrom) {
                endValue = Add(startValue, endValue);
            }
            if (isFrom) {
                Color realEnd = startValue;
                Color realStart = hasGivenFromValue ? givenFromValue : endValue;
                if (isRelative) {
                    realStart = Add(realEnd, realStart);
                }
                startValue = realStart;
                endValue = realEnd;
                setter(startValue);
            }

            changeValue = Subtract(endValue, startValue);

            if (isSpeedBased) {
                float speed = duration;
                float magnitude = Math::Abs(changeValue.r) + Math::Abs(changeValue.g)
                    + Math::Abs(changeValue.b) + Math::Abs(changeValue.a);
                duration = speed <= 0.0f ? 0.0f : magnitude / speed;
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
            if (alphaOnly) {
                Color value = getter is null ? startValue : getter();
                value.a = startValue.a + changeValue.a * eased;
                setter(value);
                return;
            }
            Color value;
            value.r = startValue.r + changeValue.r * eased;
            value.g = startValue.g + changeValue.g * eased;
            value.b = startValue.b + changeValue.b * eased;
            value.a = startValue.a + changeValue.a * eased;
            setter(value);
        }

        private Color Add(const Color&in a, const Color&in b)
        {
            return Color(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a);
        }

        private Color Subtract(const Color&in a, const Color&in b)
        {
            return Color(a.r - b.r, a.g - b.g, a.b - b.b, a.a - b.a);
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
        Color GetStartValue() const { return startValue; }

        /// <summary>The value the tween is heading to.</summary>
        /// <returns>Returns the end value.</returns>
        Color GetEndValue() const { return endValue; }

        /// <summary>Replaces the end value and rewinds the tween.</summary>
        /// <param name="to">The new end value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenColor@ ChangeEndValue(Color to, float newDuration = -1.0f)
        {
            endValue = to;
            isRelative = false;
            if (newDuration >= 0.0f) { duration = newDuration; }
            if (startupDone) { changeValue = Subtract(endValue, startValue); }
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        TweenColor@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenColor@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenColor@ SetEase(Ease value, float amplitude, float period) { CoreSetEaseParams(value, amplitude, period); return this; }
        TweenColor@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenColor@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenColor@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenColor@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenColor@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenColor@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenColor@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenColor@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenColor@ SetUpdate(bool independent) { CoreSetUpdate(updateType, independent); return this; }
        TweenColor@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenColor@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenColor@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenColor@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenColor@ SetInverted(bool value = true) { CoreSetInverted(value); return this; }
        TweenColor@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Writes only the alpha channel, leaving the colour untouched.</summary>
        /// <param name="value">Whether the tween is alpha only.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenColor@ SetAlphaOnly(bool value = true) { alphaOnly = value; return this; }

        /// <summary>Plays the tween from the end value back to the target's current value.</summary>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenColor@ From(bool relative = false)
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
        TweenColor@ From(Color from, bool setImmediately = true, bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = true;
            givenFromValue = from;
            if (setImmediately) { ForceInit(); }
            return this;
        }

        TweenColor@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenColor@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenColor@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenColor@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenColor@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenColor@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenColor@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenColor@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
