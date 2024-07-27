import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';
import 'package:intl/intl.dart';

part 'model.g.dart';

abstract class Location implements Built<Location, LocationBuilder> {
  static Serializer<Location> get serializer => _$locationSerializer;

  int get x;

  int get y;

  Location get left => rebuild((b) => b.x = x - 1);

  Location get right => rebuild((b) => b.x = x + 1);

  Location get up => rebuild((b) => b.y = y - 1);

  Location get down => rebuild((b) => b.y = y + 1);

  Location leftOffset(int offset) => rebuild((b) => b.x = x - offset);

  Location rightOffset(int offset) => rebuild((b) => b.x = x + offset);

  Location upOffset(int offset) => rebuild((b) => b.y = y - offset);

  Location downOffset(int offset) => rebuild((b) => b.y = y + offset);

  String prettyPrint() => '($x,$y)';

  factory Location([void Function(LocationBuilder)? updates]) = _$Location;
  Location._();

  factory Location.at(int x, int y) {
    return Location((b) {
      b
        ..x = x
        ..y = y;
    });
  }
}

enum Direction {
  across,
  down;

  @override
  String toString() => name;
}

abstract class CrosswordWord
    implements Built<CrosswordWord, CrosswordWordBuilder> {
  static Serializer<CrosswordWord> get serializer => _$crosswordWordSerializer;

  String get word;

  Location get location;

  Direction get direction;

  static int locationComparator(CrosswordWord a, CrosswordWord b) {
    final compareRows = a.location.y.compareTo(b.location.y);
    final compareColumns = a.location.x.compareTo(b.location.x);
    return switch (compareColumns) { 0 => compareRows, _ => compareColumns };
  }

  factory CrosswordWord.word({
    required String word,
    required Location location,
    required Direction direction,
  }) {
    return CrosswordWord((b) => b
      ..word = word
      ..direction = direction
      ..location.replace(location));
  }

  factory CrosswordWord([void Function(CrosswordWordBuilder)? updates]) =
      _$CrosswordWord;
  CrosswordWord._();
}

abstract class CrosswordCharacter
    implements Built<CrosswordCharacter, CrosswordCharacterBuilder> {
  static Serializer<CrosswordCharacter> get serializer =>
      _$crosswordCharacterSerializer;

  String get character;

  CrosswordWord? get acrossWord;

  CrosswordWord? get downWord;

  factory CrosswordCharacter.character({
    required String character,
    CrosswordWord? acrossWord,
    CrosswordWord? downWord,
  }) {
    return CrosswordCharacter((b) {
      b.character = character;
      if (acrossWord != null) {
        b.acrossWord.replace(acrossWord);
      }
      if (downWord != null) {
        b.downWord.replace(downWord);
      }
    });
  }

  factory CrosswordCharacter(
          [void Function(CrosswordCharacterBuilder)? updates]) =
      _$CrosswordCharacter;
  CrosswordCharacter._();
}

abstract class Crossword implements Built<Crossword, CrosswordBuilder> {
  static Serializer<Crossword> get serializer => _$crosswordSerializer;

  int get width;

  int get height;

  BuiltList<CrosswordWord> get words;

  BuiltMap<Location, CrosswordCharacter> get characters;

  bool get valid {
    final wordSet = words.map((word) => word.word).toBuiltSet();
    if (wordSet.length != words.length) {
      return false;
    }

    for (final MapEntry(key: location, value: character)
        in characters.entries) {
      if (character.acrossWord == null && character.downWord == null) {
        return false;
      }

      if (location.x < 0 ||
          location.y < 0 ||
          location.x >= width ||
          location.y >= height) {
        return false;
      }

      if (characters[location.up] case final up?) {
        if (character.downWord == null) {
          return false;
        }
        if (up.downWord != character.downWord) {
          return false;
        }
      }

      if (characters[location.down] case final down?) {
        if (character.downWord == null) {
          return false;
        }
        if (down.downWord != character.downWord) {
          return false;
        }
      }

      final left = characters[location.left];
      if (left != null) {
        if (character.acrossWord == null) {
          return false;
        }
        if (left.acrossWord != character.acrossWord) {
          return false;
        }
      }

      final right = characters[location.right];
      if (right != null) {
        if (character.acrossWord == null) {
          return false;
        }
        if (right.acrossWord != character.acrossWord) {
          return false;
        }
      }
    }

    return true;
  }

