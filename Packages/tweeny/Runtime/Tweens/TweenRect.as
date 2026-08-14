using namespace CometEngine;

namespace Tweeny
{
    /// <summary>Reads the current value of whatever a Rectf tween drives.</summary>
    /// <returns>Returns the current value.</returns>
    funcdef Rectf RectGetter();

    /// <summary>Writes a new value to whatever a Rectf tween drives.</summary>
    /// <param name="value">The value to write.</param>
    funcdef void RectSetter(Rectf value);

    /// <summary>
    /// Animates a rectangle. Rectf carries no arithmetic operators of its own, so each of the four
    /// components is interpolated by hand.
    /// </summary>
    class TweenRect : ITween, TweenCore
    {
        private RectGetter@ getter;
        private RectSetter@ setter;
        private Rectf startValue;
        private Rectf endValue;
        private Rectf changeValue;
        private bool snapping = false;

        /// <summary>Binds the tween to a value.</summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="to">The value to reach.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(RectGetter@ valueGetter, RectSetter@ valueSetter, Rectf to, float tweenDuration)
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
                endValue = Rectf(startValue.x + endValue.x, startValue.y + endValue.y,
                    startValue.w + endValue.w, startValue.h + endValue.h);
            }
            if (isFrom) {
                Rectf realEnd = startValue;
                Rectf realStart = endValue;
                startValue = realStart;
                endValue = realEnd;
                setter(startValue);
            }

            changeValue = Rectf(endValue.x - startValue.x, endValue.y - startValue.y,
                endValue.w - startValue.w, endValue.h - startValue.h);
            return true;
        }

        void TweenApply(float eased, UpdateNotice notice)
        {
            if (setter is null) {
                return;
            }
            float x = startValue.x + changeValue.x * eased;
            float y = startValue.y + changeValue.y * eased;
            float w = startValue.w + changeValue.w * eased;
            float h = startValue.h + changeValue.h * eased;
            if (snapping) {
                x = float(Math::RoundToInt(x));
                y = float(Math::RoundToInt(y));
                w = float(Math::RoundToInt(w));
                h = float(Math::RoundToInt(h));
            }
            setter(Rectf(x, y, w, h));
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
        Rectf GetStartValue() const { return startValue; }

        /// <summary>The value the tween is heading to.</summary>
        /// <returns>Returns the end value.</returns>
        Rectf GetEndValue() const { return endValue; }

        TweenRect@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenRect@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenRect@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenRect@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenRect@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenRect@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenRect@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenRect@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenRect@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenRect@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenRect@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenRect@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenRect@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenRect@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Rounds every written component to the nearest whole number.</summary>
        /// <param name="value">Whether snapping is enabled.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenRect@ SetSnapping(bool value = true) { snapping = value; return this; }

        /// <summary>Plays the tween from the end value back to the target's current value.</summary>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenRect@ From(bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            return this;
        }

        TweenRect@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenRect@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenRect@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenRect@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenRect@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenRect@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenRect@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenRect@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
