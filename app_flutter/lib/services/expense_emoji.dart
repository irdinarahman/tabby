const _keywords = <String, String>{
  'hotel': '\u{1F3E8}',
  'dinner': '\u{1F35C}',
  'ramen': '\u{1F35C}',
  'steamboat': '\u{1F372}',
  'satay': '\u{1F362}',
  'train': '\u{1F686}',
  'grab': '\u{1F695}',
  'taxi': '\u{1F695}',
  'universal': '\u{1F3A2}',
  'shopping': '\u{1F6CD}',
  'rent': '\u{1F3E0}',
  'grocer': '\u{1F6D2}',
  'utilit': '\u{1F4A1}',
  'cake': '\u{1F382}',
  'drinks': '\u{1F964}',
  'parking': '\u{1F17F}',
  'flight': '\u2708',
  'coffee': '\u2615',
};

/// Picks a small emoji for an expense from its description. Falls back to a
/// receipt so every row has an icon.
String emojiFor(String description) {
  final text = description.toLowerCase();
  for (final entry in _keywords.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return '\u{1F9FE}';
}
