using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Exercises the tween state machine: interpolation, delay, loops, callbacks, seeking and the
    /// boundary cases where a frame lands exactly on a loop edge.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunCoreTests(TweenyTestContext@ t)
    {
        t.Suite("core");

        t.Case("linear interpolation");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            Advance(tween, 0.25f, 1);
            t.CheckApprox(probe.value, 2.5f, "a quarter through");
            Advance(tween, 0.25f, 1);
            t.CheckApprox(probe.value, 5.0f, "halfway");
            Advance(tween, 0.25f, 2);
            t.CheckApprox(probe.value, 10.0f, "at the end");
            t.Check(tween.IsComplete(), "the tween reports complete");
        }

        t.Case("a zero delta does not advance or divide by zero");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            Advance(tween, 0.0f, 3);
            t.CheckApprox(probe.value, 0.0f, "nothing moved on a zero delta");
            t.CheckEqualInt(probe.writeCount, 0, "no value was written");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 5.0f, "a real delta still works afterwards");
        }

        t.Case("the tween lands exactly on the end value");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 3.0f, 1.0f);
            Advance(tween, 0.3f, 10);
            t.CheckApprox(probe.value, 3.0f, "overshooting deltas still land on the end", 0.0001f);
        }

        t.Case("delay is consumed exactly once");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetDelay(0.5f);
            Advance(tween, 0.25f, 1);
            t.CheckApprox(probe.value, 0.0f, "nothing happens during the delay");
            t.CheckApprox(tween.GetElapsedDelay(), 0.25f, "the delay is accumulating");
            Advance(tween, 0.25f, 1);
            t.CheckApprox(probe.value, 0.0f, "still nothing at the delay boundary");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 5.0f, "the tween starts once the delay is spent");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 10.0f, "and finishes without paying the delay again");
        }

        t.Case("Restart loops start over each cycle");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(3, LoopType::Restart);
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 5.0f, "first cycle halfway");
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 5.0f, "second cycle halfway");
            t.CheckEqualInt(tween.GetCompletedLoops(), 1, "one loop finished");
            Advance(tween, 1.0f, 1);
            t.CheckEqualInt(tween.GetCompletedLoops(), 2, "two loops finished");
            Advance(tween, 1.0f, 1);
            t.Check(tween.IsComplete(), "three loops completes the tween");
        }

        t.Case("Yoyo loops alternate direction");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(2, LoopType::Yoyo);
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 5.0f, "first cycle rises");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 10.0f, "first cycle tops out");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 5.0f, "second cycle falls back");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 0.0f, "second cycle returns to the start");
        }

        t.Case("Incremental loops keep climbing");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(3, LoopType::Incremental);
            Advance(tween, 0.25f, 3);
            t.CheckApprox(probe.value, 7.5f, "three quarters through the first cycle");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 12.5f, "the second cycle continues past 10");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 17.5f, "and keeps climbing");
            Advance(tween, 0.25f, 6);
            t.CheckApprox(probe.value, 30.0f, "three cycles of 10 end at 30");
            t.Check(tween.IsComplete(), "and the tween is complete");
        }

        t.Case("Incremental sits one cycle ahead exactly on a loop boundary");
        {
            // Landing precisely on the boundary leaves position clamped to the duration while the loop has
            // already been counted, so the value reads one increment high for that single frame. The next
            // tick corrects it, and pinning both halves here stops anyone "fixing" the transient.
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(3, LoopType::Incremental);
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 20.0f, "the boundary frame reads one increment ahead");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 15.0f, "the next tick settles back onto the real curve");
        }

        t.Case("infinite loops never complete");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(-1, LoopType::Restart);
            bool killed = Advance(tween, 0.5f, 20);
            t.Check(!killed, "an infinite tween is never auto-killed");
            t.Check(!tween.IsComplete(), "an infinite tween never reports complete");
            t.Check(tween.GetCompletedLoops() >= 9, "it kept looping");
        }

        t.Case("callbacks fire in the documented order");
        {
            FloatProbe probe(0.0f);
            CallbackRecorder recorder;
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.OnStart(TweenCallback(recorder.OnStart));
            tween.OnPlay(TweenCallback(recorder.OnPlay));
            tween.OnUpdate(TweenCallback(recorder.OnUpdate));
            tween.OnStepComplete(TweenCallback(recorder.OnStepComplete));
            tween.OnComplete(TweenCallback(recorder.OnComplete));

            Advance(tween, 0.5f, 1);
            t.CheckEqualInt(recorder.starts, 1, "OnStart fired once");
            t.CheckEqualInt(recorder.plays, 1, "OnPlay fired once");
            t.CheckEqualInt(recorder.updates, 1, "OnUpdate fired once");
            t.CheckEqualInt(recorder.completes, 0, "OnComplete has not fired yet");

            Advance(tween, 0.5f, 1);
            t.CheckEqualInt(recorder.completes, 1, "OnComplete fired at the end");
            t.CheckEqualInt(recorder.steps, 1, "OnStepComplete fired for the single loop");
            t.Check(recorder.IndexOf("start") < recorder.IndexOf("play"), "start comes before play");
            t.Check(recorder.IndexOf("play") < recorder.IndexOf("update"), "play comes before update");
            t.Check(recorder.IndexOf("step") < recorder.IndexOf("complete"), "step comes before complete");
            t.CheckEqualInt(recorder.starts, 1, "OnStart never fires twice");
        }

        t.Case("OnStepComplete fires once per loop");
        {
            FloatProbe probe(0.0f);
            CallbackRecorder recorder;
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(4, LoopType::Restart);
            tween.OnStepComplete(TweenCallback(recorder.OnStepComplete));
            // Deliberately not stepping by exactly the loop duration: landing on the boundary parks the
            // position at the duration, which costs an extra tick per cycle. That is covered separately.
            Advance(tween, 0.5f, 8);
            t.CheckEqualInt(recorder.steps, 4, "four loops produced four step callbacks");
        }

        t.Case("several loops crossed in one frame still fire every step");
        {
            FloatProbe probe(0.0f);
            CallbackRecorder recorder;
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 0.1f);
            tween.SetLoops(5, LoopType::Restart);
            tween.OnStepComplete(TweenCallback(recorder.OnStepComplete));
            Advance(tween, 0.5f, 1);
            t.CheckEqualInt(recorder.steps, 5, "one big delta fired all five step callbacks");
        }

        t.Case("OnKill fires when the tween is killed");
        {
            FloatProbe probe(0.0f);
            CallbackRecorder recorder;
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.OnKill(TweenCallback(recorder.OnKill));
            tween.Kill(false);
            t.CheckEqualInt(recorder.kills, 1, "OnKill fired");
            t.Check(!tween.IsActive(), "the tween is no longer active");
        }

        t.Case("Kill with complete applies the end value");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            Advance(tween, 0.2f, 1);
            tween.Kill(true);
            t.CheckApprox(probe.value, 10.0f, "killing with complete jumps to the end");
            t.Check(!tween.IsActive(), "the tween is dead afterwards");
        }

        t.Case("Complete jumps to the end");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetAutoKill(false);
            Advance(tween, 0.1f, 1);
            tween.Complete(false);
            t.CheckApprox(probe.value, 10.0f, "Complete writes the end value");
            t.Check(tween.IsComplete(), "the tween reports complete");
            t.Check(!tween.IsPlaying(), "and stops playing");
        }

        t.Case("Rewind returns to the start");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetAutoKill(false);
            Advance(tween, 0.7f, 1);
            t.CheckApprox(probe.value, 7.0f, "moved before rewinding");
            tween.Rewind();
            t.CheckApprox(probe.value, 0.0f, "Rewind writes the start value");
            t.CheckApprox(tween.GetPosition(), 0.0f, "position is back to zero");
            t.Check(!tween.IsPlaying(), "Rewind pauses the tween");
        }

        t.Case("Restart plays from the beginning again");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetAutoKill(false);
            Advance(tween, 1.0f, 1);
            t.Check(tween.IsComplete(), "finished once");
            tween.Restart();
            t.Check(!tween.IsComplete(), "Restart clears the complete flag");
            t.Check(tween.IsPlaying(), "Restart resumes playback");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 5.0f, "and the tween runs again");
        }

        t.Case("Goto seeks to an absolute position");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 2.0f);
            tween.SetAutoKill(false);
            tween.Goto(0.5f);
            t.CheckApprox(probe.value, 2.5f, "seeking forward writes the right value");
            tween.Goto(1.5f);
            t.CheckApprox(probe.value, 7.5f, "seeking further forward works");
            tween.Goto(0.25f);
            t.CheckApprox(probe.value, 1.25f, "seeking backwards works too");
            t.Check(!tween.IsPlaying(), "Goto leaves the tween paused by default");
        }

        t.Case("Goto across loops resolves the loop count");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetLoops(4, LoopType::Restart);
            tween.SetAutoKill(false);
            tween.Goto(2.5f);
            t.CheckEqualInt(tween.GetCompletedLoops(), 2, "two loops are behind us");
            t.CheckApprox(probe.value, 5.0f, "and we are halfway through the third");
        }

        t.Case("Pause and Play");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            Advance(tween, 0.3f, 1);
            tween.Pause();
            t.Check(!tween.IsPlaying(), "the tween is paused");
            Advance(tween, 0.3f, 1);
            t.CheckApprox(probe.value, 3.0f, "a paused tween ignores ticks");
            tween.Play();
            Advance(tween, 0.3f, 1);
            t.CheckApprox(probe.value, 6.0f, "playing again resumes from where it stopped");
        }

        t.Case("Flip reverses direction");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetAutoKill(false);
            Advance(tween, 0.6f, 1);
            t.CheckApprox(probe.value, 6.0f, "moved forward first");
            tween.Flip();
            t.Check(tween.IsBackwards(), "the tween now runs backwards");
            Advance(tween, 0.2f, 1);
            t.CheckApprox(probe.value, 4.0f, "and it walks back");
        }

        t.Case("relative tweens offset the start value");
        {
            FloatProbe probe(5.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetRelative(true);
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 15.0f, "the end value was added to the start value");
        }

        t.Case("From plays the tween in reverse");
        {
            FloatProbe probe(4.0f);
            TweenFloat@ tween = TweenFloat();
            tween.Bind(probe.Getter(), probe.Setter(), 20.0f, 1.0f);
            tween.SetEase(Ease::Linear);
            tween.From(false);
            tween.Play();
            Advance(tween, 0.0f, 1);
            tween.ForceInit();
            t.CheckApprox(tween.GetStartValue(), 20.0f, "the tween starts from the given end value");
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 4.0f, "and lands on the target's original value");
        }

        t.Case("From with an explicit value");
        {
            FloatProbe probe(2.0f);
            TweenFloat@ tween = TweenFloat();
            tween.Bind(probe.Getter(), probe.Setter(), 0.0f, 1.0f);
            tween.SetEase(Ease::Linear);
            tween.From(50.0f, true, false);
            t.CheckApprox(probe.value, 50.0f, "setImmediately jumps the target right away");
            tween.Play();
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 2.0f, "and it eases back to the original value");
        }

        t.Case("speed based tweens derive their duration");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = TweenFloat();
            tween.Bind(probe.Getter(), probe.Setter(), 10.0f, 5.0f);
            tween.SetEase(Ease::Linear);
            tween.SetSpeedBased(true);
            tween.Play();
            tween.ForceInit();
            t.CheckApprox(tween.GetDuration(), 2.0f, "10 units at 5 per second takes 2 seconds");
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 5.0f, "and it moves at that speed");
        }

        t.Case("snapping rounds the written value");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetSnapping(true);
            Advance(tween, 0.33f, 1);
            t.CheckApprox(probe.value, float(Math::RoundToInt(probe.value)), "the value is a whole number");
        }

        t.Case("autoKill asks the scheduler to remove the tween");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            bool killed = Advance(tween, 0.5f, 3);
            t.Check(killed, "an autoKill tween reports that it is finished");
        }

        t.Case("autoKill false keeps the tween alive");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetAutoKill(false);
            bool killed = Advance(tween, 0.5f, 3);
            t.Check(!killed, "the tween survives completion");
            t.Check(tween.IsActive(), "and stays active");
        }

        t.Case("timeScale changes the pace");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetTimeScale(0.5f);
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 2.5f, "half speed covers half the ground");
        }

        t.Case("elapsed and duration getters");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 2.0f);
            tween.SetLoops(3, LoopType::Restart);
            tween.SetAutoKill(false);
            Advance(tween, 1.0f, 1);
            t.CheckApprox(tween.GetElapsed(false), 1.0f, "elapsed inside the loop");
            t.CheckApprox(tween.GetDuration(), 2.0f, "one loop lasts two seconds");
            t.CheckApprox(tween.GetFullDuration(true), 6.0f, "three loops last six seconds");
            t.CheckApprox(tween.GetElapsedPercentage(), 1.0f / 6.0f, "one sixth of the way through");
            t.CheckEqualInt(tween.GetLoops(), 3, "the loop count is reported");
        }

        t.Case("ChangeEndValue retargets a running tween");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetAutoKill(false);
            Advance(tween, 0.5f, 1);
            tween.ChangeEndValue(100.0f);
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 100.0f, "the tween now heads for the new end value");
        }

        t.Case("ids and target are stored");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetId("fade-in");
            t.CheckEqualString(tween.GetStringId(), "fade-in", "the string id round-trips");
            tween.SetId(42);
            t.CheckEqualInt(tween.GetIntId(), 42, "the int id round-trips");
        }

        t.Case("settings are locked once the tween has started");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            Advance(tween, 0.1f, 1);
            tween.SetLoops(5);
            t.CheckEqualInt(tween.GetLoops(), 1, "SetLoops is ignored after the tween started");
        }

        t.Case("a custom ease drives the tween");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = MakeFloatTween(probe, 10.0f, 1.0f);
            tween.SetEase(EaseFunc(SquaredEase));
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 2.5f, "the squared ease is applied");
        }
    }
}
