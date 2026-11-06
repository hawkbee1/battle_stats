import 'package:battle_rules/battle_rules.dart';
import 'package:battle_stats/battle_stats.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('decision 230 hit rates far above the norm', () {
    final flags = HitRateFlags(planMedals().hitRateFlag);

    /// Ten players hitting [hits] of 100 rifle shots, and one more with
    /// [cheater] hits of [shots].
    AimedShots day(int cheater, {int shots = 100}) => {
      for (var i = 0; i < 10; i++)
        'acc-$i': {'rifle': Shots(fired: 100, hits: 40 + i)},
      'acc-x': {'rifle': Shots(fired: shots, hits: cheater)},
    };

    test('flags a player 3 standard deviations above the mean of the players '
        'with that weapon that day', () {
      final flagged = flags.of(4, day(95)).single;

      expect(flagged.day, 4);
      expect(flagged.accountId, 'acc-x');
      expect(flagged.weapon, 'rifle');
      expect(flagged.shots, const Shots(fired: 100, hits: 95));
      expect(flagged.mean, closeTo(0.4909, 1e-4));
      expect(flagged.shots.rate, greaterThan(flagged.mean + 3 * flagged.sigma));
      expect(
        flagged,
        FlaggedHitRate(
          day: 4,
          accountId: 'acc-x',
          weapon: 'rifle',
          shots: const Shots(fired: 100, hits: 95),
          mean: flagged.mean,
          sigma: flagged.sigma,
        ),
      );
    });

    test('flags no one within the norm', () {
      expect(flags.of(4, day(50)), isEmpty);
    });

    test('ignores a player with fewer than 50 shots with the weapon', () {
      expect(flags.of(4, day(49, shots: 49)), isEmpty);
    });

    test('compares each weapon apart', () {
      final shots = {
        ...day(50),
        'acc-y': {'mortar': const Shots(fired: 60, hits: 60)},
      };

      expect(flags.of(1, shots), isEmpty);
      expect(
        const HitRateFlags(HitRateFlag(sigmas: 0, minShots: 1))
            .of(1, {
              'a': {'mortar': const Shots(fired: 2, hits: 2)},
              'b': {'mortar': const Shots(fired: 2)},
            })
            .map((flag) => flag.accountId),
        ['a'],
      );
    });
  });
}
