import 'dart:math';

import 'package:built_collection/built_collection.dart';

final _random = Random();

extension RandomElements<E> on BuiltSet<E> {
  E randomElement() {
    return elementAt(_random.nextInt(length));
  }
}

extension DurationFormat on Duration {
  String get formatted {
    final hours = inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return switch ((inDays, inHours, inMinutes, inSeconds)) {
      (0, 0, 0, _) => '${inSeconds}s',
      (0, 0, _, _) => '$inMinutes:$seconds',
      (0, _, _, _) => '$inHours:$minutes:$seconds',
      _ => '$inDays days, $hours:$minutes:$seconds',
    };
  }
}
