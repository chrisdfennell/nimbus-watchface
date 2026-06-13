# Changelog

All notable changes to Nimbus Digital are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Improved legibility on MIP / transflective displays: larger date, temperature,
  label, and value fonts, and bold small-caps labels.
- Raised contrast of secondary text (daily High/Low now bright off-white instead
  of the dark accent color; brighter forecast day labels; lighter humidity icon).
- Thicker icon strokes for the humidity and wind glyphs.

### Fixed
- Weather detail metrics (precipitation, humidity, wind) are now measured and
  centered as a single row so wind speed no longer overflows the right edge on
  round screens.

### Removed
- Redundant text condition label under the current weather (the icon already
  conveys the condition), freeing vertical space.

[Unreleased]: ../../compare/main...HEAD
