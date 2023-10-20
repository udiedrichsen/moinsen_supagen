// ignore_for_file: avoid_dynamic_calls, lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:moinsen_supagen/src/commands/converter/entity_ext_helper.dart';
import 'package:moinsen_supagen/src/commands/converter/utils.dart';
import 'package:simple_mustache/simple_mustache.dart';

Future<void> generateDartFiles(String inputFile, String outputDir) async {
  final input = await File(inputFile).readAsString();
  final inputJson = jsonDecode(input);
  final json = inputJson['tables_infos'] as Map<String, dynamic>;

  final directory = Directory(outputDir);
  if (!directory.existsSync()) {
    await directory.create();
  }

  final indexFileName = '$outputDir/_index.dart';
  final fileIndex = File(indexFileName);
  final sinkIndex = fileIndex.openWrite();

  for (final table in json.keys) {
    final modifiedTable =
        modifyTableName(table); // Verwendet die modifyTableName Funktion
    final pascalCaseTable = toPascalCase(modifiedTable);
    final fileName = '$outputDir/$modifiedTable.dart';

    sinkIndex.write("export '$modifiedTable.dart';\n");

    final file = File(fileName);
    final sink = file.openWrite();

    sink.write(
      "import 'package:moinsen_supagen/moinsen_supagen.dart';\n\n",
    );
    sink.write("part '$modifiedTable.freezed.dart';\n");
    sink.write("part '$modifiedTable.g.dart';\n\n");
    sink.write('@freezed\n');
    /*
    sink.write(
      'class $pascalCaseTable extends MoinsenBaseEntity<$pascalCaseTable> with _\$$pascalCaseTable {\n',
    );
    */
    sink.write(
      'class $pascalCaseTable with _\$$pascalCaseTable {\n',
    );
    sink.write("  static const tableName = '$table';\n\n");

    final fields = sortAndFilterByName(json[table] as List<dynamic>);
    // -- Generate all attributes as constants
    final pkKey = <String>[];
    for (final field in fields) {
      final fieldName = field['name'] as String;
      final attrName = 'attr${toPascalCase(fieldName)}';
      sink.write("  static const $attrName = '$fieldName';\n");

      final keyInformations = erdKey(field['keyInformations'] as String);
      if (keyInformations.contains('PK')) {
        pkKey.add(fieldName);
      }
    }

    // Convert pkKey to a list of quoted strings
    final pkKeyString = pkKey.map((e) => "'$e'").join(', ');
    sink.write('\n  static const pkKey= [$pkKeyString];\n');

    sink.write('\n  const factory $pascalCaseTable({\n');
    for (final field in fields) {
      final fieldName = field['name'] as String;
      final camelCaseName = toCamelCase(fieldName);
      final type = dartType(field['type'] as String);

      var nullable = '';
      var required = '';
      if (field['name'] != 'id') {
        nullable = field['nullable'] as bool ? '?' : '';
        required = field['nullable'] as bool ? '' : 'required ';
      } else {
        nullable = '?'; // Setzt id Feld als nullable
      }

      sink.write('    $required$type$nullable $camelCaseName,\n');
    }

    sink.write('  }) = _$pascalCaseTable;\n\n');

    sink.write(
      '  factory $pascalCaseTable.fromJson(Map<String, Object?> json)'
      ' => _\$${pascalCaseTable}FromJson(json);\n',
    );

    sink.write('}\n\n');

    // Create a mustache converter
    final m = Mustache(map: {'entity': pascalCaseTable});
    final output = m.convert(entityExtensionTemplate);
    sink.write(output);

    await sink.close();
  }

  await sinkIndex.close();
}
