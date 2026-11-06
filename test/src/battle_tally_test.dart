import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_stats/battle_stats.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('SOC-22 decision 143 the statistics of a committed log', () {
    late BattleTally tally;

    setUp(() => tally = BattleTally()..addAll(readFixtureLog()));

    final red = Stats(
      shots: const {
        'rifle': Shots(fired: 6, hits: 5),
        'artillery': Shots(fired: 3, hits: 3),
      },
      kills: const {'soldier': 1, 'jeep': 1, 'hq': 1},
      friendlyKills: const {'soldier': 1},
      actions: const {
        ActionKind.hit: 5,
        ActionKind.hqHit: 2,
        ActionKind.defectionCaused: 1,
        ActionKind.capture: 1,
        ActionKind.push: 1,
        ActionKind.observe: 1,
        ActionKind.build: 1,
        ActionKind.repair: 1,
        ActionKind.heal: 1,
      },
    );
    final blue = Stats(
      shots: const {'rifle': Shots(fired: 1, hits: 1)},
      actions: const {ActionKind.hit: 1},
      losses: const {Loss.killed: 2, Loss.defected: 1, Loss.crushed: 1},
    );

    test('per unit: shots, kills by target type, actions by kind', () {
      expect(
        tally.units.keys,
        unorderedEquals([
          'sol-r1',
          'art-r',
          'cmd-r',
          'sol-b2',
          'eng-r',
          'med-r',
          'unit-15',
        ]),
      );
      expect(
        tally.units['sol-r1'],
        Stats(
          shots: const {'rifle': Shots(fired: 4, hits: 3)},
          kills: const {'soldier': 1},
          actions: const {
            ActionKind.hit: 3,
            ActionKind.observe: 1,
            ActionKind.push: 1,
          },
        ),
      );
      expect(tally.units['eng-r']!.actions, {
        ActionKind.build: 1,
        ActionKind.repair: 1,
      });
    });

    test('COMBAT-35 a friendly kill counts apart; an HQ kill is no unit '
        'kill', () {
      final artillery = tally.units['art-r']!;

      expect(artillery.kills, {'jeep': 1, 'hq': 1});
      expect(artillery.friendlyKills, {'soldier': 1});
      expect(artillery.actions, {ActionKind.hit: 1, ActionKind.hqHit: 2});
    });

    test('per section and player, with their losses', () {
      expect(tally.sections['s-red'], red);
      expect(tally.sections['s-blue'], blue);
      expect(tally.sections['s-red2'], Stats(losses: const {Loss.killed: 1}));
      expect(tally.players['acc-red'], red);
      expect(tally.players['acc-blue'], blue);
      expect(tally.accounts, {
        's-red': 'acc-red',
        's-red2': 'acc-red2',
        's-blue': 'acc-blue',
      });
    });

    test('decision 74 a defection counts for the captor, a loss for the '
        'owner, and the unit fights for its captor after', () {
      expect(tally.units['cmd-r']!.actions[ActionKind.defectionCaused], 1);
      expect(tally.sections['s-blue']!.losses[Loss.defected], 1);
      expect(tally.units['sol-b2']!.actions[ActionKind.hit], 1);
    });

    test('decision 230 the first-person shots of each battle-day, a waiting '
        'one included and a refused one not', () {
      expect(tally.aimedDays, unorderedEquals([0, 1]));
      expect(tally.aimedShotsOn(0), {
        'acc-red': {'rifle': const Shots(fired: 2, hits: 1)},
      });
      expect(tally.aimedShotsOn(1), {
        'acc-red': {'rifle': const Shots(fired: 1, hits: 1)},
      });
      expect(tally.aimedShotsOn(2), isEmpty);
    });
  });

  group(BattleTally, () {
    test(
      'UNIT-06 a work finished counts for the unit that resumed it last',
      () {
        final tally = BattleTally()
          ..addAll(const [
            LogEntry(
              at: Duration.zero,
              events: [
                SectionJoined(
                  sectionId: 's',
                  accountId: 'a',
                  team: 't',
                  units: [
                    JoinedUnit(unitId: 'e1', unitType: 'engineer'),
                    JoinedUnit(unitId: 'e2', unitType: 'engineer'),
                  ],
                ),
                BuildStarted(
                  unitId: 'e1',
                  siteId: 'w',
                  structure: 'wall',
                  cells: [Cell(1, 1)],
                  endsAt: Duration(minutes: 1),
                ),
                WorkInterrupted(unitId: 'e1', workId: 'w'),
                WorkResumed(
                  unitId: 'e2',
                  workId: 'w',
                  endsAt: Duration(minutes: 2),
                ),
              ],
            ),
            LogEntry(
              at: Duration(minutes: 2),
              events: [
                StructureBuilt(
                  siteId: 'w',
                  structure: 'wall',
                  cells: [Cell(1, 1)],
                ),
              ],
            ),
          ]);

        expect(tally.units.keys, ['e2']);
        expect(tally.players['a']!.actions, {ActionKind.build: 1});
      },
    );

    test('refuses a unit or a section the log has not named', () {
      expect(
        () => BattleTally().add(
          const LogEntry(
            at: Duration.zero,
            events: [ObservationStarted(unitId: 'x', endsAt: Duration.zero)],
          ),
        ),
        throwsStateError,
      );
      expect(
        () => BattleTally().add(
          const LogEntry(
            at: Duration.zero,
            events: [
              Attacked(
                attackerId: 'x',
                sectionId: 's-x',
                weapon: 'rifle',
                hit: false,
                impacts: [],
              ),
            ],
          ),
        ),
        throwsStateError,
      );
    });
  });
}
