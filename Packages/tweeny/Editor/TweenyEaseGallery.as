using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Picks an easing curve by eye and hands back the line of code for it.
///
/// Choosing an ease from a dropdown is guesswork: the names describe the maths, not how the motion feels.
/// This lists every curve, plots the selected one large enough to read, and runs a marker along it so the
/// pacing is visible and not just the shape. The parameters shown are only the ones the selected curve
/// actually reads, because Back, Elastic and Flash are the only families that take any.
/// </summary>
[MainMenuItemWindow("Tweeny/Ease Gallery", "Tweeny Ease Gallery")] class TweenyEaseGallery : EditorWindow
{
    /// One curve in the list, with the family it belongs to so the list can be grouped.
    private array<Ease> eases;
    private array<string> names;
    private array<string> families;

    private int selected = 0;
    private string filter = "";

    private float overshoot = DEFAULT_OVERSHOOT;
    private float period = DEFAULT_PERIOD;
    private float flashes = 4.0f;
    private float speed = 1.0f;
    private bool animate = true;
    private float playhead = 0.0f;

    /// Width of the curve list. Roughly the widest curve name plus room for the scrollbar.
    private float LIST_WIDTH = 190.0f;
    /// How many segments the plotted curve is drawn with. One curve at this resolution is a handful of
    /// draw calls a frame; the whole set plotted at once was thousands, and the editor felt it.
    private int PLOT_SAMPLES = 72;

    CometEditor::WindowConfig OnGetWindowConfig()
    {
        CometEditor::WindowConfig config;
        config.initialSize = Vector2i(820, 460);
        config.initialPositionType = CometEditor::WindowConfigPositionType::CENTERED;
        config.iconRaw = CometEditor::RawIcon::ChartLine;
        return config;
    }

    void Awake()
    {
        BuildList();
    }

    void OnGUI()
    {
        if (eases.length() == 0) {
            BuildList();
        }

        if (animate) {
            CometEditor::EditorApplication::RequestRedraw();

            playhead += Time::GetUnscaledDeltaTime() * speed * 0.5f;
            while (playhead > 1.0f) {
                playhead -= 1.0f;
            }
        }

        DrawList();
        GUI::SameLine();
        DrawDetail();
    }

    // ---- the curve list ------------------------------------------------------------------------------

    private void DrawList()
    {
        GUI::BeginChild("curves", LIST_WIDTH, 0.0f, GUI::ChildFlags::Borders);

        DrawSearchField();
        GUI::Spacing();

        string lastFamily = "";
        for (uint i = 0; i < eases.length(); i++) {
            if (!Matches(names[i])) {
                continue;
            }
            if (families[i] != lastFamily) {
                lastFamily = families[i];
                GUI::TextDisabled(lastFamily);
            }
            GUI::Indent();
            if (GUI::Selectable(names[i], int(i) == selected)) {
                selected = int(i);
            }
            GUI::Unindent();
        }

        GUI::EndChild();
    }

    /// <summary>
    /// The editor's own search field: magnifier to the left, and a clear button overlaid on the right end
    /// of the box once there is something to clear.
    ///
    /// The engine draws this shape from one shared helper, which is not reachable from script, so it is
    /// reproduced here call for call: the magnifier is a separate text item rather than a placeholder, the
    /// clear button sits inside the frame so the row never changes width, and the field is marked as
    /// allowing overlap -- without that the input swallows the mouse and the button can never be clicked.
    /// </summary>
    private void DrawSearchField()
    {
        float clearWidth = 22.0f;
        float spacing = GUI::GetStyleVarVector(GUI::StyleVar::ItemSpacing).x;

        GUI::AlignTextToFramePadding();
        GUI::TextDisabled(CometEditor::RawIcon::Search);
        GUI::SameLine();

        float boxWidth = GUI::GetContentRegionAvail().x;
        if (boxWidth < 40.0f) {
            boxWidth = 40.0f;
        }

        bool edited = false;
        GUI::SetNextItemWidth(boxWidth);
        GUI::SetNextItemAllowOverlap();
        filter = GUI::InputText("##filter", filter, edited, GUI::InputTextFlags::AutoSelectAll);

        Vector2 frameMin = GUI::GetItemRectMin();
        Vector2 frameMax = GUI::GetItemRectMax();

        if (filter.isEmpty()) {
            Vector2 padding = GUI::GetStyleVarVector(GUI::StyleVar::FramePadding);
            GUI::DrawText(Vector2(frameMin.x + padding.x, frameMin.y + padding.y),
                GUI::GetStyleColor(GUI::Col::TextDisabled), "Search");
            return;
        }

        GUI::PushIDString("clearFilter");
        GUI::SetCursorScreenPos(Vector2(frameMax.x - clearWidth, frameMin.y));

        Color transparent = Color(0.0f, 0.0f, 0.0f, 0.0f);
        GUI::PushStyleColor(int(GUI::Col::Button), transparent);
        GUI::PushStyleColor(int(GUI::Col::ButtonHovered), transparent);
        GUI::PushStyleColor(int(GUI::Col::ButtonActive), transparent);
        if (GUI::Button(CometEditor::RawIcon::TimesCircle, Vector2(clearWidth, frameMax.y - frameMin.y))) {
            filter = "";
        }
        GUI::PopStyleColor(3);
        GUI::PopID();

        GUI::SetCursorScreenPos(Vector2(frameMin.x, frameMax.y + spacing));
    }

    private bool Matches(const string&in name)
    {
        if (filter.isEmpty()) {
            return true;
        }
        return Lowered(name).findFirst(Lowered(filter)) >= 0;
    }

    /// <summary>
    /// Lowercases ASCII by hand, because the scripting string type has no case conversion of its own.
    /// </summary>
    /// <param name="text">The text to fold.</param>
    /// <returns>Returns the folded text.</returns>
    private string Lowered(const string&in text)
    {
        string folded = text;
        for (uint i = 0; i < folded.length(); i++) {
            uint8 character = folded[i];
            if (character >= 65 && character <= 90) {
                folded[i] = character + 32;
            }
        }
        return folded;
    }

    // ---- the selected curve --------------------------------------------------------------------------

    private void DrawDetail()
    {
        GUI::BeginChild("detail", 0.0f, 0.0f);

        if (selected < 0 || selected >= int(eases.length())) {
            selected = 0;
        }
        Ease current = eases[uint(selected)];

        GUI::SeparatorText(names[uint(selected)]);

        float plotHeight = GUI::GetContentRegionAvail().y - ControlsHeight(current);
        if (plotHeight < 90.0f) {
            plotHeight = 90.0f;
        }
        DrawPlot(current, plotHeight);

        GUI::Spacing();
        DrawMotionStrip(current);
        GUI::Spacing();

        DrawParameters(current);

        GUI::EndChild();
    }

    /// <summary>
    /// Exact height of everything drawn below the plot, so the plot can be given the rest.
    ///
    /// What sits below it is the motion strip, then one row per control -- always the animate toggle and the
    /// preview speed, plus one for each parameter the selected curve uses -- then the copy row, and the
    /// spacings between them.
    /// </summary>
    /// <param name="current">The selected curve, which decides how many parameter rows there are.</param>
    /// <returns>Returns the height in pixels.</returns>
    private float ControlsHeight(Ease current)
    {
        int rows = 2;
        if (UsesOvershoot(current)) { rows++; }
        if (UsesPeriod(current)) { rows++; }
        if (UsesFlashes(current)) { rows++; }

        float spacing = GUI::GetStyleVarVector(GUI::StyleVar::ItemSpacing).y;
        return GUI::GetFrameHeight()
            + GUI::GetFrameHeightWithSpacing() * float(rows)
            + GUI::GetFrameHeightWithSpacing()
            + spacing * 4.0f;
    }

    /// <summary>
    /// Width available for the plot and the motion strip, kept off the right-hand edge.
    /// </summary>
    /// <returns>Returns the width in pixels.</returns>
    private float ContentWidth()
    {
        float width = GUI::GetContentRegionAvail().x - GUI::GetStyleVarVector(GUI::StyleVar::ItemSpacing).x;
        return width < 60.0f ? 60.0f : width;
    }

    private void DrawPlot(Ease current, float height)
    {
        float width = ContentWidth();
        Vector2 origin = GUI::GetCursorScreenPos();
        Vector2 topLeft = origin;
        Vector2 bottomRight = Vector2(origin.x + width, origin.y + height);

        Color frame = GUI::GetStyleColor(GUI::Col::Border);
        Color guide = GUI::GetStyleColor(GUI::Col::TableBorderLight);
        Color curveColor = GUI::GetStyleColor(GUI::Col::PlotLines);
        Color markerColor = GUI::GetStyleColor(GUI::Col::PlotHistogram);
        Color faint = GUI::GetStyleColor(GUI::Col::TextDisabled);

        GUI::DrawRectFilled(topLeft, bottomRight, GUI::GetStyleColor(GUI::Col::FrameBg), 3.0f);
        GUI::DrawRect(topLeft, bottomRight, frame, 3.0f);

        float pad = height * 0.24f;
        float yZero = bottomRight.y - pad;
        float yOne = topLeft.y + pad;
        GUI::DrawLine(Vector2(topLeft.x, yZero), Vector2(bottomRight.x, yZero), guide);
        GUI::DrawLine(Vector2(topLeft.x, yOne), Vector2(bottomRight.x, yOne), guide);
        GUI::DrawText(Vector2(topLeft.x + 6.0f, yOne - 16.0f), faint, "1");
        GUI::DrawText(Vector2(topLeft.x + 6.0f, yZero + 2.0f), faint, "0");

        float amplitude = UsesFlashes(current) ? flashes : overshoot;
        Vector2 previous;
        for (int s = 0; s <= PLOT_SAMPLES; s++) {
            float progress = float(s) / float(PLOT_SAMPLES);
            float value = EaseManager::Evaluate(current, null, progress, 1.0f, amplitude, period);
            Vector2 point = Vector2(topLeft.x + width * progress, yZero - (yZero - yOne) * value);
            if (s > 0) {
                GUI::DrawLine(previous, point, curveColor, 2.0f);
            }
            previous = point;
        }

        if (animate) {
            float headValue = EaseManager::Evaluate(current, null, playhead, 1.0f, amplitude, period);
            Vector2 head = Vector2(topLeft.x + width * playhead, yZero - (yZero - yOne) * headValue);
            GUI::DrawLine(Vector2(head.x, topLeft.y), Vector2(head.x, bottomRight.y), guide);
            GUI::DrawCircleFilled(head, 4.0f, markerColor);
        }

        GUI::Dummy(Vector2(width, height));
    }

    /// <summary>
    /// A marker running left to right on the curve's own timing, which is the part a graph cannot show.
    /// </summary>
    /// <param name="current">The curve being previewed.</param>
    private void DrawMotionStrip(Ease current)
    {
        float width = ContentWidth();
        float height = GUI::GetFrameHeight();
        Vector2 origin = GUI::GetCursorScreenPos();
        Vector2 bottomRight = Vector2(origin.x + width, origin.y + height);

        GUI::DrawRectFilled(origin, bottomRight, GUI::GetStyleColor(GUI::Col::FrameBg), 3.0f);
        GUI::DrawRect(origin, bottomRight, GUI::GetStyleColor(GUI::Col::Border), 3.0f);

        float amplitude = UsesFlashes(current) ? flashes : overshoot;
        float value = animate ? EaseManager::Evaluate(current, null, playhead, 1.0f, amplitude, period) : 0.0f;
        float inset = height * 0.5f;
        float x = origin.x + inset + (width - inset * 2.0f) * value;
        GUI::DrawCircleFilled(Vector2(x, origin.y + height * 0.5f), height * 0.28f,
            GUI::GetStyleColor(GUI::Col::CheckMark));

        GUI::Dummy(Vector2(width, height));
    }

    private void DrawParameters(Ease current)
    {
        bool edited = false;

        GUI::StandardFieldName("Animate", "Runs a marker along the curve so its pacing is visible.");
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        animate = GUI::Checkbox("##animate", animate, edited);

        GUI::BeginDisabled(!animate);
        GUI::StandardFieldName("Preview speed", "How fast the marker sweeps. Does not change the curve.");
        GUI::SetCursorAtStandardPropertyWidgetPosition();
        GUI::SetNextItemWidthToStandardPropertyWidget();
        speed = GUI::SliderFloat("##speed", speed, 0.1f, 3.0f, edited);
        GUI::EndDisabled();

        if (UsesOvershoot(current)) {
            GUI::StandardFieldName(UsesPeriod(current) ? "Amplitude" : "Overshoot",
                "How far past the destination the curve reaches.");
            GUI::SetCursorAtStandardPropertyWidgetPosition();
            GUI::SetNextItemWidthToStandardPropertyWidget();
            overshoot = GUI::SliderFloat("##overshoot", overshoot, 0.0f, 6.0f, edited);
        }

        if (UsesPeriod(current)) {
            GUI::StandardFieldName("Period", "How tight the springing is.");
            GUI::SetCursorAtStandardPropertyWidgetPosition();
            GUI::SetNextItemWidthToStandardPropertyWidget();
            period = GUI::SliderFloat("##period", period, -1.0f, 2.0f, edited);
        }

        if (UsesFlashes(current)) {
            GUI::StandardFieldName("Flashes", "How many times the value blinks.");
            GUI::SetCursorAtStandardPropertyWidgetPosition();
            GUI::SetNextItemWidthToStandardPropertyWidget();
            flashes = GUI::SliderFloat("##flashes", flashes, 1.0f, 12.0f, edited);
        }

        GUI::Spacing();
        string code = CodeFor(current);
        if (GUI::Button(CometEditor::RawIcon::Clipboard + "  Copy")) {
            GUI::SetClipboardText(code);
        }
        GUI::Tooltip("Copies the call to the clipboard.");
        GUI::SameLine();
        GUI::TextDisabled(code);
    }

    /// <summary>
    /// The call that reproduces what the window is showing, parameters and all.
    /// </summary>
    /// <param name="current">The selected curve.</param>
    /// <returns>Returns a line of AngelScript.</returns>
    private string CodeFor(Ease current)
    {
        string call = "SetEase(Ease::" + names[uint(selected)];
        if (UsesPeriod(current)) {
            call += ", " + formatFloat(overshoot, "", 0, 2) + "f, " + formatFloat(period, "", 0, 2) + "f";
        }
        else if (UsesOvershoot(current)) {
            call += ", " + formatFloat(overshoot, "", 0, 2) + "f";
        }
        else if (UsesFlashes(current)) {
            call += ", " + formatFloat(flashes, "", 0, 0) + "f";
        }
        return call + ")";
    }

    private bool UsesOvershoot(Ease value)
    {
        return value == Ease::InBack || value == Ease::OutBack || value == Ease::InOutBack
            || UsesPeriod(value);
    }

    private bool UsesPeriod(Ease value)
    {
        return value == Ease::InElastic || value == Ease::OutElastic || value == Ease::InOutElastic;
    }

    private bool UsesFlashes(Ease value)
    {
        return value == Ease::Flash || value == Ease::InFlash
            || value == Ease::OutFlash || value == Ease::InOutFlash;
    }

    private void Add(Ease value, const string&in name, const string&in family)
    {
        eases.insertLast(value);
        names.insertLast(name);
        families.insertLast(family);
    }

    private void BuildList()
    {
        eases.resize(0);
        names.resize(0);
        families.resize(0);

        Add(Ease::Linear, "Linear", "Linear");

        Add(Ease::InSine, "InSine", "Sine");
        Add(Ease::OutSine, "OutSine", "Sine");
        Add(Ease::InOutSine, "InOutSine", "Sine");

        Add(Ease::InQuad, "InQuad", "Power");
        Add(Ease::OutQuad, "OutQuad", "Power");
        Add(Ease::InOutQuad, "InOutQuad", "Power");
        Add(Ease::InCubic, "InCubic", "Power");
        Add(Ease::OutCubic, "OutCubic", "Power");
        Add(Ease::InOutCubic, "InOutCubic", "Power");
        Add(Ease::InQuart, "InQuart", "Power");
        Add(Ease::OutQuart, "OutQuart", "Power");
        Add(Ease::InOutQuart, "InOutQuart", "Power");
        Add(Ease::InQuint, "InQuint", "Power");
        Add(Ease::OutQuint, "OutQuint", "Power");
        Add(Ease::InOutQuint, "InOutQuint", "Power");

        Add(Ease::InExpo, "InExpo", "Exponential");
        Add(Ease::OutExpo, "OutExpo", "Exponential");
        Add(Ease::InOutExpo, "InOutExpo", "Exponential");

        Add(Ease::InCirc, "InCirc", "Circular");
        Add(Ease::OutCirc, "OutCirc", "Circular");
        Add(Ease::InOutCirc, "InOutCirc", "Circular");

        Add(Ease::InElastic, "InElastic", "Elastic");
        Add(Ease::OutElastic, "OutElastic", "Elastic");
        Add(Ease::InOutElastic, "InOutElastic", "Elastic");

        Add(Ease::InBack, "InBack", "Back");
        Add(Ease::OutBack, "OutBack", "Back");
        Add(Ease::InOutBack, "InOutBack", "Back");

        Add(Ease::InBounce, "InBounce", "Bounce");
        Add(Ease::OutBounce, "OutBounce", "Bounce");
        Add(Ease::InOutBounce, "InOutBounce", "Bounce");

        Add(Ease::Flash, "Flash", "Flash");
        Add(Ease::InFlash, "InFlash", "Flash");
        Add(Ease::OutFlash, "OutFlash", "Flash");
        Add(Ease::InOutFlash, "InOutFlash", "Flash");
    }
}
