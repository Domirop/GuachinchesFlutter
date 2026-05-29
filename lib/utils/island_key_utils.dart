const List<String> kCanonicalIslandKeys = ['TF', 'GC', 'LZ', 'FV', 'LP', 'GO', 'EH'];

const _nameToKey = {
  'tenerife': 'TF',
  'gran canaria': 'GC',
  'lanzarote': 'LZ',
  'fuerteventura': 'FV',
  'la palma': 'LP',
  'la gomera': 'GO',
  'el hierro': 'EH',
};

const _keyToName = {
  'TF': 'Tenerife',
  'GC': 'Gran Canaria',
  'LZ': 'Lanzarote',
  'FV': 'Fuerteventura',
  'LP': 'La Palma',
  'GO': 'La Gomera',
  'EH': 'El Hierro',
};

String islandKeyFromName(String name) =>
    _nameToKey[name.toLowerCase().trim()] ?? 'TF';

String islandNameFromKey(String key) =>
    _keyToName[key.toUpperCase().trim()] ?? 'Tenerife';
