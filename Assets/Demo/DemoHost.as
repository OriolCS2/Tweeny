using namespace CometEngine;
using namespace Tweeny;

/// <summary>
/// Runs one demo at a time and moves on to the next.
///
/// It survives scene loads, notices when a new demo scene has come up, builds that demo's objects, and
/// advances once the animations have finished or the scene's time is up. Pressing Play on the first scene
/// therefore walks the whole tour unattended, which is the point: every feature gets seen, in order,
/// without anyone clicking.
/// </summary>
class DemoHost : CometBehaviour
{
    private array<string> tour = {
        "00_Bootstrap",
        "01_TweenBasics",
        "02_Sequences",
        "03_PunchShakeJump",
        "04_Paths",
        "05_Shortcuts",
        "06_Renderers",
        "07_Control",
        "08_Coroutines",
        "09_TweenyAnimation",
        "10_StressTest"
    };

    /// Where the tour writes the scenes it has visited. Set by the director.
    string reportPath = "";

    /// Folder that captured frames are written into. Empty means the tour just plays.
    string capturePath = "";
    float captureFps = 20.0f;
    int captureFramesPerScene = 48;

    /// Game speed used while recording. Low enough that a frame's worth of animation happens between two
    /// captures, which is what makes the recorded clip play back at the right speed.
    float captureTimeScale = 0.1f;

    private int capturedThisScene = 0;
    private float captureAccumulator = 0.0f;
    private bool captureConfigured = false;

    private array<string> visited;
    /// Scenes are identified by build index rather than by name: a scene loaded out of a packed build
    /// reports an empty name, so comparing names would never notice a scene change in a shipped game.
    private int currentIndex = -1;
    private float loadWait = 0.0f;
    /// Scene loading is deferred by a frame or two, so the host waits this long before building content
    /// into a scene it has just asked for.
    private float LOAD_SETTLE_SECONDS = 0.3f;
    private float elapsed = 0.0f;
    private float sceneDuration = 8.0f;
    private bool waitForTweens = false;
    private bool advancing = false;
    private array<Entity@> spawned;

    void Update()
    {
        // The host loads every scene itself, so it simply keeps count rather than asking the engine which
        // demo is on screen: a scene loaded out of a packed build does not report a usable build index, and
        // the immutable scene this host lives in has none at all.
        if (currentIndex < 0) {
            currentIndex = 0;
            BuildSceneContent(0);
            return;
        }

        if (advancing) {
            loadWait += Time::GetUnscaledDeltaTime();
            if (loadWait >= LOAD_SETTLE_SECONDS) {
                advancing = false;
                loadWait = 0.0f;
                BuildSceneContent(currentIndex);
            }
            return;
        }

        elapsed += Time::GetDeltaTime();

        if (!capturePath.isEmpty()) {
            if (!captureConfigured) {
                captureConfigured = true;
                Time::SetTimeScale(captureTimeScale);
            }
            CaptureFrames();
            // While recording, a scene lasts exactly as long as the frames it owes, so every clip is the
            // same length and no motion is cut short.
            if (capturedThisScene >= captureFramesPerScene) {
                Advance();
            }
            return;
        }

        bool finished = elapsed >= sceneDuration;
        if (!finished && waitForTweens && elapsed > 1.0f && Tweeny::TotalActiveTweens() == 0) {
            finished = true;
        }
        if (finished) {
            Advance();
        }
    }

    private void Advance()
    {
        Tweeny::KillAll(false);

        currentIndex = (currentIndex + 1 >= int(tour.length())) ? 0 : currentIndex + 1;
        advancing = true;
        loadWait = 0.0f;
        CometEngine::SceneManagement::SceneManager::LoadScene(currentIndex);
    }

    private Texture2D@ whiteTexture;
    private bool whiteTextureResolved = false;

