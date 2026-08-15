using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Collects the waypoint indices a path tween reports.
    /// </summary>
    class WaypointRecorder
    {
        array<int> hits;
        void OnWaypoint(int index) { hits.insertLast(index); }
    }

    /// <summary>
    /// Exercises the composite effects: multi-segment tweens, punch, shake, paths and jumps.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunSpecialTests(TweenyTestContext@ t)
    {
        t.Suite("punch, shake, path and jump");

        t.Case("segment durations always add up to the requested duration");
        {
            array<float> fading = BuildSegmentDurations(7, 2.0f, true);
            float sum = 0.0f;
            for (uint i = 0; i < fading.length(); i++) {
                sum += fading[i];
            }
            t.CheckApprox(sum, 2.0f, "the fading segments still total two seconds", 0.001f);
            t.Check(fading[6] > fading[0], "and later segments last longer");

            array<float> even = BuildSegmentDurations(5, 1.0f, false);
            float evenSum = 0.0f;
            for (uint i = 0; i < even.length(); i++) {
                evenSum += even[i];
            }
            t.CheckApprox(evenSum, 1.0f, "the even segments total one second", 0.001f);
            t.CheckApprox(even[0], even[4], "and they are all the same length");
        }

        t.Case("there are never fewer than two hops");
        {
            t.CheckEqualInt(BuildIterationCount(10, 0.01f), 2, "a very short effect still gets two hops");
            t.CheckEqualInt(BuildIterationCount(10, 1.0f), 10, "ten per second over a second gives ten");
        }

        t.Case("a multi-segment tween walks its waypoints");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            array<Vector2> points = { Vector2(10.0f, 0.0f), Vector2(0.0f, 0.0f) };
            array<float> times = { 1.0f, 1.0f };
            TweenVector2Array@ tween = Tweeny::ToArray(probe.Getter(), probe.Setter(), points, times);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);

            t.CheckApprox(tween.GetDuration(), 2.0f, "the durations add up");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(probe.value.x, 5.0f, "halfway through the first segment");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(probe.value.x, 10.0f, "at the first waypoint");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(probe.value.x, 5.0f, "halfway back on the second segment");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckApprox(probe.value.x, 0.0f, "back where it started");
        }

        t.Case("punch returns exactly to where it started");
        {
            ResetManager();
            Vector2Probe probe(Vector2(100.0f, 50.0f));
            TweenVector2Array@ tween = Tweeny::Punch(probe.Getter(), probe.Setter(),
                Vector2(10.0f, 0.0f), 1.0f, 10, 1.0f);
            tween.SetUpdate(UpdateType::Manual);

            t.CheckApprox(tween.GetDuration(), 1.0f, "the punch lasts the requested time");
            bool moved = false;
            for (int i = 0; i < 20; i++) {
                Tweeny::ManualUpdate(0.05f, 0.05f);
                if (Math::Abs(probe.value.x - 100.0f) > 0.01f) {
                    moved = true;
                }
            }
            t.Check(moved, "the punch actually displaced the value");
            Tweeny::ManualUpdate(0.2f, 0.2f);
            t.CheckApprox(probe.value.x, 100.0f, "and it ended back at the start", 0.001f);
            t.CheckApprox(probe.value.y, 50.0f, "on both axes", 0.001f);
        }

        t.Case("punch decays over its run");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenVector2Array@ tween = Tweeny::Punch(probe.Getter(), probe.Setter(),
                Vector2(10.0f, 0.0f), 1.0f, 10, 1.0f);
            tween.SetUpdate(UpdateType::Manual);
            tween.ForceInit();

            float firstHop = Math::Abs(tween.GetWaypoint(0).x);
            float laterHop = Math::Abs(tween.GetWaypoint(4).x);
            t.Check(firstHop > laterHop, "later hops are smaller than the first");
            t.CheckApprox(tween.GetWaypoint(tween.GetSegmentCount() - 1).x, 0.0f,
                "the last waypoint returns to the origin", 0.001f);
        }

        t.Case("shake settles back and is reproducible from a seed");
        {
            ResetManager();
            Vector2Probe first(Vector2(0.0f, 0.0f));
            TweenVector2Array@ a = Tweeny::Shake(first.Getter(), first.Setter(), 1.0f, 5.0f, 10, 90.0f,
                true, ShakeRandomnessMode::Full, 4242);
            a.SetUpdate(UpdateType::Manual);
            for (int i = 0; i < 10; i++) {
                Tweeny::ManualUpdate(0.05f, 0.05f);
            }
            float sampleA = first.value.x;

            ResetManager();
            Vector2Probe second(Vector2(0.0f, 0.0f));
            TweenVector2Array@ b = Tweeny::Shake(second.Getter(), second.Setter(), 1.0f, 5.0f, 10, 90.0f,
                true, ShakeRandomnessMode::Full, 4242);
            b.SetUpdate(UpdateType::Manual);
            for (int i = 0; i < 10; i++) {
                Tweeny::ManualUpdate(0.05f, 0.05f);
            }
            t.CheckApprox(second.value.x, sampleA, "the same seed replays the same shake");

            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(second.value.x, 0.0f, "the shake settles back to the origin", 0.001f);
            t.CheckApprox(second.value.y, 0.0f, "on both axes", 0.001f);
        }

        t.Case("different seeds shake differently");
        {
            ResetManager();
            Vector2Probe first(Vector2(0.0f, 0.0f));
            Tweeny::Shake(first.Getter(), first.Setter(), 1.0f, 5.0f, 10, 90.0f, true,
                ShakeRandomnessMode::Full, 1).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.1f, 0.1f);
            float sampleA = first.value.x;

            ResetManager();
            Vector2Probe second(Vector2(0.0f, 0.0f));
            Tweeny::Shake(second.Getter(), second.Setter(), 1.0f, 5.0f, 10, 90.0f, true,
                ShakeRandomnessMode::Full, 2).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.1f, 0.1f);

            t.Check(Math::Abs(second.value.x - sampleA) > 0.0001f, "another seed gives another shake");
        }

        t.Case("a shake without fade-out keeps its strength");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenVector2Array@ tween = Tweeny::Shake(probe.Getter(), probe.Setter(), 1.0f, 5.0f, 10, 90.0f,
                false, ShakeRandomnessMode::Full, 77);
            tween.SetUpdate(UpdateType::Manual);
            tween.ForceInit();
            t.CheckApprox(tween.GetSegmentDuration(0), tween.GetSegmentDuration(3),
                "every hop lasts the same without fade-out", 0.001f);
        }

        t.Case("a linear path measures its own length");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            array<Vector2> points = { Vector2(3.0f, 4.0f), Vector2(3.0f, 14.0f) };
            TweenPath@ path = Tweeny::Path(probe.Getter(), probe.Setter(), points, 2.0f, PathType::Linear);
            path.SetUpdate(UpdateType::Manual);
            path.ForceInit();
            t.CheckApprox(path.PathLength(), 15.0f, "5 across then 10 up is 15 units", 0.01f);
        }

        t.Case("a path moves at a constant speed");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            array<Vector2> points = { Vector2(10.0f, 0.0f), Vector2(10.0f, 10.0f) };
            TweenPath@ path = Tweeny::Path(probe.Getter(), probe.Setter(), points, 2.0f, PathType::Linear);
            path.SetUpdate(UpdateType::Manual);

            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(probe.value.x, 10.0f, "halfway by distance is the first corner", 0.01f);
            t.CheckApprox(probe.value.y, 0.0f, "and not yet climbing", 0.01f);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(probe.value.y, 10.0f, "and it finishes at the last waypoint", 0.01f);
        }

        t.Case("a closed path returns to the start");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            array<Vector2> points = { Vector2(10.0f, 0.0f), Vector2(10.0f, 10.0f) };
            TweenPath@ path = Tweeny::Path(probe.Getter(), probe.Setter(), points, 1.0f, PathType::Linear);
            path.SetClosePath(true).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(probe.value.x, 0.0f, "a closed path ends where it began", 0.01f);
            t.CheckApprox(probe.value.y, 0.0f, "on both axes", 0.01f);
        }

        t.Case("waypoint callbacks fire in order");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            WaypointRecorder recorder;
            array<Vector2> points = { Vector2(10.0f, 0.0f), Vector2(20.0f, 0.0f), Vector2(30.0f, 0.0f) };
            TweenPath@ path = Tweeny::Path(probe.Getter(), probe.Setter(), points, 3.0f, PathType::Linear);
            path.SetUpdate(UpdateType::Manual);
            path.OnWaypointChange(TweenCallbackInt(recorder.OnWaypoint));

            for (int i = 0; i < 7; i++) {
                Tweeny::ManualUpdate(0.5f, 0.5f);
            }
            t.Check(recorder.hits.length() >= 3, "every waypoint was reported");
            bool ascending = true;
            for (uint i = 1; i < recorder.hits.length(); i++) {
                if (recorder.hits[i] < recorder.hits[i - 1]) {
                    ascending = false;
                }
            }
            t.Check(ascending, "and they arrived in order");
        }

        t.Case("a curved path is longer than the straight line through the same points");
        {
            ResetManager();
            Vector2Probe straightProbe(Vector2(0.0f, 0.0f));
            Vector2Probe curvedProbe(Vector2(0.0f, 0.0f));
            array<Vector2> points = { Vector2(10.0f, 10.0f), Vector2(20.0f, -10.0f), Vector2(30.0f, 0.0f) };

            TweenPath@ straight = Tweeny::Path(straightProbe.Getter(), straightProbe.Setter(), points, 1.0f, PathType::Linear);
            straight.SetUpdate(UpdateType::Manual);
            straight.ForceInit();

            TweenPath@ curved = Tweeny::Path(curvedProbe.Getter(), curvedProbe.Setter(), points, 1.0f, PathType::CatmullRom);
            curved.SetUpdate(UpdateType::Manual);
            curved.ForceInit();

            t.Check(curved.PathLength() > straight.PathLength(), "the smooth path takes a longer route");
        }

        t.Case("PathGetDrawPoints returns a usable outline");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            array<Vector2> points = { Vector2(10.0f, 0.0f), Vector2(10.0f, 10.0f) };
            TweenPath@ path = Tweeny::Path(probe.Getter(), probe.Setter(), points, 1.0f, PathType::Linear);
            path.SetUpdate(UpdateType::Manual);
            array<Vector2>@ outline = path.PathGetDrawPoints(16);
            t.CheckEqualInt(int(outline.length()), 16, "the requested number of points came back");
            t.CheckApprox(outline[15].x, 10.0f, "the last point is the end of the path", 0.01f);
            t.CheckApprox(outline[15].y, 10.0f, "on both axes", 0.01f);
        }

        t.Case("jump lands on its destination having arced on the way");
        {
            ResetManager();
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenSequence@ jump = Tweeny::Jump(probe.Getter(), probe.Setter(),
                Vector2(10.0f, 0.0f), 4.0f, 2, 1.0f);
            jump.SetUpdate(UpdateType::Manual);

            float highest = 0.0f;
            for (int i = 0; i < 12; i++) {
                Tweeny::ManualUpdate(0.1f, 0.1f);
                if (probe.value.y > highest) {
                    highest = probe.value.y;
                }
            }
            t.Check(highest > 0.5f, "the jump rose off the ground");
            t.CheckApprox(probe.value.x, 10.0f, "and landed on the destination", 0.01f);
            t.CheckApprox(probe.value.y, 0.0f, "back at ground level", 0.01f);
        }

        ResetManager();
    }
}
