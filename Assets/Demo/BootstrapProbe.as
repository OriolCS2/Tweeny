using namespace CometEngine;
using namespace Tweeny;

/// <summary>
/// Proves, from inside a real running build, that Tweeny bootstraps itself and that tweens actually
/// advance. It runs a plain tween on its own field and writes a report once enough frames have passed.
///
/// This lives in Assets/ rather than in the package because it is verification scaffolding for this repo,
/// not something a consumer of Tweeny should receive.
/// </summary>
class BootstrapProbe : CometBehaviour
{
    /// Where the report is written. Set by the verifier before the probe starts.
    string reportPath = "";

    private float animated = 0.0f;
    private int updates = 0;
    private float elapsed = 0.0f;
    /// Headless builds run at thousands of frames per second, so the probe waits on elapsed time rather
    /// than a frame count: the tween needs real seconds to finish, not frames.
    private float secondsToRun = 1.0f;
    private bool reported = false;
    private bool tweenCreated = false;
    private bool completed = false;

    void Start()
    {
        Tweeny::To(FloatGetter(this.GetAnimated), FloatSetter(this.SetAnimated), 100.0f, 0.25f)
            .SetEase(Ease::Linear)
            .OnComplete(TweenCallback(this.OnTweenComplete));
        tweenCreated = true;
    }

    void Update()
    {
        updates++;
        elapsed += Time::GetDeltaTime();
        if (!reported && elapsed >= secondsToRun) {
            reported = true;
            WriteReport();
        }
    }

    private float GetAnimated() { return animated; }
    private void SetAnimated(float value) { animated = value; }
    private void OnTweenComplete() { completed = true; }

    private void WriteReport()
    {
        string report = "=== Tweeny bootstrap probe ===\n";
        report += Line("project setting created the probe", true);
        report += Line("the probe received Update", updates > 0);
        report += Line("a tween could be created", tweenCreated);
        report += Line("the runner advanced the tween", animated > 0.0f);
        report += Line("the tween reached its end value", Math::Abs(animated - 100.0f) < 0.001f);
        report += Line("OnComplete fired", completed);
        report += "updates=" + updates + " elapsed=" + formatFloat(elapsed, "", 0, 3)
            + " animated=" + formatFloat(animated, "", 0, 3) + "\n";

        bool allGood = updates > 0 && tweenCreated && completed && Math::Abs(animated - 100.0f) < 0.001f;
        report += allGood ? "RESULT: PASS\n" : "RESULT: FAIL\n";

        if (!reportPath.isEmpty()) {
            FileSystem::Save(reportPath, report);
        }
    }

    private string Line(const string&in what, bool ok)
    {
        return (ok ? "[PASS] " : "[FAIL] ") + what + "\n";
    }
}