    /// <summary>
    /// Loads the shared white texture once.
    ///
    /// The demos draw with TextureRectRenderer rather than SpriteRenderer because it takes a texture
    /// directly, with no sprite sub-resource to look up, and it still derives from BaseRenderer so the tint
    /// and fade shortcuts work on it unchanged.
    /// </summary>
    /// <returns>Returns the texture, or null when it is missing.</returns>
    private Texture2D@ ResolveWhiteTexture()
    {
        if (whiteTextureResolved) {
            return whiteTexture;
        }
        whiteTextureResolved = true;

        // Built straight from the file rather than through Assets::Load, which resolves content addresses
        // and not paths: the demo texture is a loose file with no address assigned to it.
        // Prefer the imported asset, which has gone through the texture pipeline and has real pixel data.
        // Building one straight from the file works as a fallback but samples black, so the tint would be
        // lost; either way the object is visible against the light background.
        @whiteTexture = cast<Texture2D@>(Assets::Load("white", ResourceType::TEXTURE));
        if (whiteTexture is null) {
            @whiteTexture = Texture2D::Create(Texture2DDefinition("Assets/Demo/white.png"));
        }
        if (whiteTexture !is null) {
            // Creation kicks off an async upload. Without waiting, the first frames draw with no texture
            // bound at all, which multiplies every tint down to black.
            whiteTexture.WaitForLoad();
        }
        if (whiteTexture is null) {
            Debug::LogWarning("[Tweeny demo] the white texture was not found; demo objects will be invisible");
        }
        return whiteTexture;
    }

    /// <summary>
    /// Gives the freshly loaded scene a camera. The demo scenes are empty on disk, so without this there
    /// is nothing to render from and the view stays blank.
    /// </summary>
    private void EnsureCamera()
    {
        Entity@ cameraEntity = Entity::Create("[demo camera]");
        if (cameraEntity is null) {
            return;
        }
        Transform::Get(cameraEntity).position = Vector3(0.0f, 0.0f, -10.0f);
        Camera@ camera = Camera::Add(cameraEntity);
        if (camera !is null) {
            camera.size = 10.0f;
            camera.backgroundColor = CometEngine::Color(0.85f, 0.87f, 0.90f, 1.0f);
            // A behaviour added by code never runs the editor's Reset, so its culling mask starts empty and
            // the camera would draw its background and nothing else. -1 is every layer.
            camera.cullingMask = LayerMask(-1);
        }
    }

    /// <summary>
    /// Makes a coloured square at a position, which is all any of these demos needs to be readable.
    /// </summary>
    /// <param name="name">Name given to the entity.</param>
    /// <param name="position">Where to put it.</param>
    /// <param name="colour">The sprite renderer's tint.</param>
    /// <returns>Returns the new entity.</returns>
    private Entity@ Spawn(const string&in name, Vector2 position, Color colour)
    {
        Entity@ entity = Entity::Create(name);
        if (entity is null) {
            return null;
        }
        Transform@ tr = Transform::Get(entity);
        tr.position = Vector3(position.x, position.y, 0.0f);
        tr.localScale = Vector3(0.6f, 0.6f, 1.0f);

        TextureRectRenderer@ renderer = TextureRectRenderer::Add(entity);
        if (renderer !is null) {
            // Every demo object shares one plain white texture and gets its look purely from the tint. The
            // rect has to be set explicitly: a renderer with the default empty rect draws nothing.
            @renderer.texture = whiteTexture;
            renderer.rectUnitType = RectUnitType::NORMALIZED_0_1;
            renderer.rectNormalized = Rectf(0.0f, 0.0f, 1.0f, 1.0f);
            renderer.pivot = PivotType::MIDDLE;
            renderer.color = colour;
        }
        spawned.insertLast(entity);
        return entity;
    }

    /// <summary>
    /// Writes one frame of the game view at a fixed rate, so the resulting sequence plays back at a known
    /// speed no matter what frame rate the engine is actually running at.
    /// </summary>
    private void CaptureFrames()
    {
        if (capturedThisScene >= captureFramesPerScene) {
            return;
        }
        // Capturing a frame costs far more than rendering one, so real time is useless as a clock here:
        // the animation would leap between shots. Instead the game runs slowed down and frames are taken
        // on SCALED time, which makes each captured frame exactly one playback frame apart.
        captureAccumulator += Time::GetDeltaTime();
        float interval = 1.0f / (captureFps <= 0.0f ? 20.0f : captureFps);
        if (captureAccumulator < interval) {
            return;
        }
        captureAccumulator -= interval;

        string index = capturedThisScene < 10 ? ("0" + capturedThisScene) : ("" + capturedThisScene);
        string name = currentIndex >= 0 && currentIndex < int(tour.length())
            ? tour[uint(currentIndex)] : ("scene" + currentIndex);
        ScreenCapture::Capture(capturePath + name + "_" + index, true);
        capturedThisScene++;
    }

