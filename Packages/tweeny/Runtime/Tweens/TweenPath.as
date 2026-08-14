using namespace CometEngine;

namespace Tweeny
{
    /// <summary>How the points of a path are joined together.</summary>
    enum PathType
    {
        /// <summary>Straight lines between waypoints.</summary>
        Linear = 0,
        /// <summary>A smooth curve passing through every waypoint.</summary>
        CatmullRom
    }

    /// <summary>
    /// Moves a value along a path of waypoints.
    ///
    /// The path is sampled once into an arc-length table when the tween starts, and playback looks the
    /// distance up in that table. Without it a curve would speed up wherever its control points bunch
    /// together, which is the classic giveaway of a naive spline follower.
    /// </summary>
    class TweenPath : ITween, TweenCore
    {
        private Vector2Getter@ getter;
        private Vector2Setter@ setter;
        private array<Vector2> waypoints;
        private PathType pathType = PathType::Linear;
        private bool closePath = false;
        private int resolution = 10;

        private array<Vector2> samples;
        private array<float> cumulativeLengths;
        private array<int> sampleWaypoint;
        private float totalLength = 0.0f;
        private int lastWaypointIndex = -1;
        private bool pathBuilt = false;
        private Vector2 startValue;
        private bool relativeToStart = false;

        /// <summary>
        /// Binds the tween to a value and gives it the path to follow.
        /// </summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="points">The waypoints, in order.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        /// <param name="type">How the waypoints are joined.</param>
        /// <param name="segmentResolution">Samples taken per segment when building the arc-length table.</param>
        void Bind(Vector2Getter@ valueGetter, Vector2Setter@ valueSetter, const array<Vector2>&in points,
            float tweenDuration, PathType type = PathType::Linear, int segmentResolution = 10)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            waypoints = points;
            pathType = type;
            resolution = segmentResolution < 1 ? 1 : segmentResolution;
            duration = tweenDuration < 0.0f ? 0.0f : tweenDuration;
            noFromAllowed = true;
        }

        bool TweenStartup()
        {
            if (getter is null || setter is null || waypoints.length() < 1) {
                return false;
            }
            startValue = getter();
            BuildPath();
            // The path always starts at the target's own position, which is waypoint 0. Starting the
            // counter there means the move onto the first authored waypoint is announced like any other.
            lastWaypointIndex = 0;
            if (isSpeedBased) {
                float speed = duration;
                duration = speed <= 0.0f ? 0.0f : totalLength / speed;
                if (duration <= 0.0f) {
                    easeType = Ease::INTERNAL_Zero;
                }
            }
            return samples.length() >= 2;
        }

        void TweenApply(float eased, UpdateNotice notice)
        {
            if (setter is null || samples.length() == 0) {
                return;
            }
            float clamped = eased < 0.0f ? 0.0f : (eased > 1.0f ? 1.0f : eased);
            setter(PathGetPoint(clamped));

            int waypointIndex = WaypointIndexAt(clamped);
            if (waypointIndex != lastWaypointIndex) {
                if (onWaypointChange !is null) {
                    // Fire once for every waypoint crossed, so a big delta never silently skips one.
                    int step = waypointIndex > lastWaypointIndex ? 1 : -1;
                    for (int i = lastWaypointIndex + step; ; i += step) {
                        onWaypointChange(i);
                        if (!active || i == waypointIndex) {
                            break;
                        }
                    }
                }
                lastWaypointIndex = waypointIndex;
            }
        }

        /// <summary>
        /// Samples the whole path once and records how far along each sample sits, so playback can convert
        /// a percentage into a distance and back.
        /// </summary>
        private void BuildPath()
        {
            samples.resize(0);
            cumulativeLengths.resize(0);
            sampleWaypoint.resize(0);
            totalLength = 0.0f;

            array<Vector2> points = waypoints;
            if (relativeToStart) {
                for (uint i = 0; i < points.length(); i++) {
                    points[i] = startValue + points[i];
                }
            }
            // The path always begins wherever the target already is.
            points.insertAt(0, startValue);
            if (closePath && points.length() > 1) {
                points.insertLast(points[0]);
            }

            uint segments = points.length() - 1;
            samples.insertLast(points[0]);
            cumulativeLengths.insertLast(0.0f);
            sampleWaypoint.insertLast(0);

            for (uint s = 0; s < segments; s++) {
                int steps = pathType == PathType::Linear ? 1 : resolution;
                for (int step = 1; step <= steps; step++) {
                    float t = float(step) / float(steps);
                    Vector2 point = pathType == PathType::Linear
                        ? Lerp(points[s], points[s + 1], t)
                        : CatmullRom(points, int(s), t);
                    float previousLength = cumulativeLengths[cumulativeLengths.length() - 1];
                    Vector2 previousPoint = samples[samples.length() - 1];
                    totalLength = previousLength + previousPoint.Distance(point);
                    samples.insertLast(point);
                    cumulativeLengths.insertLast(totalLength);
                    sampleWaypoint.insertLast(int(s) + 1);
                }
            }
            pathBuilt = true;
        }

