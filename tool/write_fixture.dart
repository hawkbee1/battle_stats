// Writes the committed log fixture of the tests, `test/fixtures/battle.log`:
// a short battle with every kind of entry the statistics read. The tests
// read the committed bytes, so a change of the format shows there.
//
// Run from the package: dart run tool/write_fixture.dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:battle_protocol/battle_protocol.dart';

const _red = Sender(accountId: 'acc-red', sectionId: 's-red');
const _blue = Sender(accountId: 'acc-blue', sectionId: 's-blue');

Command _command(int seq, Order order, {Sender sender = _red}) => Command(
  sender: sender,
  sentAt: Duration.zero,
  order: order,
  origin: Origin.player,
  seq: seq,
);

Impact _impact(
  String target,
  String type,
  ImpactResult result, {
  bool friendly = false,
}) => Impact(
  targetId: target,
  targetType: type,
  damage: 10,
  friendly: friendly,
  result: result,
);

Attacked _attack(
  String attacker,
  String weapon,
  List<Impact> impacts, {
  String section = 's-red',
  bool hit = true,
}) => Attacked(
  attackerId: attacker,
  sectionId: section,
  weapon: weapon,
  hit: hit,
  impacts: impacts,
);

LogEntry _at(int seconds, List<BattleEvent> events, [Command? command]) =>
    LogEntry(
      at: Duration(seconds: seconds),
      command: command,
      events: events,
    );

final _aim = FireAimed(
  unitId: 'sol-r1',
  aim: Direction.of(1, 0, 0),
  fireTime: Duration.zero,
);

