using namespace CometEngine;

namespace Tweeny
{
    /// <summary>How an angle tween picks its route to the target angle.</summary>
    enum RotateMode
    {
        /// <summary>Take the shortest way round and never travel more than 180 degrees.</summary>
        Fast = 0,
        /// <summary>Use the given angle verbatim, so multi-turn rotations work.</summary>
        FastBeyond360,
        /// <summary>Add the given angle to the current one.</summary>
        WorldAxisAdd
    }

    /// <summary>
    /// Animates a rotation expressed as a scalar angle in degrees.
    ///
    /// This is the 2D-native replacement for DOTween's quaternion rotation family. DOTween itself uses a
    /// scalar angle for its only genuinely 2D targets (Rigidbody2D and UIToolkit), so this follows the
    /// same shape rather than dragging quaternions into a 2D engine's public API.
    /// </summary>
    class TweenAngle : ITween, TweenCore
    {
        private FloatGetter@ getter;
        private FloatSetter@ setter;
        private float startValue = 0.0f;
        private float endValue = 0.0f;
        private float changeValue = 0.0f;
        private RotateMode rotateMode = RotateMode::Fast;
        private bool hasGivenFromValue = false;
        private float givenFromValue = 0.0f;

        /// <summary>Binds the tween to an angle in degrees.</summary>
        /// <param name="valueGetter">Reads the current angle.</param>
        /// <param name="valueSetter">Writes the new angle.</param>
        /// <param name="to">The angle to reach, in degrees.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(FloatGetter@ valueGetter, FloatSetter@ valueSetter, float to, float tweenDuration)
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

            float target = endValue;
            if (rotateMode == RotateMode::WorldAxisAdd || (isRelative && !isFrom)) {
                target = startValue + endValue;
            }

            if (isFrom) {
                float realEnd = startValue;
                float realStart = hasGivenFromValue ? givenFromValue : endValue;
                if (isRelative) {
                    realStart = realEnd + realStart;
                }
                startValue = realStart;
                target = realEnd;
                setter(startValue);
            }

            endValue = target;
            changeValue = endValue - startValue;

            if (rotateMode == RotateMode::Fast) {
                // Wrap the delta into -180..180 so the rotation always takes the short way round.
                while (changeValue > 180.0f) {
                    changeValue -= 360.0f;
                }
                while (changeValue < -180.0f) {
                    changeValue += 360.0f;
                }
            }

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
            setter(startValue + changeValue * eased);
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

        /// <summary>The angle the tween started from.</summary>
        /// <returns>Returns the start angle in degrees.</returns>
        float GetStartValue() const { return startValue; }

        /// <summary>The angle the tween is heading to.</summary>
        /// <returns>Returns the end angle in degrees.</returns>
        float GetEndValue() const { return endValue; }

        /// <summary>The signed delta the tween will travel, after shortest-route wrapping.</summary>
        /// <returns>Returns the change in degrees.</returns>
        float GetChangeValue() const { return changeValue; }

        TweenAngle@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenAngle@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenAngle@ SetEase(Ease value, float amplitude, float period) { CoreSetEaseParams(value, amplitude, period); return this; }
        TweenAngle@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenAngle@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenAngle@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenAngle@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenAngle@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenAngle@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenAngle@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenAngle@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenAngle@ SetUpdate(bool independent) { CoreSetUpdate(updateType, independent); return this; }
        TweenAngle@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenAngle@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenAngle@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenAngle@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenAngle@ SetInverted(bool value = true) { CoreSetInverted(value); return this; }
        TweenAngle@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Chooses how the tween routes to the target angle.</summary>
        /// <param name="value">The routing mode.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenAngle@ SetRotateMode(RotateMode value) { rotateMode = value; return this; }

        /// <summary>Plays the tween from the end angle back to the target's current angle.</summary>
        /// <param name="relative">Whether the from angle is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenAngle@ From(bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = false;
            return this;
        }

        /// <summary>Plays the tween from an explicit angle back to the target's current angle.</summary>
        /// <param name="from">The angle to start from.</param>
        /// <param name="setImmediately">Whether the target jumps to the from angle right away.</param>
        /// <param name="relative">Whether the from angle is treated as an offset.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenAngle@ From(float from, bool setImmediately = true, bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = true;
            givenFromValue = from;
            if (setImmediately) { ForceInit(); }
            return this;
        }

        TweenAngle@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenAngle@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenAngle@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenAngle@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenAngle@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenAngle@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenAngle@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenAngle@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
