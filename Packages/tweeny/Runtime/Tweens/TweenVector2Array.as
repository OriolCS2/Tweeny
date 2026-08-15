using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Walks a Vector2 through a list of waypoints, each with its own duration.
    ///
    /// The easing curve is applied inside each segment rather than across the whole tween, which is what
    /// gives punch and shake their characteristic snap: every hop eases independently.
    ///
    /// This is the substrate Punch and Shake are built on; it is rarely used directly.
    /// </summary>
    class TweenVector2Array : ITween, TweenCore
    {
        private Vector2Getter@ getter;
        private Vector2Setter@ setter;
        private array<Vector2> endValues;
        private array<float> segmentDurations;
        private Vector2 startValue;
        private bool offsetsFromStart = false;

        /// <summary>
        /// Binds the tween to a value and gives it its waypoints.
        /// </summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="waypoints">The value to reach at the end of each segment.</param>
        /// <param name="durations">How long each segment lasts. Must match the waypoint count.</param>
        void Bind(Vector2Getter@ valueGetter, Vector2Setter@ valueSetter,
            const array<Vector2>&in waypoints, const array<float>&in durations)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            endValues = waypoints;
            segmentDurations = durations;

            float total = 0.0f;
            for (uint i = 0; i < segmentDurations.length(); i++) {
                total += segmentDurations[i];
            }
            duration = total;
            noFromAllowed = true;
        }

        /// <summary>
        /// Treats every waypoint as an offset from wherever the target is when the tween starts, which is
        /// what punch and shake need.
        /// </summary>
        /// <param name="value">Whether waypoints are offsets.</param>
        void SetOffsetsFromStart(bool value)
        {
            offsetsFromStart = value;
        }

        bool TweenStartup()
        {
            if (getter is null || setter is null || endValues.length() == 0) {
                return false;
            }
            if (endValues.length() != segmentDurations.length()) {
                return false;
            }
            startValue = getter();
            if (offsetsFromStart) {
                for (uint i = 0; i < endValues.length(); i++) {
                    endValues[i] = startValue + endValues[i];
                }
            }
            return true;
        }

        void TweenApply(float eased, UpdateNotice notice)
        {
            if (setter is null || endValues.length() == 0) {
                return;
            }

            float elapsed = position;
            uint index = 0;
            float segmentStart = 0.0f;
            while (index < segmentDurations.length() - 1
                && elapsed >= segmentStart + segmentDurations[index]) {
                segmentStart += segmentDurations[index];
                index++;
            }

            float segmentDuration = segmentDurations[index];
            float segmentElapsed = elapsed - segmentStart;
            float localEased = segmentDuration <= 0.0f
                ? 1.0f
                : EaseManager::Evaluate(easeType, customEase, segmentElapsed, segmentDuration,
                    easeOvershootOrAmplitude, easePeriod);

            Vector2 from = index == 0 ? startValue : endValues[index - 1];
            Vector2 to = endValues[index];
            setter(from + (to - from) * localEased);
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

        /// <summary>The number of segments the tween walks through.</summary>
        /// <returns>Returns the waypoint count.</returns>
        int GetSegmentCount() const { return int(endValues.length()); }

        /// <summary>The value a segment ends on.</summary>
        /// <param name="index">The segment index.</param>
        /// <returns>Returns the waypoint, or zero when the index is out of range.</returns>
        Vector2 GetWaypoint(int index) const
        {
            if (index < 0 || uint(index) >= endValues.length()) {
                return Vector2(0.0f, 0.0f);
            }
            return endValues[uint(index)];
        }

        /// <summary>How long a segment lasts.</summary>
        /// <param name="index">The segment index.</param>
        /// <returns>Returns the duration in seconds, or zero when the index is out of range.</returns>
        float GetSegmentDuration(int index) const
        {
            if (index < 0 || uint(index) >= segmentDurations.length()) {
                return 0.0f;
            }
            return segmentDurations[uint(index)];
        }

        TweenVector2Array@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenVector2Array@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenVector2Array@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenVector2Array@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenVector2Array@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenVector2Array@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenVector2Array@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenVector2Array@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenVector2Array@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenVector2Array@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenVector2Array@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        TweenVector2Array@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenVector2Array@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenVector2Array@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenVector2Array@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenVector2Array@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenVector2Array@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenVector2Array@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenVector2Array@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
