import 'dart:math';

String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  // Version 4
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Variant 1
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int value) => value.toRadixString(16).padLeft(2, '0');

  final parts = <String>[
    bytes.sublist(0, 4).map(hex).join(),
    bytes.sublist(4, 6).map(hex).join(),
    bytes.sublist(6, 8).map(hex).join(),
    bytes.sublist(8, 10).map(hex).join(),
    bytes.sublist(10, 16).map(hex).join(),
  ];

  return parts.join('-');
}
