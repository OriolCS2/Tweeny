using namespace CometEngine;

namespace Tweeny
{
    // =================================================================================================
    // Renderers
    //
    // BaseRenderer already carries the colour, and SpriteRenderer, AnimatedSprite, TextureRectRenderer and
    // RenderTextureRenderer all derive from it, so one pair of shortcuts covers every one of them.
    // =================================================================================================

    /// <summary>Tints a renderer. Named Tint rather than Color because a function called Color inside this namespace would be ambiguous with the engine Color type in any file that imports both.</summary>
    /// <param name="target">The renderer to tint.</param>
    /// <param name="to">The colour to reach.</param>
    /// <param name="duration">How long the tint takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Tint(BaseRenderer@ target, CometEngine::Color to, float duration)
    {
        TweenColor@ tween = To(ColorGetter(target.get_color), ColorSetter(target.set_color), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Fades a renderer without touching its hue.</summary>
    /// <param name="target">The renderer to fade.</param>
    /// <param name="toAlpha">The alpha to reach.</param>
    /// <param name="duration">How long the fade takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Fade(BaseRenderer@ target, float toAlpha, float duration)
    {
        TweenColor@ tween = ToAlpha(ColorGetter(target.get_color), ColorSetter(target.set_color), toAlpha, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Tints a tilemap.</summary>
    /// <param name="target">The tilemap renderer to tint.</param>
    /// <param name="to">The colour to reach.</param>
    /// <param name="duration">How long the tint takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Tint(CometEngine::Tilemaps::TilemapRenderer@ target, CometEngine::Color to, float duration)
    {
        TweenColor@ tween = To(ColorGetter(target.get_color), ColorSetter(target.set_color), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Fades a tilemap without touching its hue.</summary>
    /// <param name="target">The tilemap renderer to fade.</param>
    /// <param name="toAlpha">The alpha to reach.</param>
    /// <param name="duration">How long the fade takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Fade(CometEngine::Tilemaps::TilemapRenderer@ target, float toAlpha, float duration)
    {
        TweenColor@ tween = ToAlpha(ColorGetter(target.get_color), ColorSetter(target.set_color), toAlpha, duration);
        tween.SetTarget(target);
        return tween;
    }

    // =================================================================================================
    // Camera
    // =================================================================================================

    /// <summary>Zooms an orthographic camera.</summary>
    /// <param name="target">The camera to zoom.</param>
    /// <param name="to">The orthographic size to reach.</param>
    /// <param name="duration">How long the zoom takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ OrthoSize(Camera@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_size), FloatSetter(target.set_size), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Fades a camera's background colour.</summary>
    /// <param name="target">The camera to change.</param>
    /// <param name="to">The colour to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Tint(Camera@ target, CometEngine::Color to, float duration)
    {
        TweenColor@ tween = To(ColorGetter(target.get_backgroundColor),
            ColorSetter(target.set_backgroundColor), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    // Camera.aspectRatio is read-only in Comet, so there is deliberately no Aspect shortcut: there is
    // nothing to write to.

    /// <summary>Shakes a camera, settling back where it started.</summary>
    /// <param name="target">The camera's transform.</param>
    /// <param name="duration">How long the shake lasts.</param>
    /// <param name="strength">How far the shake reaches.</param>
    /// <param name="vibrato">How many times it shakes per second.</param>
    /// <param name="seed">Seed for the shake. Use the same value to replay it exactly.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ ShakeCamera(Transform@ target, float duration, float strength = 1.0f,
        int vibrato = 10, uint seed = 0)
    {
        return ShakePosition(target, duration, strength, vibrato, 90.0f, true, seed);
    }

    // =================================================================================================
    // Lights
    //
    // Everything a light exposes for animation lives on BaseLight, so point, global, sprite, parametric
    // and freeform lights are all covered at once.
    // =================================================================================================

    /// <summary>Changes a light's colour.</summary>
    /// <param name="target">The light to change.</param>
    /// <param name="to">The colour to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Tint(BaseLight@ target, CometEngine::Color to, float duration)
    {
        TweenColor@ tween = To(ColorGetter(target.get_color), ColorSetter(target.set_color), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Brightens or dims a light.</summary>
    /// <param name="target">The light to change.</param>
    /// <param name="to">The intensity to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Intensity(BaseLight@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_intensity),
            FloatSetter(target.set_intensity), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Changes how strongly a light casts shadows.</summary>
    /// <param name="target">The light to change.</param>
    /// <param name="to">The shadow strength to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ ShadowStrength(BaseLight@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_shadowStrength),
            FloatSetter(target.set_shadowStrength), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Grows or shrinks a point light's reach.</summary>
    /// <param name="target">The light to change.</param>
    /// <param name="to">The outer radius to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Radius(PointLight@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_outerRadius),
            FloatSetter(target.set_outerRadius), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    // =================================================================================================
    // Audio
    // =================================================================================================

    /// <summary>Fades an audio source's volume.</summary>
    /// <param name="target">The audio source to fade.</param>
    /// <param name="to">The volume to reach, from 0 to 1.</param>
    /// <param name="duration">How long the fade takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Fade(AudioSource@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_volume), FloatSetter(target.set_volume), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Slides an audio source's pitch.</summary>
    /// <param name="target">The audio source to change.</param>
    /// <param name="to">The pitch to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Pitch(AudioSource@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_pitch), FloatSetter(target.set_pitch), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Pans an audio source between the speakers.</summary>
    /// <param name="target">The audio source to change.</param>
    /// <param name="to">The pan to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Pan(AudioSource@ target, float to, float duration)
    {
        TweenFloat@ tween = To(FloatGetter(target.get_pan), FloatSetter(target.set_pan), to, duration);
        tween.SetTarget(target);
        return tween;
    }
}
