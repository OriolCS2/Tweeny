using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// A temporary measurement harness for the stress-scene investigation. Not a test: it asserts nothing,
    /// it only times the tween hot path so the cost can be split between script work and engine crossings.
    /// </summary>
    /// <param name="t">The context, used only to print the numbers into the report.</param>
    void RunPerfProbe(TweenyTestContext@ t)
    {
        t.Suite("perf probe");

        const int COUNT = 400;
        const int TICKS = 600;

        ResetManager();
        float bare = TimeTicks(COUNT, TICKS, null);

        ResetManager();
        Entity@ host = Entity::Create("[perf probe host]");
        float guarded = host is null ? -1.0f : TimeTicks(COUNT, TICKS, host);

        ResetManager();
        float phases = TimePhases(COUNT, TICKS);

        ResetManager();
        float queries = TimeQueries(COUNT, TICKS);

        ResetManager();
        float delegates = TimeDelegates(COUNT, TICKS);

        ResetManager();
        float arithmetic = TimeArithmetic(COUNT, TICKS);

        ResetManager();
        Transform@ transform = host is null ? null : Transform::Get(host);
        float engineWrites = transform is null ? -1.0f : TimeEngineWrites(COUNT, TICKS, transform);

        float emptyLoop = TimeEmptyLoop(COUNT, TICKS);
        float nativeCalls = TimeNativeCalls(COUNT, TICKS);

        string report = "=== Tweeny perf probe: " + COUNT + " tweens, " + TICKS + " iterations ===\n"
            + "bare tween tick            " + Milliseconds(bare, TICKS) + " ms\n"
            + "guarded tween tick         " + Milliseconds(guarded, TICKS) + " ms\n"
            + "frame of three phase walks " + Milliseconds(phases, TICKS) + " ms\n"
            + "frame of window queries    " + Milliseconds(queries, TICKS) + " ms\n"
            + "bare delegate get+set      " + Milliseconds(delegates, TICKS) + " ms\n"
            + "bare script arithmetic     " + Milliseconds(arithmetic, TICKS) + " ms\n"
            + "engine transform get+set   " + Milliseconds(engineWrites, TICKS) + " ms\n"
            + "empty script loop          " + Milliseconds(emptyLoop, TICKS) + " ms\n"
            + "plain native call          " + Milliseconds(nativeCalls, TICKS) + " ms\n";
        FileSystem::Save("Library/TweenyPerfProbe.txt", report);

        t.Case("perf probe wrote its numbers");
        t.Check(true, "see Library/TweenyPerfProbe.txt");

        ResetManager();
    }

    /// <summary>Times plain manual ticks over a set of float tweens.</summary>
    /// <param name="count">How many tweens to build.</param>
    /// <param name="ticks">How many manual updates to run.</param>
    /// <param name="owner">When given, every tween is routed through a guard over this object.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeTicks(int count, int ticks, Object@ owner)
    {
        array<FloatProbe@> probes;
        for (int i = 0; i < count; i++) {
            FloatProbe@ probe = FloatProbe(0.0f);
            probes.insertLast(probe);

            if (owner is null) {
                Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 100.0f)
                    .SetEase(Ease::InOutSine).SetUpdate(UpdateType::Manual);
            }
            else {
                GuardedFloat@ guard = GuardedFloat(owner, probe.Getter(), probe.Setter());
                Tweeny::To(guard.Getter(), guard.Setter(), 10.0f, 100.0f)
                    .SetEase(Ease::InOutSine).SetUpdate(UpdateType::Manual);
            }
        }

        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            Tweeny::ManualUpdate(0.016f, 0.016f);
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// Times what a real frame costs the manager: the list is walked once per update phase, so a tween on
    /// one phase is still visited by the other two.
    /// </summary>
    /// <param name="count">How many tweens to build.</param>
    /// <param name="ticks">How many frames to simulate.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimePhases(int count, int ticks)
    {
        array<FloatProbe@> probes;
        for (int i = 0; i < count; i++) {
            FloatProbe@ probe = FloatProbe(0.0f);
            probes.insertLast(probe);
            Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 100.0f)
                .SetEase(Ease::InOutSine).SetUpdate(UpdateType::Normal);
        }

        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            Tweeny::TickPhase(UpdateType::Normal, 0.016f, 0.016f);
            Tweeny::TickPhase(UpdateType::Late, 0.016f, 0.016f);
            Tweeny::TickPhase(UpdateType::Fixed, 0.016f, 0.016f);
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// Times the queries the Tweeny window makes every frame it is open in play mode.
    /// </summary>
    /// <param name="count">How many tweens to build.</param>
    /// <param name="frames">How many frames to simulate.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeQueries(int count, int frames)
    {
        array<FloatProbe@> probes;
        for (int i = 0; i < count; i++) {
            FloatProbe@ probe = FloatProbe(0.0f);
            probes.insertLast(probe);
            Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 100.0f)
                .SetEase(Ease::InOutSine).SetUpdate(UpdateType::Manual);
        }

        float start = Time::GetAppTime();
        for (int i = 0; i < frames; i++) {
            Tweeny::TotalActiveTweens();
            Tweeny::TotalPlayingTweens();
            Tweeny::TotalPlayingTweens();
            Tweeny::TotalActiveTweens();
            Tweeny::TotalPlayingTweens();
            Tweeny::TotalActiveTweens();
            Tweeny::TotalActiveTweens();
            Tweeny::AllTweens();
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// Times nothing but the delegate round trip a tween makes per tick: read the value, write it back.
    /// </summary>
    /// <param name="count">How many delegate pairs to call.</param>
    /// <param name="ticks">How many iterations to run.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeDelegates(int count, int ticks)
    {
        array<FloatProbe@> probes;
        array<FloatGetter@> getters;
        array<FloatSetter@> setters;
        for (int i = 0; i < count; i++) {
            FloatProbe@ probe = FloatProbe(0.0f);
            probes.insertLast(probe);
            getters.insertLast(probe.Getter());
            setters.insertLast(probe.Setter());
        }

        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            for (uint j = 0; j < getters.length(); j++) {
                FloatGetter@ get = getters[j];
                FloatSetter@ set = setters[j];
                set(get() + 0.001f);
            }
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// Times the same shape of loop with the delegates taken out, so the dispatch cost can be separated
    /// from the arithmetic and the array walking.
    /// </summary>
    /// <param name="count">How many elements to walk.</param>
    /// <param name="ticks">How many iterations to run.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeArithmetic(int count, int ticks)
    {
        array<FloatProbe@> probes;
        for (int i = 0; i < count; i++) {
            probes.insertLast(FloatProbe(0.0f));
        }

        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            for (uint j = 0; j < probes.length(); j++) {
                FloatProbe@ probe = probes[j];
                probe.value = probe.value + 0.001f;
            }
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// Times the engine crossing a moving tween makes per tick: read a Transform position and write it
    /// back. One transform is reused rather than four hundred, because what is being sized here is the cost
    /// of the crossing itself, not of having many entities in a scene.
    /// </summary>
    /// <param name="count">How many read-write pairs per iteration.</param>
    /// <param name="ticks">How many iterations to run.</param>
    /// <param name="transform">The transform to drive.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeEngineWrites(int count, int ticks, Transform@ transform)
    {
        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            for (int j = 0; j < count; j++) {
                Vector3 current = transform.position;
                current.y += 0.0001f;
                transform.position = current;
            }
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// The floor: what an iteration of a script loop costs when it does nothing at all.
    /// </summary>
    /// <param name="count">Iterations of the inner loop.</param>
    /// <param name="ticks">Iterations of the outer loop.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeEmptyLoop(int count, int ticks)
    {
        float sink = 0.0f;
        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            for (int j = 0; j < count; j++) {
                sink += 1.0f;
            }
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>
    /// A native call that takes no bridged object, so it never resolves user data. Comparing it against the
    /// transform figure separates the cost of entering the engine from the cost of finding the C++ object
    /// behind a script handle.
    /// </summary>
    /// <param name="count">Iterations of the inner loop.</param>
    /// <param name="ticks">Iterations of the outer loop.</param>
    /// <returns>Returns the elapsed seconds.</returns>
    float TimeNativeCalls(int count, int ticks)
    {
        float sink = 0.0f;
        float start = Time::GetAppTime();
        for (int i = 0; i < ticks; i++) {
            for (int j = 0; j < count; j++) {
                sink += Math::Abs(-1.0f);
            }
        }
        return Time::GetAppTime() - start;
    }

    /// <summary>Formats an elapsed span as milliseconds per iteration.</summary>
    /// <param name="seconds">The total elapsed seconds.</param>
    /// <param name="iterations">How many iterations it covered.</param>
    /// <returns>Returns the formatted number.</returns>
    string Milliseconds(float seconds, int iterations)
    {
        if (seconds < 0.0f) {
            return "n/a";
        }
        return formatFloat(seconds * 1000.0f / float(iterations), "", 0, 4);
    }
}
