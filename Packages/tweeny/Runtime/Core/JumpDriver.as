using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Combines a jump's horizontal travel and its vertical hops into a single written value.
    ///
    /// The two are tweened separately so each can have its own easing -- linear across, quadratic up and
    /// down -- and this driver adds them back together every time either one moves. It is kept alive by
    /// the delegates the sequence holds.
    /// </summary>
    class JumpDriver
    {
        private Vector2Getter@ getter;
        private Vector2Setter@ setter;
        private Vector2 startValue;
        private Vector2 endValue;
        private float jumpPower;
        private float progress = 0.0f;
        private float hop = 0.0f;
        private bool captured = false;

        /// <summary>
        /// Builds a driver for one jump.
        /// </summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="destination">Where the jump lands.</param>
        /// <param name="power">How high each hop rises.</param>
        /// <param name="hops">How many hops the jump makes.</param>
        /// <param name="duration">How long the whole jump lasts.</param>
        JumpDriver(Vector2Getter@ valueGetter, Vector2Setter@ valueSetter, Vector2 destination,
            float power, int hops, float duration)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            endValue = destination;
            jumpPower = power;
        }

        private void Capture()
        {
            if (!captured && getter !is null) {
                startValue = getter();
                captured = true;
            }
        }

        /// <summary>How far along the horizontal travel is.</summary>
        /// <returns>Returns a value between 0 and 1.</returns>
        float GetProgress() { Capture(); return progress; }

        /// <summary>Sets how far along the horizontal travel is and rewrites the value.</summary>
        /// <param name="value">A value between 0 and 1.</param>
        void SetProgress(float value) { Capture(); progress = value; Write(); }

        /// <summary>How high the current hop is.</summary>
        /// <returns>Returns a value between 0 and 1.</returns>
        float GetHop() { Capture(); return hop; }

        /// <summary>Sets how high the current hop is and rewrites the value.</summary>
        /// <param name="value">A value between 0 and 1.</param>
        void SetHop(float value) { Capture(); hop = value; Write(); }

        private void Write()
        {
            if (setter is null) {
                return;
            }
            Vector2 flat = startValue + (endValue - startValue) * progress;
            setter(Vector2(flat.x, flat.y + hop * jumpPower));
        }
    }
}
