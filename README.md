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

## Running the tests

The suite runs itself. Opening the project compiles the scripts, and that compile triggers the runner, which
writes its report to `Library/TweenyTestReport.txt`. No play mode and no scene needed.

To run it from a terminal, with the compile gate as well:

```bash
CometEngine --path E:\GitHub\Tweeny --headless --test-incremental-compile --test-report report.txt
```

That single command compiles every script in the project and the package, fails on any AngelScript error,
and leaves the test report behind. There are just under five hundred checks across ten suites.

## Documentation

The documentation site lives at [oriolcs2.github.io/Tweeny](https://oriolcs2.github.io/Tweeny) and is served
from the `docs/` folder. Enable it under **Settings › Pages › Deploy from a branch › main › /docs**.

| Page | What it holds |
|---|---|
| `docs/index.html` | Overview: what Tweeny is, how to install it, what it can do. |
| `docs/guide.html` | The guide, written front to back, with a runnable example per feature. |
| `docs/reference.html` | Every function, setter, enum and callback in the package. |
| `docs/assets/` | The shared stylesheet and the small script that colours code and tracks the sidebar. |

## Licence

MIT. See [LICENSE](LICENSE).
