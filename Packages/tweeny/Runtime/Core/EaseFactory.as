using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Wraps an easing curve so it is only re-evaluated at a fixed frame rate, producing a stop-motion look.
    /// The instance is kept alive by the delegate handed to SetEase, so callers only need to keep the
    /// EaseFunc handle around.
    /// </summary>
    class StopMotionEase
    {
        private float motionDelay;
        private Ease baseEase;
        private EaseFunc@ baseFunc;

        /// <summary>
        /// Builds a stop-motion wrapper.
        /// </summary>
        /// <param name="motionFps">Frames per second the wrapped ease is sampled at. Values below 1 are clamped.</param>
        /// <param name="easeType">The built-in curve to sample, or INTERNAL_Custom when using a function.</param>
        /// <param name="custom">The custom function to sample when easeType is INTERNAL_Custom.</param>
        StopMotionEase(int motionFps, Ease easeType, EaseFunc@ custom)
        {
            motionDelay = 1.0f / float(motionFps < 1 ? 1 : motionFps);
            baseEase = easeType;
            @baseFunc = custom;
        }

        /// <summary>
        /// Evaluates the wrapped ease at the quantised time.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <param name="overshootOrAmplitude">The ease's overshoot or amplitude parameter.</param>
        /// <param name="period">The ease's period parameter.</param>
        /// <returns>Returns the eased progress sampled at the stop-motion rate.</returns>
        float Evaluate(float time, float duration, float overshootOrAmplitude, float period)
        {
            float stepTime = time < duration ? time - (time % motionDelay) : time;
            return EaseManager::Evaluate(baseEase, baseFunc, stepTime, duration, overshootOrAmplitude, period);
        }
    }

    /// <summary>
    /// Builders that decorate an easing curve with extra behaviour.
    /// </summary>
    namespace EaseFactory
    {
        /// <summary>
        /// Turns a built-in ease into a stop-motion version of itself.
        /// </summary>
        /// <param name="motionFps">Frames per second the ease is sampled at.</param>
        /// <param name="easeType">The curve to sample.</param>
        /// <returns>Returns a function usable with SetEase.</returns>
        EaseFunc@ StopMotion(int motionFps, Ease easeType)
        {
            StopMotionEase@ wrapper = StopMotionEase(motionFps, easeType, null);
            return EaseFunc(wrapper.Evaluate);
        }

        /// <summary>
        /// Turns a custom ease function into a stop-motion version of itself.
        /// </summary>
        /// <param name="motionFps">Frames per second the ease is sampled at.</param>
        /// <param name="customEase">The function to sample.</param>
        /// <returns>Returns a function usable with SetEase.</returns>
        EaseFunc@ StopMotion(int motionFps, EaseFunc@ customEase)
        {
            StopMotionEase@ wrapper = StopMotionEase(motionFps, Ease::INTERNAL_Custom, customEase);
            return EaseFunc(wrapper.Evaluate);
        }
    }
}
