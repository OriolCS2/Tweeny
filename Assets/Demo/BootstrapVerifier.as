using namespace CometEngine;

/// <summary>
/// Spawns the bootstrap probe at play start without needing a scene, so the whole zero-setup path can be
/// exercised in a shipped build: a project setting is discovered, it creates an entity, adds a behaviour
/// to it by code, and that behaviour receives Update.
///
/// Turned off by default so it never interferes with the demo scenes; the export check switches it on.
/// </summary>
class BootstrapVerifier : ProjectSetting
{
    [Tooltip("Spawn the probe at play start and write a report. Only used to verify the build.")]
    bool runBootstrapProbe = false;

    [Tooltip("Absolute path the probe writes its report to. A game build has no console to log to.")]
    string reportPath = "";

    void OnStart()
    {
        if (!runBootstrapProbe) {
            return;
        }

        // Written straight away so a missing report tells us OnStart never ran, rather than leaving us
        // guessing between that and the probe failing later.
        if (!reportPath.isEmpty()) {
            FileSystem::Save(reportPath, "[PASS] the project setting's OnStart ran\nRESULT: INCOMPLETE\n");
        }

        Entity@ host = Entity::Create("[Tweeny bootstrap probe]");
        if (host is null) {
            if (!reportPath.isEmpty()) {
                FileSystem::Save(reportPath,
                    "[PASS] the project setting's OnStart ran\n"
                    + "[FAIL] Entity::Create returned null\nRESULT: FAIL\n");
            }
            return;
        }

        BootstrapProbe@ probe = BootstrapProbe::Add(host);
        if (probe is null) {
            if (!reportPath.isEmpty()) {
                FileSystem::Save(reportPath,
                    "[FAIL] the probe behaviour could not be added -- the script was not packed into the build\n"
                    + "RESULT: FAIL\n");
            }
            return;
        }

        probe.reportPath = reportPath;
        host.MakeImmutable();
    }
}
