using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// The easing curve applied to a tween's progress. Declaration order matches DOTween so numeric
    /// values serialized by other tools stay compatible.
    /// </summary>
    enum Ease
    {
        /// <summary>No ease chosen. Resolves to the project default when the tween starts.</summary>
        Unset = 0,
        Linear,
        InSine,
        OutSine,
        InOutSine,
        InQuad,
        OutQuad,
        InOutQuad,
        InCubic,
        OutCubic,
        InOutCubic,
        InQuart,
        OutQuart,
        InOutQuart,
        InQuint,
        OutQuint,
        InOutQuint,
        InExpo,
        OutExpo,
        InOutExpo,
        InCirc,
        OutCirc,
        InOutCirc,
        /// <summary>Overshoots using amplitude and period.</summary>
        InElastic,
        OutElastic,
        InOutElastic,
        /// <summary>Overshoots using the overshoot parameter (1.70158 by default).</summary>
        InBack,
        OutBack,
        InOutBack,
        InBounce,
        OutBounce,
        InOutBounce,
        /// <summary>Blinks between start and end. Amplitude is the flash count, period weights it over time.</summary>
        Flash,
        InFlash,
        OutFlash,
        InOutFlash,
        /// <summary>Assigned automatically to zero-duration tweens. Always evaluates to 1.</summary>
        INTERNAL_Zero,
        /// <summary>Assigned automatically when a custom ease function or curve is supplied.</summary>
        INTERNAL_Custom
    }

    /// <summary>
    /// Signature of a user-supplied easing function.
    /// </summary>
    /// <param name="time">Elapsed time inside the current loop.</param>
    /// <param name="duration">Duration of one loop.</param>
    /// <param name="overshootOrAmplitude">The ease's overshoot or amplitude parameter.</param>
    /// <param name="period">The ease's period parameter.</param>
    /// <returns>Returns the eased progress, normally between 0 and 1.</returns>
    funcdef float EaseFunc(float time, float duration, float overshootOrAmplitude, float period);

    /// <summary>
    /// The overshoot used by the Back eases when none is given.
    /// </summary>
    const float DEFAULT_OVERSHOOT = 1.70158f;

    /// <summary>
    /// The period used by the Elastic eases when none is given (0 means "derive it from the duration").
    /// </summary>
    const float DEFAULT_PERIOD = 0.0f;
}
