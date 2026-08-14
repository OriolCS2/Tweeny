using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// Every ease that is expected to be well behaved at the endpoints and monotonic-ish in between.
    /// Back, Elastic and the Flash family are excluded: they deliberately overshoot or oscillate.
    array<Ease> WellBehavedEases()
    {
        array<Ease> eases;
        eases.insertLast(Ease::Linear);
        eases.insertLast(Ease::InSine);     eases.insertLast(Ease::OutSine);     eases.insertLast(Ease::InOutSine);
        eases.insertLast(Ease::InQuad);     eases.insertLast(Ease::OutQuad);     eases.insertLast(Ease::InOutQuad);
        eases.insertLast(Ease::InCubic);    eases.insertLast(Ease::OutCubic);    eases.insertLast(Ease::InOutCubic);
        eases.insertLast(Ease::InQuart);    eases.insertLast(Ease::OutQuart);    eases.insertLast(Ease::InOutQuart);
        eases.insertLast(Ease::InQuint);    eases.insertLast(Ease::OutQuint);    eases.insertLast(Ease::InOutQuint);
        eases.insertLast(Ease::InExpo);     eases.insertLast(Ease::OutExpo);     eases.insertLast(Ease::InOutExpo);
        eases.insertLast(Ease::InCirc);     eases.insertLast(Ease::OutCirc);     eases.insertLast(Ease::InOutCirc);
        eases.insertLast(Ease::InBounce);   eases.insertLast(Ease::OutBounce);   eases.insertLast(Ease::InOutBounce);
        return eases;
    }

    /// The overshooting family: correct at the endpoints but free to leave 0..1 in between.
    array<Ease> OvershootingEases()
    {
        array<Ease> eases;
        eases.insertLast(Ease::InBack);    eases.insertLast(Ease::OutBack);    eases.insertLast(Ease::InOutBack);
        eases.insertLast(Ease::InElastic); eases.insertLast(Ease::OutElastic); eases.insertLast(Ease::InOutElastic);
        return eases;
    }

    string EaseName(Ease e)
    {
        return "ease#" + int(e);
    }

    float Ev(Ease e, float time, float duration)
    {
        return EaseManager::Evaluate(e, null, time, duration, DEFAULT_OVERSHOOT, DEFAULT_PERIOD);
    }

    /// <summary>
    /// Verifies the easing curves: endpoints, ranges, known midpoints, real overshoot and the edge cases.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunEaseTests(TweenyTestContext@ t)
    {
        t.Suite("ease");

        const float D = 2.0f;

        t.Case("endpoints are exact");
        array<Ease> wellBehaved = WellBehavedEases();
        for (uint i = 0; i < wellBehaved.length(); i++) {
            Ease e = wellBehaved[i];
            t.CheckApprox(Ev(e, 0.0f, D), 0.0f, EaseName(e) + " starts at 0", 0.0005f);
            t.CheckApprox(Ev(e, D, D), 1.0f, EaseName(e) + " ends at 1", 0.0005f);
        }
        array<Ease> overshooting = OvershootingEases();
        for (uint i = 0; i < overshooting.length(); i++) {
            Ease e = overshooting[i];
            t.CheckApprox(Ev(e, 0.0f, D), 0.0f, EaseName(e) + " starts at 0", 0.0005f);
            t.CheckApprox(Ev(e, D, D), 1.0f, EaseName(e) + " ends at 1", 0.0005f);
        }

        t.Case("well behaved eases stay inside 0..1");
        for (uint i = 0; i < wellBehaved.length(); i++) {
            Ease e = wellBehaved[i];
            bool inRange = true;
            for (int step = 0; step <= 40; step++) {
                float v = Ev(e, D * float(step) / 40.0f, D);
                if (v < -0.0005f || v > 1.0005f) {
                    inRange = false;
                }
            }
            t.Check(inRange, EaseName(e) + " never leaves 0..1");
        }

        t.Case("In and Out are mirror images");
        t.CheckApprox(Ev(Ease::InQuad, 0.5f * D, D), 0.25f, "InQuad at half is 0.25");
        t.CheckApprox(Ev(Ease::OutQuad, 0.5f * D, D), 0.75f, "OutQuad at half is 0.75");
        t.CheckApprox(Ev(Ease::InCubic, 0.5f * D, D), 0.125f, "InCubic at half is 0.125");
        t.CheckApprox(Ev(Ease::OutCubic, 0.5f * D, D), 0.875f, "OutCubic at half is 0.875");
        t.CheckApprox(Ev(Ease::InQuart, 0.5f * D, D), 0.0625f, "InQuart at half is 0.0625");
        t.CheckApprox(Ev(Ease::InQuint, 0.5f * D, D), 0.03125f, "InQuint at half is 0.03125");

        t.Case("known values");
        t.CheckApprox(Ev(Ease::Linear, 0.25f * D, D), 0.25f, "Linear at a quarter");
        t.CheckApprox(Ev(Ease::Linear, 0.75f * D, D), 0.75f, "Linear at three quarters");
        t.CheckApprox(Ev(Ease::InOutQuad, 0.5f * D, D), 0.5f, "InOutQuad is 0.5 at the midpoint");
        t.CheckApprox(Ev(Ease::InOutCubic, 0.5f * D, D), 0.5f, "InOutCubic is 0.5 at the midpoint");
        t.CheckApprox(Ev(Ease::InOutSine, 0.5f * D, D), 0.5f, "InOutSine is 0.5 at the midpoint");
        t.CheckApprox(Ev(Ease::InSine, 0.5f * D, D), 1.0f - Math::Cos(Math::PI * 0.25f), "InSine at half");
        t.CheckApprox(Ev(Ease::OutSine, 0.5f * D, D), Math::Sin(Math::PI * 0.25f), "OutSine at half");
        t.CheckApprox(Ev(Ease::InCirc, 0.5f * D, D), -(Math::Sqrt(1.0f - 0.25f) - 1.0f), "InCirc at half");
        t.CheckApprox(Ev(Ease::OutBounce, D, D), 1.0f, "OutBounce lands exactly on 1");

        t.Case("monotonic where it should be");
        array<Ease> monotonic;
        monotonic.insertLast(Ease::Linear);
        monotonic.insertLast(Ease::InQuad);  monotonic.insertLast(Ease::OutQuad);  monotonic.insertLast(Ease::InOutQuad);
        monotonic.insertLast(Ease::InCubic); monotonic.insertLast(Ease::OutCubic); monotonic.insertLast(Ease::InOutCubic);
        monotonic.insertLast(Ease::InSine);  monotonic.insertLast(Ease::OutSine);  monotonic.insertLast(Ease::InOutSine);
        monotonic.insertLast(Ease::InCirc);  monotonic.insertLast(Ease::OutCirc);  monotonic.insertLast(Ease::InOutCirc);
        for (uint i = 0; i < monotonic.length(); i++) {
            Ease e = monotonic[i];
            bool rising = true;
            float previous = Ev(e, 0.0f, D);
            for (int step = 1; step <= 40; step++) {
                float v = Ev(e, D * float(step) / 40.0f, D);
                if (v < previous - 0.0005f) {
                    rising = false;
                }
                previous = v;
            }
            t.Check(rising, EaseName(e) + " never goes backwards");
        }

        t.Case("Back really overshoots");
        bool backOvershoots = false;
        bool backUndershoots = false;
        for (int step = 0; step <= 40; step++) {
            float x = D * float(step) / 40.0f;
            if (Ev(Ease::OutBack, x, D) > 1.0f) {
                backOvershoots = true;
            }
            if (Ev(Ease::InBack, x, D) < 0.0f) {
                backUndershoots = true;
            }
        }
        t.Check(backOvershoots, "OutBack rises above 1 somewhere");
        t.Check(backUndershoots, "InBack dips below 0 somewhere");

        t.Case("Elastic really oscillates");
        bool elasticOvershoots = false;
        bool elasticUndershoots = false;
        for (int step = 0; step <= 80; step++) {
            float x = D * float(step) / 80.0f;
            float v = Ev(Ease::OutElastic, x, D);
            if (v > 1.0f) {
                elasticOvershoots = true;
            }
            if (Ev(Ease::InElastic, x, D) < 0.0f) {
                elasticUndershoots = true;
            }
        }
        t.Check(elasticOvershoots, "OutElastic rises above 1 somewhere");
        t.Check(elasticUndershoots, "InElastic dips below 0 somewhere");

        t.Case("overshoot parameter changes Back's amplitude");
        float gentle = EaseManager::Evaluate(Ease::OutBack, null, 0.3f * D, D, 0.5f, 0.0f);
        float wild = EaseManager::Evaluate(Ease::OutBack, null, 0.3f * D, D, 4.0f, 0.0f);
        t.Check(wild > gentle, "a larger overshoot pushes OutBack further");

        t.Case("amplitude below 1 is clamped for Elastic");
        float clamped = EaseManager::Evaluate(Ease::OutElastic, null, 0.4f * D, D, 0.2f, 0.0f);
        float atOne = EaseManager::Evaluate(Ease::OutElastic, null, 0.4f * D, D, 1.0f, 0.0f);
        t.CheckApprox(clamped, atOne, "an amplitude below 1 behaves as exactly 1");

        t.Case("period 0 derives a period from the duration");
        float derived = EaseManager::Evaluate(Ease::OutElastic, null, 0.4f * D, D, 1.0f, 0.0f);
        float explicitPeriod = EaseManager::Evaluate(Ease::OutElastic, null, 0.4f * D, D, 1.0f, D * 0.3f);
        t.CheckApprox(derived, explicitPeriod, "period 0 equals an explicit duration * 0.3");

        t.Case("INTERNAL_Zero and INTERNAL_Custom");
        t.CheckApprox(Ev(Ease::INTERNAL_Zero, 0.0f, D), 1.0f, "INTERNAL_Zero is always 1");
        t.CheckApprox(Ev(Ease::INTERNAL_Zero, D, D), 1.0f, "INTERNAL_Zero is 1 at the end too");
        EaseFunc@ squared = EaseFunc(SquaredEase);
        t.CheckApprox(EaseManager::Evaluate(Ease::INTERNAL_Custom, squared, 0.5f * D, D, 0.0f, 0.0f), 0.25f,
            "a custom ease function is used");
        t.CheckApprox(EaseManager::Evaluate(Ease::INTERNAL_Custom, null, 0.5f * D, D, 0.0f, 0.0f), 0.5f,
            "a null custom ease falls back to linear");

        t.Case("Unset falls back to OutQuad");
        t.CheckApprox(Ev(Ease::Unset, 0.5f * D, D), Ev(Ease::OutQuad, 0.5f * D, D),
            "Unset evaluates as OutQuad");

        t.Case("Flash blinks the expected number of times");
        int crossings = 0;
        float previousFlash = EaseManager::Evaluate(Ease::Flash, null, 0.0f, D, 4.0f, 0.0f);
        for (int step = 1; step <= 400; step++) {
            float v = EaseManager::Evaluate(Ease::Flash, null, D * float(step) / 400.0f, D, 4.0f, 0.0f);
            if ((previousFlash < 0.5f && v >= 0.5f) || (previousFlash > 0.5f && v <= 0.5f)) {
                crossings++;
            }
            previousFlash = v;
        }
        t.Check(crossings >= 3, "Flash with amplitude 4 crosses the midpoint several times");
        t.CheckInRange(EaseManager::Evaluate(Ease::Flash, null, D, D, 4.0f, 0.0f), -0.001f, 1.001f,
            "Flash stays within 0..1 at the end");

        t.Case("Flash with an even amplitude returns to the start value");
        t.CheckApprox(EaseManager::Evaluate(Ease::Flash, null, D, D, 2.0f, 0.0f), 0.0f,
            "an even flash count ends back at 0", 0.001f);

        t.Case("zero duration does not divide by zero");
        float zeroDuration = Ev(Ease::INTERNAL_Zero, 0.0f, 0.0f);
        t.CheckApprox(zeroDuration, 1.0f, "INTERNAL_Zero handles a zero duration");

        t.Case("stop motion quantises time");
        EaseFunc@ stopMotion = EaseFactory::StopMotion(4, Ease::Linear);
        float atTenth = stopMotion(0.10f, 1.0f, 0.0f, 0.0f);
        float atTwentieth = stopMotion(0.20f, 1.0f, 0.0f, 0.0f);
        t.CheckApprox(atTenth, atTwentieth, "samples inside one stop-motion step are identical", 0.001f);
        float atThirtieth = stopMotion(0.30f, 1.0f, 0.0f, 0.0f);
        t.Check(atThirtieth > atTenth, "the next stop-motion step advances");
        t.CheckApprox(stopMotion(1.0f, 1.0f, 0.0f, 0.0f), 1.0f, "stop motion still lands on 1 at the end");
    }

    float SquaredEase(float time, float duration, float overshootOrAmplitude, float period)
    {
        float t = time / duration;
        return t * t;
    }
}
