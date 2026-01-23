import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../services/parametros_schema_service.dart';

class ParametrosViewerScreen extends StatefulWidget {
  final String disciplina;
  final String tipo;

  const ParametrosViewerScreen({
    super.key,
    required this.disciplina,
    required this.tipo,
  });

  @override
  State<ParametrosViewerScreen> createState() => _ParametrosViewerScreenState();
}

class _ParametrosViewerScreenState extends State<ParametrosViewerScreen> {
  late final Future<void> _seedFuture;
  final _schemaService = ParametrosSchemaService();

  String get _docId => '${widget.disciplina}_${widget.tipo}';

  @override
  void initState() {
    super.initState();
    _seedFuture = _schemaService.seedSchemasIfMissing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.disciplina.toUpperCase()} - ${widget.tipo.toUpperCase()}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _seedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('parametros_schemas').doc(_docId).snapshots(),
            builder: (context, schemaSnapshot) {
              if (schemaSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!schemaSnapshot.hasData || !schemaSnapshot.data!.exists) {
                return const Center(child: Text('No hay esquema disponible.'));
              }

              final schemaData = schemaSnapshot.data!.data() as Map<String, dynamic>;
              final filename =
                  schemaData['filenameDefault']?.toString() ?? '${widget.disciplina}_${widget.tipo}.xlsx';
              final columns = (schemaData['columns'] as List<dynamic>? ?? [])
                  .map((column) => _SchemaColumn.fromMap(column as Map<String, dynamic>))
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('parametros_datasets')
                    .doc(_docId)
                    .collection('rows')
                    .snapshots(),
                builder: (context, rowsSnapshot) {
                  if (rowsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!rowsSnapshot.hasData) {
                    return const Center(child: Text('No hay parámetros disponibles.'));
                  }

                  final rows = rowsSnapshot.data!.docs
                      .map((doc) => _DatasetRow.fromMap(doc.data() as Map<String, dynamic>))
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
          );
        },
      ),
    );
  }

  int _rowSorter(_DatasetRow a, _DatasetRow b) {
    final nombreA = a.nombre.toLowerCase();
    final nombreB = b.nombre.toLowerCase();
    final nameCompare = nombreA.compareTo(nombreB);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return a.id.compareTo(b.id);
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
              ? const Center(child: Text('No hay parámetros disponibles.'))
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
                                  .map((column) => DataCell(Text(row.valueFor(column.key))))
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
        final rowValues = columns.map((column) => row.valueFor(column.key)).toList();
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
  final String nombre;
  final String piso;
  final String estado;
  final Map<String, dynamic> values;

  _DatasetRow({
    required this.id,
    required this.nombre,
    required this.piso,
    required this.estado,
    required this.values,
  });

  factory _DatasetRow.fromMap(Map<String, dynamic> map) {
    return _DatasetRow(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      piso: map['piso']?.toString() ?? '',
      estado: map['estado']?.toString() ?? '',
      values: Map<String, dynamic>.from(map['values'] as Map? ?? {}),
    );
  }

  String valueFor(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'nombre':
        return nombre;
      case 'piso':
        return piso;
      case 'estado':
        return estado;
      default:
        return values[key]?.toString() ?? '';
    }
  }
}
