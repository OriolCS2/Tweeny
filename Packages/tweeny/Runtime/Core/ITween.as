using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Fired by a tween when it reaches one of its lifecycle points.
    /// </summary>
    funcdef void TweenCallback();

    /// <summary>
    /// Fired by a path tween when it passes a waypoint.
    /// </summary>
    /// <param name="waypointIndex">The index of the waypoint just reached.</param>
    funcdef void TweenCallbackInt(int waypointIndex);

    /// <summary>
    /// The type-agnostic face of a tween. The scheduler only ever sees this, which is what lets a single
    /// active list hold tweens of every value type even though AngelScript has no generics.
    ///
    /// Every method here is supplied by the TweenCore mixin, so a concrete tween satisfies this interface
    /// simply by including the mixin and declaring the interface.
    /// </summary>
    interface ITween
    {
        /// <summary>
        /// Advances the tween by one frame.
        /// </summary>
        /// <param name="deltaTime">Scaled seconds since the last tick.</param>
        /// <param name="unscaledDeltaTime">Unscaled seconds since the last tick.</param>
        /// <returns>Returns true when the tween is finished and must be removed from the active list.</returns>
        bool TweenTick(float deltaTime, float unscaledDeltaTime);

        /// <summary>Whether the tween is still alive.</summary>
        bool IsActive() const;
        /// <summary>Whether the tween is currently advancing.</summary>
        bool IsPlaying() const;
        /// <summary>Whether the tween has reached its end.</summary>
        bool IsComplete() const;
        /// <summary>Whether the tween has captured its start value yet.</summary>
        bool IsInitialized() const;
        /// <summary>Whether the tween is playing in reverse.</summary>
        bool IsBackwards() const;

        /// <summary>The update phase that drives this tween.</summary>
        UpdateType GetUpdateType() const;
        /// <summary>Whether this tween ignores the global time scale.</summary>
        bool IsIndependentUpdate() const;
        /// <summary>The string id used by filtered operations, empty when unset.</summary>
        string GetStringId() const;
        /// <summary>The integer id used by filtered operations, -999 when unset.</summary>
        int GetIntId() const;
        /// <summary>The object this tween animates, null when unset.</summary>
        Object@ GetTarget() const;
        /// <summary>Whether this tween is nested inside a sequence.</summary>
        bool IsSequenced() const;

        /// <summary>Starts or resumes playback.</summary>
        void Play();
        /// <summary>Suspends playback.</summary>
        void Pause();
        /// <summary>Pauses when playing, plays when paused.</summary>
        void TogglePause();
        /// <summary>Plays towards the end.</summary>
        void PlayForward();
        /// <summary>Plays towards the start.</summary>
        void PlayBackwards();
        /// <summary>Returns to the start and pauses.</summary>
        /// <param name="includeDelay">Whether the delay is restored as well.</param>
        void Rewind(bool includeDelay = true);
        /// <summary>Plays backwards from the current position instead of jumping to the start.</summary>
        void SmoothRewind();
        /// <summary>Returns to the start and plays again.</summary>
        /// <param name="includeDelay">Whether the delay is played again.</param>
        void Restart(bool includeDelay = true);
        /// <summary>Jumps to the end, firing the callbacks along the way.</summary>
        /// <param name="withCallbacks">Whether intermediate loop callbacks fire.</param>
        void Complete(bool withCallbacks = false);
        /// <summary>Stops the tween and removes it from the scheduler.</summary>
        /// <param name="complete">Whether the end value is applied before stopping.</param>
        void Kill(bool complete = false);
        /// <summary>Reverses the play direction.</summary>
        void Flip();
        /// <summary>Jumps to an absolute time position.</summary>
        /// <param name="to">The position in seconds, delay excluded.</param>
        /// <param name="andPlay">Whether playback resumes afterwards.</param>
        /// <param name="withCallbacks">Whether the callbacks between here and there fire.</param>
        void Goto(float to, bool andPlay = false, bool withCallbacks = false);
        /// <summary>Forces the start value to be captured now instead of on the first tick.</summary>
        void ForceInit();

        /// <summary>Seconds elapsed inside the current loop.</summary>
        float GetPosition() const;
        /// <summary>Duration of a single loop, in seconds.</summary>
        float GetDuration() const;
        /// <summary>Number of loop cycles finished so far.</summary>
        int GetCompletedLoops() const;
        /// <summary>Configured number of loops, -1 for infinite.</summary>
        int GetLoops() const;
        /// <summary>Configured delay before the first loop, in seconds.</summary>
        float GetDelay() const;
        /// <summary>Seconds of the delay consumed so far.</summary>
        float GetElapsedDelay() const;
        /// <summary>Total elapsed time, optionally counting every finished loop.</summary>
        /// <param name="includeLoops">Whether finished loops are added in.</param>
        float GetElapsed(bool includeLoops = true) const;
        /// <summary>Total duration, optionally counting every loop. Infinite loops report a huge value.</summary>
        /// <param name="includeLoops">Whether the loop count is multiplied in.</param>
        float GetFullDuration(bool includeLoops = true) const;

        /// <summary>Releases handles held by the tween so it can be collected.</summary>
        void ReleaseReferences();

        /// <summary>
        /// Copies the project-wide defaults onto a freshly created tween. Called once, at creation.
        /// </summary>
        /// <param name="ease">The default easing curve.</param>
        /// <param name="overshoot">The default overshoot or amplitude.</param>
        /// <param name="period">The default period.</param>
        /// <param name="killOnComplete">Whether tweens are removed once finished.</param>
        /// <param name="defaultLoopType">The default loop style.</param>
        /// <param name="defaultUpdateType">The default update phase.</param>
        /// <param name="independent">Whether tweens ignore the game time scale by default.</param>
        void ApplyManagerDefaults(Ease ease, float overshoot, float period, bool killOnComplete,
            LoopType defaultLoopType, UpdateType defaultUpdateType, bool independent);
    }
}
