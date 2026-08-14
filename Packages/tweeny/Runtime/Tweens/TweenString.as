using namespace CometEngine;

namespace Tweeny
{
    /// <summary>Reads the current value of whatever a string tween drives.</summary>
    /// <returns>Returns the current value.</returns>
    funcdef string StringGetter();

    /// <summary>Writes a new value to whatever a string tween drives.</summary>
    /// <param name="value">The value to write.</param>
    funcdef void StringSetter(const string&in value);

    /// <summary>
    /// Types a string out over time, optionally filling the not-yet-revealed part with scrambled characters
    /// so the field keeps its final width instead of growing letter by letter.
    ///
    /// Randomness comes from a small internal generator rather than the engine's, so a scrambled tween
    /// replays identically given the same seed. That is what makes it testable.
    /// </summary>
    class TweenString : ITween, TweenCore
    {
        private StringGetter@ getter;
        private StringSetter@ setter;
        private string startValue = "";
        private string endValue = "";
        private ScrambleMode scrambleMode = ScrambleMode::None;
        private string scrambleChars = "";
        private bool richTextEnabled = false;
        private uint randomState = 2463534242;
        private bool hasGivenFromValue = false;
        private string givenFromValue = "";

        /// <summary>Binds the tween to a value.</summary>
        /// <param name="valueGetter">Reads the current value.</param>
        /// <param name="valueSetter">Writes the new value.</param>
        /// <param name="to">The text to end up with.</param>
        /// <param name="tweenDuration">How long one loop takes, in seconds.</param>
        void Bind(StringGetter@ valueGetter, StringSetter@ valueSetter, const string&in to, float tweenDuration)
        {
            @getter = valueGetter;
            @setter = valueSetter;
            endValue = to;
            duration = tweenDuration < 0.0f ? 0.0f : tweenDuration;
        }

        bool TweenStartup()
        {
            if (getter is null || setter is null) {
                return false;
            }
            startValue = getter();

            if (isRelative && !isFrom) {
                endValue = startValue + endValue;
            }
            if (isFrom) {
                string realEnd = startValue;
                string realStart = hasGivenFromValue ? givenFromValue : endValue;
                if (isRelative) {
                    realStart = realEnd + realStart;
                }
                startValue = realStart;
                endValue = realEnd;
                setter(startValue);
            }

            if (isSpeedBased) {
                float speed = duration;
                float characters = float(endValue.length());
                duration = speed <= 0.0f ? 0.0f : characters / speed;
                if (duration <= 0.0f) {
                    easeType = Ease::INTERNAL_Zero;
                }
            }
            return true;
        }

        void TweenApply(float eased, UpdateNotice notice)
        {
            if (setter is null) {
                return;
            }

            float clamped = eased < 0.0f ? 0.0f : (eased > 1.0f ? 1.0f : eased);
            uint total = endValue.length();
            uint revealed = uint(float(total) * clamped + 0.5f);
            if (revealed > total) {
                revealed = total;
            }

            string result = endValue.substr(0, revealed);

            if (scrambleMode != ScrambleMode::None && revealed < total) {
                uint missing = total - revealed;
                string pool = ScramblePool();
                if (pool.length() > 0) {
                    for (uint i = 0; i < missing; i++) {
                        uint index = NextRandom() % pool.length();
                        result += pool.substr(index, 1);
                    }
                }
            }

            setter(result);
        }

        /// <summary>
        /// The character set the scrambler draws from.
        /// </summary>
        /// <returns>Returns the pool, empty when scrambling is off.</returns>
        private string ScramblePool() const
        {
            switch (scrambleMode) {
            case ScrambleMode::All:
                return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            case ScrambleMode::Uppercase:
                return "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            case ScrambleMode::Lowercase:
                return "abcdefghijklmnopqrstuvwxyz";
            case ScrambleMode::Numerals:
                return "0123456789";
            case ScrambleMode::Custom:
                return scrambleChars;
            }
            return "";
        }

        /// <summary>
        /// A small xorshift generator, kept internal so a scrambled tween is reproducible.
        /// </summary>
        /// <returns>Returns the next pseudo-random number.</returns>
        private uint NextRandom()
        {
            randomState ^= randomState << 13;
            randomState ^= randomState >> 17;
            randomState ^= randomState << 5;
            return randomState;
        }

        void TweenReleaseReferences()
        {
            @getter = null;
            @setter = null;
            @tweenTarget = null;
            @onStart = null; @onPlay = null; @onPause = null; @onRewind = null;
            @onUpdate = null; @onStepComplete = null; @onComplete = null; @onKill = null;
            @onWaypointChange = null; @customEase = null;
        }

        void ReleaseReferences() { TweenReleaseReferences(); }

        /// <summary>The text the tween started from.</summary>
        /// <returns>Returns the start value.</returns>
        string GetStartValue() const { return startValue; }

        /// <summary>The text the tween is heading to.</summary>
        /// <returns>Returns the end value.</returns>
        string GetEndValue() const { return endValue; }

        TweenString@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenString@ SetEase(Ease value, float overshoot) { CoreSetEaseParams(value, overshoot, DEFAULT_PERIOD); return this; }
        TweenString@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenString@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenString@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenString@ SetDelay(float value) { CoreSetDelay(value); return this; }
        TweenString@ SetRelative(bool value = true) { CoreSetRelative(value); return this; }
        TweenString@ SetSpeedBased(bool value = true) { CoreSetSpeedBased(value); return this; }
        TweenString@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenString@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenString@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenString@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenString@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenString@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenString@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }

        /// <summary>Fills the unrevealed part of the text with random characters.</summary>
        /// <param name="mode">Which character set to draw from.</param>
        /// <param name="customChars">The characters used when the mode is Custom.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenString@ SetScramble(ScrambleMode mode, const string&in customChars = "")
        {
            scrambleMode = mode;
            scrambleChars = customChars;
            return this;
        }

        /// <summary>Seeds the scrambler so a run can be reproduced exactly.</summary>
        /// <param name="seed">Any non-zero seed.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenString@ SetScrambleSeed(uint seed)
        {
            randomState = seed == 0 ? 1 : seed;
            return this;
        }

        /// <summary>Treats markup tags as part of the text rather than as visible characters.</summary>
        /// <param name="value">Whether rich text handling is on.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenString@ SetRichText(bool value = true) { richTextEnabled = value; return this; }

        /// <summary>Plays the tween from the end text back to the target's current text.</summary>
        /// <param name="relative">Whether the from text is appended rather than replacing.</param>
        /// <returns>Returns this tween so calls can be chained.</returns>
        TweenString@ From(bool relative = false)
        {
            if (creationLocked || noFromAllowed) { return this; }
            isFrom = true;
            isRelative = relative;
            hasGivenFromValue = false;
            return this;
        }

        TweenString@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenString@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenString@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenString@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenString@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenString@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
        TweenString@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenString@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
    }
}
