using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// The Tweeny page in Project Settings, and the thing that bootstraps the engine.
    ///
    /// A ProjectSetting is discovered and instantiated by the engine on its own, so importing the package is
    /// all a project has to do: there is no manager prefab to place and no script to register by hand.
    /// OnStart creates the runner entity and makes it immutable so it survives scene loads.
    /// </summary>
    class TweenySettings : ProjectSetting
    {
        [Header("Defaults for new tweens")]
        [Tooltip("Easing curve used when a tween does not choose one.")]
        Ease defaultEase = Ease::OutQuad;

        [Tooltip("Overshoot for Back eases, amplitude for Elastic eases.")]
        float defaultEaseOvershoot = 1.70158f;

        [Tooltip("Period for Elastic eases. 0 derives it from the tween duration.")]
        float defaultEasePeriod = 0.0f;

        [Tooltip("Which kinds of tween start playing as soon as they are created.")]
        AutoPlay defaultAutoPlay = AutoPlay::All;

        [Tooltip("Whether a tween is discarded once it finishes.")]
        bool defaultAutoKill = true;

        [Tooltip("How a tween behaves when it loops.")]
        LoopType defaultLoopType = LoopType::Restart;

        [Tooltip("Which update phase drives a tween. Late runs in PostUpdate.")]
        UpdateType defaultUpdateType = UpdateType::Normal;

        [Tooltip("Whether new tweens ignore the game time scale by default.")]
        bool defaultTimeScaleIndependent = false;

        [Header("Global")]
        [Tooltip("Multiplier applied to every scaled tween. 0.5 plays everything at half speed.")]
        float timeScale = 1.0f;

        [Tooltip("Multiplier applied to tweens that ignore the game time scale.")]
        float unscaledTimeScale = 1.0f;

        [Header("Safety and diagnostics")]
        [Tooltip("Check that a tween's target still exists before writing to it each frame.")]
        bool validateTargets = true;

        [Tooltip("What happens to a sequence when one of its children can no longer run.")]
        NestedTweenFailureBehaviour nestedTweenFailure = NestedTweenFailureBehaviour::TryToPreserveSequence;

        [Tooltip("How much Tweeny writes to the console.")]
        LogBehaviour logBehaviour = LogBehaviour::ErrorsOnly;

        [Header("Bootstrap")]
        [Tooltip("Create the runner automatically at play start. Turn off only to drive Tweeny yourself.")]
        bool autoCreateRunner = true;

        [Tooltip("Name given to the entity that hosts the runner.")]
        string runnerEntityName = "[Tweeny]";

        /// <summary>
        /// Pushes the settings into the manager and creates the runner. Runs at play start, before any
        /// scene entity wakes up.
        /// </summary>
        void OnStart()
        {
            ApplyToManager();

            if (!autoCreateRunner) {
                return;
            }

            Entity@ host = Entity::Create(runnerEntityName);
            if (host is null) {
                Debug::LogError("[Tweeny] Could not create the runner entity.");
                return;
            }

            TweenyRunner@ runner = TweenyRunner::Add(host);
            if (runner is null) {
                Debug::LogError("[Tweeny] Could not add the runner behaviour. Tweens will not advance.");
                return;
            }

            host.MakeImmutable();
        }

        /// <summary>
        /// Copies every setting onto the live manager. Safe to call again after changing a value.
        /// </summary>
        void ApplyToManager()
        {
            TweenyManager@ manager = Tweeny::Manager();
            manager.defaultEase = defaultEase;
            manager.defaultEaseOvershoot = defaultEaseOvershoot;
            manager.defaultEasePeriod = defaultEasePeriod;
            manager.defaultAutoPlay = defaultAutoPlay;
            manager.defaultAutoKill = defaultAutoKill;
            manager.defaultLoopType = defaultLoopType;
            manager.defaultUpdateType = defaultUpdateType;
            manager.defaultTimeScaleIndependent = defaultTimeScaleIndependent;
            manager.globalTimeScale = timeScale;
            manager.unscaledTimeScale = unscaledTimeScale;
            manager.validateTargets = validateTargets;
            manager.nestedTweenFailure = nestedTweenFailure;
            manager.logBehaviour = logBehaviour;
        }
    }
}
