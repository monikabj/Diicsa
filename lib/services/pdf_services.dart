import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generarReporteMovimientos({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {

    Query query = FirebaseFirestore.instance
        .collection('movimientos')
        .orderBy('fecha', descending: true);

    if (fechaInicio != null && fechaFin != null) {
      query = query
          .where('fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
          .where('fecha',
              isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
    }

    final querySnapshot = await query.get();

    final List<List<String>> tablaData = [];

    // 🔥 PREPARAR DATOS ANTES DEL PDF
    for (final doc in querySnapshot.docs) {
      final d = doc.data() as Map<String, dynamic>;

      final tipo = d['tipo'] ?? '';
      final codigo = d['codigoInterno'] ?? '';
      final int cantidad = d['cantidad'] ?? 0;

      String descripcion = '';
      int existencia = 0;

      final productoQuery = await FirebaseFirestore.instance
          .collection('productos')
          .where('codigoInterno', isEqualTo: codigo)
          .limit(1)
          .get();

      if (productoQuery.docs.isNotEmpty) {
        final producto = productoQuery.docs.first.data();
        descripcion = producto['descripcion'] ?? '';
        existencia = producto['cantidadDisponible'] ?? 0;
      }

      final fecha = (d['fecha'] as Timestamp).toDate();

      tablaData.add([
        tipo.toUpperCase(),
        codigo,
        descripcion,
        cantidad.toString(),
        existencia.toString(),
        d['usuarioEmail'] ?? '',
        '${fecha.day}/${fecha.month}/${fecha.year} '
            '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
      ]);
    }

    final pdf = pw.Document();

    // 🔥 LOGO
    final ByteData logoBytes =
        await rootBundle.load('assets/images/logo-diicsa.png');
    final Uint8List logoUint8List =
        logoBytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoUint8List);

    String textoFecha = 'Reporte General';

    if (fechaInicio != null && fechaFin != null) {
      textoFecha =
          'Reporte del ${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [

          // ================= ENCABEZADO =================
          pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, height: 60),
              pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DIICSA - Reporte de Movimientos',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(textoFecha),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ================= TABLA =================
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration:
                const pw.BoxDecoration(
                    color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              'Tipo',
              'Código',
              'Descripción',
              'Cant.',
              'Existencia',
              'Usuario',
              'Fecha',
            ],
            data: tablaData,
          ),

          pw.SizedBox(height: 20),

          // 🔥 RESUMEN ELIMINADO
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}