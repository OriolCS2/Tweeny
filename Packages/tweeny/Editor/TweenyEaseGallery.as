using namespace CometEngine;
using namespace CometEditor;
using namespace Tweeny;

/// <summary>
/// Plots every built-in easing curve so they can be compared against the reference graphs by eye.
/// A live playhead sweeps across the curves so the pacing of each ease is visible, not just its shape.
/// </summary>
[MainMenuItemWindow("Tweeny/Ease Gallery", "Tweeny Ease Gallery")] class TweenyEaseGallery : EditorWindow
{
    private array<Ease> eases;
    private array<string> names;

    private float overshoot = DEFAULT_OVERSHOOT;
    private float period = DEFAULT_PERIOD;
    private float flashAmplitude = 4.0f;
    private int columns = 4;
    private float cellHeight = 110.0f;
    private bool animate = true;
    private float playhead = 0.0f;

    void Awake()
    {
        BuildList();
    }

    void OnGUI()
    {
        if (eases.length() == 0) {
            BuildList();
        }

        DrawToolbar();
        GUI::Separator();

        if (animate) {
            playhead += Time::GetUnscaledDeltaTime() * 0.5f;
            while (playhead > 1.0f) {
                playhead -= 1.0f;
            }
        }

        float available = GUI::GetContentRegionAvail().x;
        float spacing = 6.0f;
        float cellWidth = (available - spacing * float(columns - 1)) / float(columns);
        if (cellWidth < 40.0f) {
            cellWidth = 40.0f;
        }

        for (uint i = 0; i < eases.length(); i++) {
            if (i % uint(columns) != 0) {
                GUI::SameLine(0.0f, spacing);
            }
            DrawCell(eases[i], names[i], cellWidth, cellHeight);
        }
    }

    private void DrawToolbar()
    {
        bool edited = false;
        overshoot = GUI::SliderFloat("Overshoot / amplitude", overshoot, 0.0f, 6.0f, edited);
        period = GUI::SliderFloat("Period", period, -1.0f, 2.0f, edited);
        flashAmplitude = GUI::SliderFloat("Flash count", flashAmplitude, 1.0f, 12.0f, edited);
        animate = GUI::Checkbox("Animate playhead", animate, edited);
        GUI::SameLine();
        GUI::TextDisabled("  " + eases.length() + " curves");
    }

    private void DrawCell(Ease easeType, const string&in label, float width, float height)
    {
        GUI::BeginChild("cell" + int(easeType), width, height);

        Vector2 origin = GUI::GetCursorScreenPos();
        float plotTop = origin.y + 16.0f;
        float plotHeight = height - 30.0f;
        float plotWidth = width - 12.0f;
        float plotLeft = origin.x + 6.0f;

        Color frame = Color(0.35f, 0.40f, 0.39f, 1.0f);
        Color guide = Color(0.25f, 0.29f, 0.28f, 1.0f);
        Color curve = Color(0.31f, 0.80f, 0.75f, 1.0f);
        Color marker = Color(0.95f, 0.72f, 0.35f, 1.0f);

        GUI::DrawText(Vector2(plotLeft, origin.y), Color(0.85f, 0.90f, 0.89f, 1.0f), label);
        GUI::DrawRect(Vector2(plotLeft, plotTop), Vector2(plotLeft + plotWidth, plotTop + plotHeight), frame);

        // The 0 and 1 guide lines sit inside a padded band so overshoot stays visible.
        float pad = plotHeight * 0.22f;
        float yZero = plotTop + plotHeight - pad;
        float yOne = plotTop + pad;
        GUI::DrawLine(Vector2(plotLeft, yZero), Vector2(plotLeft + plotWidth, yZero), guide);
        GUI::DrawLine(Vector2(plotLeft, yOne), Vector2(plotLeft + plotWidth, yOne), guide);

        float amplitude = IsFlash(easeType) ? flashAmplitude : overshoot;

        const int SAMPLES = 48;
        Vector2 previous;
        for (int s = 0; s <= SAMPLES; s++) {
            float progress = float(s) / float(SAMPLES);
            float value = EaseManager::Evaluate(easeType, null, progress, 1.0f, amplitude, period);
            Vector2 point = Vector2(plotLeft + plotWidth * progress, yZero - (yZero - yOne) * value);
            if (s > 0) {
                GUI::DrawLine(previous, point, curve, 1.6f);
            }
            previous = point;
        }

        float headValue = EaseManager::Evaluate(easeType, null, playhead, 1.0f, amplitude, period);
        Vector2 head = Vector2(plotLeft + plotWidth * playhead, yZero - (yZero - yOne) * headValue);
        GUI::DrawCircleFilled(head, 3.0f, marker);

        GUI::EndChild();
    }

    private bool IsFlash(Ease easeType)
    {
        return easeType == Ease::Flash || easeType == Ease::InFlash
            || easeType == Ease::OutFlash || easeType == Ease::InOutFlash;
    }

    private void Add(Ease easeType, const string&in name)
    {
        eases.insertLast(easeType);
        names.insertLast(name);
    }

    private void BuildList()
    {
        eases.resize(0);
        names.resize(0);

        Add(Ease::Linear, "Linear");
        Add(Ease::InSine, "InSine");           Add(Ease::OutSine, "OutSine");           Add(Ease::InOutSine, "InOutSine");
        Add(Ease::InQuad, "InQuad");           Add(Ease::OutQuad, "OutQuad");           Add(Ease::InOutQuad, "InOutQuad");
        Add(Ease::InCubic, "InCubic");         Add(Ease::OutCubic, "OutCubic");         Add(Ease::InOutCubic, "InOutCubic");
        Add(Ease::InQuart, "InQuart");         Add(Ease::OutQuart, "OutQuart");         Add(Ease::InOutQuart, "InOutQuart");
        Add(Ease::InQuint, "InQuint");         Add(Ease::OutQuint, "OutQuint");         Add(Ease::InOutQuint, "InOutQuint");
        Add(Ease::InExpo, "InExpo");           Add(Ease::OutExpo, "OutExpo");           Add(Ease::InOutExpo, "InOutExpo");
        Add(Ease::InCirc, "InCirc");           Add(Ease::OutCirc, "OutCirc");           Add(Ease::InOutCirc, "InOutCirc");
        Add(Ease::InElastic, "InElastic");     Add(Ease::OutElastic, "OutElastic");     Add(Ease::InOutElastic, "InOutElastic");
        Add(Ease::InBack, "InBack");           Add(Ease::OutBack, "OutBack");           Add(Ease::InOutBack, "InOutBack");
        Add(Ease::InBounce, "InBounce");       Add(Ease::OutBounce, "OutBounce");       Add(Ease::InOutBounce, "InOutBounce");
        Add(Ease::Flash, "Flash");             Add(Ease::InFlash, "InFlash");
        Add(Ease::OutFlash, "OutFlash");       Add(Ease::InOutFlash, "InOutFlash");
    }
}
