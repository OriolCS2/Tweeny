using namespace CometEngine;

/// <summary>
/// Builds and chains the demo tour without any scene authoring.
///
/// Every demo scene is deliberately empty. This project setting runs at play start, creates one host
/// entity, and that host looks at which scene is loaded and builds the right demonstration into it. That
/// keeps the whole tour in readable script instead of a dozen hand-placed scene files, and means a demo can
/// be changed by editing code rather than by clicking around the editor.
/// </summary>
class DemoDirector : ProjectSetting
{
    [Tooltip("Run the chained demo tour when the game starts.")]
    bool runDemoTour = true;

    [Tooltip("Absolute path for a log of the scenes visited. A game build has no console to log to.")]
    string tourReportPath = "";

    [Header("Recording")]
    [Tooltip("Absolute folder to write captured frames into. Leave empty to just play the tour.")]
    string capturePath = "";

    [Tooltip("Frames captured per second while recording.")]
    float captureFps = 20.0f;

    [Tooltip("Frames captured per scene before moving on.")]
    int captureFramesPerScene = 48;

    void OnStart()
    {
        if (!runDemoTour) {
            return;
        }
        Entity@ host = Entity::Create("[Tweeny demo]");
        if (host is null) {
            if (!tourReportPath.isEmpty()) {
                FileSystem::Save(tourReportPath,
                    "=== Tweeny demo tour ===\n[FAIL] Entity::Create returned null\n");
            }
            return;
        }
        DemoHost@ demo = DemoHost::Add(host);
        if (demo is null) {
            if (!tourReportPath.isEmpty()) {
                FileSystem::Save(tourReportPath,
                    "=== Tweeny demo tour ===\n[FAIL] DemoHost could not be added\n");
            }
            return;
        }
        demo.reportPath = tourReportPath;
        demo.capturePath = capturePath;
        demo.captureFps = captureFps;
        demo.captureFramesPerScene = captureFramesPerScene;
        host.MakeImmutable();
    }
}
