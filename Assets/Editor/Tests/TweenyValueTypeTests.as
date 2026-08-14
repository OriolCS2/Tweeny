using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    class Vector2Probe
    {
        Vector2 value;
        Vector2Probe() {}
        Vector2Probe(Vector2 initial) { value = initial; }
        Vector2 Get() { return value; }
        void Set(Vector2 v) { value = v; }
        Vector2Getter@ Getter() { return Vector2Getter(this.Get); }
        Vector2Setter@ Setter() { return Vector2Setter(this.Set); }
    }

    class Vector3Probe
    {
        Vector3 value;
        Vector3Probe() {}
        Vector3Probe(Vector3 initial) { value = initial; }
        Vector3 Get() { return value; }
        void Set(Vector3 v) { value = v; }
        Vector3Getter@ Getter() { return Vector3Getter(this.Get); }
        Vector3Setter@ Setter() { return Vector3Setter(this.Set); }
    }

    class ColorProbe
    {
        Color value;
        ColorProbe() {}
        ColorProbe(Color initial) { value = initial; }
        Color Get() { return value; }
        void Set(Color v) { value = v; }
        ColorGetter@ Getter() { return ColorGetter(this.Get); }
        ColorSetter@ Setter() { return ColorSetter(this.Set); }
    }

    /// <summary>
    /// Verifies every value type interpolates correctly, including the cases where an overshooting ease
    /// pushes the parameter outside 0..1.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunValueTypeTests(TweenyTestContext@ t)
    {
        t.Suite("value types");

        t.Case("Vector2 interpolates both components");
        {
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenVector2@ tween = TweenVector2();
            tween.Bind(probe.Getter(), probe.Setter(), Vector2(10.0f, 20.0f), 1.0f);
            tween.SetEase(Ease::Linear);
            tween.Play();
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value.x, 5.0f, "x is halfway");
            t.CheckApprox(probe.value.y, 10.0f, "y is halfway");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value.x, 10.0f, "x reaches the end");
            t.CheckApprox(probe.value.y, 20.0f, "y reaches the end");
        }

        t.Case("Vector2 axis constraint leaves other components alone");
        {
            Vector2Probe probe(Vector2(1.0f, 2.0f));
            TweenVector2@ tween = TweenVector2();
            tween.Bind(probe.Getter(), probe.Setter(), Vector2(10.0f, 20.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetAxisConstraint(AxisConstraint::X);
            tween.Play();
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value.x, 10.0f, "the constrained axis moved");
            t.CheckApprox(probe.value.y, 2.0f, "the other axis kept its value");
        }

        t.Case("Vector2 relative offsets from the start");
        {
            Vector2Probe probe(Vector2(3.0f, 4.0f));
            TweenVector2@ tween = TweenVector2();
            tween.Bind(probe.Getter(), probe.Setter(), Vector2(10.0f, 10.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetRelative(true);
            tween.Play();
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value.x, 13.0f, "x was offset");
            t.CheckApprox(probe.value.y, 14.0f, "y was offset");
        }

        t.Case("Vector2 speed based derives its duration from the distance");
        {
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenVector2@ tween = TweenVector2();
            tween.Bind(probe.Getter(), probe.Setter(), Vector2(3.0f, 4.0f), 5.0f);
            tween.SetEase(Ease::Linear).SetSpeedBased(true);
            tween.Play();
            tween.ForceInit();
            t.CheckApprox(tween.GetDuration(), 1.0f, "a distance of 5 at 5 per second takes a second");
        }

        t.Case("Vector2 snapping rounds each component");
        {
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenVector2@ tween = TweenVector2();
            tween.Bind(probe.Getter(), probe.Setter(), Vector2(10.0f, 10.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetSnapping(true);
            tween.Play();
            Advance(tween, 0.33f, 1);
            t.CheckApprox(probe.value.x, float(Math::RoundToInt(probe.value.x)), "x is whole");
            t.CheckApprox(probe.value.y, float(Math::RoundToInt(probe.value.y)), "y is whole");
        }

        t.Case("Vector3 interpolates all three components");
        {
            Vector3Probe probe(Vector3(0.0f, 0.0f, 0.0f));
            TweenVector3@ tween = TweenVector3();
            tween.Bind(probe.Getter(), probe.Setter(), Vector3(10.0f, 20.0f, 30.0f), 1.0f);
            tween.SetEase(Ease::Linear);
            tween.Play();
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value.x, 5.0f, "x is halfway");
            t.CheckApprox(probe.value.y, 10.0f, "y is halfway");
            t.CheckApprox(probe.value.z, 15.0f, "z is halfway");
        }

        t.Case("Vector3 axis constraint can keep Z out of it");
        {
            Vector3Probe probe(Vector3(0.0f, 0.0f, 7.0f));
            TweenVector3@ tween = TweenVector3();
            tween.Bind(probe.Getter(), probe.Setter(), Vector3(10.0f, 10.0f, 10.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetAxisConstraint(AxisConstraint(int(AxisConstraint::X) | int(AxisConstraint::Y)));
            tween.Play();
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value.x, 10.0f, "x moved");
            t.CheckApprox(probe.value.y, 10.0f, "y moved");
            t.CheckApprox(probe.value.z, 7.0f, "z was left at its sorting depth");
        }

        t.Case("overshooting eases work on vectors without clamping");
        {
            Vector2Probe probe(Vector2(0.0f, 0.0f));
            TweenVector2@ tween = TweenVector2();
            tween.Bind(probe.Getter(), probe.Setter(), Vector2(10.0f, 0.0f), 1.0f);
            tween.SetEase(Ease::OutBack);
            tween.SetAutoKill(false);
            tween.Play();
            bool wentPast = false;
            for (int i = 0; i < 20; i++) {
                Advance(tween, 0.05f, 1);
                if (probe.value.x > 10.0f) {
                    wentPast = true;
                }
            }
            t.Check(wentPast, "OutBack pushed the vector past its target");
            t.CheckApprox(probe.value.x, 10.0f, "and it still settled exactly on the target", 0.001f);
        }

        t.Case("Color interpolates every channel");
        {
            ColorProbe probe(Color(0.0f, 0.0f, 0.0f, 1.0f));
            TweenColor@ tween = TweenColor();
            tween.Bind(probe.Getter(), probe.Setter(), Color(1.0f, 0.5f, 0.25f, 0.0f), 1.0f);
            tween.SetEase(Ease::Linear);
            tween.Play();
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value.r, 0.5f, "red is halfway");
            t.CheckApprox(probe.value.g, 0.25f, "green is halfway");
            t.CheckApprox(probe.value.b, 0.125f, "blue is halfway");
            t.CheckApprox(probe.value.a, 0.5f, "alpha is halfway");
        }

        t.Case("alpha only leaves the colour untouched");
        {
            ColorProbe probe(Color(0.2f, 0.4f, 0.6f, 1.0f));
            TweenColor@ tween = TweenColor();
            tween.Bind(probe.Getter(), probe.Setter(), Color(0.0f, 0.0f, 0.0f, 0.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetAlphaOnly(true);
            tween.Play();
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value.a, 0.0f, "alpha faded out");
            t.CheckApprox(probe.value.r, 0.2f, "red kept its value");
            t.CheckApprox(probe.value.g, 0.4f, "green kept its value");
            t.CheckApprox(probe.value.b, 0.6f, "blue kept its value");
        }

        t.Case("angle takes the short way round by default");
        {
            FloatProbe probe(350.0f);
            TweenAngle@ tween = TweenAngle();
            tween.Bind(probe.Getter(), probe.Setter(), 10.0f, 1.0f);
            tween.SetEase(Ease::Linear);
            tween.Play();
            tween.ForceInit();
            t.CheckApprox(tween.GetChangeValue(), 20.0f, "350 to 10 travels forward 20 degrees, not back 340");
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 370.0f, "and it ends up at the equivalent angle");
        }

        t.Case("FastBeyond360 keeps multi-turn rotations");
        {
            FloatProbe probe(0.0f);
            TweenAngle@ tween = TweenAngle();
            tween.Bind(probe.Getter(), probe.Setter(), 720.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetRotateMode(RotateMode::FastBeyond360);
            tween.Play();
            tween.ForceInit();
            t.CheckApprox(tween.GetChangeValue(), 720.0f, "two full turns survive");
            Advance(tween, 0.5f, 1);
            t.CheckApprox(probe.value, 360.0f, "halfway is one full turn");
        }

        t.Case("WorldAxisAdd rotates by an offset");
        {
            FloatProbe probe(45.0f);
            TweenAngle@ tween = TweenAngle();
            tween.Bind(probe.Getter(), probe.Setter(), 90.0f, 1.0f);
            tween.SetEase(Ease::Linear).SetRotateMode(RotateMode::WorldAxisAdd);
            tween.Play();
            Advance(tween, 1.0f, 1);
            t.CheckApprox(probe.value, 135.0f, "the offset was added to the current angle");
        }

        t.Case("the typed creation helpers register and play");
        {
            ResetManager();
            Vector2Probe v2(Vector2(0.0f, 0.0f));
            ColorProbe col(Color(0.0f, 0.0f, 0.0f, 1.0f));
            FloatProbe angle(0.0f);

            Tweeny::To(v2.Getter(), v2.Setter(), Vector2(4.0f, 0.0f), 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ToAlpha(col.Getter(), col.Setter(), 0.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ToAngle(angle.Getter(), angle.Setter(), 90.0f, 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);

            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 3, "three tweens were registered");
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(v2.value.x, 2.0f, "the vector tween advanced");
            t.CheckApprox(col.value.a, 0.5f, "the alpha tween advanced");
            t.CheckApprox(angle.value, 45.0f, "the angle tween advanced");
            ResetManager();
        }
    }
}
