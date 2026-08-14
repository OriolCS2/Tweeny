using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Verifies the editor preview, whose most important property is that it leaves nothing behind: a
    /// preview that displaces the scene and does not put it back would quietly corrupt saved work.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunPreviewTests(TweenyTestContext@ t)
    {
        t.Suite("editor preview");

        ResetManager();

        t.Case("a preview restores the value it started from");
        {
            FloatProbe probe(3.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 100.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            TweenyPreview preview;
            preview.Add(tween);
            t.Check(preview.IsPreviewing(), "the preview started");
            t.CheckEqualInt(preview.GetCount(), 1, "and took the tween over");

            preview.Update(0.5f);
            t.CheckApprox(probe.value, 51.5f, "the value moved while previewing");

            preview.Stop(true);
            t.CheckApprox(probe.value, 3.0f, "and went back exactly where it was");
            t.Check(!preview.IsPreviewing(), "the preview stopped");
            t.Check(!tween.IsActive(), "and the previewed tween was discarded");
            ResetManager();
        }

        t.Case("stopping without restoring keeps the previewed value");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            TweenyPreview preview;
            preview.Add(tween);
            preview.Update(0.5f);
            preview.Stop(false);
            t.CheckApprox(probe.value, 5.0f, "the value stayed where the preview left it");
            ResetManager();
        }

        t.Case("a From tween restores to its end value");
        {
            FloatProbe probe(7.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 50.0f, 1.0f);
            tween.SetEase(Ease::Linear).From(false);

            TweenyPreview preview;
            preview.Add(tween);
            preview.Update(0.3f);
            t.Check(Math::Abs(probe.value - 7.0f) > 0.001f, "the preview moved it away");
            preview.Stop(true);
            t.CheckApprox(probe.value, 7.0f, "and a From tween still lands back on the original value");
            ResetManager();
        }

        t.Case("a preview never fires callbacks");
        {
            FloatProbe probe(0.0f);
            CallbackRecorder recorder;
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);
            tween.OnStart(TweenCallback(recorder.OnStart));
            tween.OnUpdate(TweenCallback(recorder.OnUpdate));
            tween.OnComplete(TweenCallback(recorder.OnComplete));
            tween.OnKill(TweenCallback(recorder.OnKill));

            TweenyPreview preview;
            preview.Add(tween);
            preview.Update(0.5f);
            preview.Update(0.6f);
            preview.Stop(true);

            t.CheckEqualInt(recorder.starts, 0, "OnStart never fired");
            t.CheckEqualInt(recorder.updates, 0, "OnUpdate never fired");
            t.CheckEqualInt(recorder.completes, 0, "OnComplete never fired");
            t.CheckEqualInt(recorder.kills, 0, "OnKill never fired");
            ResetManager();
        }

        t.Case("a preview survives the tween finishing");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 0.5f);
            tween.SetEase(Ease::Linear);

            TweenyPreview preview;
            preview.Add(tween);
            preview.Update(1.0f);
            t.Check(tween.IsActive(), "auto-kill was turned off for the preview");
            t.CheckApprox(probe.value, 10.0f, "the tween ran to its end");
            preview.Stop(true);
            t.CheckApprox(probe.value, 0.0f, "and it still restored afterwards");
            ResetManager();
        }

        t.Case("several tweens preview and restore together");
        {
            FloatProbe a(1.0f);
            FloatProbe b(2.0f);
            TweenFloat@ first = Tweeny::To(a.Getter(), a.Setter(), 100.0f, 1.0f);
            first.SetEase(Ease::Linear);
            TweenFloat@ second = Tweeny::To(b.Getter(), b.Setter(), 200.0f, 1.0f);
            second.SetEase(Ease::Linear);

            TweenyPreview preview;
            preview.Add(first);
            preview.Add(second);
            t.CheckEqualInt(preview.GetCount(), 2, "both tweens are previewed");
            preview.Update(0.4f);
            t.Check(Math::Abs(a.value - 1.0f) > 0.001f, "the first moved");
            t.Check(Math::Abs(b.value - 2.0f) > 0.001f, "the second moved");
            preview.Stop(true);
            t.CheckApprox(a.value, 1.0f, "the first restored");
            t.CheckApprox(b.value, 2.0f, "the second restored");
            ResetManager();
        }

        t.Case("the preview is independent of the game time scale");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);

            TweenyPreview preview;
            preview.Add(tween);
            t.Check(tween.IsIndependentUpdate(), "a previewed tween ignores the game time scale");
            t.Check(tween.GetUpdateType() == UpdateType::Manual, "and is driven manually");
            preview.Stop(true);
            ResetManager();
        }

        ResetManager();
    }
}