        private Vector2 Lerp(Vector2 a, Vector2 b, float t)
        {
            return a + (b - a) * t;
        }

        /// <summary>
        /// Evaluates a Catmull-Rom spline segment, duplicating the end points so the curve still passes
        /// through the first and last waypoints.
        /// </summary>
        private Vector2 CatmullRom(const array<Vector2>&in points, int segment, float t)
        {
            int last = int(points.length()) - 1;
            Vector2 p0 = points[uint(Math::Clamp(segment - 1, 0, last))];
            Vector2 p1 = points[uint(Math::Clamp(segment, 0, last))];
            Vector2 p2 = points[uint(Math::Clamp(segment + 1, 0, last))];
            Vector2 p3 = points[uint(Math::Clamp(segment + 2, 0, last))];

            float t2 = t * t;
            float t3 = t2 * t;
            float x = 0.5f * ((2.0f * p1.x)
                + (-p0.x + p2.x) * t
                + (2.0f * p0.x - 5.0f * p1.x + 4.0f * p2.x - p3.x) * t2
                + (-p0.x + 3.0f * p1.x - 3.0f * p2.x + p3.x) * t3);
            float y = 0.5f * ((2.0f * p1.y)
                + (-p0.y + p2.y) * t
                + (2.0f * p0.y - 5.0f * p1.y + 4.0f * p2.y - p3.y) * t2
                + (-p0.y + 3.0f * p1.y - 3.0f * p2.y + p3.y) * t3);
            return Vector2(x, y);
        }

        /// <summary>
        /// The point at a percentage along the path, measured by distance rather than by segment index so
        /// the speed stays constant.
        /// </summary>
        /// <param name="percentage">How far along, from 0 to 1.</param>
        /// <returns>Returns the point.</returns>
        Vector2 PathGetPoint(float percentage)
        {
            if (samples.length() == 0) {
                return startValue;
            }
            if (samples.length() == 1 || totalLength <= 0.0f) {
                return samples[samples.length() - 1];
            }

            float target = percentage * totalLength;
            uint low = 0;
            uint high = cumulativeLengths.length() - 1;
            while (low < high) {
                uint mid = (low + high) / 2;
                if (cumulativeLengths[mid] < target) {
                    low = mid + 1;
                }
                else {
                    high = mid;
                }
            }
            if (low == 0) {
                return samples[0];
            }

            float before = cumulativeLengths[low - 1];
            float after = cumulativeLengths[low];
            float span = after - before;
            float local = span <= 0.0f ? 0.0f : (target - before) / span;
            return Lerp(samples[low - 1], samples[low], local);
        }

        private int WaypointIndexAt(float percentage)
        {
            if (samples.length() == 0 || totalLength <= 0.0f) {
                return 0;
            }
            float target = percentage * totalLength;
            for (uint i = 0; i < cumulativeLengths.length(); i++) {
                if (cumulativeLengths[i] >= target) {
                    return sampleWaypoint[i];
                }
            }
            return sampleWaypoint[sampleWaypoint.length() - 1];
        }

        /// <summary>The total length of the path in world units.</summary>
        /// <returns>Returns the length, valid once the tween has started.</returns>
        float PathLength()
        {
            if (!pathBuilt) {
                ForceInit();
            }
            return totalLength;
        }

        /// <summary>
        /// Points along the path, for drawing it as a gizmo.
        /// </summary>
        /// <param name="count">How many points to return.</param>
        /// <returns>Returns evenly spaced points along the path.</returns>
        array<Vector2>@ PathGetDrawPoints(int count = 32)
        {
            if (!pathBuilt) {
                ForceInit();
            }
            array<Vector2>@ result = array<Vector2>();
            int total = count < 2 ? 2 : count;
            for (int i = 0; i < total; i++) {
                result.insertLast(PathGetPoint(float(i) / float(total - 1)));
            }
            return result;
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

        TweenPath@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenPath@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenPath@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenPath@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenPath@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenPath@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenPath@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenPath@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenPath@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenPath@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenPath@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenPath@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenPath@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Joins the last waypoint back to the first.</summary>
        /// <param name="value">Whether the path is closed.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenPath@ SetClosePath(bool value = true) { closePath = value; return this; }

        /// <summary>Treats every waypoint as an offset from where the target starts.</summary>
        /// <param name="value">Whether the waypoints are relative.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenPath@ SetRelative(bool value = true) { relativeToStart = value; return this; }

        /// <summary>Fires as the path passes each waypoint.</summary>
        /// <param name="value">The callback, given the waypoint index.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenPath@ OnWaypointChange(TweenCallbackInt@ value) { @onWaypointChange = value; return this; }

        TweenPath@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenPath@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenPath@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenPath@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenPath@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenPath@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenPath@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenPath@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
