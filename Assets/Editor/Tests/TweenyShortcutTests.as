using namespace CometEngine;
using namespace Tweeny;

namespace TweenyTests
{
    /// <summary>
    /// Exercises the shortcuts against real entities, which is the only way to prove the delegates really
    /// bind to the engine's own property accessors rather than just compiling.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunShortcutTests(TweenyTestContext@ t)
    {
        t.Suite("shortcuts");

        ResetManager();

        CometEngine::SceneManagement::Scene scene =
            CometEngine::SceneManagement::SceneManager::CreateScene("[Tweeny tests]");
        CometEngine::SceneManagement::SceneManager::SetSceneActive(scene);

        Entity@ host = Entity::Create("[Tweeny shortcut test]");
        if (host is null) {
            t.Check(false, "an entity could be created to test the shortcuts against");
            return;
        }

        Transform@ transform = Transform::Get(host);
        if (transform is null) {
            t.Check(false, "the test entity has a transform");
            return;
        }

        t.Case("Move drives the real transform");
        {
            transform.position = Vector3(0.0f, 0.0f, 5.0f);
            TweenVector3@ tween = Tweeny::Move(transform, Vector3(10.0f, 20.0f, 5.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(transform.position.x, 5.0f, "x moved halfway");
            t.CheckApprox(transform.position.y, 10.0f, "y moved halfway");
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckApprox(transform.position.x, 10.0f, "x reached the target");
            t.CheckApprox(transform.position.y, 20.0f, "y reached the target");
            ResetManager();
        }

        t.Case("the planar overload keeps the sorting depth");
        {
            transform.position = Vector3(0.0f, 0.0f, 7.5f);
            TweenVector2@ tween = Tweeny::Move(transform, Vector2(10.0f, 10.0f), 1.0f);
            tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(transform.position.x, 10.0f, "x reached the target");
            t.CheckApprox(transform.position.y, 10.0f, "y reached the target");
            t.CheckApprox(transform.position.z, 7.5f, "and z was left alone");
            ResetManager();
        }

        t.Case("MoveX only touches x");
        {
            transform.position = Vector3(0.0f, 3.0f, 4.0f);
            Tweeny::MoveX(transform, 10.0f, 1.0f).SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(transform.position.x, 10.0f, "x moved");
            t.CheckApprox(transform.position.y, 3.0f, "y stayed put");
            t.CheckApprox(transform.position.z, 4.0f, "z stayed put");
            ResetManager();
        }

        t.Case("MoveY only touches y");
        {
            transform.position = Vector3(2.0f, 0.0f, 4.0f);
            Tweeny::MoveY(transform, 10.0f, 1.0f).SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(transform.position.y, 10.0f, "y moved");
            t.CheckApprox(transform.position.x, 2.0f, "x stayed put");
            ResetManager();
        }

        t.Case("LocalMove drives the local position");
        {
            transform.localPosition = Vector3(0.0f, 0.0f, 0.0f);
            Tweeny::LocalMove(transform, Vector3(4.0f, 0.0f, 0.0f), 1.0f)
                .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(transform.localPosition.x, 2.0f, "the local position moved halfway");
            ResetManager();
        }

        t.Case("Scale drives the local scale");
        {
            transform.localScale = Vector3(1.0f, 1.0f, 1.0f);
            Tweeny::Scale(transform, 3.0f, 1.0f).SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(transform.localScale.x, 2.0f, "x scaled halfway");
            t.CheckApprox(transform.localScale.y, 2.0f, "y scaled halfway");
            ResetManager();
        }

        t.Case("ScaleY only touches y");
        {
            transform.localScale = Vector3(1.0f, 1.0f, 1.0f);
            Tweeny::ScaleY(transform, 5.0f, 1.0f).SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(transform.localScale.y, 5.0f, "y scaled");
            t.CheckApprox(transform.localScale.x, 1.0f, "x kept its scale");
            ResetManager();
        }

        t.Case("Rotate turns about the view axis");
        {
            transform.eulerAngles = Vector3(0.0f, 0.0f, 0.0f);
            Tweeny::Rotate(transform, 90.0f, 1.0f).SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.CheckApprox(transform.eulerAngles.z, 45.0f, "it turned halfway", 0.01f);
            Tweeny::ManualUpdate(0.6f, 0.6f);
            t.CheckApprox(transform.eulerAngles.z, 90.0f, "and reached the target angle", 0.01f);
            ResetManager();
        }

        t.Case("PunchScale bounces the scale and settles back on it");
        {
            transform.localScale = Vector3(2.0f, 2.0f, 1.0f);
            Tweeny::Kill(transform);
            Tweeny::PunchScale(transform, Vector2(0.15f, 0.15f), 0.3f).SetUpdate(UpdateType::Manual);
            float largest = 0.0f;
            float smallest = 100.0f;
            for (int i = 0; i < 30; i++) {
                Tweeny::ManualUpdate(0.01f, 0.01f);
                largest = Math::Max(largest, transform.localScale.x);
                smallest = Math::Min(smallest, transform.localScale.x);
            }
            Tweeny::ManualUpdate(0.1f, 0.1f);
            t.Check(largest > 2.05f, "the punch grew the scale");
            t.Check(smallest > 1.7f, "it never collapsed the scale");
            t.CheckApprox(transform.localScale.x, 2.0f, "x settled back", 0.001f);
            t.CheckApprox(transform.localScale.y, 2.0f, "y settled back", 0.001f);
            t.CheckApprox(transform.localScale.z, 1.0f, "z was left alone", 0.001f);
            ResetManager();
        }

        t.Case("PunchPosition returns the transform to where it started");
        {
            transform.position = Vector3(5.0f, 5.0f, 1.0f);
            Tweeny::PunchPosition(transform, Vector2(3.0f, 0.0f), 0.5f, 10, 1.0f)
                .SetUpdate(UpdateType::Manual);
            bool moved = false;
            for (int i = 0; i < 10; i++) {
                Tweeny::ManualUpdate(0.05f, 0.05f);
                if (Math::Abs(transform.position.x - 5.0f) > 0.01f) {
                    moved = true;
                }
            }
            t.Check(moved, "the punch displaced the transform");
            Tweeny::ManualUpdate(0.2f, 0.2f);
            t.CheckApprox(transform.position.x, 5.0f, "and it settled back", 0.001f);
            t.CheckApprox(transform.position.z, 1.0f, "with its depth intact", 0.001f);
            ResetManager();
        }

        t.Case("ShakePosition settles back and is seedable");
        {
            transform.position = Vector3(0.0f, 0.0f, 2.0f);
            Tweeny::ShakePosition(transform, 0.5f, 2.0f, 10, 90.0f, true, 555)
                .SetUpdate(UpdateType::Manual);
            for (int i = 0; i < 12; i++) {
                Tweeny::ManualUpdate(0.05f, 0.05f);
            }
            t.CheckApprox(transform.position.x, 0.0f, "the shake settled back on x", 0.001f);
            t.CheckApprox(transform.position.y, 0.0f, "and on y", 0.001f);
            t.CheckApprox(transform.position.z, 2.0f, "keeping its depth", 0.001f);
            ResetManager();
        }

        t.Case("Jump lands on its destination");
        {
            transform.position = Vector3(0.0f, 0.0f, 0.0f);
            Tweeny::Jump(transform, Vector2(8.0f, 0.0f), 3.0f, 2, 1.0f).SetUpdate(UpdateType::Manual);
            float highest = 0.0f;
            for (int i = 0; i < 12; i++) {
                Tweeny::ManualUpdate(0.1f, 0.1f);
                if (transform.position.y > highest) {
                    highest = transform.position.y;
                }
            }
            t.Check(highest > 0.5f, "the jump left the ground");
            t.CheckApprox(transform.position.x, 8.0f, "and landed on the destination", 0.01f);
            ResetManager();
        }

        t.Case("Path walks the transform through its waypoints");
        {
            transform.position = Vector3(0.0f, 0.0f, 0.0f);
            array<Vector2> waypoints = { Vector2(10.0f, 0.0f), Vector2(10.0f, 10.0f) };
            Tweeny::Path(transform, waypoints, 1.0f, PathType::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(1.1f, 1.1f);
            t.CheckApprox(transform.position.x, 10.0f, "it finished at the last waypoint");
            t.CheckApprox(transform.position.y, 10.0f, "on both axes");
            ResetManager();
        }

        t.Case("the shortcut records its target so filtered operations can find it");
        {
            transform.position = Vector3(0.0f, 0.0f, 0.0f);
            Tweeny::Move(transform, Vector3(10.0f, 0.0f, 0.0f), 1.0f).SetUpdate(UpdateType::Manual);
            t.Check(Tweeny::IsTweening(transform), "the transform is reported as tweening");
            t.CheckEqualInt(Tweeny::Kill(transform), 1, "and killing by target finds it");
            t.CheckEqualInt(Tweeny::TotalActiveTweens(), 0, "leaving nothing behind");
            ResetManager();
        }

        t.Case("a renderer can be tinted and faded");
        {
            SpriteRenderer@ renderer = SpriteRenderer::Add(host);
            if (renderer is null) {
                t.Check(false, "a sprite renderer could be added");
            }
            else {
                renderer.color = CometEngine::Color(0.0f, 0.0f, 0.0f, 1.0f);
                Tweeny::Tint(renderer, CometEngine::Color(1.0f, 1.0f, 1.0f, 1.0f), 1.0f)
                    .SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
                Tweeny::ManualUpdate(0.5f, 0.5f);
                t.CheckApprox(renderer.color.r, 0.5f, "the tint reached halfway");
                ResetManager();

                renderer.color = CometEngine::Color(0.2f, 0.4f, 0.6f, 1.0f);
                Tweeny::Fade(renderer, 0.0f, 1.0f).SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
                Tweeny::ManualUpdate(1.1f, 1.1f);
                t.CheckApprox(renderer.color.a, 0.0f, "the fade reached zero alpha");
                t.CheckApprox(renderer.color.r, 0.2f, "and the hue was left alone");
                ResetManager();
            }
        }

        t.Case("shortcuts given a null target return a harmless tween instead of dying");
        {
            Transform@ missingTransform = null;
            BaseRenderer@ missingRenderer = null;
            Camera@ missingCamera = null;

            TweenVector3@ move = Tweeny::Move(missingTransform, Vector3(5.0f, 0.0f, 0.0f), 1.0f);
            t.Check(move !is null, "Move returns a tween rather than null");
            move.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
            Tweeny::ManualUpdate(0.5f, 0.5f);
            t.Check(move.IsActive(), "and it can be driven without touching anything");
            ResetManager();

            t.Check(Tweeny::MoveX(missingTransform, 3.0f, 1.0f) !is null, "MoveX survives it");
            t.Check(Tweeny::LocalMove(missingTransform, Vector3(1.0f, 0.0f, 0.0f), 1.0f) !is null, "LocalMove survives it");
            t.Check(Tweeny::Scale(missingTransform, 2.0f, 1.0f) !is null, "Scale survives it");
            t.Check(Tweeny::Rotate(missingTransform, 90.0f, 1.0f) !is null, "Rotate survives it");
            t.Check(Tweeny::Tint(missingRenderer, CometEngine::Color(1, 0, 0, 1), 1.0f) !is null, "Tint survives it");
            t.Check(Tweeny::Fade(missingRenderer, 0.0f, 1.0f) !is null, "Fade survives it");
            t.Check(Tweeny::OrthoSize(missingCamera, 4.0f, 1.0f) !is null, "OrthoSize survives it");
            t.Check(Tweeny::PunchPosition(missingTransform, Vector2(1.0f, 0.0f), 0.5f) !is null, "PunchPosition survives it");
            t.Check(Tweeny::ShakePosition(missingTransform, 0.5f) !is null, "ShakePosition survives it");

            Tweeny::ManualUpdate(2.0f, 2.0f);
            t.Check(true, "and a whole batch of them completes without an exception");
            ResetManager();
        }

        t.Case("a tween keeps running after its target is destroyed");
        {
            Entity@ doomed = Entity::Create("[Tweeny doomed target]");
            if (doomed is null) {
                t.Check(false, "a throwaway entity could be created");
            }
            else {
                Transform@ doomedTransform = Transform::Get(doomed);
                TweenVector3@ tween = Tweeny::Move(doomedTransform, Vector3(10.0f, 0.0f, 0.0f), 1.0f);
                tween.SetEase(Ease::Linear).SetUpdate(UpdateType::Manual);
                Tweeny::ManualUpdate(0.25f, 0.25f);

                Object::Destroy(doomed);
                Tweeny::ManualUpdate(0.5f, 0.5f);
                t.Check(true, "ticking a tween whose entity was destroyed does not raise");
                ResetManager();
            }
        }

        ResetManager();
    }
}
