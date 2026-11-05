# battle_stats

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

The **statistics and medals** of Battle Team, a 3D, massive, persistent, real-time team
battle game, computed from the battle logs (decision 143). Pure Dart, no I/O: the caller
passes the log entries of [battle_protocol](https://github.com/hawkbee1/battle_protocol)
and the `medals.yaml` data that [battle_rules](https://github.com/hawkbee1/battle_rules)
reads.

- `BattleTally` reads a battle's log and gives the `Stats` of each unit, section and player:
  enemy kills and friendly kills by target type, actions by kind, losses by cause, and shots
  by weapon. Stats add up for a war and for the game.
- `MedalRules` gives the medals stats reach at the thresholds of `medals.yaml`, and their
  points.
- `HitRateFlags` flags the first-person hit rates far above the norm of a battle-day, for
  the moderation tools.

The `daily_stats` Appwrite Function of hawkbee (`backend/functions/daily_stats`) runs it on
the uploaded logs.

## Part of hawkbee

This repository is a git submodule of the [hawkbee](https://github.com/hawkbee1/hawkbee)
monorepo and **only builds inside it** (pub workspace, `resolution: workspace`):

```sh
git clone --recurse-submodules https://github.com/hawkbee1/hawkbee.git
cd hawkbee && flutter pub get
```

The tests read the plan's `medals.yaml` from that checkout (`apps/battle_team/plan/data`).
`test/fixtures/battle.log` is a committed log, written by `tool/write_fixture.dart`.

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
