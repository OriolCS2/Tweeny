using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// One slot on a sequence's timeline: either a nested tween or a callback.
    /// </summary>
    class SequenceItem
    {
        ITween@ tween;
        TweenCallback@ callback;
        float startPosition = 0.0f;
        float endPosition = 0.0f;

        /// <summary>Whether this slot fires a callback rather than driving a tween.</summary>
        /// <returns>Returns true for callback slots.</returns>
        bool IsCallback() const { return tween is null; }
    }

    /// <summary>
    /// Plays a group of tweens and callbacks on one timeline.
    ///
    /// Children are driven by absolute placement: on every update the sequence works out where each child
    /// should be for the current timeline position and seeks it there, rather than nudging each child by a
    /// delta. That keeps seeking, rewinding and reversing exact -- jumping to the middle of a sequence puts
    /// every child exactly where it belongs, with no accumulated drift.
    ///
    /// Callbacks fire when the window between the previous position and the current one crosses them, in
    /// whichever direction the sequence is playing.
    /// </summary>
    class TweenSequence : ITween, TweenCore
    {
        private array<SequenceItem@> items;
        private float lastInsertPosition = 0.0f;
        private float previousTimelinePosition = 0.0f;
        private bool hasPreviousPosition = false;

        TweenSequence()
        {
            easeType = Ease::Linear;
            tweenType = TweenType::Sequence;
            duration = 0.0f;
        }

        // ---- composition ----------------------------------------------------------------------------

        /// <summary>
        /// Adds a tween after everything already in the sequence.
        /// </summary>
        /// <param name="tween">The tween to add.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ Append(ITween@ tween)
        {
            return Insert(duration, tween);
        }

        /// <summary>
        /// Adds a tween starting at the same time as the last thing added.
        /// </summary>
        /// <param name="tween">The tween to add.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ Join(ITween@ tween)
        {
            return Insert(lastInsertPosition, tween);
        }

        /// <summary>
        /// Adds a tween at an exact position on the timeline, extending the sequence if it reaches past the end.
        /// </summary>
        /// <param name="atPosition">Where the tween starts, in seconds.</param>
        /// <param name="tween">The tween to add.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ Insert(float atPosition, ITween@ tween)
        {
            if (creationLocked || tween is null || !tween.IsActive() || tween.IsSequenced()) {
                return this;
            }

            tween.PrepareAsSequenced();
            Tweeny::Manager().MarkDirty();

            SequenceItem@ item = SequenceItem();
            @item.tween = tween;
            item.startPosition = atPosition < 0.0f ? 0.0f : atPosition;
            item.endPosition = item.startPosition + tween.GetSequencedSpan();

            items.insertLast(item);
            lastInsertPosition = item.startPosition;
            if (item.endPosition > duration) {
                duration = item.endPosition;
            }
            return this;
        }

        /// <summary>
        /// Adds empty time after everything already in the sequence.
        /// </summary>
        /// <param name="interval">How long the gap lasts, in seconds.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ AppendInterval(float interval)
        {
            if (creationLocked || interval <= 0.0f) {
                return this;
            }
            lastInsertPosition = duration;
            duration += interval;
            return this;
        }

        /// <summary>
        /// Adds empty time before everything already in the sequence, shifting it all later.
        /// </summary>
        /// <param name="interval">How long the gap lasts, in seconds.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ PrependInterval(float interval)
        {
            if (creationLocked || interval <= 0.0f) {
                return this;
            }
            ShiftEverything(interval);
            duration += interval;
            lastInsertPosition = 0.0f;
            return this;
        }

        /// <summary>
        /// Adds a tween before everything already in the sequence, shifting it all later.
        /// </summary>
        /// <param name="tween">The tween to add.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ Prepend(ITween@ tween)
        {
            if (creationLocked || tween is null || !tween.IsActive() || tween.IsSequenced()) {
                return this;
            }
            float span = tween.GetSequencedSpan();
            ShiftEverything(span);
            duration += span;
            return Insert(0.0f, tween);
        }

        /// <summary>
        /// Fires a callback once the sequence reaches the end of everything added so far.
        /// </summary>
        /// <param name="callback">The callback to fire.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ AppendCallback(TweenCallback@ callback)
        {
            return InsertCallback(duration, callback);
        }

        /// <summary>
        /// Fires a callback at the very start of the sequence.
        /// </summary>
        /// <param name="callback">The callback to fire.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ PrependCallback(TweenCallback@ callback)
        {
            return InsertCallback(0.0f, callback);
        }

        /// <summary>
        /// Fires a callback at the same time as the last thing added.
        /// </summary>
        /// <param name="callback">The callback to fire.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ JoinCallback(TweenCallback@ callback)
        {
            return InsertCallback(lastInsertPosition, callback);
        }

        /// <summary>
        /// Fires a callback at an exact position on the timeline.
        /// </summary>
        /// <param name="atPosition">When the callback fires, in seconds.</param>
        /// <param name="callback">The callback to fire.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ InsertCallback(float atPosition, TweenCallback@ callback)
        {
            if (creationLocked || callback is null) {
                return this;
            }
            SequenceItem@ item = SequenceItem();
            @item.callback = callback;
            item.startPosition = atPosition < 0.0f ? 0.0f : atPosition;
            item.endPosition = item.startPosition;
            items.insertLast(item);
            if (item.startPosition > duration) {
                duration = item.startPosition;
            }
            return this;
        }

        private void ShiftEverything(float by)
        {
            for (uint i = 0; i < items.length(); i++) {
                items[i].startPosition += by;
                items[i].endPosition += by;
            }
        }

        /// <summary>The number of slots on the timeline.</summary>
        /// <returns>Returns how many tweens and callbacks the sequence holds.</returns>
        int GetItemCount() const { return int(items.length()); }

        // ---- required by TweenCore ------------------------------------------------------------------

        bool TweenStartup()
        {
            SortItems();
            return items.length() > 0 || duration > 0.0f;
        }

        void TweenApply(float eased, UpdateNotice notice)
        {
            float timelinePosition = eased * duration;
            float from = hasPreviousPosition ? previousTimelinePosition : 0.0f;

            bool inclusiveStart = !hasPreviousPosition;

            if (notice == UpdateNotice::RewindStep) {
                RewindChildren();
                from = 0.0f;
                inclusiveStart = true;
            }

            DriveChildren(timelinePosition);
            FireCallbacks(from, timelinePosition, inclusiveStart);

            previousTimelinePosition = timelinePosition;
            hasPreviousPosition = true;
        }

        private void SortItems()
        {
            for (uint i = 1; i < items.length(); i++) {
                SequenceItem@ current = items[i];
                int j = int(i) - 1;
                while (j >= 0 && items[uint(j)].startPosition > current.startPosition) {
                    @items[uint(j + 1)] = items[uint(j)];
                    j--;
                }
                @items[uint(j + 1)] = current;
            }
        }

        private void DriveChildren(float timelinePosition)
        {
            for (uint i = 0; i < items.length(); i++) {
                SequenceItem@ item = items[i];
                if (item.IsCallback() || item.tween is null || !item.tween.IsActive()) {
                    continue;
                }
                float span = item.endPosition - item.startPosition;
                float local = timelinePosition - item.startPosition;
                if (local < 0.0f) {
                    local = 0.0f;
                }
                else if (local > span) {
                    local = span;
                }
                item.tween.Goto(local, false, false);
            }
        }

        private void RewindChildren()
        {
            for (uint i = 0; i < items.length(); i++) {
                SequenceItem@ item = items[i];
                if (!item.IsCallback() && item.tween !is null && item.tween.IsActive()) {
                    item.tween.Goto(0.0f, false, false);
                }
            }
        }

        private void FireCallbacks(float from, float to, bool inclusiveStart)
        {
            if (from == to && !inclusiveStart) {
                return;
            }
            bool forward = to >= from;
            float low = forward ? from : to;
            float high = forward ? to : from;

            if (forward) {
                for (uint i = 0; i < items.length(); i++) {
                    SequenceItem@ item = items[i];
                    bool afterLow = inclusiveStart ? item.startPosition >= low : item.startPosition > low;
                    if (item.IsCallback() && afterLow && item.startPosition <= high) {
                        item.callback();
                        if (!active) {
                            return;
                        }
                    }
                }
            }
            else {
                for (int i = int(items.length()) - 1; i >= 0; i--) {
                    SequenceItem@ item = items[uint(i)];
                    if (item.IsCallback() && item.startPosition >= low && item.startPosition < high) {
                        item.callback();
                        if (!active) {
                            return;
                        }
                    }
                }
            }
        }

        void TweenReleaseReferences()
        {
            for (uint i = 0; i < items.length(); i++) {
                if (items[i].tween !is null) {
                    items[i].tween.ReleaseReferences();
                }
                @items[i].tween = null;
                @items[i].callback = null;
            }
            items.resize(0);
            @tweenTarget = null;
            @onStart = null; @onPlay = null; @onPause = null; @onRewind = null;
            @onUpdate = null; @onStepComplete = null; @onComplete = null; @onKill = null;
            @onWaypointChange = null; @customEase = null;
        }

        void ReleaseReferences() { TweenReleaseReferences(); }

        // ---- fluent settings ------------------------------------------------------------------------

        TweenSequence@ SetEase(Ease value) { CoreSetEase(value); return this; }
        TweenSequence@ SetEase(EaseFunc@ value) { CoreSetEaseFunc(value); return this; }
        TweenSequence@ SetLoops(int count) { CoreSetLoops(count, loopType); return this; }
        TweenSequence@ SetLoops(int count, LoopType kind) { CoreSetLoops(count, kind); return this; }
        TweenSequence@ SetAutoKill(bool value = true) { CoreSetAutoKill(value); return this; }
        TweenSequence@ SetUpdate(UpdateType kind) { CoreSetUpdate(kind, independentUpdate); return this; }
        TweenSequence@ SetUpdate(UpdateType kind, bool independent) { CoreSetUpdate(kind, independent); return this; }
        TweenSequence@ SetId(const string&in value) { CoreSetStringId(value); return this; }
        TweenSequence@ SetId(int value) { CoreSetIntId(value); return this; }
        TweenSequence@ SetTarget(Object@ value) { CoreSetTarget(value); return this; }
        TweenSequence@ SetTimeScale(float value) { CoreSetTimeScale(value); return this; }
        TweenSequence@ SetInverted(bool value = true) { CoreSetInverted(value); return this; }

        /// <summary>
        /// Delays the whole sequence. Unlike a plain tween's delay, this is a real gap at the front of the
        /// timeline, so it is replayed on every loop cycle.
        /// </summary>
        /// <param name="value">How long to wait, in seconds.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ SetDelay(float value)
        {
            return PrependInterval(value);
        }

        /// <summary>
        /// Delays the sequence once, the way a plain tween's delay behaves.
        /// </summary>
        /// <param name="value">How long to wait, in seconds.</param>
        /// <param name="asPrependedInterval">True to make the gap part of the looping timeline instead.</param>
        /// <returns>Returns this sequence so calls can be chained.</returns>
        TweenSequence@ SetDelay(float value, bool asPrependedInterval)
        {
            if (asPrependedInterval) {
                return PrependInterval(value);
            }
            CoreSetDelay(value);
            return this;
        }

        TweenSequence@ OnStart(TweenCallback@ value) { @onStart = value; return this; }
        TweenSequence@ OnPlay(TweenCallback@ value) { @onPlay = value; return this; }
        TweenSequence@ OnPause(TweenCallback@ value) { @onPause = value; return this; }
        TweenSequence@ OnRewind(TweenCallback@ value) { @onRewind = value; return this; }
        TweenSequence@ OnUpdate(TweenCallback@ value) { @onUpdate = value; return this; }
        TweenSequence@ OnStepComplete(TweenCallback@ value) { @onStepComplete = value; return this; }
        TweenSequence@ OnComplete(TweenCallback@ value) { @onComplete = value; return this; }
        TweenSequence@ OnKill(TweenCallback@ value) { @onKill = value; return this; }
    }
}