    /// <summary>
    /// Appends a scene to the tour log and rewrites it, so a headless run leaves a trace of how far it got.
    /// </summary>
    /// <param name="sceneName">The scene just entered.</param>
    private void RecordVisit(const string&in sceneName)
    {
        visited.insertLast(sceneName);
        if (reportPath.isEmpty()) {
            return;
        }
        string text = "=== Tweeny demo tour ===\n";
        for (uint i = 0; i < visited.length(); i++) {
            text += "[VISIT] " + visited[i] + "\n";
        }
        text += "visited=" + visited.length() + " of " + tour.length() + "\n";
        text += "whiteTexture=" + (ResolveWhiteTexture() !is null ? "loaded" : "MISSING") + "\n";
        text += "spawned=" + spawned.length() + "\n";
        FileSystem::Save(reportPath, text);
    }

    private Color Hue(int index, int total)
    {
        float t = total <= 1 ? 0.0f : float(index) / float(total - 1);
        return Color(0.25f + 0.7f * t, 0.85f - 0.5f * t, 0.95f - 0.4f * t, 1.0f);
    }

    private void BuildSceneContent(int index)
    {
        elapsed = 0.0f;
        advancing = false;
        waitForTweens = false;
        sceneDuration = 8.0f;
        spawned.resize(0);
        capturedThisScene = 0;
        captureAccumulator = 0.0f;

        EnsureCamera();

        string sceneName = (index >= 0 && index < int(tour.length())) ? tour[uint(index)] : ("scene " + index);
        Debug::Log("[Tweeny demo] " + sceneName);
        RecordVisit(sceneName);

        if (sceneName == "00_Bootstrap")           { BuildEaseGallery(); }
        else if (sceneName == "01_TweenBasics")    { BuildTweenBasics(); }
        else if (sceneName == "02_Sequences")      { BuildSequences(); }
        else if (sceneName == "03_PunchShakeJump") { BuildPunchShakeJump(); }
        else if (sceneName == "04_Paths")          { BuildPaths(); }
        else if (sceneName == "05_Shortcuts")      { BuildShortcuts(); }
        else if (sceneName == "06_Renderers")      { BuildRenderers(); }
        else if (sceneName == "07_Control")        { BuildControl(); }
        else if (sceneName == "08_Coroutines")     { BuildCoroutines(); }
        else if (sceneName == "09_TweenyAnimation"){ BuildAnimationComponent(); }
        else if (sceneName == "10_StressTest")     { BuildStressTest(); }
    }

    // ---- the demos ----------------------------------------------------------------------------------

    /// Every easing curve racing the same distance side by side, so their pacing can be compared directly.
    private void BuildEaseGallery()
    {
        sceneDuration = 10.0f;
        array<Ease> eases = {
            Ease::Linear, Ease::InSine, Ease::OutSine, Ease::InOutSine,
            Ease::InQuad, Ease::OutQuad, Ease::InOutQuad, Ease::InCubic,
            Ease::OutCubic, Ease::InOutCubic, Ease::InQuart, Ease::OutQuart,
            Ease::InQuint, Ease::OutQuint, Ease::InExpo, Ease::OutExpo,
            Ease::InCirc, Ease::OutCirc, Ease::InElastic, Ease::OutElastic,
            Ease::InBack, Ease::OutBack, Ease::InOutBack, Ease::InBounce,
            Ease::OutBounce, Ease::InOutBounce, Ease::Flash, Ease::InOutFlash
        };

        for (uint i = 0; i < eases.length(); i++) {
            float y = 7.0f - float(i) * 0.5f;
            Entity@ entity = Spawn("ease" + i, Vector2(-9.0f, y), Hue(int(i), int(eases.length())));
            if (entity is null) {
                continue;
            }
            Tweeny::MoveX(Transform::Get(entity), 9.0f, 3.0f)
                .SetEase(eases[i], 4.0f, 0.0f)
                .SetLoops(-1, LoopType::Yoyo);
        }
    }

