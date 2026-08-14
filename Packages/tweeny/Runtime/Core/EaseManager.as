using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Evaluates every built-in easing curve. The formulas are ported verbatim from DOTween, which in turn
    /// derives most of them from Robert Penner's equations, so a tween authored against DOTween produces the
    /// same motion here. Compound assignments have been expanded into explicit statements because the C#
    /// originals rely on assignment-expression evaluation order.
    /// </summary>
    namespace EaseManager
    {
        const float PI_OVER_2 = Math::PI * 0.5f;
        const float TWO_PI = Math::PI * 2.0f;

        /// <summary>
        /// Evaluates an easing curve.
        /// </summary>
        /// <param name="easeType">The curve to evaluate.</param>
        /// <param name="customEase">The function used when easeType is INTERNAL_Custom.</param>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <param name="overshootOrAmplitude">Overshoot for Back, amplitude for Elastic, flash count for Flash.</param>
        /// <param name="period">Period for Elastic, time weighting for Flash.</param>
        /// <returns>Returns the eased progress. Back and Elastic deliberately leave the 0..1 range.</returns>
        float Evaluate(Ease easeType, EaseFunc@ customEase, float time, float duration,
            float overshootOrAmplitude, float period)
        {
            switch (easeType) {
            case Ease::Linear:
                return time / duration;

            case Ease::InSine:
                return -Math::Cos(time / duration * PI_OVER_2) + 1.0f;
            case Ease::OutSine:
                return Math::Sin(time / duration * PI_OVER_2);
            case Ease::InOutSine:
                return -0.5f * (Math::Cos(Math::PI * time / duration) - 1.0f);

            case Ease::InQuad: {
                float t = time / duration;
                return t * t; }
            case Ease::OutQuad: {
                float t = time / duration;
                return -t * (t - 2.0f); }
            case Ease::InOutQuad: {
                float t = time / (duration * 0.5f);
                if (t < 1.0f) {
                    return 0.5f * t * t;
                }
                t -= 1.0f;
                return -0.5f * (t * (t - 2.0f) - 1.0f); }

            case Ease::InCubic: {
                float t = time / duration;
                return t * t * t; }
            case Ease::OutCubic: {
                float t = time / duration - 1.0f;
                return t * t * t + 1.0f; }
            case Ease::InOutCubic: {
                float t = time / (duration * 0.5f);
                if (t < 1.0f) {
                    return 0.5f * t * t * t;
                }
                t -= 2.0f;
                return 0.5f * (t * t * t + 2.0f); }

            case Ease::InQuart: {
                float t = time / duration;
                return t * t * t * t; }
            case Ease::OutQuart: {
                float t = time / duration - 1.0f;
                return -(t * t * t * t - 1.0f); }
            case Ease::InOutQuart: {
                float t = time / (duration * 0.5f);
                if (t < 1.0f) {
                    return 0.5f * t * t * t * t;
                }
                t -= 2.0f;
                return -0.5f * (t * t * t * t - 2.0f); }

            case Ease::InQuint: {
                float t = time / duration;
                return t * t * t * t * t; }
            case Ease::OutQuint: {
                float t = time / duration - 1.0f;
                return t * t * t * t * t + 1.0f; }
            case Ease::InOutQuint: {
                float t = time / (duration * 0.5f);
                if (t < 1.0f) {
                    return 0.5f * t * t * t * t * t;
                }
                t -= 2.0f;
                return 0.5f * (t * t * t * t * t + 2.0f); }

            case Ease::InExpo:
                if (time == 0.0f) {
                    return 0.0f;
                }
                return Math::Pow(2.0f, 10.0f * (time / duration - 1.0f));
            case Ease::OutExpo:
                if (time == duration) {
                    return 1.0f;
                }
                return -Math::Pow(2.0f, -10.0f * time / duration) + 1.0f;
            case Ease::InOutExpo: {
                if (time == 0.0f) {
                    return 0.0f;
                }
                if (time == duration) {
                    return 1.0f;
                }
                float t = time / (duration * 0.5f);
                if (t < 1.0f) {
                    return 0.5f * Math::Pow(2.0f, 10.0f * (t - 1.0f));
                }
                t -= 1.0f;
                return 0.5f * (-Math::Pow(2.0f, -10.0f * t) + 2.0f); }

            case Ease::InCirc: {
                float t = time / duration;
                return -(Math::Sqrt(1.0f - t * t) - 1.0f); }
            case Ease::OutCirc: {
                float t = time / duration - 1.0f;
                return Math::Sqrt(1.0f - t * t); }
            case Ease::InOutCirc: {
                float t = time / (duration * 0.5f);
                if (t < 1.0f) {
                    return -0.5f * (Math::Sqrt(1.0f - t * t) - 1.0f);
                }
                t -= 2.0f;
                return 0.5f * (Math::Sqrt(1.0f - t * t) + 1.0f); }

            case Ease::InElastic: {
                if (time == 0.0f) {
                    return 0.0f;
                }
                float t = time / duration;
                if (t == 1.0f) {
                    return 1.0f;
                }
                float p = period == 0.0f ? duration * 0.3f : period;
                float amplitude = overshootOrAmplitude;
                float s = 0.0f;
                if (amplitude < 1.0f) {
                    amplitude = 1.0f;
                    s = p * 0.25f;
                }
                else {
                    s = p / TWO_PI * Math::Asin(1.0f / amplitude);
                }
                t -= 1.0f;
                return -(amplitude * Math::Pow(2.0f, 10.0f * t) * Math::Sin((t * duration - s) * TWO_PI / p)); }

            case Ease::OutElastic: {
                if (time == 0.0f) {
                    return 0.0f;
                }
                float t = time / duration;
                if (t == 1.0f) {
                    return 1.0f;
                }
                float p = period == 0.0f ? duration * 0.3f : period;
                float amplitude = overshootOrAmplitude;
                float s = 0.0f;
                if (amplitude < 1.0f) {
                    amplitude = 1.0f;
                    s = p * 0.25f;
                }
                else {
                    s = p / TWO_PI * Math::Asin(1.0f / amplitude);
                }
                return amplitude * Math::Pow(2.0f, -10.0f * t) * Math::Sin((t * duration - s) * TWO_PI / p) + 1.0f; }

            case Ease::InOutElastic: {
                if (time == 0.0f) {
                    return 0.0f;
                }
                float t = time / (duration * 0.5f);
                if (t == 2.0f) {
                    return 1.0f;
                }
                float p = period == 0.0f ? duration * (0.3f * 1.5f) : period;
                float amplitude = overshootOrAmplitude;
                float s = 0.0f;
                if (amplitude < 1.0f) {
                    amplitude = 1.0f;
                    s = p * 0.25f;
                }
                else {
                    s = p / TWO_PI * Math::Asin(1.0f / amplitude);
                }
                if (t < 1.0f) {
                    t -= 1.0f;
                    return -0.5f * (amplitude * Math::Pow(2.0f, 10.0f * t) * Math::Sin((t * duration - s) * TWO_PI / p));
                }
                t -= 1.0f;
                return amplitude * Math::Pow(2.0f, -10.0f * t) * Math::Sin((t * duration - s) * TWO_PI / p) * 0.5f + 1.0f; }

            case Ease::InBack: {
                float t = time / duration;
                return t * t * ((overshootOrAmplitude + 1.0f) * t - overshootOrAmplitude); }
            case Ease::OutBack: {
                float t = time / duration - 1.0f;
                return t * t * ((overshootOrAmplitude + 1.0f) * t + overshootOrAmplitude) + 1.0f; }
            case Ease::InOutBack: {
                float t = time / (duration * 0.5f);
                float s = overshootOrAmplitude * 1.525f;
                if (t < 1.0f) {
                    return 0.5f * (t * t * ((s + 1.0f) * t - s));
                }
                t -= 2.0f;
                return 0.5f * (t * t * ((s + 1.0f) * t + s) + 2.0f); }

            case Ease::InBounce:
                return BounceIn(time, duration);
            case Ease::OutBounce:
                return BounceOut(time, duration);
            case Ease::InOutBounce:
                return BounceInOut(time, duration);

            case Ease::Flash:
                return FlashEase(time, duration, overshootOrAmplitude, period);
            case Ease::InFlash:
                return FlashIn(time, duration, overshootOrAmplitude, period);
            case Ease::OutFlash:
                return FlashOut(time, duration, overshootOrAmplitude, period);
            case Ease::InOutFlash:
                return FlashInOut(time, duration, overshootOrAmplitude, period);

            case Ease::INTERNAL_Custom:
                return customEase is null ? time / duration : customEase(time, duration, overshootOrAmplitude, period);

            case Ease::INTERNAL_Zero:
                return 1.0f;
            }

            float fallback = time / duration;
            return -fallback * (fallback - 2.0f);
        }

        /// <summary>
        /// Evaluates a bounce that decelerates towards the end.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <returns>Returns the eased progress.</returns>
        float BounceOut(float time, float duration)
        {
            float t = time / duration;
            if (t < (1.0f / 2.75f)) {
                return 7.5625f * t * t;
            }
            if (t < (2.0f / 2.75f)) {
                t -= (1.5f / 2.75f);
                return 7.5625f * t * t + 0.75f;
            }
            if (t < (2.5f / 2.75f)) {
                t -= (2.25f / 2.75f);
                return 7.5625f * t * t + 0.9375f;
            }
            t -= (2.625f / 2.75f);
            return 7.5625f * t * t + 0.984375f;
        }

        /// <summary>
        /// Evaluates a bounce that accelerates from the start.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <returns>Returns the eased progress.</returns>
        float BounceIn(float time, float duration)
        {
            return 1.0f - BounceOut(duration - time, duration);
        }

        /// <summary>
        /// Evaluates a bounce that accelerates until halfway and then decelerates.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <returns>Returns the eased progress.</returns>
        float BounceInOut(float time, float duration)
        {
            if (time < duration * 0.5f) {
                return BounceIn(time * 2.0f, duration) * 0.5f;
            }
            return BounceOut(time * 2.0f - duration, duration) * 0.5f + 0.5f;
        }

        /// <summary>
        /// Blends a flash step's raw result using the amplitude and period weighting.
        /// </summary>
        /// <param name="overshootOrAmplitude">The number of flashes.</param>
        /// <param name="period">Time weighting between -1 and 1.</param>
        /// <param name="stepIndex">The one-based index of the current flash step.</param>
        /// <param name="dir">The direction of the current step, 1 or -1.</param>
        /// <param name="res">The raw eased value of the current step.</param>
        /// <returns>Returns the weighted value, clamped to a maximum of 1.</returns>
        float FlashWeighted(float overshootOrAmplitude, float period, int stepIndex, float dir, float res)
        {
            float easedRes = 0.0f;
            float finalDecimals = 0.0f;
            int amplitudeInt = int(overshootOrAmplitude);

            if (dir > 0.0f && amplitudeInt % 2 == 0) {
                stepIndex++;
            }
            else if (dir < 0.0f && amplitudeInt % 2 != 0) {
                stepIndex++;
            }

            float p = period;
            if (p > 0.0f) {
                float finalTruncated = float(int(overshootOrAmplitude));
                finalDecimals = overshootOrAmplitude - finalTruncated;
                if (int(finalTruncated) % 2 > 0) {
                    finalDecimals = 1.0f - finalDecimals;
                }
                finalDecimals = (finalDecimals * float(stepIndex)) / overshootOrAmplitude;
                easedRes = (res * (overshootOrAmplitude - float(stepIndex))) / overshootOrAmplitude;
            }
            else if (p < 0.0f) {
                p = -p;
                easedRes = (res * float(stepIndex)) / overshootOrAmplitude;
            }

            float diff = easedRes - res;
            float result = res + (diff * p) + finalDecimals;
            if (result > 1.0f) {
                result = 1.0f;
            }
            return result;
        }

        /// <summary>
        /// Evaluates a linear flash.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <param name="overshootOrAmplitude">The number of flashes.</param>
        /// <param name="period">Time weighting between -1 and 1.</param>
        /// <returns>Returns the eased progress.</returns>
        float FlashEase(float time, float duration, float overshootOrAmplitude, float period)
        {
            int stepIndex = Math::CeilToInt((time / duration) * overshootOrAmplitude);
            float stepDuration = duration / overshootOrAmplitude;
            float t = time - stepDuration * float(stepIndex - 1);
            float dir = (stepIndex % 2 != 0) ? 1.0f : -1.0f;
            if (dir < 0.0f) {
                t -= stepDuration;
            }
            float res = (t * dir) / stepDuration;
            return FlashWeighted(overshootOrAmplitude, period, stepIndex, dir, res);
        }

        /// <summary>
        /// Evaluates a flash whose steps accelerate.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <param name="overshootOrAmplitude">The number of flashes.</param>
        /// <param name="period">Time weighting between -1 and 1.</param>
        /// <returns>Returns the eased progress.</returns>
        float FlashIn(float time, float duration, float overshootOrAmplitude, float period)
        {
            int stepIndex = Math::CeilToInt((time / duration) * overshootOrAmplitude);
            float stepDuration = duration / overshootOrAmplitude;
            float t = time - stepDuration * float(stepIndex - 1);
            float dir = (stepIndex % 2 != 0) ? 1.0f : -1.0f;
            if (dir < 0.0f) {
                t -= stepDuration;
            }
            t = (t * dir) / stepDuration;
            float res = t * t;
            return FlashWeighted(overshootOrAmplitude, period, stepIndex, dir, res);
        }

        /// <summary>
        /// Evaluates a flash whose steps decelerate.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <param name="overshootOrAmplitude">The number of flashes.</param>
        /// <param name="period">Time weighting between -1 and 1.</param>
        /// <returns>Returns the eased progress.</returns>
        float FlashOut(float time, float duration, float overshootOrAmplitude, float period)
        {
            int stepIndex = Math::CeilToInt((time / duration) * overshootOrAmplitude);
            float stepDuration = duration / overshootOrAmplitude;
            float t = time - stepDuration * float(stepIndex - 1);
            float dir = (stepIndex % 2 != 0) ? 1.0f : -1.0f;
            if (dir < 0.0f) {
                t -= stepDuration;
            }
            t = (t * dir) / stepDuration;
            float res = -t * (t - 2.0f);
            return FlashWeighted(overshootOrAmplitude, period, stepIndex, dir, res);
        }

        /// <summary>
        /// Evaluates a flash whose steps accelerate until halfway and then decelerate.
        /// </summary>
        /// <param name="time">Elapsed time inside the current loop.</param>
        /// <param name="duration">Duration of one loop.</param>
        /// <param name="overshootOrAmplitude">The number of flashes.</param>
        /// <param name="period">Time weighting between -1 and 1.</param>
        /// <returns>Returns the eased progress.</returns>
        float FlashInOut(float time, float duration, float overshootOrAmplitude, float period)
        {
            int stepIndex = Math::CeilToInt((time / duration) * overshootOrAmplitude);
            float stepDuration = duration / overshootOrAmplitude;
            float t = time - stepDuration * float(stepIndex - 1);
            float dir = (stepIndex % 2 != 0) ? 1.0f : -1.0f;
            if (dir < 0.0f) {
                t -= stepDuration;
            }
            t = t * dir;

            float res = 0.0f;
            float half = t / (stepDuration * 0.5f);
            if (half < 1.0f) {
                res = 0.5f * half * half;
            }
            else {
                half -= 1.0f;
                res = -0.5f * (half * (half - 2.0f) - 1.0f);
            }
            return FlashWeighted(overshootOrAmplitude, period, stepIndex, dir, res);
        }
    }
}
