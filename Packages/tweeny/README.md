# Tweeny

A complete tweening and animation engine for CometEngine.

Tweeny animates anything you can read and write: positions, rotations, scales, colours, alpha, UI, audio,
and any value of your own. It ships easings, sequences, paths, punch and shake, callbacks, coroutine
integration, an inspector-driven animation component and an in-editor inspector with live preview.

```angelscript
using namespace Tweeny;

// Move something, with an ease, looping back and forth forever.
Move(transform, Vector2(5.0f, 0.0f), 1.0f)
    .SetEase(Ease::OutBack)
    .SetLoops(-1, LoopType::Yoyo);

// Chain a few things together.
TweenSequence@ intro = Sequence();
intro.Append(Move(transform, Vector2(0.0f, 3.0f), 0.5f));
intro.Join(Fade(renderer, 1.0f, 0.5f));
intro.AppendInterval(0.2f);
intro.AppendCallback(TweenCallback(this.OnIntroDone));
```

## Setup

Import the package. That is the whole setup.

Tweeny registers itself through a project setting, so the moment the package is in your project the engine
creates its runner at play start. There is no prefab to place, no manager to add to a scene and no
initialisation call. Open **Project Settings > TweenySettings** to change the defaults (easing, loop type,
auto-kill, time scale and so on).

## What is in the box

| Area | What you get |
|---|---|
| Easings | 38 built-in curves, plus your own easing function or a stop-motion wrapper |
| Value types | float, int, Vector2, Vector3, Color, angle, Rect and string |
| Timing | delays, loops (restart, yoyo, incremental), relative and speed-based tweens, `From` |
| Control | play, pause, rewind, restart, complete, kill, flip, goto, plus filtered versions by id or target |
| Callbacks | start, play, pause, rewind, update, step complete, complete, kill, waypoint change |
| Sequences | append, prepend, join, insert, intervals, callbacks and nesting |
| Effects | punch, shake, jump, paths (straight and curved) at a constant speed |
| Shortcuts | Transform, renderers, tilemaps, camera, lights, audio and the whole UI stack |
| Coroutines | `WaitForCompletion`, `WaitForKill`, `WaitForRewind`, `WaitForElapsedLoops`, `WaitForPosition`, `WaitForStart` |
| Editor | Tweeny Inspector window with a live tween list and a preview that restores everything afterwards |
| No code | `TweenyAnimation` animates an entity straight from the inspector |

## How the API reads

**Shortcuts take their target as the first argument.** AngelScript has no extension methods, so a shortcut
is a free function in the `Tweeny` namespace: `Move(transform, ...)`, `Tint(renderer, ...)`,
`Fade(renderer, ...)`. There is no prefix on any of them — the namespace already does that job, so
`Tweeny::Move` is unambiguous on its own.

**Everything after the shortcut is a chained setter.** `SetEase`, `SetLoops`, `SetDelay`, `SetRelative`,
`SetSpeedBased`, `SetAutoKill`, `SetUpdate`, `SetId`, `SetTarget`, `SetLink`, `From`, `OnComplete` and the
rest all return the tween, so a whole animation is one statement.

**Rotation is a scalar angle.** Comet is a 2D engine, so `Rotate(transform, degrees, duration)` takes a
number of degrees rather than a quaternion — which is also what makes `RotateMode::FastBeyond360` possible.

**Colour shortcuts are named `Tint`, not `Color`.** `Color` is already a Comet type, and a function of the
same name would make every file that imports both namespaces ambiguous.

Three things are deliberately absent, each for a concrete reason:

- **Object pooling.** Pools exist to dodge a tracing garbage collector. AngelScript is reference counted, so
  a finished tween is released the moment the last handle drops. A pool would buy nothing here and would
  bring its worst footgun: a recycled tween that reports itself alive while being a different animation.
- **`await`-style asynchrony.** AngelScript has no equivalent. The functionality does not disappear: use
  `OnComplete`, or wait inside a coroutine with `Yield(WaitForCompletion(tween))`.
- **Generic plugins.** AngelScript has no script-side generics. Write a `To` with your own getter and setter
  instead; that is the extension point, and it is the same one the built-in shortcuts use.

## Getting a value moving

Any pair of functions that read and write a value can be tweened, which is how you animate things Tweeny
has never heard of:

```angelscript
float GetHealth() { return health; }
void SetHealth(float v) { health = v; }

To(FloatGetter(this.GetHealth), FloatSetter(this.SetHealth), 100.0f, 2.0f)
    .SetEase(Ease::OutQuint);
```

## Tweeny Inspector

**Tweeny > Tweeny Inspector** in the main menu opens a window listing every live tween with its progress and
state, with per-tween play, pause, rewind, complete and kill. The preview button runs the tweens inside the
editor without entering play mode and puts every target back where it was when you stop.

## Licence

MIT. See LICENSE.md.
