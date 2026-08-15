using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Shows every live tween and lets them be driven by hand.
///
/// Tweens are invisible while they run: when one misbehaves there is normally nothing to look at. This
/// lists the active ones with their progress and state, gives each row the same controls the scripting API
/// has, and can play the whole set inside the editor without entering play mode.
/// </summary>
[MainMenuItemWindow("Tweeny/Tweeny Inspector", "Tweeny Inspector")] class TweenyInspectorWindow : EditorWindow
{
    private TweenyPreview preview;
    private float previewSpeed = 1.0f;
    private bool restoreOnStop = true;
    private float lastFrameTime = 0.0f;
    private int selected = -1;

    CometEditor::WindowConfig OnGetWindowConfig()
    {
        CometEditor::WindowConfig config;
        config.initialSize = Vector2i(760, 420);
        config.initialPositionType = CometEditor::WindowConfigPositionType::CENTERED;
        config.iconRaw = CometEditor::RawIcon::SlidersH;
        return config;
    }

    void OnGUI()
    {
        DrawHeader();
        GUI::Spacing();
        DrawPreviewSection();
        GUI::Spacing();
        DrawTable();

        AdvancePreview();
    }

    // ---- header --------------------------------------------------------------------------------------

    private void DrawHeader()
    {
        int total = Tweeny::TotalActiveTweens();
        int playing = Tweeny::TotalPlayingTweens();

        GUI::AlignTextToFramePadding();
        GUI::Text(total + (total == 1 ? " tween" : " tweens"));
        GUI::SameLine();
        GUI::TextDisabled("(" + playing + " playing)");

        // The bulk controls sit right-aligned on the same line, which is where every other Comet panel puts
        // the actions that apply to a whole list. SameLine takes an absolute X inside the window, so this
        // is measured back from the right edge rather than forward from the text.
        float button = GUI::GetFrameHeight() + GUI::GetStyleVarVector(GUI::StyleVar::ItemSpacing).x;
        float right = GUI::GetWindowSize().x - button * 4.0f - 12.0f;
        if (right > GUI::GetCursorPosX()) {
            GUI::SameLine(right);
        }
        else {
            GUI::SameLine();
        }

        GUI::BeginDisabled(total == 0);
        if (GUI::Button(CometEditor::RawIcon::Play)) { Tweeny::PlayAll(); }
        GUI::Tooltip("Play every tween");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Pause)) { Tweeny::PauseAll(); }
        GUI::Tooltip("Pause every tween");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Backward)) { Tweeny::RewindAll(true); }
        GUI::Tooltip("Rewind every tween");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Trash)) { Tweeny::KillAll(false); }
        GUI::Tooltip("Kill every tween");
        GUI::EndDisabled();
    }

    // ---- preview -------------------------------------------------------------------------------------

    private void DrawPreviewSection()
    {
        GUI::SeparatorText("Preview");

        bool previewing = preview.IsPreviewing();
        bool edited = false;

        GUI::StandardFieldName("Speed", "Multiplies the preview clock. It does not change the tweens.");
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        GUI::SetNextItemWidthToStandardPropertyWidget();
        previewSpeed = GUI::SliderFloat("##speed", previewSpeed, 0.05f, 4.0f, edited);

        GUI::StandardFieldName("Restore on close",
            "Puts every target back where it was if the window closes mid-preview.");
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        restoreOnStop = GUI::Checkbox("##restore", restoreOnStop, edited);

        GUI::SetCursorAtStandardFieldPosition();
        if (!previewing) {
            GUI::BeginDisabled(Tweeny::TotalActiveTweens() == 0);
            if (GUI::Button(CometEditor::RawIcon::Eye + "  Preview in editor")) {
                StartPreview();
            }
            GUI::EndDisabled();
            GUI::SameLine();
            GUI::TextDisabled("Runs the tweens here, then puts every target back.");
        }
        else {
            if (GUI::Button(CometEditor::RawIcon::Undo + "  Stop and restore")) {
                preview.Stop(true);
            }
            GUI::SameLine();
            if (GUI::Button(CometEditor::RawIcon::Check + "  Stop and keep")) {
                preview.Stop(false);
            }
            GUI::SameLine();
            GUI::TextDisabled(preview.GetCount() + " previewing, "
                + formatFloat(preview.GetElapsed(), "", 0, 2) + "s elapsed");
        }
    }

    private void StartPreview()
    {
        array<ITween@>@ tweens = Tweeny::AllTweens();
        for (uint i = 0; i < tweens.length(); i++) {
            preview.Add(tweens[i]);
        }
    }

    private void AdvancePreview()
    {
        if (!preview.IsPreviewing()) {
            lastFrameTime = 0.0f;
            return;
        }
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

    // ---- the list ------------------------------------------------------------------------------------

    private void DrawTable()
    {
        GUI::SeparatorText("Active tweens");

        array<ITween@>@ tweens = Tweeny::AllTweens();
        if (tweens.length() == 0) {
            GUI::TextDisabled("Nothing is tweening right now.");
            return;
        }

        int flags = GUI::TableFlags::RowBg | GUI::TableFlags::BordersInnerV | GUI::TableFlags::BordersOuter
            | GUI::TableFlags::ScrollY | GUI::TableFlags::Resizable | GUI::TableFlags::SizingStretchProp;
        if (!GUI::BeginTable("tweens", 6, flags)) {
            return;
        }

        GUI::TableSetupScrollFreeze(0, 1);
        GUI::TableSetupColumn("Tween", GUI::TableColumnFlags::WidthStretch, 2.0f);
        GUI::TableSetupColumn("Target", GUI::TableColumnFlags::WidthStretch, 1.6f);
        GUI::TableSetupColumn("Progress", GUI::TableColumnFlags::WidthStretch, 1.6f);
        GUI::TableSetupColumn("Loops", GUI::TableColumnFlags::WidthFixed, 70.0f);
        GUI::TableSetupColumn("State", GUI::TableColumnFlags::WidthFixed, 80.0f);
        // The actions column carries buttons, so it neither needs a heading nor benefits from being sorted
        // or resized to something the buttons do not fit in.
        GUI::TableSetupColumn("Actions",
            GUI::TableColumnFlags::WidthFixed | GUI::TableColumnFlags::NoHeaderLabel
            | GUI::TableColumnFlags::NoResize | GUI::TableColumnFlags::NoReorder,
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

    /// <summary>
    /// The settings behind the selected row, laid out the way the inspector lays out a component.
    ///
    /// The table can only carry what fits in a column. Everything that decides how a tween behaves --
    /// its delay, its easing, which update phase drives it -- lives here, and it is what you actually need
    /// when a tween is not doing what you expected.
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
                                      : ", " + tween.GetFullDuration(true) + "s in total"));
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
        Object@ target = tween.GetTarget();
        if (target !is null && Object::IsValid(target)) {
            GUI::Text(target.name);
        }
        else {
            GUI::TextDisabled("--");
        }

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

    private void DrawProgress(ITween@ tween)
    {
        float full = tween.GetFullDuration(true);
        float elapsed = tween.GetElapsed(true);
        float fraction = full <= 0.0f ? 0.0f : elapsed / full;
        if (fraction < 0.0f) { fraction = 0.0f; }
        if (fraction > 1.0f) { fraction = 1.0f; }

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
        GUI::Tooltip(formatFloat(elapsed, "", 0, 2) + "s of "
            + (tween.GetLoops() == -1 ? "an endless tween" : formatFloat(full, "", 0, 2) + "s"));
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
        if (GUI::Button(tween.IsPlaying() ? CometEditor::RawIcon::Pause : CometEditor::RawIcon::Play)) {
            if (tween.IsPlaying()) { tween.Pause(); } else { tween.Play(); }
        }
        GUI::Tooltip(tween.IsPlaying() ? "Pause" : "Play");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Backward)) { tween.Rewind(true); }
        GUI::Tooltip("Rewind");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::StepForward)) { tween.Complete(false); }
        GUI::Tooltip("Jump to the end");
        GUI::SameLine();
        if (GUI::Button(CometEditor::RawIcon::Times)) { tween.Kill(false); }
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

    void OnDestroy()
    {
        if (preview.IsPreviewing()) {
            preview.Stop(restoreOnStop);
        }
    }
}
