using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// A stand-in for a real target: holds a float and exposes it through the getter/setter pair a tween
    /// expects, so the core can be driven without any scene or entity.
    /// </summary>
    class FloatProbe
    {
        float value = 0.0f;
        int writeCount = 0;

        FloatProbe() {}
        FloatProbe(float initial) { value = initial; }

        float Get() { return value; }
        void Set(float v) { value = v; writeCount++; }

        FloatGetter@ Getter() { return FloatGetter(this.Get); }
        FloatSetter@ Setter() { return FloatSetter(this.Set); }
    }

    /// <summary>
    /// Records the order and count of every tween callback so the firing sequence can be asserted.
    /// </summary>
    class CallbackRecorder
    {
        array<string> order;
        int starts = 0;
        int plays = 0;
        int pauses = 0;
        int rewinds = 0;
        int updates = 0;
        int steps = 0;
        int completes = 0;
        int kills = 0;

        void OnStart() { starts++; order.insertLast("start"); }
        void OnPlay() { plays++; order.insertLast("play"); }
        void OnPause() { pauses++; order.insertLast("pause"); }
        void OnRewind() { rewinds++; order.insertLast("rewind"); }
        void OnUpdate() { updates++; order.insertLast("update"); }
        void OnStepComplete() { steps++; order.insertLast("step"); }
        void OnComplete() { completes++; order.insertLast("complete"); }
        void OnKill() { kills++; order.insertLast("kill"); }

        string Sequence() const
        {
            string joined = "";
            for (uint i = 0; i < order.length(); i++) {
                if (i > 0) {
                    joined += ",";
                }
                joined += order[i];
            }
            return joined;
        }

        int IndexOf(const string&in name) const
        {
            for (uint i = 0; i < order.length(); i++) {
                if (order[i] == name) {
                    return int(i);
                }
            }
            return -1;
        }
    }

    /// <summary>
    /// Builds a float tween already bound to a probe and ready to play.
    /// </summary>
    /// <param name="probe">The probe the tween drives.</param>
    /// <param name="to">The value to reach.</param>
    /// <param name="duration">How long one loop takes.</param>
    /// <returns>Returns the tween, playing and eased linearly.</returns>
    TweenFloat@ MakeFloatTween(FloatProbe@ probe, float to, float duration)
    {
        TweenFloat@ tween = TweenFloat();
        tween.Bind(probe.Getter(), probe.Setter(), to, duration);
        tween.SetEase(Ease::Linear);
        tween.Play();
        return tween;
    }

    /// <summary>
    /// Advances a tween with a fixed synthetic delta, which is what makes these tests deterministic.
    /// </summary>
    /// <param name="tween">The tween to advance.</param>
    /// <param name="deltaTime">Seconds per step.</param>
    /// <param name="steps">How many steps to run.</param>
    /// <returns>Returns true if the tween asked to be killed during the run.</returns>
    bool Advance(ITween@ tween, float deltaTime, int steps)
    {
        bool wantsKill = false;
        for (int i = 0; i < steps; i++) {
            if (tween.TweenTick(deltaTime, deltaTime)) {
                wantsKill = true;
                break;
            }
        }
        return wantsKill;
    }
}
