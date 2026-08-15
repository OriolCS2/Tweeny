using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Puts transport controls at the top of a TweenyAnimation component, so an animation can be tried out
/// from the inspector without pressing Play and without opening another window.
///
/// The buttons come first and the component's own fields follow, drawn by the editor exactly as it would
/// have drawn them. Previewing here runs the very tween the component would build at play start, and it goes
/// through the shared preview session, so the Tweeny window shows the same state and its buttons agree with
/// these ones.
///
/// Moving the selection elsewhere stops the preview and puts the targets back, because an animation left
/// halfway through looks exactly like the object's real position and would be saved into the scene as one.
/// </summary>
[CustomInspector("Tweeny::TweenyAnimation")]
class TweenyAnimationInspector : EditorBehaviour
{
    void OnCustomInspector(Tweeny::TweenyAnimation@ target)
    {
        DrawTransport(target);
        GUI::ShowAllProperties();
    }

    /// <summary>
    /// Drives the preview and ends it when the user looks away.
    ///
    /// This runs every editor tick rather than only while the inspector is on screen, which is what makes
    /// both halves work: the animation keeps moving, and deselecting the entity puts it back.
    /// </summary>
    void Update()
    {
        TweenyPreviewSession@ session = Tweeny::PreviewSession();
        DropDeselected(session);

        // The preview moves entities in the world, so the viewports have to be marked stale as well as the
        // interface. Without it the values change and the scene keeps showing its last image.
        if (session.Advance()) {
            CometEditor::EditorApplication::RequestSceneRedraw();
        }
    }

    /// <summary>
    /// Ends the previews started here for entities that are no longer selected.
    ///
    /// A preview left running once its inspector is off screen is how a scene quietly ends up saved with an
    /// object halfway through an animation. Previews started from the Tweeny window are left alone, because
    /// the window is still there showing them.
    /// </summary>
    /// <param name="session">The shared session.</param>
    private void DropDeselected(TweenyPreviewSession@ session)
    {
        array<TweenyAnimation@>@ mine = session.GetSources(true);
        for (uint i = 0; i < mine.length(); i++) {
            TweenyAnimation@ animation = mine[i];
            Entity@ owner = animation.entity;
            if (owner is null || !Object::IsValid(owner) || !CometEditor::Selection::Contains(owner)) {
                session.StopFor(animation);
                CometEditor::EditorApplication::RequestSceneRedraw();
            }
        }
    }

    /// <summary>
    /// The three transport buttons, centred and joined into one control.
    ///
    /// They are drawn as a single block rather than as a property row because they act on the component as a
    /// whole rather than on any one of its fields, and the fields underneath are what the editor's standard
    /// layout is for.
    /// </summary>
    /// <param name="target">The component being inspected.</param>
    private void DrawTransport(TweenyAnimation@ target)
    {
        TweenyPreviewSession@ session = Tweeny::PreviewSession();
        bool running = session.IsPreviewing(target);
        bool paused = running && session.IsPaused();

        float size = GUI::GetFrameHeight();
        Vector2 square = Vector2(size, size);

        // Joined, so the three read as one control rather than three loose buttons. The spacing has to go
        // before the width is measured, or the group would be centred as if the gaps were still there.
        GUI::PushStyleVarVector(int(GUI::StyleVar::ItemSpacing), Vector2(0.0f, 0.0f));

        float available = GUI::GetContentRegionAvail().x;
        float offset = (available - size * 3.0f) * 0.5f;
        if (offset > 0.0f) {
            GUI::SetCursorPosX(GUI::GetCursorPosX() + offset);
        }

        // Once it is running, the button restarts it, so it shows the replay arrow: pressing play on
        // something that is already playing has nothing left to mean.
        if (GUI::Button(running ? CometEditor::RawIcon::Redo : CometEditor::RawIcon::Play, square)) {
            session.Play(target, true);
            CometEditor::EditorApplication::RequestSceneRedraw();
        }
        GUI::Tooltip(running ? "Play this animation again from the start"
                             : "Preview this animation in the editor");

        GUI::SameLine();
        GUI::BeginDisabled(!running);

        // Held down while paused, because a pause that leaves the button looking untouched gives no way to
        // tell a paused preview from a finished one.
        if (paused) {
            GUI::PushStyleColor(int(GUI::Col::Button), GUI::GetStyleColor(GUI::Col::ButtonActive));
        }
        if (GUI::Button(CometEditor::RawIcon::Pause, square)) {
            session.TogglePause();
        }
        if (paused) {
            GUI::PopStyleColor();
        }
        GUI::Tooltip(paused ? "Resume" : "Pause");

        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Stop, square)) {
            session.StopFor(target);
            // Stopping writes the original values back, and the viewports would otherwise keep showing the
            // animated ones until something else happened to make them redraw.
            CometEditor::EditorApplication::RequestSceneRedraw();
        }
        GUI::Tooltip("Stop and put everything back");

        GUI::EndDisabled();
        GUI::PopStyleVar();
    }

    void OnDestroy()
    {
        // Losing this object -- a script recompile, or the editor closing -- would drop the only thing still
        // pointing at a preview started here, so it is put back now rather than left in the scene.
        Tweeny::PreviewSession().StopOwned(true);
    }
}
