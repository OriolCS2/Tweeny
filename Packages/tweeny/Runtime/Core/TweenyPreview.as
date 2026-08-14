using namespace CometEngine;

namespace Tweeny
{
/// <summary>
/// Plays tweens inside the editor without entering play mode, and puts everything back afterwards.
///
/// The restore is the important part. A preview that leaves the scene displaced is worse than no preview,
/// because the damage is silent and gets saved. Every previewed tween is rewound on stop, which writes back
/// the value it captured when it started -- the same capture-and-restore contract the engine's own
/// animation timeline uses. A tween created with From is completed instead of rewound, since for those the
/// original value is the one at the end.
///
/// Previewed tweens are forced onto the Manual queue and stripped of their callbacks and auto-kill, so a
/// preview can never fire game logic or destroy itself midway.
/// </summary>
class TweenyPreview
{
    private array<ITween@> previewed;
    private bool previewing = false;
    private float elapsed = 0.0f;

    /// <summary>Whether a preview is running.</summary>
    /// <returns>Returns true while previewing.</returns>
    bool IsPreviewing() const { return previewing; }

    /// <summary>How long the current preview has been running.</summary>
    /// <returns>Returns the elapsed seconds.</returns>
    float GetElapsed() const { return elapsed; }

    /// <summary>The number of tweens under preview.</summary>
    /// <returns>Returns the count.</returns>
    int GetCount() const { return int(previewed.length()); }

    /// <summary>
    /// Takes a tween over for previewing: manual updates, no callbacks, no auto-kill.
    /// </summary>
    /// <param name="tween">The tween to preview.</param>
    void Add(ITween@ tween)
    {
        if (tween is null || !tween.IsActive()) {
            return;
        }
        tween.PrepareForPreview();
        tween.ForceInit();
        tween.Play();
        previewed.insertLast(tween);
        previewing = true;
    }

    /// <summary>
    /// Advances every previewed tween.
    /// </summary>
    /// <param name="deltaTime">Seconds to advance by.</param>
    void Update(float deltaTime)
    {
        if (!previewing) {
            return;
        }
        elapsed += deltaTime;
        Tweeny::ManualUpdate(deltaTime, deltaTime);
    }

    /// <summary>
    /// Ends the preview.
    /// </summary>
    /// <param name="restoreTargets">Whether every target is put back where it was before the preview.</param>
    void Stop(bool restoreTargets = true)
    {
        for (uint i = 0; i < previewed.length(); i++) {
            ITween@ tween = previewed[i];
            if (tween is null || !tween.IsActive()) {
                continue;
            }
            if (restoreTargets) {
                if (tween.IsFromTween()) {
                    tween.Complete(false);
                }
                else {
                    tween.Rewind(true);
                }
            }
            tween.Kill(false);
        }
        previewed.resize(0);
        previewing = false;
        elapsed = 0.0f;
    }
}
}
