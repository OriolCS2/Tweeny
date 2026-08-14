using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// A small xorshift generator used by the shake family.
    ///
    /// Tweeny keeps its own instead of reaching for the engine's so a shake can be seeded and replayed
    /// exactly. Without that, shakes are untestable and cannot be reproduced from a bug report.
    /// </summary>
    class TweenyRandom
    {
        private uint state = 2463534242;

        TweenyRandom() {}

        /// <summary>Creates a generator with a specific seed.</summary>
        /// <param name="seed">Any value. Zero is replaced, since xorshift cannot escape it.</param>
        TweenyRandom(uint seed) { Seed(seed); }

        /// <summary>Restarts the sequence from a seed.</summary>
        /// <param name="seed">Any value. Zero is replaced.</param>
        void Seed(uint seed) { state = seed == 0 ? 1 : seed; }

        /// <summary>The next raw value.</summary>
        /// <returns>Returns a pseudo-random unsigned integer.</returns>
        uint NextUint()
        {
            state ^= state << 13;
            state ^= state >> 17;
            state ^= state << 5;
            return state;
        }

        /// <summary>The next value between 0 and 1.</summary>
        /// <returns>Returns a pseudo-random number in [0, 1).</returns>
        float NextFloat()
        {
            return float(NextUint() % 16777216) / 16777216.0f;
        }

        /// <summary>The next value inside a range.</summary>
        /// <param name="minimum">The lowest value.</param>
        /// <param name="maximum">The highest value.</param>
        /// <returns>Returns a pseudo-random number in [minimum, maximum).</returns>
        float Range(float minimum, float maximum)
        {
            return minimum + NextFloat() * (maximum - minimum);
        }
    }

    /// <summary>
    /// Builds a vector of the given length pointing at an angle. Used by shake and punch to turn a random
    /// direction into an offset.
    /// </summary>
    /// <param name="degrees">The direction, in degrees.</param>
    /// <param name="magnitude">How long the vector should be.</param>
    /// <returns>Returns the vector.</returns>
    Vector2 VectorFromAngle(float degrees, float magnitude)
    {
        float radians = degrees * Math::Deg2Rad;
        return Vector2(Math::Cos(radians) * magnitude, Math::Sin(radians) * magnitude);
    }

    /// <summary>
    /// Shortens a vector so it is no longer than a maximum, leaving shorter ones alone.
    /// </summary>
    /// <param name="value">The vector to clamp.</param>
    /// <param name="maxLength">The longest it may be.</param>
    /// <returns>Returns the clamped vector.</returns>
    Vector2 ClampMagnitude(Vector2 value, float maxLength)
    {
        float length = value.Length();
        if (length <= maxLength || length <= 0.0f) {
            return value;
        }
        return value * (maxLength / length);
    }
}
