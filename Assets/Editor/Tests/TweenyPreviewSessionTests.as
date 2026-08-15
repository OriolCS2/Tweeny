using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Verifies the shared preview session: the one object every Tweeny tool drives.
    ///
    /// Two things matter here. The session must be genuinely shared, because when each surface kept its own
    /// the buttons in one showed the opposite state of the other. And it must never lose the value a target
    /// held before the preview started, because that value is the scene as the user left it -- if the
    /// preview cannot put it back, the displacement is what gets saved.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunPreviewSessionTests(TweenyTestContext@ t)
    {
        t.Suite("shared preview session");

        ResetManager();

        t.Case("every surface reaches the same session");
        {
            TweenyPreviewSession@ first = Tweeny::PreviewSession();
            TweenyPreviewSession@ second = Tweeny::PreviewSession();
            t.Check(first is second, "the session is a single shared instance");
        }

        t.Case("taking a tween over and putting it back");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            FloatProbe probe(4.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 100.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(tween);
            session.PlayLive(live);
            t.Check(session.IsPreviewing(), "the session is previewing");
            t.CheckEqualInt(session.GetCount(), 1, "and holds the tween");
            t.Check(tween.GetUpdateType() == UpdateType::Manual, "the tween is driven by hand");

            session.Step(0.5f);
            t.Check(Math::Abs(probe.value - 4.0f) > 0.001f, "the value moved while previewing");

            session.Stop();
            t.CheckApprox(probe.value, 4.0f, "and went back exactly where it was");
            t.Check(!session.IsPreviewing(), "the session went idle");
            ResetManager();
        }

        t.Case("pausing holds the preview and pausing again releases it");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 10.0f);
            tween.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(tween);
            session.PlayLive(live);
            session.Step(1.0f);
            float moved = probe.value;
            t.Check(moved > 0.001f, "it advanced before being paused");

            session.TogglePause();
            t.Check(session.IsPaused(), "the session reports itself paused");
            session.Step(2.0f);
            t.CheckApprox(probe.value, moved, "and nothing moved while it was paused");

            session.TogglePause();
            t.Check(!session.IsPaused(), "pressing pause again released it");
            session.Step(1.0f);
            t.Check(probe.value > moved + 0.001f, "and it started moving again");

            session.Stop();
            ResetManager();
        }

        t.Case("restarting sends everything back to the beginning");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(tween);
            session.PlayLive(live);
            session.Step(0.6f);
            t.Check(probe.value > 5.0f, "it ran most of the way through");

            session.Restart();
            session.Step(0.01f);
            t.Check(probe.value < 1.0f, "and a restart put it back at the start");
            t.Check(!session.IsPaused(), "a restart also releases a paused preview");

            session.Stop();
            t.CheckApprox(probe.value, 0.0f, "stopping still restored the original value");
            ResetManager();
        }

        t.Case("several previews stop together");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            FloatProbe a(1.0f);
            FloatProbe b(2.0f);
            TweenFloat@ first = Tweeny::To(a.Getter(), a.Setter(), 100.0f, 1.0f);
            first.SetEase(Ease::Linear);
            TweenFloat@ second = Tweeny::To(b.Getter(), b.Setter(), 200.0f, 1.0f);
            second.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(first);
            live.insertLast(second);
            session.PlayLive(live);
            t.CheckEqualInt(session.GetCount(), 2, "both tweens are under preview");

            session.Step(0.3f);
            session.Stop();
            t.CheckApprox(a.value, 1.0f, "the first restored");
            t.CheckApprox(b.value, 2.0f, "the second restored");
            ResetManager();
        }

        t.Case("the same tween is never taken over twice");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(tween);
            session.PlayLive(live);
            session.PlayLive(live);
            t.CheckEqualInt(session.GetCount(), 1, "asking twice still holds it once");

            session.Stop();
            ResetManager();
        }

        t.Case("playing again never re-captures the value to restore");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            FloatProbe probe(4.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 100.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(tween);
            session.PlayLive(live);

            session.Step(0.5f);
            float displaced = probe.value;
            t.Check(displaced > 40.0f, "the preview dragged the value a long way from where it started");

            session.Restart();
            session.Step(0.3f);
            t.Check(probe.value < displaced,
                "starting again ran from the original value rather than from the displaced one");

            session.Stop();
            t.CheckApprox(probe.value, 4.0f, "and stopping still found the value the target began with");
            ResetManager();
        }

        t.Case("switching in or out of play mode ends the preview");
        {
            TweenyPreviewSession@ session = Tweeny::PreviewSession();
            session.SetPlayMode(false);

            FloatProbe probe(6.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 60.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            array<ITween@> live;
            live.insertLast(tween);
            session.PlayLive(live);
            session.Step(0.4f);
            t.Check(session.IsPreviewing(), "a preview is running in edit mode");

            session.SetPlayMode(true);
            t.Check(!session.IsPreviewing(), "entering play mode ended it");
            t.CheckApprox(probe.value, 6.0f, "and put the target back before the game took over");

            session.SetPlayMode(true);
            t.Check(!session.IsPreviewing(), "being told the same mode again changes nothing");

            session.SetPlayMode(false);
            ResetManager();
        }

        Tweeny::PreviewSession().Stop();
        ResetManager();
    }
}
