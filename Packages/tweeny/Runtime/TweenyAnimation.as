using namespace CometEngine;

namespace Tweeny
{
    /// <summary>What a TweenyAnimation animates.</summary>
    enum TweenyAnimationType
    {
        Move = 0,
        LocalMove,
        Scale,
        Rotate,
        Fade,
        Tint,
        PunchPosition,
        PunchScale,
        ShakePosition,
        ShakeScale
    }

    /// <summary>When a TweenyAnimation starts.</summary>
    enum TweenyAutoPlayMode
    {
        /// <summary>Plays as soon as the entity wakes up.</summary>
        OnStart = 0,
        /// <summary>Plays every time the entity is enabled.</summary>
        OnEnable,
        /// <summary>Waits for something to call Play.</summary>
        Manual
    }

    /// <summary>
    /// Animates an entity straight from the inspector, with no code at all.
    ///
    /// Add it, pick what to animate and how, and press Play. Everything it can do is also reachable from
    /// script; this is the same feature set wired to inspector fields for designers.
    /// </summary>
    class TweenyAnimation : CometBehaviour
    {
        [Header("What to animate")]
        [Tooltip("Which property this animation drives.")]
        TweenyAnimationType animationType = TweenyAnimationType::Move;

        [Tooltip("Renderer to tint or fade. Leave empty to use the one on this entity.")]
        BaseRenderer@ rendererTarget;

        [Header("Target value")]
        [Tooltip("Destination for Move, LocalMove, Scale and the punch and shake effects.")]
        Vector2 endValueVector = Vector2(0.0f, 0.0f);

        [Tooltip("Destination for Rotate, in degrees, and for Fade, as an alpha.")]
        float endValueFloat = 0.0f;

        [Tooltip("Destination colour for Tint.")]
        Color endValueColor = Color(1.0f, 1.0f, 1.0f, 1.0f);

        [Header("Timing")]
        [Tooltip("How long one loop takes, in seconds.")]
        float duration = 1.0f;

        [Tooltip("How long to wait before starting, in seconds.")]
        float delay = 0.0f;

        [Tooltip("Easing curve. Punch and shake choose their own.")]
        Ease ease = Ease::OutQuad;

        [Tooltip("How many times to run. -1 loops forever.")]
        int loops = 1;

        [Tooltip("What happens at the end of each loop.")]
        LoopType loopType = LoopType::Restart;

        [Header("Behaviour")]
        [Tooltip("Treat the target value as an offset from where the entity already is.")]
        bool relative = false;

        [Tooltip("Play from the target value towards the entity's current one.")]
        bool from = false;

        [Tooltip("Ignore the game time scale, so the animation still runs while paused.")]
        bool ignoreTimeScale = false;

        [Tooltip("When the animation starts.")]
        TweenyAutoPlayMode autoPlay = TweenyAutoPlayMode::OnStart;

        [Tooltip("Discard the tween once it finishes. Turn off to replay it later.")]
        bool autoKill = true;

        [Header("Punch and shake")]
        [Tooltip("How many times the effect bounces per second.")]
        int vibrato = 10;

        [Tooltip("How far past the start a punch may spring back, from 0 to 1.")]
        float elasticity = 1.0f;

        [Tooltip("How far a shake reaches.")]
        float shakeStrength = 2.0f;

        private ITween@ current;

        void Start()
        {
            if (autoPlay == TweenyAutoPlayMode::OnStart) {
                Play();
            }
        }

        void OnEnable()
        {
            if (autoPlay == TweenyAutoPlayMode::OnEnable) {
                Play();
            }
        }

        void OnDestroy()
        {
            Kill();
        }

        /// <summary>
        /// Builds the tween and starts it, replacing whatever was running.
        /// </summary>
        void Play()
        {
            Kill();
            @current = Build();
            if (current is null) {
                return;
            }
            Tweeny::SetLink(current, entity, LinkBehaviour::KillOnDestroy);
        }

        /// <summary>Stops and discards the running tween.</summary>
        void Kill()
        {
            if (current !is null && current.IsActive()) {
                current.Kill(false);
            }
            @current = null;
        }

        /// <summary>Suspends the running tween.</summary>
        void Pause()
        {
            if (current !is null && current.IsActive()) {
                current.Pause();
            }
        }

