# Tweeny

A complete tweening and animation engine for CometEngine.

This repository is the development project for the package. The package itself lives in
[`Packages/tweeny/`](Packages/tweeny) — that folder is what gets published, and
[its README](Packages/tweeny/README.md) is the documentation you want if you just came to use Tweeny.

## What is in this repository

| Path | What it holds |
|---|---|
| `Packages/tweeny/` | The package. Runtime and editor assemblies, and nothing else ships. |
| `Assets/Scenes/` | Eleven demo scenes covering every feature. |
| `Assets/Demo/` | The scripts that build and chain the demos. |
| `Assets/Editor/Tests/` | The test suite. Deliberately outside the package, so no consumer ever receives it. |

## Seeing it work

Open the project and press Play on `Assets/Scenes/00_Bootstrap`. The demo tour walks itself through all
eleven scenes and loops back to the start, so one Play shows every feature: easings, loops, sequences, punch
and shake, jumps, paths, shortcuts, playback control, coroutines, the inspector-driven component, and a
stress test running four hundred simultaneous tweens.

## Licence

MIT. See [LICENSE](LICENSE).
