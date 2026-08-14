using namespace CometEngine;

namespace Tweeny
{
    /// <summary>
    /// True when an object can still be read and written through.
    /// </summary>
    ///
    /// A handle can outlive the thing it points at: destroy an entity and every handle to its components
    /// stays non-null while the object behind it is gone. Reading a property through one of those is fatal,
    /// so every guard below asks this first.
    /// <param name="target">The object to check. Null is not alive.</param>
    /// <returns>Returns true when the object is safe to touch.</returns>
    bool IsAlive(Object@ target)
    {
        return target !is null && Object::IsValid(target);
    }

    /// <summary>
    /// Wraps a float property so the tween driving it cannot be hurt by its target going away.
    ///
    /// A tween holds a getter and a setter, and those delegates are bound to the object they read. Bind them
    /// straight to a target and two things go wrong: building the delegate at all needs a live target, and a
    /// target destroyed halfway through the animation takes the next frame down with it. Routing through a
    /// guard fixes both -- the delegates belong to the guard, which is always alive, and the guard checks
    /// the target before every read and write.
    ///
    /// Constructed with no arguments it is inert: reads return the fallback and writes go nowhere. That is
    /// what a shortcut hands back when it is asked to animate something that is already gone, so the call
    /// still returns a real tween and the chained setters after it stay safe.
    /// </summary>
    class GuardedFloat
    {
        private Object@ owner;
        private FloatGetter@ reader;
        private FloatSetter@ writer;
        private float fallback = 0.0f;

        /// <summary>Makes an inert guard, for a target that is already gone.</summary>
        GuardedFloat() {}

        /// <summary>Makes a guard over a live target.</summary>
        /// <param name="target">The object that owns the property.</param>
        /// <param name="get">Reads the property.</param>
        /// <param name="set">Writes the property.</param>
        /// <param name="fallbackValue">What a read returns once the target is gone.</param>
        GuardedFloat(Object@ target, FloatGetter@ get, FloatSetter@ set, float fallbackValue = 0.0f)
        {
            @owner = target;
            @reader = get;
            @writer = set;
            fallback = fallbackValue;
        }

        /// <summary>Reads the property, or the fallback once the target is gone.</summary>
        /// <returns>Returns the current value.</returns>
        float Get()
        {
            if (reader is null || !IsAlive(owner)) {
                return fallback;
            }
            return reader();
        }

        /// <summary>Writes the property, and does nothing once the target is gone.</summary>
        /// <param name="value">The value to write.</param>
        void Set(float value)
        {
            if (writer is null || !IsAlive(owner)) {
                return;
            }
            writer(value);
        }

        /// <summary>A getter delegate for this guard.</summary>
        /// <returns>Returns the getter.</returns>
        FloatGetter@ Getter() { return FloatGetter(this.Get); }

        /// <summary>A setter delegate for this guard.</summary>
        /// <returns>Returns the setter.</returns>
        FloatSetter@ Setter() { return FloatSetter(this.Set); }
    }

    /// <summary>Guards a Vector2 property. See <see cref="GuardedFloat"/> for why this exists.</summary>
    class GuardedVector2
    {
        private Object@ owner;
        private Vector2Getter@ reader;
        private Vector2Setter@ writer;
        private Vector2 fallback = Vector2(0.0f, 0.0f);

        /// <summary>Makes an inert guard, for a target that is already gone.</summary>
        GuardedVector2() {}

        /// <summary>Makes a guard over a live target.</summary>
        /// <param name="target">The object that owns the property.</param>
        /// <param name="get">Reads the property.</param>
        /// <param name="set">Writes the property.</param>
        /// <param name="fallbackValue">What a read returns once the target is gone.</param>
        GuardedVector2(Object@ target, Vector2Getter@ get, Vector2Setter@ set,
                       Vector2 fallbackValue = Vector2(0.0f, 0.0f))
        {
            @owner = target;
            @reader = get;
            @writer = set;
            fallback = fallbackValue;
        }

        /// <summary>Reads the property, or the fallback once the target is gone.</summary>
        /// <returns>Returns the current value.</returns>
        Vector2 Get()
        {
            if (reader is null || !IsAlive(owner)) {
                return fallback;
            }
            return reader();
        }

