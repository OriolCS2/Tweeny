using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Works out how long each hop of a punch or shake lasts.
    ///
    /// With fade-out the segments grow linearly and are then normalised so they still add up to the
    /// requested duration, which is what makes the motion settle rather than stop dead.
    /// </summary>
    /// <param name="iterations">How many hops there are.</param>
    /// <param name="totalDuration">How long the whole effect lasts.</param>
    /// <param name="fadeOut">Whether the hops get progressively longer.</param>
    /// <returns>Returns one duration per hop, summing to totalDuration.</returns>
    array<float> BuildSegmentDurations(int iterations, float totalDuration, bool fadeOut)
    {
        array<float> durations;
        durations.resize(uint(iterations));
        float sum = 0.0f;
        for (int i = 0; i < iterations; i++) {
            float value = fadeOut
                ? totalDuration * (float(i + 1) / float(iterations))
                : totalDuration / float(iterations);
            durations[uint(i)] = value;
            sum += value;
        }
        float multiplier = sum <= 0.0f ? 0.0f : totalDuration / sum;
        for (int i = 0; i < iterations; i++) {
            durations[uint(i)] *= multiplier;
        }
        return durations;
    }

    /// <summary>
    /// How many hops a punch or shake of this length gets.
    /// </summary>
    /// <param name="vibrato">Hops per second.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <returns>Returns the hop count, never below two.</returns>
    int BuildIterationCount(int vibrato, float duration)
    {
        int iterations = int(float(vibrato) * duration);
        return iterations < 2 ? 2 : iterations;
    }

    /// <summary>
    /// Punches a value in one direction and lets it spring back, ending exactly where it started.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="direction">Which way and how far the first punch goes.</param>
    /// <param name="duration">How long the whole effect lasts.</param>
    /// <param name="vibrato">How many times it bounces per second.</param>
    /// <param name="elasticity">How far past the start it may spring back, from 0 to 1.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ Punch(Vector2Getter@ getter, Vector2Setter@ setter, Vector2 direction,
        float duration, int vibrato = 10, float elasticity = 1.0f)
    {
        float clampedElasticity = elasticity > 1.0f ? 1.0f : (elasticity < 0.0f ? 0.0f : elasticity);
        float strength = direction.Length();
        int iterations = BuildIterationCount(vibrato, duration);
        float decay = strength / float(iterations);

        array<float> durations = BuildSegmentDurations(iterations, duration, true);
        array<Vector2> waypoints;
        waypoints.resize(uint(iterations));

        for (int i = 0; i < iterations; i++) {
            if (i < iterations - 1) {
                if (i == 0) {
                    waypoints[uint(i)] = direction;
                }
                else if (i % 2 != 0) {
                    waypoints[uint(i)] = ClampMagnitude(direction, strength * clampedElasticity) * -1.0f;
                }
                else {
                    waypoints[uint(i)] = ClampMagnitude(direction, strength);
                }
                strength -= decay;
            }
            else {
                waypoints[uint(i)] = Vector2(0.0f, 0.0f);
            }
        }

        TweenVector2Array@ tween = TweenVector2Array();
        tween.Bind(getter, setter, waypoints, durations);
        tween.SetOffsetsFromStart(true);
        ApplyDefaults(tween);
        tween.SetEase(Ease::OutQuad);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Shakes a value in random directions, settling back where it started.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="duration">How long the whole effect lasts.</param>
    /// <param name="strength">How far the shake reaches.</param>
    /// <param name="vibrato">How many times it shakes per second.</param>
    /// <param name="randomness">How much the direction wanders each hop, in degrees.</param>
    /// <param name="fadeOut">Whether the shake dies down over its duration.</param>
    /// <param name="mode">Full scatters freely; Harmonic keeps successive hops closer together.</param>
    /// <param name="seed">Seed for the shake. Use the same value to replay a shake exactly.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ Shake(Vector2Getter@ getter, Vector2Setter@ setter, float duration,
        float strength = 3.0f, int vibrato = 10, float randomness = 90.0f, bool fadeOut = true,
        ShakeRandomnessMode mode = ShakeRandomnessMode::Full, uint seed = 0)
    {
        float magnitude = strength;
        int iterations = BuildIterationCount(vibrato, duration);
        float decay = magnitude / float(iterations);

        array<float> durations = BuildSegmentDurations(iterations, duration, fadeOut);
        array<Vector2> waypoints;
        waypoints.resize(uint(iterations));

        TweenyRandom random;
        if (seed != 0) {
            random.Seed(seed);
        }
        else {
            random.Seed(uint(Math::Max(1, Math::RoundToInt(Time::GetUnscaledGameTime() * 100000.0f))));
        }

        float angle = random.Range(0.0f, 360.0f);
        for (int i = 0; i < iterations; i++) {
            if (i < iterations - 1) {
                if (i > 0) {
                    angle = mode == ShakeRandomnessMode::Harmonic
                        ? angle - 180.0f + random.Range(0.0f, randomness)
                        : angle - 180.0f + random.Range(-randomness, randomness);
                }
                waypoints[uint(i)] = VectorFromAngle(angle, magnitude);
                if (fadeOut) {
                    magnitude -= decay;
                }
            }
            else {
                waypoints[uint(i)] = Vector2(0.0f, 0.0f);
            }
        }

        TweenVector2Array@ tween = TweenVector2Array();
        tween.Bind(getter, setter, waypoints, durations);
        tween.SetOffsetsFromStart(true);
        ApplyDefaults(tween);
        tween.SetEase(Ease::Linear);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Moves a value along a path of waypoints at a constant speed.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="waypoints">The points to travel through, in order.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <param name="type">Straight lines or a smooth curve.</param>
    /// <param name="resolution">Samples per segment used to measure the curve.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenPath@ Path(Vector2Getter@ getter, Vector2Setter@ setter, const array<Vector2>&in waypoints,
        float duration, PathType type = PathType::Linear, int resolution = 10)
    {
        TweenPath@ tween = TweenPath();
        tween.Bind(getter, setter, waypoints, duration, type, resolution);
        ApplyDefaults(tween);
        tween.SetEase(Ease::Linear);
        Register(tween);
        return tween;
    }

    /// <summary>
    /// Hops a value towards a destination, arcing upward on the way.
    ///
    /// The horizontal travel and the hops are separate tweens joined on one timeline, so the arc keeps its
    /// shape no matter how far the jump goes.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="endValue">Where to land.</param>
    /// <param name="jumpPower">How high each hop rises.</param>
    /// <param name="numJumps">How many hops to make.</param>
    /// <param name="duration">How long the whole jump lasts.</param>
    /// <returns>Returns the sequence driving the jump.</returns>
    TweenSequence@ Jump(Vector2Getter@ getter, Vector2Setter@ setter, Vector2 endValue,
        float jumpPower, int numJumps, float duration)
    {
        int hops = numJumps < 1 ? 1 : numJumps;
        float hopDuration = duration / float(hops * 2);

        JumpDriver@ driver = JumpDriver(getter, setter, endValue, jumpPower, hops, duration);

        TweenSequence@ sequence = Sequence();

        TweenFloat@ horizontal = TweenFloat();
        horizontal.Bind(FloatGetter(driver.GetProgress), FloatSetter(driver.SetProgress), 1.0f, duration);
        horizontal.SetEase(Ease::Linear);
        sequence.Append(horizontal);

        for (int i = 0; i < hops * 2; i++) {
            bool rising = (i % 2) == 0;
            TweenFloat@ hop = TweenFloat();
            hop.Bind(FloatGetter(driver.GetHop), FloatSetter(driver.SetHop), rising ? 1.0f : 0.0f, hopDuration);
            hop.SetEase(rising ? Ease::OutQuad : Ease::InQuad);
            sequence.Insert(float(i) * hopDuration, hop);
        }

        return sequence;
    }

    /// <summary>
    /// Walks a value through an explicit list of waypoints.
    /// </summary>
    /// <param name="getter">Reads the current value.</param>
    /// <param name="setter">Writes the new value.</param>
    /// <param name="waypoints">The value to reach at the end of each segment.</param>
    /// <param name="durations">How long each segment lasts.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ ToArray(Vector2Getter@ getter, Vector2Setter@ setter,
        const array<Vector2>&in waypoints, const array<float>&in durations)
    {
        TweenVector2Array@ tween = TweenVector2Array();
        tween.Bind(getter, setter, waypoints, durations);
        ApplyDefaults(tween);
        Register(tween);
        return tween;
    }
}
