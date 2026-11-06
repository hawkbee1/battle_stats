import 'package:battle_stats/battle_stats.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('SOC-24 SOC-25 SOC-26 the medals of the plan', () {
    final rules = MedalRules(planMedals());

    List<String> tiers(Stats stats, String track) => [
      for (final medal in rules.of(stats))
        if (medal.track == track) medal.tier,
    ];

    test('decision 105 each tier of a commander kill track is reached at its '
        'threshold: bronze at 5 commanders', () {
      List<String> at(int kills) =>
          tiers(Stats(kills: {'commander': kills}), 'kills.commander');

      expect(at(4), isEmpty);
      expect(at(5), ['bronze']);
      expect(at(24), ['bronze']);
      expect(at(25), ['bronze', 'silver']);
      expect(at(99), ['bronze', 'silver']);
      expect(at(100), ['bronze', 'silver', 'gold']);
    });

    test('every other unit type follows the default kill track; an HQ has '
        'none', () {
      List<String> at(int kills) =>
          tiers(Stats(kills: {'jeep': kills}), 'kills.jeep');

      expect(at(19), isEmpty);
      expect(at(20), ['bronze']);
      expect(at(100), ['bronze', 'silver']);
      expect(at(500), ['bronze', 'silver', 'gold']);
      expect(rules.of(Stats(kills: const {'hq': 1000})), isEmpty);
    });

    test('each kind of action has a track', () {
      List<String> at(int heals) =>
          tiers(Stats(actions: {ActionKind.heal: heals}), 'actions.heal');

      expect(at(49), isEmpty);
      expect(at(50), ['bronze']);
      expect(at(250), ['bronze', 'silver']);
      expect(at(1000), ['bronze', 'silver', 'gold']);
      expect(
        planMedals().actionKinds,
        unorderedEquals([
          ActionKind.hit,
          ActionKind.build,
          ActionKind.repair,
          ActionKind.heal,
          ActionKind.capture,
          ActionKind.observe,
          ActionKind.push,
          ActionKind.hqHit,
          ActionKind.prisonerTaken,
          ActionKind.defectionCaused,
        ]),
      );
    });

    test('COMBAT-35 decision 231 friendly kills of every type add up on '
        'their own track and never on a kill track', () {
      List<String> at(int jeeps) => tiers(
        Stats(friendlyKills: {'soldier': 4, 'jeep': jeeps}),
        'friendly_kills',
      );

      expect(at(0), isEmpty);
      expect(at(1), ['bronze']);
      expect(at(21), ['bronze', 'silver']);
      expect(at(96), ['bronze', 'silver', 'gold']);
      expect(
        rules
            .of(Stats(friendlyKills: const {'commander': 100}))
            .where((medal) => medal.track.startsWith('kills.')),
        isEmpty,
      );
    });

    test('SOC-29 medal points: bronze 1, silver 3, gold 10, each tier a '
        'medal of its own', () {
      final medals = rules.of(Stats(kills: const {'commander': 100}));

      expect(rules.points(medals), 14);
      expect(rules.points(const []), 0);
      expect(
        medals.first,
        Medal(track: 'kills.commander', tier: ['bronze'].first),
      );
    });
  });
}