    /// Loops, delays, relative moves and callbacks, each on its own row.
    private void BuildTweenBasics()
    {
        Entity@ restart = Spawn("restart", Vector2(-8.0f, 4.0f), Color(0.3f, 0.8f, 0.9f, 1.0f));
        Tweeny::MoveX(Transform::Get(restart), 8.0f, 2.0f).SetLoops(-1, LoopType::Restart).SetEase(Ease::Linear);

        Entity@ yoyo = Spawn("yoyo", Vector2(-8.0f, 2.0f), Color(0.9f, 0.6f, 0.3f, 1.0f));
        Tweeny::MoveX(Transform::Get(yoyo), 8.0f, 2.0f).SetLoops(-1, LoopType::Yoyo).SetEase(Ease::InOutQuad);

        Entity@ delayed = Spawn("delayed", Vector2(-8.0f, 0.0f), Color(0.6f, 0.9f, 0.4f, 1.0f));
        Tweeny::MoveX(Transform::Get(delayed), 8.0f, 2.0f).SetDelay(1.5f).SetLoops(-1, LoopType::Yoyo);

        Entity@ relative = Spawn("relative", Vector2(-8.0f, -2.0f), Color(0.9f, 0.4f, 0.7f, 1.0f));
        Tweeny::Move(Transform::Get(relative), Vector2(3.0f, 0.0f), 1.0f)
            .SetRelative(true).SetLoops(-1, LoopType::Restart).SetEase(Ease::OutQuad);

        Entity@ scaler = Spawn("scale", Vector2(0.0f, -4.5f), Color(0.5f, 0.5f, 1.0f, 1.0f));
        Tweeny::Scale(Transform::Get(scaler), 1.8f, 1.0f).SetLoops(-1, LoopType::Yoyo).SetEase(Ease::InOutSine);

        Entity@ spinner = Spawn("rotate", Vector2(4.0f, -4.5f), Color(1.0f, 0.8f, 0.2f, 1.0f));
        Tweeny::Rotate(Transform::Get(spinner), 360.0f, 2.0f)
            .SetRotateMode(RotateMode::FastBeyond360).SetLoops(-1, LoopType::Restart).SetEase(Ease::Linear);
    }

    /// A choreography that is obviously wrong if any step runs out of order.
    private void BuildSequences()
    {
        waitForTweens = true;
        sceneDuration = 12.0f;

        Entity@ a = Spawn("step A", Vector2(-6.0f, 3.0f), Color(0.3f, 0.9f, 0.8f, 1.0f));
        Entity@ b = Spawn("step B", Vector2(0.0f, 3.0f), Color(0.9f, 0.7f, 0.3f, 1.0f));
        Entity@ c = Spawn("step C", Vector2(6.0f, 3.0f), Color(0.9f, 0.4f, 0.5f, 1.0f));

        TweenSequence@ sequence = Tweeny::Sequence();
        sequence.Append(Tweeny::MoveY(Transform::Get(a), -3.0f, 1.0f).SetEase(Ease::OutBounce));
        sequence.Append(Tweeny::MoveY(Transform::Get(b), -3.0f, 1.0f).SetEase(Ease::OutBounce));
        sequence.Append(Tweeny::MoveY(Transform::Get(c), -3.0f, 1.0f).SetEase(Ease::OutBounce));
        sequence.AppendInterval(0.5f);
        sequence.Append(Tweeny::Scale(Transform::Get(a), 1.5f, 0.4f));
        sequence.Join(Tweeny::Scale(Transform::Get(b), 1.5f, 0.4f));
        sequence.Join(Tweeny::Scale(Transform::Get(c), 1.5f, 0.4f));
        sequence.AppendInterval(0.3f);
        sequence.Append(Tweeny::MoveY(Transform::Get(a), 3.0f, 0.8f).SetEase(Ease::InOutQuad));
        sequence.Join(Tweeny::MoveY(Transform::Get(b), 3.0f, 0.8f).SetEase(Ease::InOutQuad));
        sequence.Join(Tweeny::MoveY(Transform::Get(c), 3.0f, 0.8f).SetEase(Ease::InOutQuad));
        sequence.SetLoops(2, LoopType::Restart);
    }

