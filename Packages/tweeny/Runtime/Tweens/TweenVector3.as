using namespace CometEngine;

namespace Tweeny
{
    /// <summary>Reads the current value of whatever a Vector3 tween drives.</summary>
    /// <returns>Returns the current value.</returns>
    funcdef Vector3 Vector3Getter();

    /// <summary>Writes a new value to whatever a Vector3 tween drives.</summary>
    /// <param name="value">The value to write.</param>
    funcdef void Vector3Setter(Vector3 value);

    /// <summary>
    /// Animates a Vector3 between two values. Comet's Transform is three-component even in a 2D game,
    /// where Z carries sorting depth, so this is the type most Transform shortcuts use.
    /// </summary>
    class TweenVector3 : ITween, TweenCore
    {
        private Vector3Getter@ getter;
        private Vector3Setter@ setter;
        private Vector3 startValue;
        private Vector3 endValue;
        private Vector3 changeValue;
        private bool snapping = false;
        private AxisConstraint axisConstraint = AxisConstraint::None;
        private bool hasGivenFromValue = false;
        private Vector3 givenFromValue;

        /// <summary>Binds the tween to a value.</summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="to">The value to reach.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(Vector3Getter@ valueGetter, Vector3Setter@ valueSetter, Vector3 to, float tweenDuration)
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
                endValue = startValue + endValue;
            }
            if (isFrom) {
                Vector3 realEnd = startValue;
                Vector3 realStart = hasGivenFromValue ? givenFromValue : endValue;
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
                duration = speed <= 0.0f ? 0.0f : Math::Abs(changeValue.Length() / speed);
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
            Vector3 value = startValue + changeValue * eased;
            if (snapping) {
                value = Vector3(float(Math::RoundToInt(value.x)), float(Math::RoundToInt(value.y)),
                    float(Math::RoundToInt(value.z)));
            }
            if (axisConstraint != AxisConstraint::None && getter !is null) {
                Vector3 current = getter();
                if ((axisConstraint & AxisConstraint::X) == 0) { value.x = current.x; }
                if ((axisConstraint & AxisConstraint::Y) == 0) { value.y = current.y; }
                if ((axisConstraint & AxisConstraint::Z) == 0) { value.z = current.z; }
            }
            setter(value);
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
        Vector3 GetStartValue() const { return startValue; }

        /// <summary>The value the tween is heading to.</summary>
        /// <returns>Returns the end value.</returns>
        Vector3 GetEndValue() const { return endValue; }

        /// <summary>Replaces the end value and rewinds the tween.</summary>
        /// <param name="to">The new end value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenVector3@ ChangeEndValue(Vector3 to, float newDuration = -1.0f)
        {
            endValue = to;
            isRelative = false;
            if (newDuration >= 0.0f) { duration = newDuration; }
            if (startupDone) { changeValue = endValue - startValue; }
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        /// <summary>Replaces both ends and rewinds the tween.</summary>
        /// <param name="from">The new start value.</param>
        /// <param name="to">The new end value.</param>
        /// <param name="newDuration">A new duration, or a negative number to keep the current one.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenVector3@ ChangeValues(Vector3 from, Vector3 to, float newDuration = -1.0f)
        {
            ForceInit();
            startValue = from;
            endValue = to;
            isRelative = false;
            if (newDuration >= 0.0f) { duration = newDuration; }
            changeValue = endValue - startValue;
            DoGotoInternal(0.0f, 0, UpdateMode::IgnoreOnUpdate);
            return this;
        }

        TweenVector3@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenVector3@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenVector3@ SetEase(Ease value, float amplitude, float period) { CoreSetEaseParams(value, amplitude, period); return this; }
        TweenVector3@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenVector3@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenVector3@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenVector3@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenVector3@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenVector3@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenVector3@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenVector3@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenVector3@ SetUpdate(bool independent) { CoreSetUpdate(updateType, independent); return this; }
        TweenVector3@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenVector3@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenVector3@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenVector3@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenVector3@ SetInverted(bool value = true) { CoreSetInverted(value); return this; }
        TweenVector3@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Rounds every written component to the nearest whole number.</summary>
        /// <param name="value">Whether snapping is enabled.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenVector3@ SetSnapping(bool value = true) { snapping = value; return this; }

        /// <summary>Restricts which components the tween is allowed to write.</summary>
        /// <param name="value">The axes to write. None writes all of them.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenVector3@ SetAxisConstraint(AxisConstraint value) { axisConstraint = value; return this; }

        /// <summary>Plays the tween from the end value back to the target's current value.</summary>
        /// <param name="relative">Whether the from value is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenVector3@ From(bool relative = false)
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
        TweenVector3@ From(Vector3 from, bool setImmediately = true, bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = true;
            givenFromValue = from;
            if (setImmediately) { ForceInit(); }
            return this;
        }

        TweenVector3@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenVector3@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenVector3@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenVector3@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenVector3@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenVector3@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenVector3@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenVector3@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
