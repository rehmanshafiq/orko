import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds and exports a booking payment receipt as a PDF, laid out to match the
/// HUBCO Green receipt design: logo + issue date/time header, a centered
/// "Payment Receipt" title, the booking detail rows, and a closing tagline.
class BookingReceiptPdf {
  const BookingReceiptPdf._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1D1F);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);

  /// Generates the receipt PDF bytes for the given booking details.
  ///
  /// [vehicleRegNo] and [kwhDispensed] are optional; when null/empty they fall
  /// back to an em-dash so the row layout stays identical across flows.
  static Future<Uint8List> build({
    required String bookingRef,
    required String stationName,
    required String slotLabel,
    String? paymentLabel,
    required int amountPaid,
    String? vehicleRegNo,
    String? kwhDispensed,
    DateTime? issuedAt,
  }) async {
    // The built-in PDF fonts (Helvetica) have no Unicode support, so glyphs
    // like "–", "·" and "•" fail. Use the bundled Lexend fonts instead.
    // Font loading is best-effort: if it fails the PDF still generates.
    pw.ThemeData? theme;
    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/lexend/Lexend-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/lexend/Lexend-Bold.ttf'),
      );
      theme = pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        fontFallback: [regular],
      );
    } catch (_) {
      theme = null;
    }

    // The HUBCO Green wordmark (black "HUBCO" + green "green"), best-effort:
    // falls back to a plain text wordmark if the asset can't be loaded.
    pw.MemoryImage? logo;
    try {
      final data =
          await rootBundle.load('assets/images/hubco_splash_light.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    final doc = pw.Document(title: 'Receipt $bookingRef');
    final issued = issuedAt ?? DateTime.now();
    final dateLabel = DateFormat('MMMM d, yyyy').format(issued);
    final timeLabel = DateFormat('h:mm a')
        .format(issued)
        .replaceAll('AM', 'am')
        .replaceAll('PM', 'pm');
    final amountLabel =
        'Rs. ${NumberFormat.decimalPattern().format(amountPaid)}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(logo, dateLabel, timeLabel),
              pw.SizedBox(height: 72),
              pw.Center(
                child: pw.Text(
                  'Payment Receipt',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for choosing HUBCO Green.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 48),
              _row('Booking number', bookingRef),
              _row('Vehicle Registration Number', vehicleRegNo),
              _row('Station', stationName),
              _row('Booking Slot', slotLabel),
              _row('Total kWh dispensed', kwhDispensed),
              pw.SizedBox(height: 24),
              _row('Payment Method', paymentLabel),
              _row('Amount Paid', amountLabel, bold: true),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Your choice to charge has contributed to a greener future '
                  'for Pakistan.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 11, color: _ink),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Builds the receipt and opens the system share / save sheet so the user
  /// can download it as a PDF.
  static Future<void> download({
    required String bookingRef,
    required String stationName,
    required String slotLabel,
    String? paymentLabel,
    required int amountPaid,
    String? vehicleRegNo,
    String? kwhDispensed,
  }) async {
    final bytes = await build(
      bookingRef: bookingRef,
      stationName: stationName,
      slotLabel: slotLabel,
      paymentLabel: paymentLabel,
      amountPaid: amountPaid,
      vehicleRegNo: vehicleRegNo,
      kwhDispensed: kwhDispensed,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'HUBCO_Receipt_$bookingRef.pdf',
    );
  }

  static pw.Widget _header(
    pw.MemoryImage? logo,
    String dateLabel,
    String timeLabel,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        logo != null
            ? pw.Image(logo, width: 120, fit: pw.BoxFit.contain)
            : pw.Text(
                'HUBCO green',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Issue date: $dateLabel',
              style: const pw.TextStyle(fontSize: 12, color: _muted),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Time: $timeLabel',
              style: const pw.TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  /// One label/value line. [value] falls back to an em-dash when null/empty so
  /// the layout stays consistent. When [bold] both sides render in bold — used
  /// for the closing Amount Paid row.
  static pw.Widget _row(String label, String? value, {bool bold = false}) {
    final display = (value == null || value.trim().isEmpty) ? '—' : value.trim();
    final weight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 13, color: _ink, fontWeight: weight),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Text(
              display,
              textAlign: pw.TextAlign.right,
              style:
                  pw.TextStyle(fontSize: 13, color: _ink, fontWeight: weight),
            ),
          ),
        ],
      ),
    );
  }
}