    /// Punch, shake and jump, all of which must end exactly where they began.
    private void BuildPunchShakeJump()
    {
        Entity@ punch = Spawn("punch", Vector2(-6.0f, 2.0f), Color(0.9f, 0.5f, 0.3f, 1.0f));
        Tweeny::PunchPosition(Transform::Get(punch), Vector2(2.0f, 0.0f), 1.0f, 10, 1.0f)
            .SetLoops(-1, LoopType::Restart);

        Entity@ punchScale = Spawn("punch scale", Vector2(-2.0f, 2.0f), Color(0.4f, 0.9f, 0.6f, 1.0f));
        Tweeny::PunchScale(Transform::Get(punchScale), Vector2(0.6f, 0.6f), 1.0f, 10, 1.0f)
            .SetLoops(-1, LoopType::Restart);

        Entity@ shake = Spawn("shake", Vector2(2.0f, 2.0f), Color(0.5f, 0.6f, 0.95f, 1.0f));
        Tweeny::ShakePosition(Transform::Get(shake), 1.0f, 1.5f, 14)
            .SetLoops(-1, LoopType::Restart);

        Entity@ shakeScale = Spawn("shake scale", Vector2(6.0f, 2.0f), Color(0.9f, 0.4f, 0.8f, 1.0f));
        Tweeny::ShakeScale(Transform::Get(shakeScale), 1.0f, 0.5f, 14)
            .SetLoops(-1, LoopType::Restart);

        Entity@ jumper = Spawn("jump", Vector2(-7.0f, -3.0f), Color(1.0f, 0.85f, 0.3f, 1.0f));
        Tweeny::Jump(Transform::Get(jumper), Vector2(7.0f, -3.0f), 2.5f, 3, 2.5f)
            .SetLoops(-1, LoopType::Yoyo);
    }

    /// Straight and curved paths, open and closed, at a constant speed.
    private void BuildPaths()
    {
        array<Vector2> square = { Vector2(5.0f, 3.0f), Vector2(5.0f, -1.0f), Vector2(-5.0f, -1.0f) };
        Entity@ linear = Spawn("linear path", Vector2(-5.0f, 3.0f), Color(0.4f, 0.9f, 0.9f, 1.0f));
        Tweeny::Path(Transform::Get(linear), square, 4.0f, PathType::Linear)
            .SetClosePath(true).SetLoops(-1, LoopType::Restart);

        array<Vector2> wave = {
            Vector2(-3.0f, -5.0f), Vector2(0.0f, -2.0f), Vector2(3.0f, -5.0f), Vector2(6.0f, -2.0f)
        };
        Entity@ curved = Spawn("curved path", Vector2(-6.0f, -2.0f), Color(0.95f, 0.6f, 0.35f, 1.0f));
        Tweeny::Path(Transform::Get(curved), wave, 4.0f, PathType::CatmullRom)
            .SetLoops(-1, LoopType::Yoyo);
    }

    /// One row per shortcut family.
    private void BuildShortcuts()
    {
        Entity@ mover = Spawn("Move", Vector2(-8.0f, 4.0f), Color(0.4f, 0.85f, 0.95f, 1.0f));
        Tweeny::Move(Transform::Get(mover), Vector2(8.0f, 4.0f), 2.0f).SetLoops(-1, LoopType::Yoyo);

        Entity@ localMover = Spawn("LocalMove", Vector2(-8.0f, 2.0f), Color(0.5f, 0.9f, 0.6f, 1.0f));
        Tweeny::LocalMoveX(Transform::Get(localMover), 8.0f, 2.0f).SetLoops(-1, LoopType::Yoyo);

        Entity@ scaler = Spawn("Scale", Vector2(-8.0f, 0.0f), Color(0.95f, 0.7f, 0.3f, 1.0f));
        Tweeny::Scale(Transform::Get(scaler), 2.0f, 1.5f).SetLoops(-1, LoopType::Yoyo);

        Entity@ scalerY = Spawn("ScaleY", Vector2(-5.0f, 0.0f), Color(0.9f, 0.5f, 0.4f, 1.0f));
        Tweeny::ScaleY(Transform::Get(scalerY), 2.5f, 1.5f).SetLoops(-1, LoopType::Yoyo);

        Entity@ spinner = Spawn("Rotate", Vector2(-8.0f, -2.5f), Color(0.8f, 0.5f, 0.95f, 1.0f));
        Tweeny::Rotate(Transform::Get(spinner), 720.0f, 3.0f)
            .SetRotateMode(RotateMode::FastBeyond360).SetLoops(-1, LoopType::Restart).SetEase(Ease::Linear);

        Entity@ speedBased = Spawn("SpeedBased", Vector2(-8.0f, -4.5f), Color(0.6f, 0.95f, 0.5f, 1.0f));
        Tweeny::MoveX(Transform::Get(speedBased), 8.0f, 4.0f)
            .SetSpeedBased(true).SetLoops(-1, LoopType::Yoyo).SetEase(Ease::Linear);
    }