  Crossword? addWord({
    required Location location,
    required String word,
    required Direction direction,
    bool requireOverlap = true,
  }) {
    if (words.map((crosswordWord) => crosswordWord.word).contains(word)) {
      return null;
    }

    final wordCharacters = word.characters;
    bool overlap = false;

    for (final (index, character) in wordCharacters.indexed) {
      final characterLocation = switch (direction) {
        Direction.across => location.rightOffset(index),
        Direction.down => location.downOffset(index),
      };

      final target = characters[characterLocation];
      if (target != null) {
        overlap = true;
        if (target.character != character) {
          return null;
        }
        if (direction == Direction.across && target.acrossWord != null ||
            direction == Direction.down && target.downWord != null) {
          return null;
        }
      }
    }

    if (words.isNotEmpty && !overlap && requireOverlap) {
      return null;
    }

    final candidate = rebuild(
      (b) => b
        ..words.add(
          CrosswordWord.word(
            word: word,
            direction: direction,
            location: location,
          ),
        ),
    );

    if (candidate.valid) {
      return candidate;
    } else {
      return null;
    }
  }

  @BuiltValueHook(finalizeBuilder: true)
  static void _fillCharacters(CrosswordBuilder b) {
    b.characters.clear();

    for (final word in b.words.build()) {
      for (final (idx, character) in word.word.characters.indexed) {
        switch (word.direction) {
          case Direction.across:
            b.characters.updateValue(
              word.location.rightOffset(idx),
              (b) => b.rebuild((bInner) => bInner.acrossWord.replace(word)),
              ifAbsent: () => CrosswordCharacter.character(
                acrossWord: word,
                character: character,
              ),
            );
          case Direction.down:
            b.characters.updateValue(
              word.location.downOffset(idx),
              (b) => b.rebuild((bInner) => bInner.downWord.replace(word)),
              ifAbsent: () => CrosswordCharacter.character(
                downWord: word,
                character: character,
              ),
            );
        }
      }
    }
  }

  String prettyPrintCrossword() {
    final buffer = StringBuffer();
    final grid = List.generate(
      height,
      (_) => List.generate(
        width, (_) => '░', 
      ),
    );

    for (final MapEntry(key: Location(:x, :y), value: character)
        in characters.entries) {
      grid[y][x] = character.character;
    }

    for (final row in grid) {
      buffer.writeln(row.join());
    }

    buffer.writeln();
    buffer.writeln('Across:');
    for (final word
        in words.where((word) => word.direction == Direction.across).toList()
          ..sort(CrosswordWord.locationComparator)) {
      buffer.writeln('${word.location.prettyPrint()}: ${word.word}');
    }

    buffer.writeln();
    buffer.writeln('Down:');
    for (final word
        in words.where((word) => word.direction == Direction.down).toList()
          ..sort(CrosswordWord.locationComparator)) {
      buffer.writeln('${word.location.prettyPrint()}: ${word.word}');
    }

    return buffer.toString();
  }

  factory Crossword.crossword({
    required int width,
    required int height,
    Iterable<CrosswordWord>? words,
  }) {
    return Crossword((b) {
      b
        ..width = width
        ..height = height;
      if (words != null) {
        b.words.addAll(words);
      }
    });
  }

  factory Crossword([void Function(CrosswordBuilder)? updates]) = _$Crossword;
  Crossword._();
}

abstract class WorkQueue implements Built<WorkQueue, WorkQueueBuilder> {
  static Serializer<WorkQueue> get serializer => _$workQueueSerializer;

  Crossword get crossword;

  BuiltMap<Location, Direction> get locationsToTry;

  BuiltSet<Location> get badLocations;

  BuiltSet<String> get candidateWords;

  bool get isCompleted => locationsToTry.isEmpty || candidateWords.isEmpty;

