import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  
  // -----------------------------------------------------------
  // --- A. EXPORTAR FICHA TÉCNICA (DETALLE PRODUCTO) ---
  // -----------------------------------------------------------
  static Future<void> generarFichaTecnica({
    required Map<String, dynamic> producto,
    required String productId,
    required List<Map<String, dynamic>> ultimosReportes,
  }) async {
    
    // 1. Cargar la imagen de la red (si existe)
    final String? imageUrl = producto['imagenUrl'];
    Uint8List? imageBytes;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      } catch (e) {
        print("ADVERTENCIA: Fallo al descargar imagen para PDF ($e).");
      }
    }

    final pdf = pw.Document();

    try {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(producto, productId),
              pw.SizedBox(height: 20),
              _buildProductInfo(producto, imageBytes),
              pw.SizedBox(height: 20),
              _buildPdfSection("Ubicación", _buildLocationInfo(producto)),
              pw.SizedBox(height: 10),
              _buildPdfSection("Historial de reportes (últimos 5)", _buildReportsTable(ultimosReportes)),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Ficha_${producto['nombre']}.pdf',
      );
      
    } catch (e) {
        print("ERROR GENERANDO FICHA TÉCNICA: $e");
    }
  }

  // -----------------------------------------------------------
  // --- B. EXPORTAR REPORTE INDIVIDUAL (DETALLE REPORTE) ---
  // -----------------------------------------------------------
  
  static Future<void> generarReporte({
    required Map<String, dynamic> reporte,
    required String reportId,
  }) async {
    final pdf = pw.Document();
    
    // Preparar datos
    final String nro = reporte['nro'] ?? '0000';
    final String fecha = reporte['fechaDisplay'] ?? '--/--/----';
    final String nombreEquipo = reporte['activo_nombre'] ?? 'N/A';
    final String estadoNuevo = reporte['estado_nuevo']?.toUpperCase() ?? 'N/A';
    final Map<String, dynamic> ubicacion = reporte['ubicacion'] ?? {};

    try {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // 1. Título del Reporte
              _buildPdfHeader("REPORTE TÉCNICO N° $nro"),
              pw.Divider(height: 20, thickness: 2, color: PdfColors.red800),
              
              // 2. Información General
              _buildPdfSection(
                "Información General", 
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow("Fecha de Emisión:", fecha),
                    _infoRow("Encargado:", reporte['encargado']),
                    _infoRow("Tipo de Reporte:", reporte['tipo_reporte']),
                    _infoRow("Estado Final del Equipo:", estadoNuevo),
                  ]
                )
              ),
              
              // 3. Datos del Equipo
               _buildPdfSection(
                "Datos del Equipo", 
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow("Equipo:", nombreEquipo),
                    _infoRow("Categoría:", reporte['categoria']),
                    _infoRow("ID Sistema:", reporte['productId']),
                  ]
                )
              ),

              // 4. NUEVA SECCIÓN: UBICACIÓN
              _buildPdfSection(
                "Ubicación del Equipo", 
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow("Bloque:", ubicacion['bloque']),
                    _infoRow("Nivel:", ubicacion['nivel'] ?? ubicacion['piso']),
                    _infoRow("Área:", ubicacion['area']), // Agregué Área también por si acaso
                  ]
                )
              ),

              // 5. Descripción del Problema
              _buildPdfSection(
                "Descripción del Problema / Motivo", 
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4)
                  ),
                  child: pw.Text(reporte['descripcion'] ?? 'Sin descripción detallada.', style: const pw.TextStyle(fontSize: 11))
                )
              ),
              
              // 6. Solución / Comentarios
              _buildPdfSection(
                "Acciones Tomadas / Comentarios", 
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4)
                  ),
                  child: pw.Text(reporte['comentarios'] ?? 'No se registraron comentarios adicionales.', style: const pw.TextStyle(fontSize: 11))
                )
              ),
              
              pw.SizedBox(height: 40),
              
              // 7. Área de Firma
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text("Firma del Encargado", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(reporte['encargado'] ?? '', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  )
                ]
              ),
              
              pw.Spacer(),
              _buildFooter(),
            ];
          },
        ),
      );

      // Compartir/Guardar el PDF
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_$nro.pdf');
      
    } catch (e) {
      print("ERROR GENERANDO REPORTE PDF: $e");
    }
  }

  // -----------------------------------------------------------
  // --- WIDGETS INTERNOS Y HELPERS (REUTILIZABLES) ---
  // -----------------------------------------------------------

  // Helper para títulos grandes
  static pw.Widget _buildPdfHeader(String title) {
    return pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900));
  }

  // Helper para secciones con título y contenido
  static pw.Widget _buildPdfSection(String title, pw.Widget content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Divider(height: 5, thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 5),
          content,
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(Map<String, dynamic> data, String id) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("FICHA TÉCNICA DE EQUIPO", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text("ID Sistema: $id", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Text(data['estado']?.toUpperCase() ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ),
      ],
    );
  }

  static pw.Widget _buildProductInfo(Map<String, dynamic> data, Uint8List? imageBytes) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow("Equipo:", data['nombre']),
              _infoRow("Marca:", data['marca']),
              _infoRow("Serie:", data['serie']),
              _infoRow("Código QR:", data['codigoQR']),
              _infoRow("Categoría:", data['categoria']),
              _infoRow("Disciplina:", data['disciplina']),
              pw.SizedBox(height: 10),
              pw.Text("Descripción:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(data['descripcion'] ?? 'Sin descripción', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        if (imageBytes != null)
          pw.Container(
            width: 150,
            height: 150,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
          )
        else
          pw.Container(
            width: 150,
            height: 150,
            color: PdfColors.grey200,
            child: pw.Center(child: pw.Text("Sin Imagen")),
          ),
      ],
    );
  }

  static pw.Widget _buildLocationInfo(Map<String, dynamic> data) {
      final ubicacion = data['ubicacion'] ?? {};
      return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
              _infoRow("Bloque:", ubicacion['bloque']), 
              _infoRow("Nivel:", ubicacion['nivel'] ?? ubicacion['piso']),   
              _infoRow("Área:", ubicacion['area']),     
          ],
      );
  }

  static pw.Widget _buildReportsTable(List<Map<String, dynamic>> reportes) {
      if (reportes.isEmpty) {
          return pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                  "No hay reportes registrados.", 
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey) 
              ),
          );
      }

      final sorted = List<Map<String, dynamic>>.from(reportes)
        ..sort((a, b) => _resolveDate(b['fechaInspeccion'] ?? b['fecha'])
            .compareTo(_resolveDate(a['fechaInspeccion'] ?? a['fecha'])));
      final latest = sorted.take(5).toList();

      return pw.Column(
        children: latest.map((reporte) {
          final tipoReporte = reporte['tipoReporte'] ?? reporte['tipo_reporte'] ?? 'General';
          final estadoOperativo = reporte['estadoOperativo'] ?? reporte['estadoNuevo'] ?? reporte['estado_nuevo'] ?? 'N/A';
          final tipoMantenimiento = reporte['tipoMantenimiento'];
          final fechaRaw = reporte['fechaInspeccion'] ?? reporte['fecha'];
          final fecha = _formatDate(fechaRaw);
          final requiereReemplazo = reporte['requiereReemplazo'];
          final isReemplazo = tipoReporte == 'reemplazo';
          final showRequiere = tipoReporte == 'mantenimiento' ||
              tipoReporte == 'inspeccion' ||
              tipoReporte == 'incidente_falla';

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow("Tipo de reporte:", tipoReporte.toString()),
                _infoRow("Estado operativo:", estadoOperativo.toString()),
                if (tipoReporte == 'mantenimiento' && tipoMantenimiento != null)
                  _infoRow("Tipo de mantenimiento:", tipoMantenimiento.toString()),
                _infoRow("Fecha:", fecha),
                pw.Row(
                  children: [
                    pw.Text("Reemplazo:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      isReemplazo ? "✅" : "❌",
                      style: pw.TextStyle(
                        color: isReemplazo ? PdfColors.green800 : PdfColors.red800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (showRequiere)
                  _infoRow(
                    "Requiere reemplazo:",
                    (requiereReemplazo == true) ? 'Sí' : 'No',
                  ),
              ],
            ),
          );
        }).toList(),
      );
    }

  static DateTime _resolveDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    try {
      final Timestamp valueTs = value as Timestamp;
      return valueTs.toDate();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  static String _formatDate(dynamic value) {
    final date = _resolveDate(value);
    if (date.year <= 1970) {
      return '--/--/----';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Helper básico para filas de texto
  static pw.Widget _infoRow(String label, String? value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4), 
        child: pw.Row(
          children: [
            pw.Text("$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), 
            pw.Text(value ?? 'N/A'), 
          ],
        ),
      );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Generado por AppMant", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.Text("Fecha de impresión: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        )
      ],
    );
  }
}
