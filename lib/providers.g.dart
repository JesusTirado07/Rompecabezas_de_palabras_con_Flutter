part of 'providers.dart';

String _$wordListHash() => r'8e3e9cd4555ba4baa045ccddd8dd45a25cfb6653';

@ProviderFor(wordList)
final wordListProvider = AutoDisposeFutureProvider<BuiltSet<String>>.internal(
  wordList,
  name: r'wordListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$wordListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WordListRef = AutoDisposeFutureProviderRef<BuiltSet<String>>;
String _$workQueueHash() => r'f7af7a45cf9151794c25ebfc87233f6275898214';

@ProviderFor(workQueue)
final workQueueProvider = AutoDisposeStreamProvider<model.WorkQueue>.internal(
  workQueue,
  name: r'workQueueProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$workQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WorkQueueRef = AutoDisposeStreamProviderRef<model.WorkQueue>;
String _$sizeHash() => r'e551985965bf4119e8d90c0e8aa4f4d68a555b73';

@ProviderFor(Size)
final sizeProvider = NotifierProvider<Size, CrosswordSize>.internal(
  Size.new,
  name: r'sizeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sizeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Size = Notifier<CrosswordSize>;
String _$puzzleHash() => r'dddad218b4318b008af2db67dd0ff284bcef3231';

@ProviderFor(Puzzle)
final puzzleProvider =
    AutoDisposeNotifierProvider<Puzzle, model.CrosswordPuzzleGame>.internal(
  Puzzle.new,
  name: r'puzzleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$puzzleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Puzzle = AutoDisposeNotifier<model.CrosswordPuzzleGame>;
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
