using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Holds a coroutine until a tween finishes.
    ///
    /// Use it as: <c>Yield(WaitForCompletion(myTween));</c>
    /// A tween that gets killed also releases the wait, so a coroutine can never be stranded by something
    /// else calling Kill on what it was waiting for.
    /// </summary>
    class WaitForCompletion : ICustomYieldInstruction
    {
        private ITween@ tween;

        /// <summary>Waits on a tween.</summary>
        /// <param name="target">The tween to wait for.</param>
        WaitForCompletion(ITween@ target) { @tween = target; }

        /// <summary>Whether the coroutine may resume.</summary>
        /// <returns>Returns true once the tween has finished or died.</returns>
        bool CanContinue()
        {
            return tween is null || !tween.IsActive() || tween.IsComplete();
        }
    }

    /// <summary>
    /// Holds a coroutine until a tween is killed.
    /// </summary>
    class WaitForKill : ICustomYieldInstruction
    {
        private ITween@ tween;

        /// <summary>Waits on a tween.</summary>
        /// <param name="target">The tween to wait for.</param>
        WaitForKill(ITween@ target) { @tween = target; }

        /// <summary>Whether the coroutine may resume.</summary>
        /// <returns>Returns true once the tween is no longer alive.</returns>
        bool CanContinue()
        {
            return tween is null || !tween.IsActive();
        }
    }

    /// <summary>
    /// Holds a coroutine until a tween has returned to its start.
    /// </summary>
    class WaitForRewind : ICustomYieldInstruction
    {
        private ITween@ tween;

        /// <summary>Waits on a tween.</summary>
        /// <param name="target">The tween to wait for.</param>
        WaitForRewind(ITween@ target) { @tween = target; }

        /// <summary>Whether the coroutine may resume.</summary>
        /// <returns>Returns true once the tween sits at position zero.</returns>
        bool CanContinue()
        {
            if (tween is null || !tween.IsActive()) {
                return true;
            }
            return tween.IsInitialized() && tween.GetPosition() <= 0.0f && tween.GetCompletedLoops() <= 0;
        }
    }

    /// <summary>
    /// Holds a coroutine until a tween has finished a given number of loops.
    /// </summary>
    class WaitForElapsedLoops : ICustomYieldInstruction
    {
        private ITween@ tween;
        private int loops;

        /// <summary>Waits on a tween's loop count.</summary>
        /// <param name="target">The tween to wait for.</param>
        /// <param name="elapsedLoops">How many finished loops to wait for.</param>
        WaitForElapsedLoops(ITween@ target, int elapsedLoops)
        {
            @tween = target;
            loops = elapsedLoops;
        }

        /// <summary>Whether the coroutine may resume.</summary>
        /// <returns>Returns true once enough loops have gone by or the tween died.</returns>
        bool CanContinue()
        {
            return tween is null || !tween.IsActive() || tween.GetCompletedLoops() >= loops;
        }
    }

    /// <summary>
    /// Holds a coroutine until a tween passes a position on its timeline.
    /// </summary>
    class WaitForPosition : ICustomYieldInstruction
    {
        private ITween@ tween;
        private float position;

        /// <summary>Waits on a tween's position.</summary>
        /// <param name="target">The tween to wait for.</param>
        /// <param name="targetPosition">The elapsed time to wait for, in seconds.</param>
        WaitForPosition(ITween@ target, float targetPosition)
        {
            @tween = target;
            position = targetPosition;
        }

        /// <summary>Whether the coroutine may resume.</summary>
        /// <returns>Returns true once the tween has travelled far enough or died.</returns>
        bool CanContinue()
        {
            return tween is null || !tween.IsActive() || tween.GetElapsed(true) >= position;
        }
    }

    /// <summary>
    /// Holds a coroutine until a tween actually starts, which matters when it has a delay.
    /// </summary>
    class WaitForStart : ICustomYieldInstruction
    {
        private ITween@ tween;

        /// <summary>Waits on a tween.</summary>
        /// <param name="target">The tween to wait for.</param>
        WaitForStart(ITween@ target) { @tween = target; }

        /// <summary>Whether the coroutine may resume.</summary>
        /// <returns>Returns true once the tween has begun or died.</returns>
        bool CanContinue()
        {
            return tween is null || !tween.IsActive() || tween.IsInitialized();
        }
    }
}
