using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// One animation under preview, and where the preview was started from.
    ///
    /// The source component is kept because a preview has to be recognised again later: a tool needs to know
    /// whether the animation it is drawing is the one running, and asking to play the same animation twice
    /// has to restart it rather than build a second tween over the first.
    /// </summary>
    class TweenyPreviewEntry
    {
        /// <summary>The tween being driven.</summary>
        ITween@ tween;

        /// <summary>The component the tween was built from, or null when a bare tween was taken over.</summary>
        TweenyAnimation@ source;

        /// <summary>
        /// Whether this was started from a component inspector rather than from a window.
        ///
        /// The session only records it. What it means is up to whoever set it: the editor uses it to end the
        /// previews an inspector started once its entity stops being selected.
        /// </summary>
        bool fromInspector = false;
    }

    /// The one session every Tweeny tool drives. Created on first use, like the tween manager.
    TweenyPreviewSession@ g_previewSession;

    /// <summary>
    /// The shared preview session, creating it on first use.
    /// </summary>
    /// <returns>Returns the session. Never null.</returns>
    TweenyPreviewSession@ PreviewSession()
    {
        if (g_previewSession is null) {
            @g_previewSession = TweenyPreviewSession();
        }
        return g_previewSession;
    }

    /// <summary>
    /// The one preview running at a time, shared by every tool that shows it.
    ///
    /// There is one of these rather than one per tool because a window and a component inspector are two
    /// views of the same thing. When each kept its own, starting a preview in one left the other's buttons
    /// showing the opposite state, and stopping in one left the other still driving tweens it no longer knew
    /// about.
    ///
    /// The session also owns the clock. Every view calls Advance once a frame and the first call is the one
    /// that does the work, so a preview runs at the same speed whether one panel is open or several.
    ///
    /// Nothing here talks to the editor. It reports what is happening and leaves redrawing, selection and
    /// everything else editor-shaped to the tools on top, which is what lets it be tested without one.
    /// </summary>
    class TweenyPreviewSession
    {
        private array<TweenyPreviewEntry@> entries;
        private bool paused = false;
        private float elapsed = 0.0f;
        private float speed = 1.0f;
        private float lastAdvanceTime = 0.0f;

        // ---- state ------------------------------------------------------------------------------------

        /// <summary>Whether anything is being previewed.</summary>
        /// <returns>Returns true while a preview is running.</returns>
        bool IsPreviewing() const { return entries.length() > 0; }

        /// <summary>Whether the preview is being held.</summary>
        /// <returns>Returns true while paused.</returns>
        bool IsPaused() const { return paused && entries.length() > 0; }

        /// <summary>How many tweens are under preview.</summary>
        /// <returns>Returns the count.</returns>
        int GetCount() const { return int(entries.length()); }

        /// <summary>How long the preview has been running.</summary>
        /// <returns>Returns the elapsed seconds.</returns>
        float GetElapsed() const { return elapsed; }

        /// <summary>How fast the preview runs, as a multiplier.</summary>
        /// <returns>Returns the speed.</returns>
        float GetSpeed() const { return speed; }

        /// <summary>Sets how fast the preview runs.</summary>
        /// <param name="value">The multiplier.</param>
        void SetSpeed(float value) { speed = value; }

        /// <summary>Whether one particular component is the one being previewed.</summary>
        /// <param name="animation">The component to look for.</param>
        /// <returns>Returns true when that component has a tween in this session.</returns>
        bool IsPreviewing(TweenyAnimation@ animation) const
        {
            return IndexOf(animation) >= 0;
        }

        /// <summary>
        /// The components previewing that were started from one kind of place.
        /// </summary>
        /// <param name="fromInspector">True for the ones an inspector started, false for the rest.</param>
        /// <returns>Returns the matching components.</returns>
        array<TweenyAnimation@>@ GetSources(bool fromInspector) const
        {
            array<TweenyAnimation@>@ found = array<TweenyAnimation@>();
            for (uint i = 0; i < entries.length(); i++) {
                if (entries[i].fromInspector == fromInspector && entries[i].source !is null) {
                    found.insertLast(entries[i].source);
                }
            }
            return found;
        }

        // ---- starting ---------------------------------------------------------------------------------

        /// <summary>
        /// Previews one component, or restarts it when it is already running.
        ///
        /// Restarting rather than rebuilding is what keeps the scene recoverable. A tween captures the value
        /// it starts from the first time it is initialised, and that capture is what stopping writes back.
        /// Building a second tween over a target the preview has already displaced would capture the
        /// displaced value as the original, and the real one would be gone for good.
        /// </summary>
        /// <param name="animation">The component to preview.</param>
        /// <param name="fromInspector">True when started from the component's own inspector.</param>
        void Play(TweenyAnimation@ animation, bool fromInspector = false)
        {
            if (animation is null || !Object::IsValid(animation)) {
                return;
            }

            int at = IndexOf(animation);
            if (at >= 0) {
                entries[uint(at)].tween.Restart(true);
                paused = false;
                return;
            }

            animation.Play();
            ITween@ tween = animation.GetTween();
            if (tween is null || !tween.IsActive()) {
                return;
            }

            TweenyPreviewEntry@ entry = TweenyPreviewEntry();
            @entry.tween = Take(tween);
            @entry.source = animation;
            entry.fromInspector = fromInspector;
            entries.insertLast(entry);
            paused = false;
        }

        /// <summary>Previews a whole list of components.</summary>
        /// <param name="animations">The components to preview.</param>
        void PlayAll(array<TweenyAnimation@>@ animations)
        {
            if (animations is null) {
                return;
            }
            for (uint i = 0; i < animations.length(); i++) {
                Play(animations[i]);
            }
        }

        /// <summary>
        /// Takes over tweens that already exist, which is what previewing means once the game is running.
        /// </summary>
        /// <param name="tweens">The tweens to drive by hand.</param>
        void PlayLive(array<ITween@>@ tweens)
        {
            if (tweens is null) {
                return;
            }
            for (uint i = 0; i < tweens.length(); i++) {
                ITween@ tween = tweens[i];
                if (tween is null || !tween.IsActive() || Holds(tween)) {
                    continue;
                }
                TweenyPreviewEntry@ entry = TweenyPreviewEntry();
                @entry.tween = Take(tween);
                entries.insertLast(entry);
            }
            paused = false;
        }

        // ---- transport --------------------------------------------------------------------------------

        /// <summary>Sends everything back to the beginning and plays it again.</summary>
        void Restart()
        {
            for (uint i = 0; i < entries.length(); i++) {
                if (entries[i].tween !is null && entries[i].tween.IsActive()) {
                    entries[i].tween.Restart(true);
                }
            }
            elapsed = 0.0f;
            paused = false;
        }

        /// <summary>Holds the preview if it is running, and lets it go again if it is held.</summary>
        void TogglePause()
        {
            SetPaused(!paused);
        }

        /// <summary>Holds or releases the preview.</summary>
        /// <param name="value">True to hold it.</param>
        void SetPaused(bool value)
        {
            paused = value;
            for (uint i = 0; i < entries.length(); i++) {
                ITween@ tween = entries[i].tween;
                if (tween is null || !tween.IsActive()) {
                    continue;
                }
                if (paused) {
                    tween.Pause();
                }
                else {
                    tween.Play();
                }
            }
        }

        /// <summary>Ends the preview and puts every target back where it was.</summary>
        void Stop()
        {
            for (uint i = 0; i < entries.length(); i++) {
                Release(entries[i]);
            }
            entries.resize(0);
            Idle();
        }

        /// <summary>
        /// Ends the preview of one component and puts its target back, leaving the rest running.
        /// </summary>
        /// <param name="animation">The component to stop previewing.</param>
        void StopFor(TweenyAnimation@ animation)
        {
            int at = IndexOf(animation);
            if (at < 0) {
                return;
            }
            Release(entries[uint(at)]);
            entries.removeAt(uint(at));
            if (entries.length() == 0) {
                Idle();
            }
        }

        /// <summary>
        /// Ends every preview started from one kind of place, putting those targets back.
        ///
        /// Tools use this to clean up after themselves without disturbing each other: a window closing has
        /// no business undoing a preview somebody started from a component that is still on screen.
        /// </summary>
        /// <param name="fromInspector">True for the ones an inspector started, false for the rest.</param>
        void StopOwned(bool fromInspector)
        {
            for (int i = int(entries.length()) - 1; i >= 0; i--) {
                if (entries[uint(i)].fromInspector != fromInspector) {
                    continue;
                }
                Release(entries[uint(i)]);
                entries.removeAt(uint(i));
            }
            if (entries.length() == 0) {
                Idle();
            }
        }

        // ---- the clock --------------------------------------------------------------------------------

        /// <summary>
        /// Moves the preview on by one frame of editor time.
        ///
        /// Every view calls this, and the second call within a frame does nothing: the clock has not moved,
        /// so there is nothing to advance. That is what stops a preview running at double speed when two
        /// panels are open on it.
        /// </summary>
        /// <returns>Returns true when something actually moved, so the caller knows to redraw.</returns>
        bool Advance()
        {
            Forget();

            if (entries.length() == 0) {
                lastAdvanceTime = 0.0f;
                return false;
            }

            float now = Time::GetUnscaledGameTime();
            if (now == lastAdvanceTime) {
                return false;
            }

            float delta = lastAdvanceTime <= 0.0f ? 0.0f : (now - lastAdvanceTime);
            lastAdvanceTime = now;

            if (paused) {
                return false;
            }

            // An editor only draws when it is asked to, so a long gap between two frames would make the
            // preview leap instead of move.
            if (delta > 0.25f) {
                delta = 0.25f;
            }

            Step(delta);
            return delta > 0.0f;
        }

        /// <summary>
        /// Moves the preview on by a fixed amount, whatever the clock is doing.
        ///
        /// Advance works out how much time has passed and then calls this. Asking for an exact amount is
        /// useful on its own -- stepping through an animation, or driving one from a test, where the wall
        /// clock would make the result depend on how fast the machine ran.
        /// </summary>
        /// <param name="delta">Seconds to advance by, before the speed multiplier.</param>
        void Step(float delta)
        {
            if (entries.length() == 0 || paused || delta <= 0.0f) {
                return;
            }
            float amount = delta * speed;
            elapsed += amount;
            Tweeny::ManualUpdate(amount, amount);
        }

        // ---- internals --------------------------------------------------------------------------------

        /// <summary>
        /// Puts a tween under manual control: no callbacks, no auto-kill, driven only by this session.
        /// </summary>
        /// <param name="tween">The tween to take over.</param>
        /// <returns>Returns the same tween.</returns>
        private ITween@ Take(ITween@ tween)
        {
            tween.PrepareForPreview();
            tween.ForceInit();
            tween.Play();
            return tween;
        }

        /// <summary>Restores one entry's target and discards its tween.</summary>
        /// <param name="entry">The entry to release.</param>
        private void Release(TweenyPreviewEntry@ entry)
        {
            if (entry is null) {
                return;
            }
            Tweeny::RestorePreviewed(entry.tween, true);

            // The component still holds the tween it built. Clearing it stops the component offering a dead
            // tween to whoever asks next.
            if (entry.source !is null && Object::IsValid(entry.source)) {
                entry.source.Kill();
            }
        }

        /// <summary>
        /// Drops entries there is nothing left to drive or restore.
        ///
        /// An entity can be deleted while its animation is being previewed, and a link can kill a tween out
        /// from under the preview. Either way the value is already unreachable, so the entry is let go
        /// rather than kept as a handle to nothing.
        /// </summary>
        private void Forget()
        {
            for (int i = int(entries.length()) - 1; i >= 0; i--) {
                TweenyPreviewEntry@ entry = entries[uint(i)];
                bool sourceGone = entry.source !is null && !Object::IsValid(entry.source);
                if (entry.tween is null || !entry.tween.IsActive() || sourceGone) {
                    entries.removeAt(uint(i));
                }
            }
        }

        private int IndexOf(TweenyAnimation@ animation) const
        {
            if (animation is null) {
                return -1;
            }
            for (uint i = 0; i < entries.length(); i++) {
                TweenyAnimation@ source = entries[i].source;
                if (source !is null && source.instanceID == animation.instanceID) {
                    return int(i);
                }
            }
            return -1;
        }

        private bool Holds(ITween@ tween) const
        {
            for (uint i = 0; i < entries.length(); i++) {
                if (entries[i].tween is tween) {
                    return true;
                }
            }
            return false;
        }

        private void Idle()
        {
            paused = false;
            elapsed = 0.0f;
            lastAdvanceTime = 0.0f;
        }
    }
}
