import 'dart:io';
import 'dart:convert';

void checkFile(String path) {
  final content = File(path).readAsStringSync();
  final regex = RegExp(r'^  "([^"]+)":', multiLine: true);
  final matches = regex.allMatches(content);
  final keys = <String>{};
  for (final match in matches) {
    final key = match.group(1)!;
    if (keys.contains(key)) {
      print('Duplicate ROOT key in $path: $key');
    }
    keys.add(key);
  }
}

void main() {
  checkFile('app_en.arb');
  checkFile('app_ar.arb');
}
