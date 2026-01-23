import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ParametrosViewerScreen extends StatelessWidget {
  final String disciplina;
  final String tipo;

  const ParametrosViewerScreen({
    super.key,
    required this.disciplina,
    required this.tipo,
  });

  String get _docId => '${disciplina}_$tipo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${disciplina.toUpperCase()} - ${tipo.toUpperCase()}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('parametros_schemas').doc(_docId).snapshots(),
        builder: (context, schemaSnapshot) {
          if (schemaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!schemaSnapshot.hasData || !schemaSnapshot.data!.exists) {
            return const Center(child: Text('No hay esquema disponible.'));
          }

          final schemaData = schemaSnapshot.data!.data() as Map<String, dynamic>;
          final filename = schemaData['filenameDefault']?.toString() ?? '${disciplina}_$tipo.xlsx';
          final columns = (schemaData['columns'] as List<dynamic>? ?? [])
              .map((column) => _SchemaColumn.fromMap(column as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('parametros_datasets').doc(_docId).snapshots(),
            builder: (context, datasetSnapshot) {
              if (datasetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!datasetSnapshot.hasData || !datasetSnapshot.data!.exists) {
                return const Center(child: Text('No hay datos disponibles.'));
              }

              final datasetData = datasetSnapshot.data!.data() as Map<String, dynamic>;
              final storageMode = datasetData['storageMode']?.toString() ?? 'document';

              if (storageMode == 'subcollection') {
                return _RowsFromSubcollection(
                  docId: _docId,
                  columns: columns,
                  filename: filename,
                );
              }

              final rowsById = (datasetData['rowsById'] as Map<String, dynamic>? ?? {});
              final rows = rowsById.entries
                  .map((entry) => _DatasetRow.fromMap(entry.value as Map<String, dynamic>))
                  .toList()
                ..sort(_rowSorter);

              return _ViewerContent(
                columns: columns,
                rows: rows,
                filename: filename,
              );
            },
          );
        },
      ),
    );
  }

  int _rowSorter(_DatasetRow a, _DatasetRow b) {
    final nombreA = a.values['nombre']?.toString() ?? '';
    final nombreB = b.values['nombre']?.toString() ?? '';
    final nameCompare = nombreA.compareTo(nombreB);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return a.id.compareTo(b.id);
  }
}

class _RowsFromSubcollection extends StatelessWidget {
  final String docId;
  final List<_SchemaColumn> columns;
  final String filename;

  const _RowsFromSubcollection({
    required this.docId,
    required this.columns,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('parametros_datasets').doc(docId).collection('rows').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No hay datos disponibles.'));
        }

        final rows = snapshot.data!.docs
            .map((doc) => _DatasetRow.fromMap(doc.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            final nombreA = a.values['nombre']?.toString() ?? '';
            final nombreB = b.values['nombre']?.toString() ?? '';
            final nameCompare = nombreA.compareTo(nombreB);
            if (nameCompare != 0) {
              return nameCompare;
            }
            return a.id.compareTo(b.id);
          });

        return _ViewerContent(
          columns: columns,
          rows: rows,
          filename: filename,
        );
      },
    );
  }
}

class _ViewerContent extends StatelessWidget {
  final List<_SchemaColumn> columns;
  final List<_DatasetRow> rows;
  final String filename;

  const _ViewerContent({
    required this.columns,
    required this.rows,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('No hay filas para mostrar.'))
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: columns
                          .map((column) => DataColumn(label: Text(column.displayName)))
                          .toList(),
                      rows: rows
                          .map(
                            (row) => DataRow(
                              cells: columns
                                  .map((column) => DataCell(Text(row.values[column.key]?.toString() ?? '')))
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateExcel(context),
              icon: const Icon(Icons.download),
              label: const Text('Generar Excel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF1ABC9C),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateExcel(BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Parametros'];

      sheet.appendRow(columns.map((column) => column.displayName).toList());

      for (final row in rows) {
        final rowValues = columns
            .map((column) => row.values[column.key] ?? '')
            .toList();
        sheet.appendRow(rowValues);
      }

      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('No se pudo generar el archivo.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Excel: $e')),
      );
    }
  }
}

class _SchemaColumn {
  final String key;
  final String displayName;
  final int order;

  _SchemaColumn({
    required this.key,
    required this.displayName,
    required this.order,
  });

  factory _SchemaColumn.fromMap(Map<String, dynamic> map) {
    return _SchemaColumn(
      key: map['key']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      order: map['order'] is int ? map['order'] as int : int.tryParse(map['order']?.toString() ?? '') ?? 0,
    );
  }
}

class _DatasetRow {
  final String id;
  final Map<String, dynamic> values;

  _DatasetRow({
    required this.id,
    required this.values,
  });

  factory _DatasetRow.fromMap(Map<String, dynamic> map) {
    return _DatasetRow(
      id: map['id']?.toString() ?? '',
      values: Map<String, dynamic>.from(map['values'] as Map? ?? {}),
    );
  }
}
