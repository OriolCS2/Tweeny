# Tweeny

A complete tweening and animation engine for [CometEngine](https://www.cometengine.org).

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

Import the [package](https://www.cometengine.org/marketplace/tweeny).


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

**Shortcuts take their target as the first argument.** Free function in the `Tweeny` namespace: `Move(transform, ...)`, `Tint(renderer, ...)`,
`Fade(renderer, ...)`.

**Everything after the shortcut is a chained setter.** `SetEase`, `SetLoops`, `SetDelay`, `SetRelative`,
`SetSpeedBased`, `SetAutoKill`, `SetUpdate`, `SetId`, `SetTarget`, `SetLink`, `From`, `OnComplete` and the
rest all return the tween, so a whole animation is one statement.

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
editor without entering play mode.

## Licence

MIT. See LICENSE.md.
