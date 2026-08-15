using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Owns every live tween and advances them.
    ///
    /// There is no object pool: AngelScript is reference counted, so a finished tween is released the
    /// moment the last handle drops. What is reused is the active list itself, which grows to a high-water
    /// mark and removes entries by swapping with the last element instead of shifting the whole array.
    ///
    /// Callbacks are allowed to create and kill tweens while the list is being walked, so removals are
    /// deferred to a sweep that runs after the walk finishes.
    /// </summary>
    class TweenyManager
    {
        private array<ITween@> tweens;
        private array<TweenLink@> links;
        private bool ticking = false;
        private bool needsSweep = false;

        /// <summary>Global multiplier applied to every scaled tween.</summary>
        float globalTimeScale = 1.0f;

        /// <summary>Global multiplier applied to every timescale-independent tween.</summary>
        float unscaledTimeScale = 1.0f;

        /// <summary>How loudly the engine reports problems.</summary>
        LogBehaviour logBehaviour = LogBehaviour::ErrorsOnly;

        // ---- defaults for newly created tweens ------------------------------------------------------

        Ease defaultEase = Ease::OutQuad;
        float defaultEaseOvershoot = DEFAULT_OVERSHOOT;
        float defaultEasePeriod = DEFAULT_PERIOD;
        AutoPlay defaultAutoPlay = AutoPlay::All;
        bool defaultAutoKill = true;
        LoopType defaultLoopType = LoopType::Restart;
        UpdateType defaultUpdateType = UpdateType::Normal;
        bool defaultTimeScaleIndependent = false;
        NestedTweenFailureBehaviour nestedTweenFailure = NestedTweenFailureBehaviour::TryToPreserveSequence;
        bool validateTargets = true;

        /// <summary>
        /// Registers a tween so it starts receiving ticks.
        /// </summary>
        /// <param name="tween">The tween to track.</param>
        void Add(ITween@ tween)
        {
            if (tween is null) {
                return;
            }
            tweens.insertLast(tween);
        }

        /// <summary>
        /// Advances every tween bound to one update phase.
        ///
        /// A tween whose target has gone is killed here rather than left to run. Its guards already refuse
        /// to write, so it would do no damage, but it would stay in the list being ticked for as long as it
        /// could not finish on its own -- forever for an endless one -- holding the dead target's script
        /// object alive with it. Killing lets the sweep drop the references for good.
        /// </summary>
        /// <param name="phase">The phase being driven.</param>
        /// <param name="deltaTime">Scaled seconds since the last tick of this phase.</param>
        /// <param name="unscaledDeltaTime">Unscaled seconds since the last tick of this phase.</param>
        void Tick(UpdateType phase, float deltaTime, float unscaledDeltaTime)
        {
            float scaled = deltaTime * globalTimeScale;
            float unscaled = unscaledDeltaTime * unscaledTimeScale * globalTimeScale;

            EvaluateLinks();

            ticking = true;
            uint count = tweens.length();
            for (uint i = 0; i < count; i++) {
                ITween@ tween = tweens[i];
                if (tween is null) {
                    continue;
                }
                if (!tween.IsActive()) {
                    needsSweep = true;
                    continue;
                }
                if (tween.GetUpdateType() != phase || tween.IsSequenced()) {
                    continue;
                }
                if (validateTargets && HasLostTarget(tween)) {
                    tween.Kill(false);
                    needsSweep = true;
                    continue;
                }
                if (tween.TweenTick(scaled, unscaled)) {
                    tween.Kill(false);
                    needsSweep = true;
                }
            }
            ticking = false;

            if (needsSweep) {
                Sweep();
            }
        }

        /// <summary>
        /// Whether a tween was bound to something that no longer exists.
        ///
        /// Only tweens given a target are judged. A tween over a plain getter and setter -- a number in a
        /// script, a field on an object Tweeny never sees -- has nothing to outlive, so the absence of a
        /// target means "nothing to check" rather than "target gone".
        /// </summary>
        /// <param name="tween">The tween to check.</param>
        /// <returns>Returns true when it had a target and that target is gone.</returns>
        private bool HasLostTarget(ITween@ tween)
        {
            Object@ target = tween.GetTarget();
            return target !is null && !Tweeny::IsAlive(target);
        }

        /// <summary>
        /// Removes every dead tween from the active list.
        /// </summary>
        void Sweep()
        {
            needsSweep = false;
            uint i = 0;
            while (i < tweens.length()) {
                ITween@ tween = tweens[i];
                if (tween is null || !tween.IsActive()) {
                    if (tween !is null) {
                        tween.ReleaseReferences();
                    }
                    uint last = tweens.length() - 1;
                    if (i != last) {
                        @tweens[i] = tweens[last];
                    }
                    tweens.removeLast();
                    continue;
                }
                i++;
            }
        }

        /// <summary>
        /// Registers a link so the manager starts watching its entity.
        /// </summary>
        /// <param name="link">The link to track.</param>
        void AddLink(TweenLink@ link)
        {
            if (link !is null) {
                links.insertLast(link);
            }
        }

        /// <summary>
        /// Applies every live link and drops the ones whose tween has gone.
        /// </summary>
        void EvaluateLinks()
        {
            uint i = 0;
            while (i < links.length()) {
                TweenLink@ link = links[i];
                if (link is null || !link.IsAlive()) {
                    uint last = links.length() - 1;
                    if (i != last) {
                        @links[i] = links[last];
                    }
                    links.removeLast();
                    continue;
                }
                link.Evaluate();
                i++;
            }
        }

        /// <summary>
        /// Marks a tween as needing removal on the next sweep.
        /// </summary>
        void MarkDirty()
        {
            needsSweep = true;
            if (!ticking) {
                Sweep();
            }
        }

        // ---- queries --------------------------------------------------------------------------------

        /// <summary>The number of tweens currently tracked, playing or not.</summary>
        /// <returns>Returns the active tween count.</returns>
        int TotalActiveTweens() const
        {
            int total = 0;
            for (uint i = 0; i < tweens.length(); i++) {
                if (tweens[i] !is null && tweens[i].IsActive()) {
                    total++;
                }
            }
            return total;
        }

        /// <summary>The number of tweens currently advancing.</summary>
        /// <returns>Returns the playing tween count.</returns>
        int TotalPlayingTweens() const
        {
            int total = 0;
            for (uint i = 0; i < tweens.length(); i++) {
                if (tweens[i] !is null && tweens[i].IsActive() && tweens[i].IsPlaying()) {
                    total++;
                }
            }
            return total;
        }

        /// <summary>
        /// Collects every live tween that matches a filter.
        /// </summary>
        /// <param name="filter">Which tweens to keep.</param>
        /// <param name="target">The target to match, when the filter uses one.</param>
        /// <param name="stringId">The string id to match, empty to ignore.</param>
        /// <param name="intId">The integer id to match, -999 to ignore.</param>
        /// <param name="playingOnly">Whether paused tweens are skipped.</param>
        /// <returns>Returns the matching tweens.</returns>
        array<ITween@>@ Collect(FilterType filter, Object@ target, const string&in stringId, int intId,
            bool playingOnly = false)
        {
            array<ITween@>@ result = array<ITween@>();
            for (uint i = 0; i < tweens.length(); i++) {
                ITween@ tween = tweens[i];
                if (tween is null || !tween.IsActive()) {
                    continue;
                }
                if (playingOnly && !tween.IsPlaying()) {
                    continue;
                }
                if (Matches(tween, filter, target, stringId, intId)) {
                    result.insertLast(tween);
                }
            }
            return result;
        }

        private bool Matches(ITween@ tween, FilterType filter, Object@ target, const string&in stringId, int intId)
        {
            if (filter == FilterType::All) {
                return true;
            }

            bool targetMatches = target !is null && tween.GetTarget() !is null
                && Object::Is(tween.GetTarget(), target);
            bool stringMatches = !stringId.isEmpty() && tween.GetStringId() == stringId;
            bool intMatches = intId != -999 && tween.GetIntId() == intId;

            if (filter == FilterType::TargetOrId) {
                return targetMatches || stringMatches || intMatches;
            }
            if (filter == FilterType::TargetAndId) {
                return targetMatches && (stringMatches || intMatches);
            }
            if (filter == FilterType::AllExceptTargetsOrIds) {
                return !(targetMatches || stringMatches || intMatches);
            }
            return false;
        }

        /// <summary>
        /// Kills every tween and clears the list.
        /// </summary>
        /// <param name="complete">Whether each tween jumps to its end value first.</param>
        /// <returns>Returns how many tweens were killed.</returns>
        int Clear(bool complete = false)
        {
            int killed = 0;
            for (uint i = 0; i < tweens.length(); i++) {
                if (tweens[i] !is null && tweens[i].IsActive()) {
                    tweens[i].Kill(complete);
                    killed++;
                }
            }
            Sweep();
            return killed;
        }
    }
}