        /// <summary>Writes the property, and does nothing once the target is gone.</summary>
        /// <param name="value">The value to write.</param>
        void Set(Vector2 value)
        {
            if (writer is null || !IsAlive(owner)) {
                return;
            }
            writer(value);
        }

        /// <summary>A getter delegate for this guard.</summary>
        /// <returns>Returns the getter.</returns>
        Vector2Getter@ Getter() { return Vector2Getter(this.Get); }

        /// <summary>A setter delegate for this guard.</summary>
        /// <returns>Returns the setter.</returns>
        Vector2Setter@ Setter() { return Vector2Setter(this.Set); }
    }

    /// <summary>Guards a Vector3 property. See <see cref="GuardedFloat"/> for why this exists.</summary>
    class GuardedVector3
    {
        private Object@ owner;
        private Vector3Getter@ reader;
        private Vector3Setter@ writer;
        private Vector3 fallback = Vector3(0.0f, 0.0f, 0.0f);

        /// <summary>Makes an inert guard, for a target that is already gone.</summary>
        GuardedVector3() {}

        /// <summary>Makes a guard over a live target.</summary>
        /// <param name="target">The object that owns the property.</param>
        /// <param name="get">Reads the property.</param>
        /// <param name="set">Writes the property.</param>
        /// <param name="fallbackValue">What a read returns once the target is gone.</param>
        GuardedVector3(Object@ target, Vector3Getter@ get, Vector3Setter@ set,
                       Vector3 fallbackValue = Vector3(0.0f, 0.0f, 0.0f))
        {
            @owner = target;
            @reader = get;
            @writer = set;
            fallback = fallbackValue;
        }

        /// <summary>Reads the property, or the fallback once the target is gone.</summary>
        /// <returns>Returns the current value.</returns>
        Vector3 Get()
        {
            if (reader is null || !IsAlive(owner)) {
                return fallback;
            }
            return reader();
        }

        /// <summary>Writes the property, and does nothing once the target is gone.</summary>
        /// <param name="value">The value to write.</param>
        void Set(Vector3 value)
        {
            if (writer is null || !IsAlive(owner)) {
                return;
            }
            writer(value);
        }

        /// <summary>A getter delegate for this guard.</summary>
        /// <returns>Returns the getter.</returns>
        Vector3Getter@ Getter() { return Vector3Getter(this.Get); }

        /// <summary>A setter delegate for this guard.</summary>
        /// <returns>Returns the setter.</returns>
        Vector3Setter@ Setter() { return Vector3Setter(this.Set); }
    }

    /// <summary>Guards a Color property. See <see cref="GuardedFloat"/> for why this exists.</summary>
    class GuardedColor
    {
        private Object@ owner;
        private ColorGetter@ reader;
        private ColorSetter@ writer;
        private CometEngine::Color fallback = CometEngine::Color(1.0f, 1.0f, 1.0f, 1.0f);

        /// <summary>Makes an inert guard, for a target that is already gone.</summary>
        GuardedColor() {}

        /// <summary>Makes a guard over a live target.</summary>
        /// <param name="target">The object that owns the property.</param>
        /// <param name="get">Reads the property.</param>
        /// <param name="set">Writes the property.</param>
        GuardedColor(Object@ target, ColorGetter@ get, ColorSetter@ set)
        {
            @owner = target;
            @reader = get;
            @writer = set;
        }

        /// <summary>Reads the property, or white once the target is gone.</summary>
        /// <returns>Returns the current value.</returns>
        CometEngine::Color Get()
        {
            if (reader is null || !IsAlive(owner)) {
                return fallback;
            }
            return reader();
        }

        /// <summary>Writes the property, and does nothing once the target is gone.</summary>
        /// <param name="value">The value to write.</param>
        void Set(CometEngine::Color value)
        {
            if (writer is null || !IsAlive(owner)) {
                return;
            }
            writer(value);
        }

        /// <summary>A getter delegate for this guard.</summary>
        /// <returns>Returns the getter.</returns>
        ColorGetter@ Getter() { return ColorGetter(this.Get); }

        /// <summary>A setter delegate for this guard.</summary>
        /// <returns>Returns the setter.</returns>
        ColorSetter@ Setter() { return ColorSetter(this.Set); }
    }
}
