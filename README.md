# Nimbus Digital — Premium Garmin Weather-First Dashboard

Nimbus Digital is a premium, data-driven, weather-first digital watch face for Garmin Connect IQ. It is designed to provide an information-rich dashboard experience that remains highly legible, optimized for both MIP and AMOLED displays (Fenix, Epix, Venu, Forerunner, etc.).

By presenting current weather conditions, a full 5-day forecast, activity metrics, and device status in a clean, unified dashboard, Nimbus Digital ensures you have all critical information available at a single glance.

## Design Aesthetics & Philosophy
- **Clean Digital Interface**: Large, high-visibility digital clock featuring a split-color layout (hour in accent theme, minutes in white/silver).
- **Weather-First Dashboard**: Prominent weather section displaying live temperature, condition name, daily high/low, and detailed metrics (precipitation chance, relative humidity, wind speed).
- **Procedural Icon System**: Custom, vector-drawn weather icons (Sun, Cloud, Rain, Snow, Storm, Wind, Fog, Mixed) that scale cleanly without using heavy bitmap assets.
- **5-Day Forecast Row**: A dedicated daily forecast grid keeping you ahead of the weather for the upcoming week.
- **Full Activity Suite**: A neat four-column footer tracking Calories, Distance, Floors, and Active Minutes, alongside side indicators for Steps and Heart Rate.
- **Status Header**: Top-aligned status bar indicating Battery percentage (with responsive colored icon), solar charging intensity, phone connection status, active alarms, and notifications/DND.
- **AMOLED Burn-In Protection**: Shifted Always-On-Display (AOD) sleep layout that displays only the essential metrics and utilizes active pixel-shifting to protect screens.

## Key Features & Layout Details

1. **Header Row (Top Complications)**
   - Battery (percentage text + battery shape filled dynamically based on charge level, turning orange/red on low battery, green when charging).
   - Solar intensity level (on supported Garmin solar devices).
   - Phone Connection status icon (fades to gray when disconnected).
   - Active Alarm bell indicator.
   - Message notification envelope or purple DND crescent moon.

2. **Time & Side Indicators**
   - Large bold digital clock in the upper center.
   - Live sweeping second counter (optional, hidden in sleep mode).
   - Active Steps counter on the left side of the time.
   - Real-time Heart Rate (BPM) on the right side of the time.

3. **Date Banner**
   - Centered weekday and date readout (e.g. `FRIDAY, JUN 12`).

4. **Weather Module**
   - Procedural weather icon.
   - Current temperature (respects system statute/metric settings for °C/°F).
   - Daily High/Low forecast range (e.g. `H:64 L:51`).
   - Precipitation chance (☂), relative humidity (◈), and wind speed (¶ in mph or km/h).
   - Condition label (e.g. `CLOUDY`).

5. **5-Day Forecast Row**
   - Divided layout showing weekday abbreviation, weather category icon, and high/low temperature ranges for the next 5 days.

6. **Activity Footer Grid**
   - 4-Column stats grid tracking:
     - **CAL** — Calories burned (kcal)
     - **DIST** — Distance traveled (mi or km)
     - **FLOORS** — Floors climbed
     - **ACTIVE** — Weekly active minutes

## Customization (Garmin Connect Phone App)
Custom settings can be configured instantly in the Garmin Connect or Connect IQ phone application:

- **Accent Color**: Choose from 8 harmonious color palettes:
  - Midnight Gold (Default)
  - Rose Gold
  - Arctic Teal
  - Ember Orange
  - Forest Green
  - Lavender Mist
  - Pearl Silver
  - Solar Amber
- **Show Seconds**: Toggle the seconds indicator on/off.

## Building & Running

### Prerequisites
- Garmin Connect IQ SDK (9.1.0+ recommended) via SDK Manager.
- Java 11+.
- PowerShell.

### Build
```powershell
# Compiles the project for the target device
.\build.ps1 -Device venu3
```

### Run in Simulator
```powershell
# Launches the watch face inside the simulator
.\build.ps1 -Device venu3 -Run
```

The build script will automatically compile, copy setting schemas, and run `monkeydo` with sidecar configuration so you can edit mock settings locally.

## Project Structure
- `source/NimbusApp.mc` — Application entry point and settings listener.
- `source/NimbusView.mc` — Core rendering code, dashboard layouts, procedural drawing.
- `resources/settings/` — properties.xml and settings.xml defining user configuration.
- `resources/strings/strings.xml` — Text labels and localization settings.
- `assets/` — Promotional materials, store screenshots, and branding templates.
- `docs/` — Interactive web simulator landing page.

## Releasing

Releases are built automatically by [`.github/workflows/release.yml`](.github/workflows/release.yml).
Push a version tag and the workflow compiles a side-loadable `.prg` and a
store-ready `.iq`, then attaches both to a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The only one-time setup is a `GARMIN_DEVELOPER_KEY` repository secret (your
base64-encoded developer key) — the SDK ships inside the build container, so
nothing else is needed. See the header comment in the workflow file.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, build,
and testing guidelines, and please follow the [Code of Conduct](CODE_OF_CONDUCT.md).
Security issues should be reported privately per [SECURITY.md](SECURITY.md).

## License

Released under the [MIT License](LICENSE).