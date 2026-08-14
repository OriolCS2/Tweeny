using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Exercises the yield instructions, entity links and the inspector-driven animation component.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunIntegrationTests(TweenyTestContext@ t)
    {
        t.Suite("coroutines, links and TweenyAnimation");

        ResetManager();

        CometEngine::SceneManagement::Scene scene =
            CometEngine::SceneManagement::SceneManager::CreateScene("[Tweeny integration]");
        CometEngine::SceneManagement::SceneManager::SetSceneActive(scene);

        t.Case("WaitForCompletion releases when the tween finishes");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetAutoKill(false);
            WaitForCompletion wait(tween);

            t.Check(!wait.CanContinue(), "it holds while the tween runs");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.Check(!wait.CanContinue(), "still holding halfway");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.Check(wait.CanContinue(), "and releases once the tween is done");
            ResetManager();
        }

        t.Case("WaitForCompletion also releases if the tween is killed");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 5.0f);
            tween.SetUpdate(UpdateType::Manual);
            WaitForCompletion wait(tween);
            t.Check(!wait.CanContinue(), "it holds while the tween runs");
            tween.Kill(false);
            t.Check(wait.CanContinue(), "a killed tween never strands the coroutine");
            ResetManager();
        }

        t.Case("WaitForKill holds until the tween dies");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetAutoKill(false);
            WaitForKill wait(tween);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.Check(!wait.CanContinue(), "completing is not the same as dying");
            tween.Kill(false);
            t.Check(wait.CanContinue(), "and it releases on the kill");
            ResetManager();
        }

        t.Case("WaitForElapsedLoops counts cycles");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetLoops(4, LoopType::Restart);
            WaitForElapsedLoops wait(tween, 2);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.Check(!wait.CanContinue(), "one partial loop is not enough");
            Tweeny::ManualUpdate(1.0f, 1.0f);
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.Check(wait.CanContinue(), "two finished loops release it");
            ResetManager();
        }

        t.Case("WaitForPosition waits for a point on the timeline");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 2.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetAutoKill(false);
            WaitForPosition wait(tween, 1.5f);
            Tweeny::ManualUpdate(1.0f, 1.0f);
            t.Check(!wait.CanContinue(), "not there yet");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.Check(wait.CanContinue(), "and it releases once past the position");
            ResetManager();
        }

        t.Case("WaitForStart waits out the delay");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual).SetDelay(0.5f);
            WaitForStart wait(tween);
            t.Check(!wait.CanContinue(), "it holds during the delay");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.Check(wait.CanContinue(), "and releases once the tween really starts");
            ResetManager();
        }

        // Destroying and disabling entities are deferred operations that a SceneManager tick has to pick
        // up, and outside play mode that tick never runs. So what a link does on destroy and on disable is
        // verified in the play-mode demo scene instead; here we prove a link on a live entity stays out of
        // the way and that a link to a missing entity kills the tween immediately.
        t.Case("a link leaves a healthy tween alone");
        {
            Entity@ host = Entity::Create("[link host]");
            if (host is null) {
                t.Check(false, "an entity could be created for the link test");
            }
            else {
                FloatProbe probe(0.0f);
                TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 10.0f);
                tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
                Tweeny::SetLink(tween, host, LinkBehaviour::PauseOnDisablePlayOnEnable);

                Tweeny::ManualUpdate(1.0f, 1.0f);
                t.Check(tween.IsActive(), "the tween is still alive");
                t.Check(tween.IsPlaying(), "and still playing");
                t.CheckApprox(probe.value, 1.0f, "and it advanced normally");
            }
            ResetManager();
        }

        t.Case("a link to nothing kills the tween at once");
        {
            FloatProbe probe(0.0f);
            TweenFloat@ tween = Tweeny::To(probe.Getter(), probe.Setter(), 10.0f, 10.0f);
            tween.SetUpdate(UpdateType::Manual);

            TweenLink link(tween, null, LinkBehaviour::KillOnDestroy);
            link.Evaluate();
            t.Check(!tween.IsActive(), "a link whose entity is gone kills the tween");
            t.Check(!link.IsAlive(), "and the link retires itself");
            ResetManager();
        }

        // TweenyAnimation is a script behaviour, and attaching one to an entity from the compile-time
        // test runner leaves a live script object behind that the next recompile trips over. Its behaviour
        // is verified in the play-mode demo scene, where a script behaviour belongs.

        ResetManager();
    }
}