    /// Tint and fade on renderers, which is where most of a game's polish actually lives.
    private void BuildRenderers()
    {
        Entity@ tinted = Spawn("Tint", Vector2(-4.0f, 2.0f), Color(1.0f, 1.0f, 1.0f, 1.0f));
        TextureRectRenderer@ tintRenderer = TextureRectRenderer::Get(tinted);
        Tweeny::Tint(tintRenderer, Color(0.9f, 0.2f, 0.3f, 1.0f), 1.5f).SetLoops(-1, LoopType::Yoyo);

        Entity@ faded = Spawn("Fade", Vector2(0.0f, 2.0f), Color(0.3f, 0.9f, 0.8f, 1.0f));
        TextureRectRenderer@ fadeRenderer = TextureRectRenderer::Get(faded);
        Tweeny::Fade(fadeRenderer, 0.0f, 1.5f).SetLoops(-1, LoopType::Yoyo);

        Entity@ both = Spawn("Tint and move", Vector2(4.0f, 2.0f), Color(0.4f, 0.5f, 0.95f, 1.0f));
        TextureRectRenderer@ bothRenderer = TextureRectRenderer::Get(both);
        Tweeny::Tint(bothRenderer, Color(1.0f, 0.9f, 0.2f, 1.0f), 1.0f).SetLoops(-1, LoopType::Yoyo);
        Tweeny::MoveY(Transform::Get(both), -2.0f, 1.0f).SetLoops(-1, LoopType::Yoyo).SetEase(Ease::InOutSine);
    }

    /// Playback control: pause, rewind, flip and filtered kills, driven on a timer.
    private void BuildControl()
    {
        sceneDuration = 10.0f;

        for (int i = 0; i < 4; i++) {
            Entity@ entity = Spawn("controlled" + i, Vector2(-8.0f, 3.0f - float(i) * 2.0f), Hue(i, 4));
            Tweeny::MoveX(Transform::Get(entity), 8.0f, 3.0f)
                .SetLoops(-1, LoopType::Yoyo)
                .SetEase(Ease::InOutQuad)
                .SetId("controlled");
        }

        // A sequence of timed control calls, so the scene demonstrates the API rather than just motion.
        TweenSequence@ script = Tweeny::Sequence();
        script.AppendInterval(2.0f);
        script.AppendCallback(TweenCallback(this.PauseControlled));
        script.AppendInterval(1.5f);
        script.AppendCallback(TweenCallback(this.PlayControlled));
        script.AppendInterval(2.0f);
        script.AppendCallback(TweenCallback(this.FlipControlled));
        script.AppendInterval(2.0f);
        script.AppendCallback(TweenCallback(this.RewindControlled));
    }

    private void PauseControlled() { Tweeny::Pause("controlled"); Debug::Log("[Tweeny demo] paused"); }
    private void PlayControlled() { Tweeny::Play("controlled"); Debug::Log("[Tweeny demo] resumed"); }
    private void FlipControlled() { Tweeny::Apply(TweenOperation::OpFlip, FilterType::TargetOrId, null, "controlled", -999); Debug::Log("[Tweeny demo] flipped"); }
    private void RewindControlled() { Tweeny::Apply(TweenOperation::OpRewind, FilterType::TargetOrId, null, "controlled", -999, 0.0f, true); Debug::Log("[Tweeny demo] rewound"); }

    /// A coroutine waiting on each tween in turn, which is the readable way to script a cutscene.
    private void BuildCoroutines()
    {
        waitForTweens = true;
        sceneDuration = 12.0f;
        StartCoroutine("CoroutineDemo");
    }

