using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Ties a tween's life to an entity's.
    ///
    /// A tween that outlives what it animates is the most common way tween code goes wrong: the target is
    /// destroyed, the tween keeps writing into nothing, and either it silently does nothing or it takes the
    /// process with it. A link makes that impossible by watching the entity every frame.
    ///
    /// KillOnDestroy is always enforced regardless of the chosen behaviour, which mirrors DOTween.
    /// </summary>
    class TweenLink
    {
        private ITween@ tween;
        private Entity@ entity;
        private LinkBehaviour behaviour;
        private bool wasEnabled = true;
        private bool primed = false;

        /// <summary>
        /// Links a tween to an entity.
        /// </summary>
        /// <param name="target">The tween to control.</param>
        /// <param name="linkedEntity">The entity to watch.</param>
        /// <param name="linkBehaviour">What to do when the entity is enabled or disabled.</param>
        TweenLink(ITween@ target, Entity@ linkedEntity, LinkBehaviour linkBehaviour)
        {
            @tween = target;
            @entity = linkedEntity;
            behaviour = linkBehaviour;
        }

        /// <summary>Whether this link still has anything to watch.</summary>
        /// <returns>Returns false once the tween is gone.</returns>
        bool IsAlive() const
        {
            return tween !is null && tween.IsActive();
        }

        /// <summary>
        /// Checks the entity and applies the link behaviour. Called once per frame by the manager.
        /// </summary>
        void Evaluate()
        {
            if (tween is null || !tween.IsActive()) {
                return;
            }

            if (entity is null || !Object::IsValid(entity)) {
                tween.Kill(false);
                return;
            }

            bool enabled = entity.enabledInScene;
            if (!primed) {
                primed = true;
                wasEnabled = enabled;
                return;
            }
            if (enabled == wasEnabled) {
                return;
            }
            wasEnabled = enabled;

            if (!enabled) {
                ApplyOnDisable();
            }
            else {
                ApplyOnEnable();
            }
        }

        private void ApplyOnDisable()
        {
            switch (behaviour) {
            case LinkBehaviour::PauseOnDisable:
            case LinkBehaviour::PauseOnDisablePlayOnEnable:
            case LinkBehaviour::PauseOnDisableRestartOnEnable:
                tween.Pause();
                break;
            case LinkBehaviour::KillOnDisable:
                tween.Kill(false);
                break;
            case LinkBehaviour::CompleteOnDisable:
                tween.Complete(false);
                break;
            case LinkBehaviour::CompleteAndKillOnDisable:
                tween.Kill(true);
                break;
            case LinkBehaviour::RewindOnDisable:
                tween.Rewind(true);
                break;
            case LinkBehaviour::RewindAndKillOnDisable:
                tween.Rewind(true);
                tween.Kill(false);
                break;
            }
        }

        private void ApplyOnEnable()
        {
            switch (behaviour) {
            case LinkBehaviour::PauseOnDisablePlayOnEnable:
            case LinkBehaviour::PlayOnEnable:
                tween.Play();
                break;
            case LinkBehaviour::PauseOnDisableRestartOnEnable:
            case LinkBehaviour::RestartOnEnable:
                tween.Restart(true);
                break;
            }
        }
    }
}
