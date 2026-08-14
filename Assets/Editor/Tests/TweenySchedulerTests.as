using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Kills every tween the manager still holds so each case starts from a clean slate.
    /// </summary>
    void ResetManager()
    {
        Tweeny::Clear(false);
        Tweeny::SetTimeScale(1.0f);
    }

    /// <summary>
    /// A tween that kills another one from inside a callback, to prove the active list survives being
    /// mutated while it is being walked.
    /// </summary>
    class ReentrantKiller
    {
        ITween@ victim;
        int fired = 0;

        void Fire()
        {
            fired++;
            if (victim !is null) {
                victim.Kill(false);
            }
        }
    }

    /// <summary>
    /// Creates a new tween from inside a callback.
    /// </summary>
    class ReentrantCreator
    {
        FloatProbe@ probe;
        int fired = 0;

        void Fire()
        {
            fired++;
            Tweeny::To(probe.Getter(), probe.Setter(), 99.0f, 1.0f);
        }
    }

    /// <summary>
    /// Exercises the scheduler: registration, phases, sweeping, filtered operations and re-entrancy.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunSchedulerTests(TweenyTestContext@ t)
    {
        t.Suite("scheduler");

        t.Case("a created tween is registered and plays");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);
            tween.SetUpdate(UpdateType::Manual);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 1, "the manager tracks the tween");
            t.Check(tween.IsPlaying(), "auto play started it");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(probe.value, 5.0f, "the manager advanced it");
        }

        t.Case("a finished tween is swept out of the list");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 1, "still alive midway");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "removed once finished");
        }

        t.Case("update phases are independent");
        {
            ResetManager();
            FloatProbe normalProbe(0.0f);
            FloatProbe manualProbe(0.0f);
            Tweeny::To(normalProbe.Getter(), normalProbe.Setter(), 10.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Normal);
            Tweeny::To(manualProbe.Getter(), manualProbe.Setter(), 10.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);

            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(manualProbe.value, 5.0f, "the manual tween advanced");
            t.CheckApprox(normalProbe.value, 0.0f, "the normal tween did not");

            Tweeny::TickPhase(UpdateType::Normal, 0.5f, 0.5f);
            t.CheckApprox(normalProbe.value, 5.0f, "ticking Normal advances the normal tween");
            t.CheckApprox(manualProbe.value, 5.0f, "and leaves the manual one alone");
        }

        t.Case("the global time scale multiplies every tween");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::SetTimeScale(0.5f);
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckApprox(probe.value, 5.0f, "half speed covers half the ground");
            Tweeny::SetTimeScale(1.0f);
        }

        t.Case("KillAll empties the manager");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            Tweeny::To(a.Getter(), a.Setter(), 10.0f, 1.0f).SetUpdate(UpdateType::Manual);
            Tweeny::To(b.Getter(), b.Setter(), 10.0f, 1.0f).SetUpdate(UpdateType::Manual);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 2, "two tweens are tracked");
            int killed = Tweeny::KillAll();
            t.CheckEqualInt(killed, 2, "KillAll reports two");
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "and the list is empty");
        }

        t.Case("KillAll with complete writes the end values");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            Tweeny::To(probe.Getter(), probe.Setter(), 42.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::KillAll(true);
            t.CheckApprox(probe.value, 42.0f, "the tween was completed before dying");
        }

        t.Case("PauseAll and PlayAll");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            t.CheckEqualInt(Tweeny::TotalPlayingTweens(), 1, "one tween is playing");
            Tweeny::PauseAll();
            t.CheckEqualInt(Tweeny::TotalPlayingTweens(), 0, "PauseAll stopped it");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(probe.value, 0.0f, "a paused tween ignores ticks");
            Tweeny::PlayAll();
            t.CheckEqualInt(Tweeny::TotalPlayingTweens(), 1, "PlayAll resumed it");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(probe.value, 5.0f, "and it advances again");
        }

        t.Case("filtering by string id");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            Tweeny::To(a.Getter(), a.Setter(), 10.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetId("keep");
            Tweeny::To(b.Getter(), b.Setter(), 10.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetId("drop");

            t.Check(Tweeny::IsTweening("keep"), "the id is found");
            t.Check(!Tweeny::IsTweening("missing"), "an unknown id is not found");

            int killed = Tweeny::Kill("drop");
            t.CheckEqualInt(killed, 1, "only the matching tween was killed");
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 1, "the other one survived");
            t.Check(Tweeny::IsTweening("keep"), "and it is the one we kept");
        }

        t.Case("filtering by integer id");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            Tweeny::To(a.Getter(), a.Setter(), 10.0f, 1.0f).SetUpdate(UpdateType::Manual).SetId(1);
            Tweeny::To(b.Getter(), b.Setter(), 10.0f, 1.0f).SetUpdate(UpdateType::Manual).SetId(2);
            t.CheckEqualInt(Tweeny::Kill(2), 1, "one tween matched id 2");
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 1, "the other survived");
            array<ITween@>@ remaining = Tweeny::TweensById("", false);
            t.CheckEqualInt(int(Tweeny::PlayingTweens().length()), 1, "one tween is still playing");
        }

        t.Case("TweensById collects matches");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            FloatProbe c(0.0f);
            Tweeny::To(a.Getter(), a.Setter(), 1.0f, 1.0f).SetUpdate(UpdateType::Manual).SetId("group");
            Tweeny::To(b.Getter(), b.Setter(), 1.0f, 1.0f).SetUpdate(UpdateType::Manual).SetId("group");
            Tweeny::To(c.Getter(), c.Setter(), 1.0f, 1.0f).SetUpdate(UpdateType::Manual).SetId("other");
            t.CheckEqualInt(int(Tweeny::TweensById("group").length()), 2, "two tweens share the id");
            t.CheckEqualInt(int(Tweeny::TweensById("other").length()), 1, "one carries the other id");
        }

        t.Case("CompleteAll and RestartAll");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetAutoKill(false);
            Tweeny::CompleteAll();
            t.CheckApprox(probe.value, 10.0f, "CompleteAll jumped to the end");
            Tweeny::RestartAll();
            t.CheckApprox(probe.value, 0.0f, "RestartAll went back to the start");
            t.Check(tween.IsPlaying(), "and started playing again");
        }

        t.Case("RewindAll and FlipAll");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetAutoKill(false);
            Tweeny::ManualUpdate(0.6f, 0.6f);
            Tweeny::FlipAll();
            t.Check(tween.IsBackwards(), "FlipAll reversed the direction");
            Tweeny::RewindAll();
            t.CheckApprox(probe.value, 0.0f, "RewindAll returned to the start");
        }

        t.Case("GotoAll seeks every tween");
        {
            ResetManager();
            FloatProbe probe(0.0f);
            Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 2.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetAutoKill(false);
            Tweeny::GotoAll(1.0f);
            t.CheckApprox(probe.value, 5.0f, "every tween jumped to one second in");
        }

        t.Case("killing a tween from inside a callback is safe");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe b(0.0f);
            ReentrantKiller killer;

            TweenFloat@ victim = Tweeny::To(b.Getter(), b.Setter(), 10.0f, 5.0f);
            victim.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            @killer.victim = victim;

            TweenFloat@ trigger = Tweeny::To(a.Getter(), a.Setter(), 10.0f, 1.0f);
            trigger.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            trigger.OnUpdate(TweenCallback(killer.Fire));

            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckEqualInt(killer.fired, 1, "the callback ran");
            t.Check(!victim.IsActive(), "the victim was killed");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "and the list ends up clean");
        }

        t.Case("creating a tween from inside a callback is safe");
        {
            ResetManager();
            FloatProbe a(0.0f);
            FloatProbe spawned(0.0f);
            ReentrantCreator creator;
            @creator.probe = spawned;

            TweenFloat@ trigger = Tweeny::To(a.Getter(), a.Setter(), 10.0f, 1.0f);
            trigger.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            trigger.OnComplete(TweenCallback(creator.Fire));

            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.CheckEqualInt(creator.fired, 1, "the callback ran");
            t.Check(Tweeny::TotalActiveTweens() >= 1, "the tween created inside the callback is tracked");
        }

        t.Case("Clear removes everything");
        {
            ResetManager();
            FloatProbe a(0.0f);
            Tweeny::To(a.Getter(), a.Setter(), 1.0f, 1.0f).SetUpdate(UpdateType::Manual);
            Tweeny::Clear(false);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "the manager is empty");
        }

        t.Case("many tweens run together");
        {
            ResetManager();
            array<FloatProbe@> probes;
            for (int i = 0; i < 200; i++) {
                FloatProbe@ probe = FloatProbe(0.0f);
                probes.insertLast(probe);
                Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f)
                    .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            }
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 200, "all two hundred are tracked");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            bool allMoved = true;
            for (uint i = 0; i < probes.length(); i++) {
                if (Math::Abs(probes[i].value - 5.0f) > 0.001f) {
                    allMoved = false;
                }
            }
            t.Check(allMoved, "every one of them advanced by the same amount");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "and they were all swept when they finished");
        }

        ResetManager();
    }
}
