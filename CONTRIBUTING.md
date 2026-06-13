# Contributing to Nimbus Digital

Thanks for your interest in improving Nimbus Digital! This is a Garmin Connect IQ
watch face written in [Monkey C](https://developer.garmin.com/connect-iq/monkey-c/).
Contributions of all kinds are welcome — bug reports, new color themes, layout
improvements, device support, and documentation.

By participating in this project you agree to abide by our
[Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Report a bug** — open a [bug report](../../issues/new?template=bug_report.yml).
  Please include your device, firmware version, and the SDK version you used.
- **Request a feature** — open a [feature request](../../issues/new?template=feature_request.yml).
- **Submit a change** — fork, branch, and open a pull request (see below).

## Development setup

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) **9.1.0+**
  (install device profiles via the **SDK / Device Manager**).
- **Java 17+** (Java 21 is what `build.ps1` defaults to).
- **PowerShell** (the build script is PowerShell-based).
- A Connect IQ **developer key** (`developer_key.der`) in the repo root.
  Generate one with:
  ```powershell
  openssl genrsa -out developer_key.pem 4096
  openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
  ```
  This file is git-ignored and must **never** be committed.

### Build

```powershell
# Compile for a specific device
.\build.ps1 -Device fenix7

# Compile and launch in the simulator
.\build.ps1 -Device fenix8solar51mm -Run

# Package a store-ready .iq bundle (all devices in the manifest)
.\build.ps1 -Export
```

On first run, `build.ps1` writes a `build_config.json` (git-ignored) with your
local `JavaHome` and `SdkDir` paths — edit it to match your machine.

## Testing your changes

Because this face targets both **MIP / transflective** (fenix 7 series, fenix 8
Solar) and **AMOLED** (epix 2, venu 3, fr965, fenix 8) displays, please verify
your change on at least one of each before submitting:

- **MIP:** `fenix7` (260px), `fenix8solar51mm` (280px)
- **AMOLED:** `venu3`, `epix2pro47mm`

Things to check in the simulator:

- Legibility at a glance — text and icons should read clearly on the low-contrast
  MIP preview, not just AMOLED.
- **Low-power / Always-On mode** (Settings → toggle sleep) — burn-in shift and the
  reduced AOD layout still render correctly.
- All 8 color themes (App Settings editor → Accent Color).
- Missing-data states (no weather, no HR) fall back gracefully (`--`).

## Coding guidelines

- Match the existing style in `source/NimbusView.mc`: 4-space indentation,
  explicit type annotations on method signatures, and `private var` for fields.
- Keep drawing **procedural** — prefer vector/`dc` drawing over bitmap assets so
  icons scale across screen sizes (see the `drawWeather*` helpers).
- Size everything relative to `mScreenWidth` / `mScreenHeight`, never hard-coded
  pixel sizes, so layouts hold across the supported device range.
- Guard optional APIs with `has` checks (e.g. `Toybox has :Weather`,
  `Activity has :getActivityInfo`) and wrap risky calls in `try/catch`.
- New user settings go in `resources/settings/` (properties + settings) with a
  matching label in `resources/strings/strings.xml`.

## Pull request process

1. Fork the repo and create a topic branch off `main`
   (e.g. `feature/sunrise-indicator` or `fix/wind-overflow`).
2. Make your change and confirm it **builds clean** (`.\build.ps1` with no
   warnings) and runs in the simulator.
3. Fill out the pull request template, including the devices you tested and
   before/after screenshots for any visual change.
4. Keep PRs focused — one logical change per PR is easier to review.

### Commit messages

Short, imperative summaries are preferred, optionally using
[Conventional Commits](https://www.conventionalcommits.org/) prefixes:

```
feat: add sunrise/sunset indicator to the weather module
fix: keep wind speed from overflowing on round MIP screens
docs: document the developer key setup
```

## Questions

Open a [discussion](../../discussions) or file an issue. Thanks for contributing!
