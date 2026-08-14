using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// Presents a Transform's position as a plain Vector2 while leaving Z exactly where it was.
    ///
    /// Comet's Transform is three-component even in a 2D game, where Z carries sorting depth. Effects like
    /// punch, shake, jump and paths are all authored in the plane, so they go through this adapter instead
    /// of writing a Vector3 and silently flattening whatever sorting depth the object had.
    /// </summary>
    class TransformPlanarAdapter
    {
        private Transform@ target;
        private bool useLocal;

        /// <summary>
        /// Wraps a transform.
        /// </summary>
        /// <param name="transform">The transform to read and write.</param>
        /// <param name="local">True to work in local space, false for world space.</param>
        TransformPlanarAdapter(Transform@ transform, bool local)
        {
            @target = transform;
            useLocal = local;
        }

        /// <summary>The current position, flattened to the plane.</summary>
        /// <returns>Returns the X and Y of the position.</returns>
        Vector2 Get()
        {
            if (target is null || !Object::IsValid(target)) {
                return Vector2(0.0f, 0.0f);
            }
            Vector3 current = useLocal ? target.localPosition : target.position;
            return Vector2(current.x, current.y);
        }

        /// <summary>Writes a new position in the plane, keeping the existing depth.</summary>
        /// <param name="value">The new X and Y.</param>
        void Set(Vector2 value)
        {
            if (target is null || !Object::IsValid(target)) {
                return;
            }
            Vector3 current = useLocal ? target.localPosition : target.position;
            current.x = value.x;
            current.y = value.y;
            if (useLocal) {
                target.localPosition = current;
            }
            else {
                target.position = current;
            }
        }

        /// <summary>A getter delegate for this adapter.</summary>
        /// <returns>Returns the getter.</returns>
        Vector2Getter@ Getter() { return Vector2Getter(this.Get); }

        /// <summary>A setter delegate for this adapter.</summary>
        /// <returns>Returns the setter.</returns>
        Vector2Setter@ Setter() { return Vector2Setter(this.Set); }
    }

    /// <summary>
    /// Presents a Transform's scale as a Vector2, keeping the Z scale untouched.
    /// </summary>
    class TransformScaleAdapter
    {
        private Transform@ target;

        /// <summary>Wraps a transform's local scale.</summary>
        /// <param name="transform">The transform to read and write.</param>
        TransformScaleAdapter(Transform@ transform) { @target = transform; }

        /// <summary>The current scale, flattened to the plane.</summary>
        /// <returns>Returns the X and Y of the local scale.</returns>
        Vector2 Get()
        {
            if (target is null || !Object::IsValid(target)) {
                return Vector2(1.0f, 1.0f);
            }
            Vector3 current = target.localScale;
            return Vector2(current.x, current.y);
        }

        /// <summary>Writes a new scale in the plane, keeping the existing depth scale.</summary>
        /// <param name="value">The new X and Y scale.</param>
        void Set(Vector2 value)
        {
            if (target is null || !Object::IsValid(target)) {
                return;
            }
            Vector3 current = target.localScale;
            current.x = value.x;
            current.y = value.y;
            target.localScale = current;
        }

        /// <summary>A getter delegate for this adapter.</summary>
        /// <returns>Returns the getter.</returns>
        Vector2Getter@ Getter() { return Vector2Getter(this.Get); }

        /// <summary>A setter delegate for this adapter.</summary>
        /// <returns>Returns the setter.</returns>
        Vector2Setter@ Setter() { return Vector2Setter(this.Set); }
    }

    /// <summary>
    /// Presents a Transform's rotation about the view axis as a single angle in degrees, which is the only
    /// rotation a 2D game actually uses.
    /// </summary>
    class TransformAngleAdapter
    {
        private Transform@ target;
        private bool useLocal;

        /// <summary>Wraps a transform's rotation.</summary>
        /// <param name="transform">The transform to read and write.</param>
        /// <param name="local">True to work in local space, false for world space.</param>
        TransformAngleAdapter(Transform@ transform, bool local)
        {
            @target = transform;
            useLocal = local;
        }

        /// <summary>The current rotation about the view axis.</summary>
        /// <returns>Returns the angle in degrees.</returns>
        float Get()
        {
            if (target is null || !Object::IsValid(target)) {
                return 0.0f;
            }
            Vector3 angles = useLocal ? target.localEulerAngles : target.eulerAngles;
            return angles.z;
        }

        /// <summary>Writes a new rotation about the view axis.</summary>
        /// <param name="value">The angle in degrees.</param>
        void Set(float value)
        {
            if (target is null || !Object::IsValid(target)) {
                return;
            }
            Vector3 angles = useLocal ? target.localEulerAngles : target.eulerAngles;
            angles.z = value;
            if (useLocal) {
                target.localEulerAngles = angles;
            }
            else {
                target.eulerAngles = angles;
            }
        }

        /// <summary>A getter delegate for this adapter.</summary>
        /// <returns>Returns the getter.</returns>
        FloatGetter@ Getter() { return FloatGetter(this.Get); }

        /// <summary>A setter delegate for this adapter.</summary>
        /// <returns>Returns the setter.</returns>
        FloatSetter@ Setter() { return FloatSetter(this.Set); }
    }
}
