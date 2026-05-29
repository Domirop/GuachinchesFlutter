import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/utils/island_key_utils.dart';

void main() {
  group('kCanonicalIslandKeys', () {
    test('has exactly 7 entries', () {
      expect(kCanonicalIslandKeys.length, 7);
    });

    test('contains the 7 canonical keys', () {
      expect(kCanonicalIslandKeys,
          containsAll(['TF', 'GC', 'LZ', 'FV', 'LP', 'GO', 'EH']));
    });
  });

  group('islandKeyFromName — 7 bidirectional mappings', () {
    test('Tenerife → TF', () => expect(islandKeyFromName('Tenerife'), 'TF'));
    test('Gran Canaria → GC',
        () => expect(islandKeyFromName('Gran Canaria'), 'GC'));
    test('Lanzarote → LZ',
        () => expect(islandKeyFromName('Lanzarote'), 'LZ'));
    test('Fuerteventura → FV',
        () => expect(islandKeyFromName('Fuerteventura'), 'FV'));
    test('La Palma → LP', () => expect(islandKeyFromName('La Palma'), 'LP'));
    test('La Gomera → GO',
        () => expect(islandKeyFromName('La Gomera'), 'GO'));
    test('El Hierro → EH',
        () => expect(islandKeyFromName('El Hierro'), 'EH'));
  });

  group('islandKeyFromName — tolerance', () {
    test('uppercase + trailing spaces → TF',
        () => expect(islandKeyFromName('TENERIFE  '), 'TF'));
    test('mixed case → GC',
        () => expect(islandKeyFromName('GRAN CANARIA'), 'GC'));
    test('unknown name falls back to TF',
        () => expect(islandKeyFromName('Unknown Island'), 'TF'));
    test('empty string falls back to TF',
        () => expect(islandKeyFromName(''), 'TF'));
  });

  group('islandNameFromKey — 7 bidirectional mappings', () {
    test('TF → Tenerife', () => expect(islandNameFromKey('TF'), 'Tenerife'));
    test('GC → Gran Canaria',
        () => expect(islandNameFromKey('GC'), 'Gran Canaria'));
    test('LZ → Lanzarote',
        () => expect(islandNameFromKey('LZ'), 'Lanzarote'));
    test('FV → Fuerteventura',
        () => expect(islandNameFromKey('FV'), 'Fuerteventura'));
    test('LP → La Palma', () => expect(islandNameFromKey('LP'), 'La Palma'));
    test('GO → La Gomera',
        () => expect(islandNameFromKey('GO'), 'La Gomera'));
    test('EH → El Hierro',
        () => expect(islandNameFromKey('EH'), 'El Hierro'));
  });

  group('islandNameFromKey — tolerance', () {
    test('lowercase key → correct name',
        () => expect(islandNameFromKey('tf'), 'Tenerife'));
    test('unknown key falls back to Tenerife',
        () => expect(islandNameFromKey('ZZ'), 'Tenerife'));
  });

  group('round-trip', () {
    for (final key in kCanonicalIslandKeys) {
      test('$key round-trip: key → name → key', () {
        final name = islandNameFromKey(key);
        expect(islandKeyFromName(name), key);
      });
    }
  });
}
