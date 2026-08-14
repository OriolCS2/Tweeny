using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Drives the tween manager every frame. One instance is created automatically by TweenySettings at
    /// play start and made immutable so it survives scene loads; nothing has to be placed in a scene.
    ///
    /// CometEngine has no LateUpdate, so UpdateType::Late is driven from PostUpdate, which occupies the
    /// same slot in the frame.
    /// </summary>
    class TweenyRunner : CometBehaviour
    {
        void Update()
        {
            Tweeny::TickPhase(UpdateType::Normal, Time::GetDeltaTime(), Time::GetUnscaledDeltaTime());
        }

        void PostUpdate()
        {
            Tweeny::TickPhase(UpdateType::Late, Time::GetDeltaTime(), Time::GetUnscaledDeltaTime());
        }

        void FixedUpdate()
        {
            Tweeny::TickPhase(UpdateType::Fixed, Time::GetFixedDeltaTime(), Time::GetFixedUnscaledDeltaTime());
        }
    }
}
