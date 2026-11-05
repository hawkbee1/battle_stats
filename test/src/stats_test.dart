import 'package:battle_stats/battle_stats.dart';
import 'package:test/test.dart';

void main() {
  group(Stats, () {
    final some = Stats(
      kills: const {'soldier': 2},
      friendlyKills: const {'jeep': 1, 'soldier': 2},
      actions: const {ActionKind.heal: 3},
      losses: const {Loss.prisoner: 1},
      shots: const {'rifle': Shots(fired: 4, hits: 1)},
    );

    test('adds up, for a war and for the game', () {
      final more = Stats(
        kills: const {'soldier': 1, 'commander': 1},
        losses: const {Loss.prisoner: 2},
        shots: const {
          'rifle': Shots(fired: 1, hits: 1),
          'mortar': Shots(fired: 2),
        },
      );

      expect(
        Stats.sum([some, more]),
        Stats(
          kills: const {'soldier': 3, 'commander': 1},
          friendlyKills: const {'jeep': 1, 'soldier': 2},
          actions: const {ActionKind.heal: 3},
          losses: const {Loss.prisoner: 3},
          shots: const {
            'rifle': Shots(fired: 5, hits: 2),
            'mortar': Shots(fired: 2),
          },
        ),
      );
      expect(Stats.sum(const []), Stats());
      expect(some.friendlyKillCount, 3);
    });

    test('reads back what it writes as JSON', () {
      expect(Stats.fromJson(some.toJson()), some);
    });

    test('refuses JSON that is not stats', () {
      Map<String, Object?> json(String key, Object? value) => {
        ...some.toJson(),
        key: value,
      };

      for (final damaged in [
        json('kills', 3),
        json('actions', {'heal': 'three'}),
        json('losses', {'stolen': 1}),
        json('shots', {
          'rifle': [1],
        }),
      ]) {
        expect(() => Stats.fromJson(damaged), throwsFormatException);
      }
    });
  });

  group(Shots, () {
    test('a rate is the share of hits; none fired is 0', () {
      expect(const Shots(fired: 4, hits: 1).rate, 0.25);
      expect(const Shots().rate, 0);
    });
  });
}