/// The fixture battle.
final entries = <LogEntry>[
  _at(0, const [
    BattleStarted(battleId: 'b-fixture', mapId: 'valley', seed: 3),
    SectionJoined(
      sectionId: 's-red',
      accountId: 'acc-red',
      team: 'red',
      units: [
        JoinedUnit(unitId: 'cmd-r', unitType: 'commander'),
        JoinedUnit(unitId: 'sol-r1', unitType: 'soldier'),
        JoinedUnit(unitId: 'eng-r', unitType: 'engineer'),
        JoinedUnit(unitId: 'med-r', unitType: 'medic'),
        JoinedUnit(unitId: 'art-r', unitType: 'artillery'),
      ],
    ),
    SectionJoined(
      sectionId: 's-red2',
      accountId: 'acc-red2',
      team: 'red',
      units: [JoinedUnit(unitId: 'sol-r2', unitType: 'soldier')],
    ),
    SectionJoined(
      sectionId: 's-blue',
      accountId: 'acc-blue',
      team: 'blue',
      units: [
        JoinedUnit(unitId: 'cmd-b', unitType: 'commander'),
        JoinedUnit(unitId: 'sol-b1', unitType: 'soldier'),
        JoinedUnit(unitId: 'sol-b2', unitType: 'soldier'),
        JoinedUnit(unitId: 'jeep-b', unitType: 'jeep'),
      ],
    ),
  ]),
  // A hit, then a first-person kill.
  _at(10, [
    _attack('sol-r1', 'rifle', [
      _impact('sol-b1', 'soldier', ImpactResult.damaged),
    ]),
  ], _command(1, const Fire(unitId: 'sol-r1', targetId: 'sol-b1'))),
  _at(20, [
    _attack('sol-r1', 'rifle', [
      _impact('sol-b1', 'soldier', ImpactResult.killed),
    ]),
  ], _command(2, _aim)),
  // A first-person shot that waits, then misses.
  _at(30, const [
    OrderDelayed(seq: 3, until: Duration(seconds: 40)),
  ], _command(3, _aim)),
  _at(40, [_attack('sol-r1', 'rifle', const [], hit: false)]),
  // An artillery shot: an enemy jeep and a friendly soldier killed.
  _at(
    50,
    [
      _attack('art-r', 'artillery', [
        _impact('jeep-b', 'jeep', ImpactResult.killed),
        _impact('sol-r2', 'soldier', ImpactResult.killed, friendly: true),
      ]),
    ],
    _command(
      4,
      FireAtPosition(unitId: 'art-r', target: Position.metres(60, 20, 0)),
    ),
  ),
  // A defection; the turned soldier then fires for its new section.
  _at(60, [
    _attack('cmd-r', 'rifle', [
      _impact('sol-b2', 'soldier', ImpactResult.defected),
    ]),
  ], _command(5, const Fire(unitId: 'cmd-r', targetId: 'sol-b2'))),
  _at(70, [
    _attack('sol-b2', 'rifle', [
      _impact('cmd-b', 'commander', ImpactResult.damaged),
    ]),
  ], _command(6, const Fire(unitId: 'sol-b2', targetId: 'cmd-b'))),
  // A build and a repair, finished by timers.
  _at(
    80,
    const [
      BuildStarted(
        unitId: 'eng-r',
        siteId: 'wall@(3, 4)',
        structure: 'wall',
        cells: [Cell(3, 4)],
        endsAt: Duration(seconds: 90),
      ),
    ],
    _command(
      7,
      const Build(unitId: 'eng-r', structure: 'wall', cells: [Cell(3, 4)]),
    ),
  ),
  _at(90, const [
    StructureBuilt(
      siteId: 'wall@(3, 4)',
      structure: 'wall',
      cells: [Cell(3, 4)],
    ),
  ]),
  _at(100, const [
    RepairStarted(
      unitId: 'eng-r',
      targetId: 'art-r',
      endsAt: Duration(seconds: 110),
    ),
  ], _command(8, const Repair(unitId: 'eng-r', targetId: 'art-r'))),
  _at(110, const [Repaired(targetId: 'art-r', hp: 50)]),
  // A heal, an observation, a capture and a push.
  _at(120, const [
    UnitHealed(unitId: 'med-r', targetId: 'sol-r1', hp: 20),
  ], _command(9, const Heal(unitId: 'med-r', targetId: 'sol-r1'))),
  _at(130, const [
    ObservationStarted(unitId: 'sol-r1', endsAt: Duration(hours: 1)),
  ], _command(10, const Observe(unitId: 'sol-r1'))),
  _at(140, const [
    AddedToCapture(unitId: 'cmd-r', relicId: 'relic-1', potAp: 5),
  ], _command(11, const Capture(unitId: 'cmd-r', relicId: 'relic-1'))),
  _at(150, const [
    AddedToPush(unitId: 'sol-r1', relicId: 'relic-2', potAp: 5),
  ], _command(12, const Push(unitId: 'sol-r1', relicId: 'relic-2'))),
  // Two shots at the blue HQ, the second destroys it.
  _at(
    160,
    [
      _attack('art-r', 'artillery', [
        _impact('hq-blue', 'hq', ImpactResult.damaged),
      ]),
    ],
    _command(
      13,
      FireAtPosition(unitId: 'art-r', target: Position.metres(110, 0, 0)),
    ),
  ),
  _at(
    170,
    [
      _attack('art-r', 'artillery', [
        _impact('hq-blue', 'hq', ImpactResult.killed),
      ]),
    ],
    _command(
      14,
      FireAtPosition(unitId: 'art-r', target: Position.metres(110, 0, 0)),
    ),
  ),
  // A relic crushes the blue commander.
  _at(180, const [
    Crushed(byId: 'relic-2', unitId: 'cmd-b', unitType: 'commander'),
  ]),
  // Blue buys a soldier, which hits.
  _at(190, const [
    UnitPurchased(
      sectionId: 's-blue',
      unitId: 'unit-15',
      unitType: 'soldier',
      price: 200,
    ),
  ], _command(15, const BuyUnit(unitType: 'soldier'), sender: _blue)),
  _at(
    200,
    [
      _attack('unit-15', 'rifle', section: 's-blue', [
        _impact('sol-r1', 'soldier', ImpactResult.damaged),
      ]),
    ],
    _command(
      16,
      const Fire(unitId: 'unit-15', targetId: 'sol-r1'),
      sender: _blue,
    ),
  ),
  // A first-person shot that waits, then is refused.
  _at(210, const [
    OrderDelayed(seq: 17, until: Duration(seconds: 220)),
  ], _command(17, _aim)),
  _at(220, const [OrderRefused(seq: 17, reason: 'weapon_busy')]),
  // The next battle-day: a first-person hit.
  _at(86405, [
    _attack('sol-r1', 'rifle', [
      _impact('unit-15', 'soldier', ImpactResult.damaged),
    ]),
  ], _command(18, _aim)),
];

void main() {
  const path = 'test/fixtures/battle.log';
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(const BinaryProtocolCodec().encodeLog(entries));
  print('wrote $path');
}
