using namespace CometEngine;

namespace Tweeny
{
    /// <summary>Moves a transform to a world position.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The world position to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ Move(Transform@ target, Vector3 to, float duration)
    {
        TweenVector3@ tween = To(Vector3Getter(target.get_position), Vector3Setter(target.set_position), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Moves a transform to a world position in the plane, keeping its sorting depth.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The world position to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2@ Move(Transform@ target, Vector2 to, float duration)
    {
        TransformPlanarAdapter@ adapter = TransformPlanarAdapter(target, false);
        TweenVector2@ tween = To(adapter.Getter(), adapter.Setter(), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Moves a transform along X only.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The world X to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ MoveX(Transform@ target, float to, float duration)
    {
        return Move(target, Vector3(to, 0.0f, 0.0f), duration).SetAxisConstraint(AxisConstraint::X);
    }

    /// <summary>Moves a transform along Y only.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The world Y to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ MoveY(Transform@ target, float to, float duration)
    {
        return Move(target, Vector3(0.0f, to, 0.0f), duration).SetAxisConstraint(AxisConstraint::Y);
    }

    /// <summary>Moves a transform along Z only, which in a 2D scene is its sorting depth.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The world Z to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ MoveZ(Transform@ target, float to, float duration)
    {
        return Move(target, Vector3(0.0f, 0.0f, to), duration).SetAxisConstraint(AxisConstraint::Z);
    }

    /// <summary>Moves a transform to a position relative to its parent.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The local position to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ LocalMove(Transform@ target, Vector3 to, float duration)
    {
        TweenVector3@ tween = To(Vector3Getter(target.get_localPosition),
            Vector3Setter(target.set_localPosition), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Moves a transform along local X only.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The local X to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ LocalMoveX(Transform@ target, float to, float duration)
    {
        return LocalMove(target, Vector3(to, 0.0f, 0.0f), duration).SetAxisConstraint(AxisConstraint::X);
    }

    /// <summary>Moves a transform along local Y only.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">The local Y to reach.</param>
    /// <param name="duration">How long the move takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ LocalMoveY(Transform@ target, float to, float duration)
    {
        return LocalMove(target, Vector3(0.0f, to, 0.0f), duration).SetAxisConstraint(AxisConstraint::Y);
    }

    /// <summary>Scales a transform.</summary>
    /// <param name="target">The transform to scale.</param>
    /// <param name="to">The local scale to reach.</param>
    /// <param name="duration">How long the scaling takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ Scale(Transform@ target, Vector3 to, float duration)
    {
        TweenVector3@ tween = To(Vector3Getter(target.get_localScale),
            Vector3Setter(target.set_localScale), to, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Scales a transform uniformly.</summary>
    /// <param name="target">The transform to scale.</param>
    /// <param name="to">The scale to reach on every axis.</param>
    /// <param name="duration">How long the scaling takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ Scale(Transform@ target, float to, float duration)
    {
        return Scale(target, Vector3(to, to, to), duration);
    }

    /// <summary>Scales a transform along X only.</summary>
    /// <param name="target">The transform to scale.</param>
    /// <param name="to">The X scale to reach.</param>
    /// <param name="duration">How long the scaling takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ ScaleX(Transform@ target, float to, float duration)
    {
        return Scale(target, Vector3(to, 0.0f, 0.0f), duration).SetAxisConstraint(AxisConstraint::X);
    }

    /// <summary>Scales a transform along Y only.</summary>
    /// <param name="target">The transform to scale.</param>
    /// <param name="to">The Y scale to reach.</param>
    /// <param name="duration">How long the scaling takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector3@ ScaleY(Transform@ target, float to, float duration)
    {
        return Scale(target, Vector3(0.0f, to, 0.0f), duration).SetAxisConstraint(AxisConstraint::Y);
    }

    /// <summary>Rotates a transform about the view axis.</summary>
    /// <param name="target">The transform to rotate.</param>
    /// <param name="toDegrees">The angle to reach.</param>
    /// <param name="duration">How long the rotation takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenAngle@ Rotate(Transform@ target, float toDegrees, float duration)
    {
        TransformAngleAdapter@ adapter = TransformAngleAdapter(target, false);
        TweenAngle@ tween = ToAngle(adapter.Getter(), adapter.Setter(), toDegrees, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Rotates a transform about the view axis, relative to its parent.</summary>
    /// <param name="target">The transform to rotate.</param>
    /// <param name="toDegrees">The angle to reach.</param>
    /// <param name="duration">How long the rotation takes, in seconds.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenAngle@ LocalRotate(Transform@ target, float toDegrees, float duration)
    {
        TransformAngleAdapter@ adapter = TransformAngleAdapter(target, true);
        TweenAngle@ tween = ToAngle(adapter.Getter(), adapter.Setter(), toDegrees, duration);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Punches a transform's position and lets it spring back.</summary>
    /// <param name="target">The transform to punch.</param>
    /// <param name="punch">Which way and how far the punch goes.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <param name="vibrato">How many times it bounces per second.</param>
    /// <param name="elasticity">How far past the start it may spring back, from 0 to 1.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ PunchPosition(Transform@ target, Vector2 punch, float duration,
        int vibrato = 10, float elasticity = 1.0f)
    {
        TransformPlanarAdapter@ adapter = TransformPlanarAdapter(target, false);
        TweenVector2Array@ tween = Punch(adapter.Getter(), adapter.Setter(), punch, duration, vibrato, elasticity);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Punches a transform's scale and lets it spring back.</summary>
    /// <param name="target">The transform to punch.</param>
    /// <param name="punch">How far the scale is pushed.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <param name="vibrato">How many times it bounces per second.</param>
    /// <param name="elasticity">How far past the start it may spring back, from 0 to 1.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ PunchScale(Transform@ target, Vector2 punch, float duration,
        int vibrato = 10, float elasticity = 1.0f)
    {
        TransformScaleAdapter@ adapter = TransformScaleAdapter(target);
        TweenVector2Array@ tween = Punch(adapter.Getter(), adapter.Setter(), punch, duration, vibrato, elasticity);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Shakes a transform's position, settling back where it started.</summary>
    /// <param name="target">The transform to shake.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <param name="strength">How far the shake reaches.</param>
    /// <param name="vibrato">How many times it shakes per second.</param>
    /// <param name="randomness">How much the direction wanders each hop, in degrees.</param>
    /// <param name="fadeOut">Whether the shake dies down over its duration.</param>
    /// <param name="seed">Seed for the shake. Use the same value to replay it exactly.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ ShakePosition(Transform@ target, float duration, float strength = 3.0f,
        int vibrato = 10, float randomness = 90.0f, bool fadeOut = true, uint seed = 0)
    {
        TransformPlanarAdapter@ adapter = TransformPlanarAdapter(target, false);
        TweenVector2Array@ tween = Shake(adapter.Getter(), adapter.Setter(), duration, strength,
            vibrato, randomness, fadeOut, ShakeRandomnessMode::Full, seed);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Shakes a transform's scale, settling back where it started.</summary>
    /// <param name="target">The transform to shake.</param>
    /// <param name="duration">How long the effect lasts.</param>
    /// <param name="strength">How far the shake reaches.</param>
    /// <param name="vibrato">How many times it shakes per second.</param>
    /// <param name="randomness">How much the direction wanders each hop, in degrees.</param>
    /// <param name="fadeOut">Whether the shake dies down over its duration.</param>
    /// <param name="seed">Seed for the shake. Use the same value to replay it exactly.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenVector2Array@ ShakeScale(Transform@ target, float duration, float strength = 1.0f,
        int vibrato = 10, float randomness = 90.0f, bool fadeOut = true, uint seed = 0)
    {
        TransformScaleAdapter@ adapter = TransformScaleAdapter(target);
        TweenVector2Array@ tween = Shake(adapter.Getter(), adapter.Setter(), duration, strength,
            vibrato, randomness, fadeOut, ShakeRandomnessMode::Full, seed);
        tween.SetTarget(target);
        return tween;
    }

    /// <summary>Hops a transform towards a destination, arcing on the way.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="to">Where to land.</param>
    /// <param name="jumpPower">How high each hop rises.</param>
    /// <param name="numJumps">How many hops to make.</param>
    /// <param name="duration">How long the whole jump lasts.</param>
    /// <returns>Returns the sequence driving the jump.</returns>
    TweenSequence@ Jump(Transform@ target, Vector2 to, float jumpPower, int numJumps, float duration)
    {
        TransformPlanarAdapter@ adapter = TransformPlanarAdapter(target, false);
        TweenSequence@ sequence = Jump(adapter.Getter(), adapter.Setter(), to, jumpPower, numJumps, duration);
        sequence.SetTarget(target);
        return sequence;
    }

    /// <summary>Moves a transform along a path of waypoints at a constant speed.</summary>
    /// <param name="target">The transform to move.</param>
    /// <param name="waypoints">The points to travel through, in order.</param>
    /// <param name="duration">How long one loop takes, in seconds.</param>
    /// <param name="type">Straight lines or a smooth curve.</param>
    /// <returns>Returns the tween so settings can be chained onto it.</returns>
    TweenPath@ Path(Transform@ target, const array<Vector2>&in waypoints, float duration,
        PathType type = PathType::Linear)
    {
        TransformPlanarAdapter@ adapter = TransformPlanarAdapter(target, false);
        TweenPath@ tween = Path(adapter.Getter(), adapter.Setter(), waypoints, duration, type);
        tween.SetTarget(target);
        return tween;
    }
}
