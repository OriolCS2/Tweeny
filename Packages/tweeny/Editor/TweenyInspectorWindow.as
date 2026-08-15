using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Shows what Tweeny is animating, and lets it be driven by hand.
///
/// The window has two jobs because there are two things worth looking at. Out of play mode there are no
/// tweens at all -- nothing has run yet -- so it lists the TweenyAnimation components sitting in the open
/// scene and previews them in place, which is the whole point of a preview: seeing the animation without
/// pressing Play. In play mode it switches to the live tween list, where the interesting thing is what is
/// actually running right now, with its progress and its controls.
/// </summary>
[MainMenuItemWindow("Tweeny/Tweeny Inspector", "Tweeny Inspector")] class TweenyInspectorWindow : EditorWindow
{
    private TweenyPreview preview;
    private float previewSpeed = 1.0f;
    private bool restoreOnStop = true;
    private float lastFrameTime = 0.0f;
    private int selected = -1;

    /// The components found in the open scenes, rebuilt each frame so the list never goes stale.
    private array<TweenyAnimation@> animations;
    private array<Entity@> animationOwners;

    /// Distance the editor leaves between a property widget and the right edge of the window. Matching it
    /// is what lines the toolbar up with the fields underneath.
    private float WIDGET_RIGHT_MARGIN = 15.0f;

    CometEditor::WindowConfig OnGetWindowConfig()
    {
        CometEditor::WindowConfig config;
        config.initialSize = Vector2i(780, 440);
        config.initialPositionType = CometEditor::WindowConfigPositionType::CENTERED;
        config.iconRaw = CometEditor::RawIcon::SlidersH;
        return config;
    }

    void OnGUI()
    {
        bool playing = CometEditor::EditorApplication::IsPlaying();
        if (!playing) {
            CollectAnimations();
        }

        DrawHeader(playing);
        GUI::Spacing();
        DrawPreviewSection(playing);
        GUI::Spacing();

        if (playing) {
            DrawTweenTable();
        }
        else {
            DrawAnimationTable();
        }

        AdvancePreview();
    }

    // ---- header --------------------------------------------------------------------------------------

    private void DrawHeader(bool playing)
    {
        GUI::AlignTextToFramePadding();
        if (playing) {
            int total = Tweeny::TotalActiveTweens();
            GUI::Text(total + (total == 1 ? " tween" : " tweens"));
            GUI::SameLine();
            GUI::TextDisabled("(" + Tweeny::TotalPlayingTweens() + " playing)");
        }
        else {
            uint found = animations.length();
            GUI::Text(found + (found == 1 ? " animation" : " animations") + " in the scene");
            GUI::SameLine();
            GUI::TextDisabled("(not playing)");
        }

        // The bulk controls are right-aligned so their last button ends exactly where the property widgets
        // below do. SameLine takes an absolute X inside the window, so the group is measured back from that
        // same right edge rather than forward from the text.
        float size = GUI::GetFrameHeight();
        float step = size + GUI::GetStyleVarVector(GUI::StyleVar::ItemSpacing).x;
        float rightEdge = GUI::GetWindowSize().x - WIDGET_RIGHT_MARGIN;
        float start = rightEdge - (step * 3.0f + size);
        if (start > GUI::GetCursorPosX()) {
            GUI::SameLine(start);
        }
        else {
            GUI::SameLine();
        }

        // These drive whatever is running, which out of play mode means the preview: a previewed tween is a
        // real tween in the manager, so the same bulk calls reach it. Only killing is held back to play
        // mode, because out of it the thing to end a preview with is Stop, which also restores.
        Vector2 square = Vector2(size, size);
        bool anything = Tweeny::TotalActiveTweens() > 0;

        GUI::BeginDisabled(!anything);
        if (GUI::Button(CometEditor::RawIcon::Play, square)) { Tweeny::PlayAll(); }
        GUI::Tooltip("Play everything");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Pause, square)) { Tweeny::PauseAll(); }
        GUI::Tooltip("Pause everything");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Stop, square)) { StopEverything(); }
        GUI::Tooltip(preview.IsPreviewing() ? "Stop the preview and restore" : "Rewind everything and pause");
        GUI::EndDisabled();

        GUI::SameLine();
        GUI::BeginDisabled(!playing || !anything);
        if (GUI::Button(CometEditor::RawIcon::Trash, square)) { Tweeny::KillAll(false); }
        GUI::Tooltip("Kill every tween");
        GUI::EndDisabled();
    }

    /// <summary>
    /// Ends whatever is running: a preview is stopped and restored, live tweens are rewound and paused.
    /// </summary>
    private void StopEverything()
    {
        if (preview.IsPreviewing()) {
            preview.Stop(true);
            return;
        }
        Tweeny::RewindAll(true);
    }

    // ---- preview -------------------------------------------------------------------------------------

    private void DrawPreviewSection(bool playing)
    {
        GUI::SeparatorText("Preview");

        bool previewing = preview.IsPreviewing();
        bool edited = false;

        // One speed, not two. It drives this window's preview clock and is pushed into Tweeny's global
        // time scale as well, so the same slider slows down a preview here and the tweens running in play
        // mode -- there is no second control that only works in one of the two situations.
        GUI::StandardFieldName("Preview speed",
            "Drives the preview here, and Tweeny's global time scale, so it slows the running scene too.");
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        GUI::SetNextItemWidthToStandardPropertyWidget();
        previewSpeed = GUI::SliderFloat("##speed", previewSpeed, 0.05f, 4.0f, edited);
        if (edited) {
            Tweeny::SetTimeScale(previewSpeed);
        }

        GUI::StandardFieldName("Restore on close",
            "Puts every target back where it was if the window closes mid-preview.");
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        restoreOnStop = GUI::Checkbox("##restore", restoreOnStop, edited);

        GUI::SetCursorAtStandardFieldPosition();
        if (previewing) {
            if (GUI::Button(CometEditor::RawIcon::Stop + "  Stop")) {
                preview.Stop(true);
            }
            GUI::SameLine();
            GUI::TextDisabled(preview.GetCount() + " previewing, "
                + formatFloat(preview.GetElapsed(), "", 0, 2) + "s elapsed");
            return;
        }

        if (playing) {
            GUI::BeginDisabled(Tweeny::TotalActiveTweens() == 0);
            if (GUI::Button(CometEditor::RawIcon::Eye + "  Preview every live tween")) {
                PreviewLiveTweens();
            }
            GUI::EndDisabled();
        }
        else {
            GUI::BeginDisabled(animations.length() == 0);
            if (GUI::Button(CometEditor::RawIcon::Eye + "  Preview every animation")) {
                for (uint i = 0; i < animations.length(); i++) {
                    PreviewAnimation(animations[i]);
                }
            }
            GUI::EndDisabled();
        }
    }

    private void PreviewLiveTweens()
    {
        array<ITween@>@ tweens = Tweeny::AllTweens();
        for (uint i = 0; i < tweens.length(); i++) {
            preview.Add(tweens[i]);
        }
    }

    /// <summary>
    /// Builds one component's tween and hands it to the preview.
    ///
    /// The component builds exactly the tween it would build at play start, so what you see here is what
    /// the game will do. The preview drives it by hand and kills it on stop, which is why this leaves
    /// nothing behind in a scene that is not even playing.
    /// </summary>
    /// <param name="animation">The component to preview.</param>
    private void PreviewAnimation(TweenyAnimation@ animation)
    {
        if (animation is null) {
            return;
        }
        animation.Play();
        preview.Add(animation.GetTween());
    }

    private void AdvancePreview()
    {
        if (!preview.IsPreviewing()) {
            lastFrameTime = 0.0f;
            return;
        }

        // A preview is something advancing on its own, so the editor has to be told to keep drawing or it
        // goes idle mid-animation. The scene variant is the one that matters here: this animates entities
        // in the world, and the viewports keep their last image until told it is stale -- which is why the
        // colour only used to change when the mouse passed over the scene view.
        CometEditor::EditorApplication::RequestSceneRedraw();

        float now = Time::GetUnscaledGameTime();
        float delta = lastFrameTime <= 0.0f ? 0.0f : (now - lastFrameTime);
        lastFrameTime = now;
        if (delta > 0.25f) {
            // The editor only redraws on demand, so a long gap between frames would make the preview leap
            // forward. Clamping keeps it looking like motion rather than teleporting.
            delta = 0.25f;
        }
        preview.Update(delta * previewSpeed);
    }

    // ---- the scene's animation components ------------------------------------------------------------

    /// <summary>
    /// Finds every TweenyAnimation in every open scene.
    ///
    /// There is no lookup by component type in the scripting API, so the scenes are walked. Every loaded
    /// scene is visited rather than just the active one, because scenes open additively and an animation
    /// in one of the others is still on screen. The list is rebuilt each frame rather than cached: the
    /// user can delete an entity from the Hierarchy between two frames, and a stale handle would outlive
    /// it. That costs nothing while nobody is looking, because the editor only draws when asked to.
    /// </summary>
    private void CollectAnimations()
    {
        animations.resize(0);
        animationOwners.resize(0);

        int sceneCount = CometEngine::SceneManagement::SceneManager::GetScenesLoadedCount();
        for (int s = 0; s < sceneCount; s++) {
            CometEngine::SceneManagement::Scene scene =
                CometEngine::SceneManagement::SceneManager::GetSceneLoadedAt(s);
            if (!scene.IsValid() || !scene.IsLoaded()) {
                continue;
            }

            array<Entity@>@ roots = CometEngine::SceneManagement::Scene::GetRoots(scene);
            if (roots is null) {
                continue;
            }
            for (uint i = 0; i < roots.length(); i++) {
                CollectFrom(roots[i]);
            }
        }
    }

    private void CollectFrom(Entity@ entity)
    {
        if (entity is null) {
            return;
        }

        // GetAll rather than Get: an entity is allowed more than one of these, and Get would quietly show
        // the first and hide the rest.
        array<TweenyAnimation@>@ here = TweenyAnimation::GetAll(entity);
        if (here !is null) {
            for (uint i = 0; i < here.length(); i++) {
                if (here[i] is null || AlreadyListed(here[i])) {
                    continue;
                }
                animations.insertLast(here[i]);
                animationOwners.insertLast(entity);
            }
        }

        for (int i = 0; i < entity.childrenSize; i++) {
            CollectFrom(entity.GetChild(i));
        }
    }

    /// <summary>
    /// Whether a component is already in the list.
    ///
    /// The same entity can be reached more than once -- a scene can appear in the loaded list under more
    /// than one index, and an entity can be walked from two roots -- and each of those would put the same
    /// component in the table twice. Matching on the instance id settles it whatever the route was.
    /// </summary>
    /// <param name="animation">The component about to be added.</param>
    /// <returns>Returns true when it is already listed.</returns>
    private bool AlreadyListed(TweenyAnimation@ animation)
    {
        for (uint i = 0; i < animations.length(); i++) {
            if (animations[i] !is null && animations[i].instanceID == animation.instanceID) {
                return true;
            }
        }
        return false;
    }

    private void DrawAnimationTable()
    {
        GUI::SeparatorText("Animations in the scene");

        if (animations.length() == 0) {
            GUI::TextDisabled("No entity in this scene has a TweenyAnimation component.");
            return;
        }

        int flags = GUI::TableFlags::RowBg | GUI::TableFlags::BordersInnerV
            | GUI::TableFlags::BordersOuter | GUI::TableFlags::ScrollY
            | GUI::TableFlags::Resizable | GUI::TableFlags::SizingStretchProp;
        if (!GUI::BeginTable("animations", 5, flags)) {
            return;
        }

        GUI::TableSetupScrollFreeze(0, 1);
        GUI::TableSetupColumn("Entity", GUI::TableColumnFlags::WidthStretch, 2.0f);
        GUI::TableSetupColumn("Animates", GUI::TableColumnFlags::WidthStretch, 1.4f);
        GUI::TableSetupColumn("Duration", GUI::TableColumnFlags::WidthFixed, 80.0f);
        GUI::TableSetupColumn("Loops", GUI::TableColumnFlags::WidthFixed, 70.0f);
        GUI::TableSetupColumn("Controls",
            GUI::TableColumnFlags::WidthFixed | GUI::TableColumnFlags::NoResize
            | GUI::TableColumnFlags::NoReorder,
            GUI::GetFrameHeight() * 2.0f + 16.0f);
        GUI::TableHeadersRow();

        for (uint i = 0; i < animations.length(); i++) {
            DrawAnimationRow(int(i), animations[i], animationOwners[i]);
        }

        GUI::EndTable();
    }

    private void DrawAnimationRow(int index, TweenyAnimation@ animation, Entity@ owner)
    {
        if (animation is null) {
            return;
        }
        GUI::TableNextRow();
        GUI::PushIDNum(index);

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        DrawEntityLink(owner);

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        GUI::Text(AnimationTypeName(animation.animationType));

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        GUI::Text(formatFloat(animation.duration, "", 0, 2) + "s");

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        GUI::Text(animation.loops == -1 ? CometEditor::RawIcon::Infinity : "" + animation.loops);

        GUI::TableNextColumn();
        if (GUI::Button(CometEditor::RawIcon::Eye)) {
            PreviewAnimation(animation);
        }
        GUI::Tooltip("Preview this one");
        GUI::SameLine();
        GUI::BeginDisabled(!preview.IsPreviewing());
        if (GUI::Button(CometEditor::RawIcon::Undo)) {
            preview.Stop(true);
        }
        GUI::EndDisabled();
        GUI::Tooltip("Stop the preview and restore");

        GUI::PopID();
    }

    private string AnimationTypeName(TweenyAnimationType kind)
    {
        switch (kind) {
        case TweenyAnimationType::Move:          return "Move";
        case TweenyAnimationType::LocalMove:     return "Local move";
        case TweenyAnimationType::Scale:         return "Scale";
        case TweenyAnimationType::Rotate:        return "Rotate";
        case TweenyAnimationType::Fade:          return "Fade";
        case TweenyAnimationType::Tint:          return "Tint";
        case TweenyAnimationType::PunchPosition: return "Punch position";
        case TweenyAnimationType::PunchScale:    return "Punch scale";
        case TweenyAnimationType::ShakePosition: return "Shake position";
        case TweenyAnimationType::ShakeScale:    return "Shake scale";
        }
        return "Move";
    }

    // ---- the live tween list -------------------------------------------------------------------------

    private void DrawTweenTable()
    {
        GUI::SeparatorText("Active tweens");

        array<ITween@>@ tweens = Tweeny::AllTweens();
        if (tweens.length() == 0) {
            GUI::TextDisabled("Nothing is tweening right now.");
            return;
        }

        int flags = GUI::TableFlags::RowBg | GUI::TableFlags::BordersInnerV
            | GUI::TableFlags::BordersOuter | GUI::TableFlags::ScrollY
            | GUI::TableFlags::Resizable | GUI::TableFlags::SizingStretchProp;
        if (!GUI::BeginTable("tweens", 6, flags)) {
            return;
        }

        GUI::TableSetupScrollFreeze(0, 1);
        GUI::TableSetupColumn("Tween", GUI::TableColumnFlags::WidthStretch, 2.0f);
        GUI::TableSetupColumn("Target", GUI::TableColumnFlags::WidthStretch, 1.6f);
        GUI::TableSetupColumn("Progress", GUI::TableColumnFlags::WidthStretch, 1.6f);
        GUI::TableSetupColumn("Loops", GUI::TableColumnFlags::WidthFixed, 70.0f);
        GUI::TableSetupColumn("State", GUI::TableColumnFlags::WidthFixed, 80.0f);
        // Fixed and unreorderable: it carries buttons, and resizing it below their width would clip them.
        GUI::TableSetupColumn("Controls",
            GUI::TableColumnFlags::WidthFixed | GUI::TableColumnFlags::NoResize
            | GUI::TableColumnFlags::NoReorder,
            GUI::GetFrameHeight() * 4.0f + 24.0f);
        GUI::TableHeadersRow();

        for (uint i = 0; i < tweens.length(); i++) {
            ITween@ tween = tweens[i];
            if (tween is null) {
                continue;
            }
            DrawRow(int(i), tween);
        }

        GUI::EndTable();

        if (selected >= 0 && selected < int(tweens.length())) {
            DrawDetails(tweens[uint(selected)]);
        }
    }

    private void DrawRow(int index, ITween@ tween)
    {
        GUI::TableNextRow();
        GUI::PushIDNum(index);

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        if (GUI::Selectable(NameOf(index, tween), selected == index,
                GUI::SelectableFlags::SpanAllColumns | GUI::SelectableFlags::AllowOverlap)) {
            selected = index;
        }

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        DrawEntityLink(EntityOf(tween), index);

        GUI::TableNextColumn();
        DrawProgress(tween);

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        int loops = tween.GetLoops();
        GUI::Text(loops == -1
            ? (tween.GetCompletedLoops() + " / " + CometEditor::RawIcon::Infinity)
            : (tween.GetCompletedLoops() + " / " + loops));

        GUI::TableNextColumn();
        GUI::AlignTextToFramePadding();
        DrawState(tween);

        GUI::TableNextColumn();
        DrawRowActions(tween);

        GUI::PopID();
    }

    /// <summary>
    /// The entity a tween is animating, as a link that selects it.
    ///
    /// A tween's target is a component, not an entity, and a component carries no name of its own -- which
    /// is why printing the target's name gave a blank column. What is useful is the entity it belongs to,
    /// and being able to click it and have the hierarchy jump there.
    /// </summary>
    /// <param name="entity">The entity to show, or null.</param>
    private void DrawEntityLink(Entity@ entity, int row = -1)
    {
        if (entity is null || !Object::IsValid(entity)) {
            GUI::TextDisabled("--");
            return;
        }
        if (GUI::Selectable(entity.name, false)) {
            FocusInHierarchy(entity);
            // Clicking the target picks its row too, so the details below follow what was just clicked
            // instead of staying on whatever was selected before.
            if (row >= 0) {
                selected = row;
            }
        }
        GUI::Tooltip("Select this entity");
    }

    /// <summary>
    /// Selects an entity and reveals it in the Hierarchy: expands its parents, scrolls its row into view
    /// and flashes it.
    ///
    /// Selecting on its own is not enough. It only marks the entity, so a row collapsed inside a parent or
    /// scrolled off the end of a long list shows nothing at all and the click looks like it did nothing.
    ///
    /// The reveal goes through the editor's bridge function rather than a namespaced wrapper because the
    /// wrappers live in the internal script module, which the editor loads from bytecode compiled into the
    /// executable. The bridge functions are registered when the editor starts, so this resolves against the
    /// engine that is actually running.
    /// </summary>
    /// <param name="entity">The entity to select and reveal.</param>
    private void FocusInHierarchy(Entity@ entity)
    {
        CometEditor::Selection::Set(entity);
        __Selection__Ping(entity);
    }

    /// <summary>
    /// Resolves a tween's target to the entity that owns it.
    /// </summary>
    /// <param name="tween">The tween to inspect.</param>
    /// <returns>Returns the entity, or null when the target is gone or is not a component.</returns>
    private Entity@ EntityOf(ITween@ tween)
    {
        Object@ target = tween.GetTarget();
        if (target is null || !Object::IsValid(target)) {
            return null;
        }
        Behaviour@ behaviour = cast<Behaviour@>(target);
        if (behaviour !is null) {
            return behaviour.entity;
        }
        return cast<Entity@>(target);
    }

    private void DrawProgress(ITween@ tween)
    {
        // The bar tracks the CURRENT loop, not the whole run. Against the full duration a looping tween
        // barely creeps and an endless one never moves at all; against the loop it sweeps and starts over
        // each cycle, which is what the tween is actually doing.
        float duration = tween.GetDuration();
        float fraction = duration <= 0.0f ? 0.0f : tween.GetPosition() / duration;
        if (fraction < 0.0f) { fraction = 0.0f; }
        if (fraction > 1.0f) { fraction = 1.0f; }

        float full = tween.GetFullDuration(true);
        float elapsed = tween.GetElapsed(true);

        float width = GUI::GetContentRegionAvail().x;
        float height = GUI::GetFrameHeight() * 0.55f;
        Vector2 origin = GUI::GetCursorScreenPos();
        origin.y += (GUI::GetFrameHeight() - height) * 0.5f;
        Vector2 far = Vector2(origin.x + width, origin.y + height);

        GUI::DrawRectFilled(origin, far, GUI::GetStyleColor(GUI::Col::FrameBg), 2.0f);
        if (fraction > 0.0f) {
            GUI::DrawRectFilled(origin, Vector2(origin.x + width * fraction, far.y),
                GUI::GetStyleColor(GUI::Col::PlotHistogram), 2.0f);
        }
        GUI::Dummy(Vector2(width, GUI::GetFrameHeight()));
        GUI::Tooltip(formatFloat(tween.GetPosition(), "", 0, 2) + "s of "
            + formatFloat(duration, "", 0, 2) + "s this loop, "
            + formatFloat(elapsed, "", 0, 2) + "s in total"
            + (tween.GetLoops() == -1 ? " (endless)" : " of " + formatFloat(full, "", 0, 2) + "s"));
    }

    private void DrawState(ITween@ tween)
    {
        if (tween.IsComplete()) {
            GUI::TextDisabled("complete");
            return;
        }
        if (!tween.IsPlaying()) {
            GUI::TextDisabled("paused");
            return;
        }
        GUI::TextColored(GUI::GetStyleColor(GUI::Col::CheckMark),
            tween.IsBackwards() ? "backwards" : "playing");
    }

    private void DrawRowActions(ITween@ tween)
    {
        Vector2 square = Vector2(GUI::GetFrameHeight(), GUI::GetFrameHeight());

        if (GUI::Button(CometEditor::RawIcon::Play, square)) { tween.Play(); }
        GUI::Tooltip("Play");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Pause, square)) { tween.Pause(); }
        GUI::Tooltip("Pause");
        GUI::SameLine();
        // Stop is rewind-and-pause, which is what stopping an animation means: back to the start, not
        // playing. Killing is the separate, destructive one.
        if (GUI::Button(CometEditor::RawIcon::Stop, square)) { tween.Rewind(true); }
        GUI::Tooltip("Stop and rewind");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Trash, square)) { tween.Kill(false); }
        GUI::Tooltip("Kill");
    }

    private string NameOf(int index, ITween@ tween)
    {
        if (!tween.GetStringId().isEmpty()) {
            return tween.GetStringId();
        }
        if (tween.GetIntId() != -999) {
            return "id " + tween.GetIntId();
        }
        return "#" + index;
    }

    /// <summary>
    /// The settings behind the selected row, laid out the way the inspector lays out a component.
    ///
    /// The table can only carry what fits in a column. Everything that decides how a tween behaves -- its
    /// delay, its easing, which update phase drives it -- lives here, and it is what you actually need when
    /// a tween is not doing what you expected.
    /// </summary>
    /// <param name="tween">The selected tween.</param>
    private void DrawDetails(ITween@ tween)
    {
        if (tween is null) {
            return;
        }

        GUI::SeparatorText("Selected");

        Row("Id", tween.GetStringId().isEmpty()
            ? (tween.GetIntId() == -999 ? "none" : "" + tween.GetIntId())
            : tween.GetStringId());
        Row("Duration", formatFloat(tween.GetDuration(), "", 0, 2) + "s"
            + (tween.GetLoops() == -1 ? ", looping forever"
                                      : ", " + formatFloat(tween.GetFullDuration(true), "", 0, 2) + "s in total"));
        Row("Position", formatFloat(tween.GetPosition(), "", 0, 2) + "s into the current loop");
        Row("Delay", tween.GetDelay() <= 0.0f
            ? "none"
            : (formatFloat(tween.GetElapsedDelay(), "", 0, 2) + "s of "
               + formatFloat(tween.GetDelay(), "", 0, 2) + "s"));
        Row("Update", UpdateTypeName(tween.GetUpdateType())
            + (tween.IsIndependentUpdate() ? ", ignores time scale" : ""));
        Row("Sequenced", tween.IsSequenced() ? "yes, driven by a sequence" : "no");
    }

    /// <summary>Draws one read-only property row in the editor's standard layout.</summary>
    /// <param name="name">The field name.</param>
    /// <param name="value">The value to show.</param>
    private void Row(const string&in name, const string&in value)
    {
        GUI::StandardFieldName(name);
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        GUI::Text(value);
    }

    private string UpdateTypeName(UpdateType kind)
    {
        switch (kind) {
        case UpdateType::Normal: return "Normal";
        case UpdateType::Late:   return "Late";
        case UpdateType::Fixed:  return "Fixed";
        case UpdateType::Manual: return "Manual";
        }
        return "Normal";
    }

    void OnDestroy()
    {
        if (preview.IsPreviewing()) {
            preview.Stop(restoreOnStop);
        }
    }
}
