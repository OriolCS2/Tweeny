using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Shows every live tween and lets them be driven by hand.
///
/// Tweens are invisible while they run: when one misbehaves there is normally nothing to look at. This
/// window makes the active list, each tween's progress and its settings visible, and adds a preview that
/// steps the whole thing forward without entering play mode.
/// </summary>
[MainMenuItemWindow("Tweeny/Tweeny Inspector", "Tweeny Inspector")] class TweenyInspectorWindow : EditorWindow
{
    private TweenyPreview preview;
    private float previewSpeed = 1.0f;
    private bool restoreOnStop = true;
    private float lastFrameTime = 0.0f;

    void OnGUI()
    {
        DrawToolbar();
        GUI::Separator();
        DrawPreviewControls();
        GUI::Separator();
        DrawTweenList();

        if (preview.IsPreviewing()) {
            float now = Time::GetUnscaledGameTime();
            float delta = lastFrameTime <= 0.0f ? 0.0f : (now - lastFrameTime);
            lastFrameTime = now;
            if (delta > 0.25f) {
                // The editor only redraws on demand, so a long gap between frames would make the preview
                // leap forward. Clamping keeps it looking like motion rather than teleporting.
                delta = 0.25f;
            }
            preview.Update(delta * previewSpeed);
        }
        else {
            lastFrameTime = 0.0f;
        }
    }

    private void DrawToolbar()
    {
        GUI::Text("Active tweens: " + Tweeny::TotalActiveTweens()
            + "   playing: " + Tweeny::TotalPlayingTweens());

        if (GUI::Button("Play all")) {
            Tweeny::PlayAll();
        }
        GUI::SameLine();
        if (GUI::Button("Pause all")) {
            Tweeny::PauseAll();
        }
        GUI::SameLine();
        if (GUI::Button("Rewind all")) {
            Tweeny::RewindAll(true);
        }
        GUI::SameLine();
        if (GUI::Button("Kill all")) {
            Tweeny::KillAll(false);
        }
    }

    private void DrawPreviewControls()
    {
        GUI::SeparatorText("Preview");

        if (!preview.IsPreviewing()) {
            if (GUI::Button("Preview every active tween")) {
                StartPreview();
            }
            GUI::TextDisabled("Runs the tweens here in the editor. Every target is put back afterwards.");
        }
        else {
            GUI::Text("Previewing " + preview.GetCount() + " tweens   "
                + formatFloat(preview.GetElapsed(), "", 0, 2) + "s");
            if (GUI::Button("Stop and restore")) {
                preview.Stop(true);
            }
            GUI::SameLine();
            if (GUI::Button("Stop and keep")) {
                preview.Stop(false);
            }
        }

        bool edited = false;
        previewSpeed = GUI::SliderFloat("Preview speed", previewSpeed, 0.05f, 4.0f, edited);
        restoreOnStop = GUI::Checkbox("Restore targets when the window closes", restoreOnStop, edited);
    }

    private void StartPreview()
    {
        array<ITween@>@ tweens = Tweeny::AllTweens();
        for (uint i = 0; i < tweens.length(); i++) {
            preview.Add(tweens[i]);
        }
    }

    private void DrawTweenList()
    {
        GUI::SeparatorText("Tweens");

        array<ITween@>@ tweens = Tweeny::AllTweens();
        if (tweens.length() == 0) {
            GUI::TextDisabled("Nothing is tweening right now.");
            return;
        }

        for (uint i = 0; i < tweens.length(); i++) {
            ITween@ tween = tweens[i];
            if (tween is null) {
                continue;
            }
            DrawTweenRow(int(i), tween);
        }
    }

    private void DrawTweenRow(int index, ITween@ tween)
    {
        string label = Describe(index, tween);
        if (!GUI::TreeNode(label)) {
            return;
        }

        float full = tween.GetFullDuration(true);
        float elapsed = tween.GetElapsed(true);
        GUI::Text("elapsed " + formatFloat(elapsed, "", 0, 2) + "s of "
            + (tween.GetLoops() == -1 ? "endless" : formatFloat(full, "", 0, 2) + "s"));
        GUI::Text("loop " + tween.GetCompletedLoops() + " of "
            + (tween.GetLoops() == -1 ? "endless" : "" + tween.GetLoops()));
        GUI::Text("state: " + (tween.IsPlaying() ? "playing" : "paused")
            + (tween.IsBackwards() ? ", backwards" : "")
            + (tween.IsComplete() ? ", complete" : ""));

        if (GUI::Button("Play##" + index)) {
            tween.Play();
        }
        GUI::SameLine();
        if (GUI::Button("Pause##" + index)) {
            tween.Pause();
        }
        GUI::SameLine();
        if (GUI::Button("Rewind##" + index)) {
            tween.Rewind(true);
        }
        GUI::SameLine();
        if (GUI::Button("Complete##" + index)) {
            tween.Complete(false);
        }
        GUI::SameLine();
        if (GUI::Button("Kill##" + index)) {
            tween.Kill(false);
        }

        GUI::TreePop();
    }

    private string Describe(int index, ITween@ tween)
    {
        string label = "#" + index;
        if (!tween.GetStringId().isEmpty()) {
            label += "  '" + tween.GetStringId() + "'";
        }
        else if (tween.GetIntId() != -999) {
            label += "  id " + tween.GetIntId();
        }
        Object@ target = tween.GetTarget();
        if (target !is null && Object::IsValid(target)) {
            label += "  on " + target.name;
        }
        float full = tween.GetFullDuration(true);
        float progress = full <= 0.0f ? 0.0f : tween.GetElapsed(true) / full;
        label += "  " + formatFloat(progress * 100.0f, "", 0, 0) + "%";
        return label;
    }

    void OnDestroy()
    {
        if (preview.IsPreviewing()) {
            preview.Stop(restoreOnStop);
        }
    }
}