    private void CoroutineDemo()
    {
        Entity@ a = Spawn("first", Vector2(-6.0f, 2.0f), Color(0.4f, 0.9f, 0.9f, 1.0f));
        Entity@ b = Spawn("second", Vector2(0.0f, 2.0f), Color(0.9f, 0.7f, 0.4f, 1.0f));
        Entity@ c = Spawn("third", Vector2(6.0f, 2.0f), Color(0.9f, 0.4f, 0.6f, 1.0f));

        Yield(WaitForCompletion(Tweeny::MoveY(Transform::Get(a), -2.0f, 1.0f).SetEase(Ease::OutBack)));
        Yield(WaitForCompletion(Tweeny::MoveY(Transform::Get(b), -2.0f, 1.0f).SetEase(Ease::OutBack)));
        Yield(WaitForCompletion(Tweeny::MoveY(Transform::Get(c), -2.0f, 1.0f).SetEase(Ease::OutBack)));
        Yield(WaitForSeconds(0.3f));
        Yield(WaitForCompletion(Tweeny::Scale(Transform::Get(a), 2.0f, 0.5f)));
        Yield(WaitForCompletion(Tweeny::Scale(Transform::Get(b), 2.0f, 0.5f)));
        Yield(WaitForCompletion(Tweeny::Scale(Transform::Get(c), 2.0f, 0.5f)));
        Debug::Log("[Tweeny demo] the coroutine finished its cutscene");
    }

    /// The inspector-driven component, configured here in code only because these scenes are generated.
    private void BuildAnimationComponent()
    {
        array<TweenyAnimationType> kinds = {
            TweenyAnimationType::Move,
            TweenyAnimationType::Scale,
            TweenyAnimationType::Rotate,
            TweenyAnimationType::Tint,
            TweenyAnimationType::PunchPosition,
            TweenyAnimationType::ShakePosition
        };

        for (uint i = 0; i < kinds.length(); i++) {
            float x = -7.5f + float(i) * 3.0f;
            Entity@ entity = Spawn("animated" + i, Vector2(x, 0.0f), Hue(int(i), int(kinds.length())));
            if (entity is null) {
                continue;
            }
            TweenyAnimation@ animation = TweenyAnimation::Add(entity);
            if (animation is null) {
                continue;
            }
            animation.animationType = kinds[i];
            animation.endValueVector = Vector2(x, 3.0f);
            animation.endValueFloat = 360.0f;
            animation.endValueColor = Color(1.0f, 0.85f, 0.2f, 1.0f);
            animation.duration = 1.5f;
            animation.loops = -1;
            animation.loopType = LoopType::Yoyo;
            animation.ease = Ease::InOutQuad;
            animation.autoPlay = TweenyAutoPlayMode::OnStart;

            if (kinds[i] == TweenyAnimationType::Scale) {
                animation.endValueVector = Vector2(1.4f, 1.4f);
            }
            else if (kinds[i] == TweenyAnimationType::PunchPosition) {
                animation.endValueVector = Vector2(0.0f, 1.5f);
                animation.loopType = LoopType::Restart;
            }
            else if (kinds[i] == TweenyAnimationType::ShakePosition) {
                animation.loopType = LoopType::Restart;
            }
        }
    }

    /// Hundreds of tweens at once, so the per-frame cost is something you can watch rather than guess at.
    private void BuildStressTest()
    {
        sceneDuration = 10.0f;
        const int COUNT = 400;
        for (int i = 0; i < COUNT; i++) {
            float x = -9.0f + float(i % 40) * 0.46f;
            float y = 5.0f - float(i / 40) * 1.1f;
            Entity@ entity = Spawn("stress" + i, Vector2(x, y), Hue(i % 40, 40));
            if (entity is null) {
                continue;
            }
            Transform::Get(entity).localScale = Vector3(0.25f, 0.25f, 1.0f);
            Tweeny::MoveY(Transform::Get(entity), y - 0.6f, 0.5f + float(i % 7) * 0.1f)
                .SetLoops(-1, LoopType::Yoyo)
                .SetEase(Ease::InOutSine);
        }
        Debug::Log("[Tweeny demo] stress test running " + Tweeny::TotalActiveTweens() + " tweens");
    }
}
