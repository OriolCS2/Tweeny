using namespace CometEngine;

/// <summary>
/// Chains the demo scenes together so pressing Play on the first one walks through all of them.
/// The last scene points back at the first, so the tour loops forever.
/// </summary>
class DemoSceneRunner : CometBehaviour
{
    [Tooltip("Scene loaded when this one finishes. Leave empty to stop at this scene.")]
    string nextScene = "";

    [Tooltip("Seconds this scene stays on screen before advancing.")]
    float duration = 6.0f;

    private float elapsed = 0.0f;
    private bool advancing = false;

    void Update()
    {
        if (advancing) {
            return;
        }

        elapsed += Time::GetDeltaTime();

        if (elapsed >= duration) {
            Advance();
        }
    }

    private void Advance()
    {
        if (nextScene.isEmpty()) {
            return;
        }
        advancing = true;
        SceneManagement::SceneManager::LoadScene(nextScene);
    }
}
