using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Puts transport controls at the top of a TweenyAnimation component, so an animation can be tried out
/// from the inspector without pressing Play and without opening another window.
///
/// The buttons come first and the component's own fields follow, drawn by the editor exactly as it would
/// have drawn them. Previewing here runs the very tween the component would build at play start, and
/// stopping puts every target back; so does moving the selection elsewhere, because an animation left
/// halfway through would otherwise be silently saved into the scene as the object's real position.
/// </summary>
[CustomInspector("Tweeny::TweenyAnimation")]
class TweenyAnimationInspector : EditorBehaviour
{
    private TweenyPreview preview;
    private TweenyAnimation@ previewed;
    private float lastFrameTime = 0.0f;

    void OnCustomInspector(Tweeny::TweenyAnimation@ target)
    {
        DrawTransport(target);
        GUI::Spacing();

        // Everything the component declares, drawn by the editor itself: no field list to keep in step
        // with the component, and new fields appear here the moment they are added to it.
        GUI::ShowAllProperties();
    }

    /// <summary>
    /// Drives the preview and ends it when the user looks away.
    ///
    /// This runs every editor tick, not just while the inspector is being drawn, which is what makes both
    /// halves work: the animation keeps moving, and deselecting the entity puts it back. A preview left
    /// half-finished would look like the object's real position and would be saved into the scene as one.
    /// </summary>
    void Update()
    {
        if (!preview.IsPreviewing()) {
            return;
        }

        if (!StillSelected()) {
            StopPreview();
            return;
        }

        Advance();
    }

    private bool StillSelected()
    {
        if (previewed is null || !Object::IsValid(previewed)) {
            return false;
        }
        Entity@ owner = previewed.entity;
        return owner !is null && Object::IsValid(owner) && CometEditor::Selection::Contains(owner);
    }

    private void DrawTransport(TweenyAnimation@ target)
    {
        bool previewingThis = preview.IsPreviewing() && previewed is target;
        Vector2 square = Vector2(GUI::GetFrameHeight(), GUI::GetFrameHeight());

        GUI::SetCursorAtStandardFieldPosition();

        if (GUI::Button(CometEditor::RawIcon::Play, square)) {
            StartPreview(target);
        }
        GUI::Tooltip("Preview this animation in the editor");

        GUI::SameLine();
        GUI::BeginDisabled(!previewingThis);
        if (GUI::Button(CometEditor::RawIcon::Pause, square)) {
            ITween@ tween = target.GetTween();
            if (tween !is null) {
                tween.Pause();
            }
        }
        GUI::Tooltip("Pause");

        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Stop, square)) {
            StopPreview();
        }
        GUI::Tooltip("Stop and put everything back");
        GUI::EndDisabled();

        if (previewingThis) {
            GUI::SameLine();
            GUI::AlignTextToFramePadding();
            GUI::TextDisabled("previewing, " + formatFloat(preview.GetElapsed(), "", 0, 2) + "s");
        }
    }

    private void StartPreview(TweenyAnimation@ target)
    {
        StopPreview();
        if (target is null) {
            return;
        }
        target.Play();
        preview.Add(target.GetTween());
        @previewed = target;
        lastFrameTime = 0.0f;
    }

    private void StopPreview()
    {
        if (preview.IsPreviewing()) {
            preview.Stop(true);
        }
        @previewed = null;
        lastFrameTime = 0.0f;
    }

    private void Advance()
    {
        // This animates entities in the world, so the viewports have to be invalidated as well as the
        // interface: without it the values change but the scene keeps its last drawn image.
        CometEditor::EditorApplication::RequestSceneRedraw();

        float now = Time::GetUnscaledGameTime();
        float delta = lastFrameTime <= 0.0f ? 0.0f : (now - lastFrameTime);
        lastFrameTime = now;
        if (delta > 0.25f) {
            // The editor draws on demand, so a long gap between frames would make the preview leap. This
            // keeps it looking like motion rather than teleporting.
            delta = 0.25f;
        }
        preview.Update(delta);
    }

    void OnDestroy()
    {
        StopPreview();
    }
}
