using namespace CometEngine;
using namespace CometEditor;

/// <summary>
/// Runs the whole Tweeny test suite. Init() is invoked by the engine after every script compile, with no
/// play mode, no scene and no window, so opening the project headlessly is enough to run the tests.
/// The report is written to Library/ so it never lands in version control.
/// </summary>
class TweenyTestRunner : EditorBehaviour
{
    private string REPORT_PATH = "Library/TweenyTestReport.txt";

    void Init()
    {
        RunAll();
    }

    [MainMenuItem("Tweeny/Run Tests")] void RunTestsMenuItem()
    {
        RunAll();
    }

    private void RunAll()
    {
        TweenyTestContext context;

        RegisterSuites(context);

        string report = context.Report();
        FileSystem::Save(REPORT_PATH, report);

        if (context.failures == 0) {
            Debug::Log("[Tweeny tests] PASS -- " + context.checks + " checks");
        }
        else {
            Debug::LogError("[Tweeny tests] FAIL -- " + context.failures
                + " of " + context.checks + " checks failed. See " + REPORT_PATH);
        }
    }

    private void RegisterSuites(TweenyTestContext@ context)
    {
        TweenyTests::RunHarnessTests(context);
        TweenyTests::RunEaseTests(context);
        TweenyTests::RunCoreTests(context);
        TweenyTests::RunSchedulerTests(context);
        TweenyTests::RunValueTypeTests(context);
        TweenyTests::RunSequenceTests(context);
        TweenyTests::RunSpecialTests(context);
        TweenyTests::RunShortcutTests(context);
        TweenyTests::RunIntegrationTests(context);
        TweenyTests::RunPreviewTests(context);
        TweenyTests::RunPreviewSessionTests(context);
    }
}