  static WorkQueue from({
    required Crossword crossword,
    required Iterable<String> candidateWords,
    required Location startLocation,
  }) =>
      WorkQueue((b) {
        if (crossword.words.isEmpty) {
          b.candidateWords.addAll(candidateWords
              .where((word) => word.characters.length <= crossword.width));

          b.crossword.replace(crossword);

          b.locationsToTry.addAll({startLocation: Direction.across});
        } else {
          b.candidateWords.addAll(
            candidateWords.toBuiltSet().rebuild(
                (b) => b.removeAll(crossword.words.map((word) => word.word))),
          );
          b.crossword.replace(crossword);
          crossword.characters
              .rebuild((b) => b.removeWhere((location, character) {
                    if (character.acrossWord != null &&
                        character.downWord != null) {
                      return true;
                    }
                    final left = crossword.characters[location.left];
                    if (left != null && left.downWord != null) return true;
                    final right = crossword.characters[location.right];
                    if (right != null && right.downWord != null) return true;
                    final up = crossword.characters[location.up];
                    if (up != null && up.acrossWord != null) return true;
                    final down = crossword.characters[location.down];
                    if (down != null && down.acrossWord != null) return true;
                    return false;
                  }))
              .forEach((location, character) {
            b.locationsToTry.addAll({
              location: switch ((character.acrossWord, character.downWord)) {
                (null, null) =>
                  throw StateError('Character is not part of a word'),
                (null, _) => Direction.across,
                (_, null) => Direction.down,
                (_, _) => throw StateError('Character is part of two words'),
              }
            });
          });
        }
      });

  WorkQueue remove(Location location) => rebuild((b) => b
    ..locationsToTry.remove(location)
    ..badLocations.add(location));


  WorkQueue updateFrom(final Crossword crossword) => WorkQueue.from(
        crossword: crossword,
        candidateWords: candidateWords,
        startLocation: locationsToTry.isNotEmpty
            ? locationsToTry.keys.first
            : Location.at(0, 0),
      ).rebuild((b) => b
        ..badLocations.addAll(badLocations)
        ..locationsToTry
            .removeWhere((location, _) => badLocations.contains(location)));

  factory WorkQueue([void Function(WorkQueueBuilder)? updates]) = _$WorkQueue;

  WorkQueue._();
}

abstract class DisplayInfo implements Built<DisplayInfo, DisplayInfoBuilder> {
  static Serializer<DisplayInfo> get serializer => _$displayInfoSerializer;

  String get wordsInGridCount;

  String get candidateWordsCount;

  String get locationsToExploreCount;

  String get knownBadLocationsCount;

  String get gridFilledPercentage;

  factory DisplayInfo.from({required WorkQueue workQueue}) {
    final gridFilled = (workQueue.crossword.characters.length /
        (workQueue.crossword.width * workQueue.crossword.height));
    final fmt = NumberFormat.decimalPattern();

    return DisplayInfo((b) => b
      ..wordsInGridCount = fmt.format(workQueue.crossword.words.length)
      ..candidateWordsCount = fmt.format(workQueue.candidateWords.length)
      ..locationsToExploreCount = fmt.format(workQueue.locationsToTry.length)
      ..knownBadLocationsCount = fmt.format(workQueue.badLocations.length)
      ..gridFilledPercentage = '${(gridFilled * 100).toStringAsFixed(2)}%');
  }

  static DisplayInfo get empty => DisplayInfo((b) => b
    ..wordsInGridCount = '0'
    ..candidateWordsCount = '0'
    ..locationsToExploreCount = '0'
    ..knownBadLocationsCount = '0'
    ..gridFilledPercentage = '0%');

  factory DisplayInfo([void Function(DisplayInfoBuilder)? updates]) =
      _$DisplayInfo;
  DisplayInfo._();
}

