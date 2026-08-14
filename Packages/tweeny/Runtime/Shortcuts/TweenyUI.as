using namespace CometEngine;
using namespace CometEngine::UI;

namespace Tweeny
{
    // =================================================================================================
    // Graphic
    //
    // Image, RawImage and Text all derive from Graphic, so tint and fade are written once here and every
    // present and future Graphic gets them.
    // =================================================================================================

    /// <summary>Tints any UI graphic.</summary>
    /// <param name="target">The graphic to tint.</param>
    /// <param name="to">The colour to reach.</param>
    /// <param name="duration">How long the tint takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Tint(Graphic@ target, CometEngine::Color to, float duration)
    {
        GuardedColor@ guard = IsAlive(target)
            ? GuardedColor(target, ColorGetter(target.get_color), ColorSetter(target.set_color))
            : GuardedColor();
        TweenColor@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Fades any UI graphic without touching its hue.</summary>
    /// <param name="target">The graphic to fade.</param>
    /// <param name="toAlpha">The alpha to reach.</param>
    /// <param name="duration">How long the fade takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenColor@ Fade(Graphic@ target, float toAlpha, float duration)
    {
        GuardedColor@ guard = IsAlive(target)
            ? GuardedColor(target, ColorGetter(target.get_color), ColorSetter(target.set_color))
            : GuardedColor();
        TweenColor@ tween = ToAlpha(guard.Getter(), guard.Setter(), toAlpha, duration);
        tween.SetTarget(target);
        return tween;
    }

    // =================================================================================================
    // CanvasGroup
    // =================================================================================================

    /// <summary>Fades a whole group of UI elements at once.</summary>
    /// <param name="target">The canvas group to fade.</param>
    /// <param name="to">The alpha to reach, from 0 to 1.</param>
    /// <param name="duration">How long the fade takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Fade(CanvasGroup@ target, float to, float duration)
    {
        GuardedFloat@ guard = IsAlive(target)
            ? GuardedFloat(target, FloatGetter(target.get_alpha), FloatSetter(target.set_alpha), to)
            : GuardedFloat();
        TweenFloat@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    // =================================================================================================
    // RectTransform
    // =================================================================================================

    /// <summary>Slides a UI element to an anchored position.</summary>
    /// <param name="target">The rect transform to move.</param>
    /// <param name="to">The anchored position to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ AnchorPos(RectTransform@ target, Vector2 to, float duration)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_anchoredPosition), Vector2Setter(target.set_anchoredPosition), to)
            : GuardedVector2();
        TweenVector2@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Slides a UI element horizontally.</summary>
    /// <param name="target">The rect transform to move.</param>
    /// <param name="to">The anchored X to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ AnchorPosX(RectTransform@ target, float to, float duration)
    {
        return AnchorPos(target, Vector2(to, 0.0f), duration).SetAxisConstraint(AxisConstraint::X);
    }

    /// <summary>Slides a UI element vertically.</summary>
    /// <param name="target">The rect transform to move.</param>
    /// <param name="to">The anchored Y to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ AnchorPosY(RectTransform@ target, float to, float duration)
    {
        return AnchorPos(target, Vector2(0.0f, to), duration).SetAxisConstraint(AxisConstraint::Y);
    }

    /// <summary>Resizes a UI element.</summary>
    /// <param name="target">The rect transform to resize.</param>
    /// <param name="to">The size to reach.</param>
    /// <param name="duration">How long the resize takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ SizeDelta(RectTransform@ target, Vector2 to, float duration)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_size), Vector2Setter(target.set_size), to)
            : GuardedVector2();
        TweenVector2@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Moves a UI element's pivot.</summary>
    /// <param name="target">The rect transform to change.</param>
    /// <param name="to">The pivot to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ Pivot(RectTransform@ target, Vector2 to, float duration)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_pivot), Vector2Setter(target.set_pivot), to)
            : GuardedVector2();
        TweenVector2@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Moves a UI element's minimum anchor.</summary>
    /// <param name="target">The rect transform to change.</param>
    /// <param name="to">The anchor to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ AnchorMin(RectTransform@ target, Vector2 to, float duration)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_anchorMin), Vector2Setter(target.set_anchorMin), to)
            : GuardedVector2();
        TweenVector2@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Moves a UI element's maximum anchor.</summary>
    /// <param name="target">The rect transform to change.</param>
    /// <param name="to">The anchor to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ AnchorMax(RectTransform@ target, Vector2 to, float duration)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_anchorMax), Vector2Setter(target.set_anchorMax), to)
            : GuardedVector2();
        TweenVector2@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Punches a UI element's anchored position and lets it spring back.</summary>
    /// <param name="target">The rect transform to punch.</param>
    /// <param name="punch">Which way and how far the punch goes.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <param name="vibrato">How many times it bounces per second.</param>
    /// <param name="elasticity">How far past the start it may spring back, from 0 to 1.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ PunchAnchorPos(RectTransform@ target, Vector2 punch, float duration,
        int vibrato = 10, float elasticity = 1.0f)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_anchoredPosition),
                             Vector2Setter(target.set_anchoredPosition))
            : GuardedVector2();
        TweenVector2Array@ tween = Punch(guard.Getter(), guard.Setter(), punch, duration, vibrato, elasticity);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Shakes a UI element's anchored position, settling back where it started.</summary>
    /// <param name="target">The rect transform to shake.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <param name="strength">How far the shake reaches.</param>
    /// <param name="vibrato">How many times it shakes per second.</param>
    /// <param name="randomness">How much the direction wanders each hop, in degrees.</param>
    /// <param name="fadeOut">Whether the shake dies down over its duration.</param>
    /// <param name="seed">Seed for the shake. Use the same value to replay it exactly.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ ShakeAnchorPos(RectTransform@ target, float duration, float strength = 100.0f,
        int vibrato = 10, float randomness = 90.0f, bool fadeOut = true, uint seed = 0)
    {
        GuardedVector2@ guard = IsAlive(target)
            ? GuardedVector2(target, Vector2Getter(target.get_anchoredPosition),
                             Vector2Setter(target.set_anchoredPosition))
            : GuardedVector2();
        TweenVector2Array@ tween = Shake(guard.Getter(), guard.Setter(), duration, strength, vibrato,
            randomness, fadeOut, ShakeRandomnessMode::Full, seed);
        tween.SetTarget(target);
        return tween;
    }

    // =================================================================================================
    // Slider and Scrollbar
    // =================================================================================================

    /// <summary>Slides a slider to a value.</summary>
    /// <param name="target">The slider to change.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ Value(Slider@ target, float to, float duration)
    {
        GuardedFloat@ guard = IsAlive(target)
            ? GuardedFloat(target, FloatGetter(target.get_value), FloatSetter(target.set_value), to)
            : GuardedFloat();
        TweenFloat@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Slides a slider to a normalised value between 0 and 1.</summary>
    /// <param name="target">The slider to change.</param>
    /// <param name="to">The normalised value to reach.</param>
    /// <param name="duration">How long the change takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenFloat@ NormalizedValue(Slider@ target, float to, float duration)
    {
        GuardedFloat@ guard = IsAlive(target)
            ? GuardedFloat(target, FloatGetter(target.get_normalizedValue), FloatSetter(target.set_normalizedValue), to)
            : GuardedFloat();
        TweenFloat@ tween = To(guard.Getter(), guard.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }
}
