using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Records which callbacks a sequence fired and in what order.
    /// </summary>
    class SequenceMarker
    {
        array<string> hits;

        void A() { hits.insertLast("A"); }
        void B() { hits.insertLast("B"); }
        void C() { hits.insertLast("C"); }

        string Joined() const
        {
            string joined = "";
            for (uint i = 0; i < hits.length(); i++) {
                joined += hits[i];
            }
            return joined;
        }
    }

    /// <summary>
    /// Builds a plain one-second linear tween that is not registered with the manager, ready to be nested.
    /// </summary>
    /// <param name="probe">The probe the tween drives.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long the tween lasts.</param>
    /// <returns>Returns the tween, paused and unregistered.</returns>
    TweenFloat@ MakeNestable(FloatProbe@ probe, float to, float duration)
    {
        TweenFloat@ tween = TweenFloat();
        tween.Bind(probe.Getter(), probe.Setter(), to, duration);
        tween.SetEase(Ease::Linear);
        return tween;
    }

    /// <summary>
    /// Exercises sequence composition, playback, seeking, looping and callbacks.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunSequenceTests(TweenyTestContext@ t)
    {
        t.Suite("sequences");

        t.Case("Append lays tweens end to end");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.Append(MakeNestable(b, 10.0f, 1.0f));

            t.CheckApprox(sequence.GetDuration(), 2.0f, "the durations add up");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 5.0f, "the first tween is halfway");
            t.CheckApprox(b.value, 0.0f, "the second has not started");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(a.value, 10.0f, "the first has finished");
            t.CheckApprox(b.value, 5.0f, "the second is halfway");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(b.value, 10.0f, "the second has finished");
            t.Check(sequence.IsComplete(), "and the sequence is complete");
        }

        t.Case("Join runs tweens side by side");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.Join(MakeNestable(b, 20.0f, 1.0f));

            t.CheckApprox(sequence.GetDuration(), 1.0f, "joined tweens do not extend the timeline");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 5.0f, "the first is halfway");
            t.CheckApprox(b.value, 10.0f, "and so is the joined one");
        }

        t.Case("Insert places a tween anywhere");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Insert(2.0f, MakeNestable(a, 10.0f, 1.0f));
            t.CheckApprox(sequence.GetDuration(), 3.0f, "the timeline stretches to fit");
            Tweeny::ManualUpdate(2.0f, 2.0f);
            t.CheckApprox(a.value, 0.0f, "nothing happened before its slot");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 5.0f, "and it runs once its slot arrives");
        }

        t.Case("AppendInterval leaves a gap");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.AppendInterval(1.0f);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            t.CheckApprox(sequence.GetDuration(), 2.0f, "the gap counts towards the duration");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(a.value, 0.0f, "nothing runs during the gap");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 5.0f, "the tween starts after the gap");
        }

        t.Case("Prepend shifts everything later");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.Prepend(MakeNestable(b, 10.0f, 1.0f));
            t.CheckApprox(sequence.GetDuration(), 2.0f, "the timeline grew");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(b.value, 5.0f, "the prepended tween runs first");
            t.CheckApprox(a.value, 0.0f, "and the original one waits");
        }

        t.Case("PrependInterval delays everything");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.PrependInterval(1.0f);
            t.CheckApprox(sequence.GetDuration(), 2.0f, "the gap was added");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(a.value, 0.0f, "the tween waits through the gap");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(a.value, 10.0f, "then runs to the end");
        }

        t.Case("callbacks fire in timeline order");
        {
            ResetManager();
            FloatProbe a(0.0f);
            SequenceMarker marker;
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.AppendCallback(TweenCallback(marker.A));
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.AppendCallback(TweenCallback(marker.B));
            sequence.AppendInterval(1.0f);
            sequence.AppendCallback(TweenCallback(marker.C));

            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckEqualString(marker.Joined(), "A", "only the first callback has fired");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckEqualString(marker.Joined(), "AB", "the second fires once its position is passed");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckEqualString(marker.Joined(), "ABC", "and the last one at the end");
        }

        t.Case("PrependCallback fires before everything");
        {
            ResetManager();
            SequenceMarker marker;
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.AppendCallback(TweenCallback(marker.B));
            sequence.PrependCallback(TweenCallback(marker.A));
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckEqualString(marker.Joined(), "AB", "the prepended callback came first");
        }

        t.Case("JoinCallback shares the last insert position");
        {
            ResetManager();
            SequenceMarker marker;
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.AppendInterval(1.0f);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.JoinCallback(TweenCallback(marker.A));
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckEqualString(marker.Joined(), "", "the callback waits with its tween");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckEqualString(marker.Joined(), "A", "and fires when that slot is reached");
        }

        t.Case("seeking puts every child exactly where it belongs");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual).SetAutoKill(false);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            sequence.Append(MakeNestable(b, 10.0f, 1.0f));

            sequence.Goto(1.5f);
            t.CheckApprox(a.value, 10.0f, "the first child is fully done");
            t.CheckApprox(b.value, 5.0f, "the second is halfway");

            sequence.Goto(0.25f);
            t.CheckApprox(a.value, 2.5f, "seeking back rewinds the first child");
            t.CheckApprox(b.value, 0.0f, "and resets the second");
        }

        t.Case("a looping sequence replays its children");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual).SetLoops(2, LoopType::Restart);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));

            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 5.0f, "first cycle halfway");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(a.value, 5.0f, "second cycle halfway after wrapping");
            t.CheckEqualInt(sequence.GetCompletedLoops(), 1, "one cycle finished");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.Check(sequence.IsComplete(), "two cycles complete the sequence");
        }

        t.Case("nested tweens lose auto-kill and their own delay");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenFloat@ child = MakeNestable(a, 10.0f, 1.0f);
            child.SetDelay(5.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(child);
            t.Check(child.IsSequenced(), "the child knows it is nested");
            t.CheckApprox(child.GetDelay(), 0.0f, "its own delay was dropped");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(a.value, 10.0f, "so it runs immediately inside the sequence");
        }

        t.Case("a nested sequence behaves like any other child");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);

            TweenSequence@ inner = Tweeny::Sequence();
            inner.SetUpdate(UpdateType::Manual);
            inner.Append(MakeNestable(a, 10.0f, 1.0f));
            inner.Append(MakeNestable(b, 10.0f, 1.0f));

            FloatProbe c(0.0f);
            TweenSequence@ outer = Tweeny::Sequence();
            outer.SetUpdate(UpdateType::Manual);
            outer.Append(MakeNestable(c, 10.0f, 1.0f));
            outer.Append(inner);

            t.CheckApprox(outer.GetDuration(), 3.0f, "the nested sequence contributes its whole span");
            Tweeny::ManualUpdate(1.5f, 1.5f);
            t.CheckApprox(c.value, 10.0f, "the outer child finished");
            t.CheckApprox(a.value, 5.0f, "and the nested sequence is running");
        }

        t.Case("the sequence itself can be eased");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual).SetEase(Ease::InQuad);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 2.5f, "the whole timeline is eased, not just the child");
        }

        t.Case("an empty sequence is discarded");
        {
            ResetManager();
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.1f, 0.1f);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "an empty sequence does not linger");
        }

        t.Case("killing a sequence releases its children");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(MakeNestable(a, 10.0f, 1.0f));
            t.CheckEqualInt(sequence.GetItemCount(), 1, "the sequence holds one item");
            sequence.Kill(false);
            t.Check(!sequence.IsActive(), "the sequence is dead");
            Tweeny::ManualUpdate(0.1f, 0.1f);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "and it was swept away");
        }

        t.Case("nested tweens are not driven by the scheduler directly");
        {
            ResetManager();
            FloatProbe a(0.0f);
            TweenFloat@ child = Tweeny::To(a.Getter(), a.Setter(), 10.0f, 1.0f);
            child.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            TweenSequence@ sequence = Tweeny::Sequence();
            sequence.SetUpdate(UpdateType::Manual);
            sequence.Append(child);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(a.value, 5.0f, "the child advanced once, not twice");
        }

        ResetManager();
    }
}