abstract class CrosswordPuzzleGame
    implements Built<CrosswordPuzzleGame, CrosswordPuzzleGameBuilder> {
  static Serializer<CrosswordPuzzleGame> get serializer =>
      _$crosswordPuzzleGameSerializer;

  Crossword get crossword;

  BuiltMap<Location, BuiltMap<Direction, BuiltList<String>>> get alternateWords;

  BuiltList<CrosswordWord> get selectedWords;

  bool canSelectWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    final crosswordWord = CrosswordWord.word(
      word: word,
      location: location,
      direction: direction,
    );

    if (selectedWords.contains(crosswordWord)) {
      return true;
    }

    var puzzle = this;

    if (puzzle.selectedWords
        .where((b) => b.direction == direction && b.location == location)
        .isNotEmpty) {
      puzzle = puzzle.rebuild((b) => b
        ..selectedWords.removeWhere(
          (selectedWord) =>
              selectedWord.location == location &&
              selectedWord.direction == direction,
        ));
    }

    return null !=
        puzzle.crosswordFromSelectedWords.addWord(
            location: location,
            word: word,
            direction: direction,
            requireOverlap: false);
  }

  CrosswordPuzzleGame? selectWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    final crosswordWord = CrosswordWord.word(
      word: word,
      location: location,
      direction: direction,
    );

    if (selectedWords.contains(crosswordWord)) {
      return rebuild((b) => b.selectedWords.remove(crosswordWord));
    }

    var puzzle = this;

    if (puzzle.selectedWords
        .where((b) => b.direction == direction && b.location == location)
        .isNotEmpty) {
      puzzle = puzzle.rebuild((b) => b
        ..selectedWords.removeWhere(
          (selectedWord) =>
              selectedWord.location == location &&
              selectedWord.direction == direction,
        ));
    }

    final updatedSelectedWordsCrossword =
        puzzle.crosswordFromSelectedWords.addWord(
      location: location,
      word: word,
      direction: direction,
      requireOverlap: false,
    );

    if (updatedSelectedWordsCrossword != null) {
      if (puzzle.crossword.words.contains(crosswordWord) ||
          puzzle.alternateWords[location]?[direction]?.contains(word) == true) {
        return puzzle.rebuild((b) => b
          ..selectedWords.add(CrosswordWord.word(
              word: word, location: location, direction: direction)));
      }
    }
    return null;
  }

  Crossword get crosswordFromSelectedWords => Crossword.crossword(
      width: crossword.width, height: crossword.height, words: selectedWords);


  bool get solved =>
      crosswordFromSelectedWords.valid &&
      crosswordFromSelectedWords.words.length == crossword.words.length &&
      crossword.words.isNotEmpty;


  factory CrosswordPuzzleGame.from({
    required Crossword crossword,
    required BuiltSet<String> candidateWords,
  }) {
    candidateWords = candidateWords
        .rebuild((p0) => p0.removeAll(crossword.words.map((p1) => p1.word)));

    var alternates =
        BuiltMap<Location, BuiltMap<Direction, BuiltList<String>>>();

    for (final crosswordWord in crossword.words) {
      final alternateWords = candidateWords.toBuiltList().rebuild((b) => b
        ..where((b) => b.length == crosswordWord.word.length)
        ..shuffle()
        ..take(4)
        ..sort());

      candidateWords =
          candidateWords.rebuild((b) => b.removeAll(alternateWords));

      alternates = alternates.rebuild(
        (b) => b.updateValue(
          crosswordWord.location,
          (b) => b.rebuild(
            (b) => b.updateValue(
              crosswordWord.direction,
              (b) => b.rebuild((b) => b.replace(alternateWords)),
              ifAbsent: () => alternateWords,
            ),
          ),
          ifAbsent: () => {crosswordWord.direction: alternateWords}.build(),
        ),
      );
    }

    return CrosswordPuzzleGame((b) {
      b
        ..crossword.replace(crossword)
        ..alternateWords.replace(alternates);
    });
  }

  factory CrosswordPuzzleGame(
          [void Function(CrosswordPuzzleGameBuilder)? updates]) =
      _$CrosswordPuzzleGame;
  CrosswordPuzzleGame._();
}

@SerializersFor([
  Location,
  Crossword,
  CrosswordWord,
  CrosswordCharacter,
  WorkQueue,
  DisplayInfo,
  CrosswordPuzzleGame,
])
final Serializers serializers = _$serializers;