        /// <summary>Sends the running tween back to its start.</summary>
        void Rewind()
        {
            if (current !is null && current.IsActive()) {
                current.Rewind(true);
            }
        }

        /// <summary>The tween this component is currently running.</summary>
        /// <returns>Returns the tween, or null when nothing is playing.</returns>
        ITween@ GetTween() { return current; }

        private BaseRenderer@ ResolveRenderer()
        {
            if (rendererTarget !is null) {
                return rendererTarget;
            }
            return BaseRenderer::Get(entity);
        }

        private ITween@ Build()
        {
            Transform@ tr = transform;
            if (tr is null) {
                return null;
            }

            switch (animationType) {
            case TweenyAnimationType::Move:
                return Configure(Tweeny::Move(tr, endValueVector, duration));
            case TweenyAnimationType::LocalMove:
                return Configure(Tweeny::LocalMove(tr,
                    Vector3(endValueVector.x, endValueVector.y, tr.localPosition.z), duration));
            case TweenyAnimationType::Scale:
                return Configure(Tweeny::Scale(tr,
                    Vector3(endValueVector.x, endValueVector.y, tr.localScale.z), duration));
            case TweenyAnimationType::Rotate:
                return Configure(Tweeny::Rotate(tr, endValueFloat, duration));
            case TweenyAnimationType::Fade: {
                BaseRenderer@ renderer = ResolveRenderer();
                if (renderer is null) {
                    return null;
                }
                return Configure(Tweeny::Fade(renderer, endValueFloat, duration)); }
            case TweenyAnimationType::Tint: {
                BaseRenderer@ renderer = ResolveRenderer();
                if (renderer is null) {
                    return null;
                }
                return Configure(Tweeny::Tint(renderer, endValueColor, duration)); }
            case TweenyAnimationType::PunchPosition:
                return ConfigureEffect(Tweeny::PunchPosition(tr, endValueVector, duration, vibrato, elasticity));
            case TweenyAnimationType::PunchScale:
                return ConfigureEffect(Tweeny::PunchScale(tr, endValueVector, duration, vibrato, elasticity));
            case TweenyAnimationType::ShakePosition:
                return ConfigureEffect(Tweeny::ShakePosition(tr, duration, shakeStrength, vibrato));
            case TweenyAnimationType::ShakeScale:
                return ConfigureEffect(Tweeny::ShakeScale(tr, duration, shakeStrength, vibrato));
            }
            return null;
        }

        private ITween@ Configure(TweenVector2@ tween)
        {
            tween.SetEase(ease).SetLoops(loops, loopType).SetDelay(delay)
                .SetAutoKill(autoKill).SetUpdate(ignoreTimeScale);
            if (relative) { tween.SetRelative(true); }
            if (from) { tween.From(relative); }
            return tween;
        }

        private ITween@ Configure(TweenVector3@ tween)
        {
            tween.SetEase(ease).SetLoops(loops, loopType).SetDelay(delay)
                .SetAutoKill(autoKill).SetUpdate(ignoreTimeScale);
            if (relative) { tween.SetRelative(true); }
            if (from) { tween.From(relative); }
            return tween;
        }

        private ITween@ Configure(TweenAngle@ tween)
        {
            tween.SetEase(ease).SetLoops(loops, loopType).SetDelay(delay)
                .SetAutoKill(autoKill).SetUpdate(ignoreTimeScale);
            if (relative) { tween.SetRelative(true); }
            if (from) { tween.From(relative); }
            return tween;
        }

        private ITween@ Configure(TweenColor@ tween)
        {
            tween.SetEase(ease).SetLoops(loops, loopType).SetDelay(delay)
                .SetAutoKill(autoKill).SetUpdate(ignoreTimeScale);
            if (relative) { tween.SetRelative(true); }
            if (from) { tween.From(relative); }
            return tween;
        }

        /// Punch and shake pick their own easing and cannot be played backwards, so they only take the
        /// settings that make sense for them.
        private ITween@ ConfigureEffect(TweenVector2Array@ tween)
        {
            tween.SetLoops(loops, loopType).SetDelay(delay).SetAutoKill(autoKill);
            return tween;
        }
    }
}
