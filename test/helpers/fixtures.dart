import 'dart:io';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_rules/battle_rules.dart';

/// The committed log fixture, written by `tool/write_fixture.dart`.
List<LogEntry> readFixtureLog() => const BinaryProtocolCodec().decodeLog(
  File('test/fixtures/battle.log').readAsBytesSync(),
);

/// The plan's `medals.yaml`, in the hawkbee checkout.
MedalsData planMedals() => MedalsData.parse(
  File('../../apps/battle_team/plan/data/medals.yaml').readAsStringSync(),
);
