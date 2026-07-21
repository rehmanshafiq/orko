import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds and exports a booking payment receipt as a PDF.
class BookingReceiptPdf {
  const BookingReceiptPdf._();

  static const PdfColor _brand = PdfColor.fromInt(0xFF329748);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1D1F);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);

  /// Generates the receipt PDF bytes for the given booking details.
  static Future<Uint8List> build({
    required String bookingRef,
    required String stationName,
    required String slotLabel,
    String? paymentLabel,
    required int amountPaid,
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

    final doc = pw.Document(title: 'Receipt $bookingRef');
    final issued = issuedAt ?? DateTime.now();
    final issuedLabel = DateFormat('MMM d, yyyy · HH:mm').format(issued);
    final amountLabel = 'Rs ${NumberFormat.decimalPattern().format(amountPaid)}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(issuedLabel),
              pw.SizedBox(height: 28),
              pw.Text(
                'Payment Receipt',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thank you for charging with HUBCO.',
                style: const pw.TextStyle(fontSize: 11, color: _muted),
              ),
              pw.SizedBox(height: 24),
              _detailsCard(
                bookingRef: bookingRef,
                stationName: stationName,
                slotLabel: slotLabel,
                paymentLabel: paymentLabel,
              ),
              pw.SizedBox(height: 16),
              _amountRow(amountLabel),
              pw.Spacer(),
              pw.Divider(color: _line),
              pw.SizedBox(height: 8),
              pw.Text(
                'This is a system-generated receipt and does not require a '
                'signature.',
                style: const pw.TextStyle(fontSize: 9, color: _muted),
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
  }) async {
    final bytes = await build(
      bookingRef: bookingRef,
      stationName: stationName,
      slotLabel: slotLabel,
      paymentLabel: paymentLabel,
      amountPaid: amountPaid,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'HUBCO_Receipt_$bookingRef.pdf',
    );
  }

  static pw.Widget _header(String issuedLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'HUBCO',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.5,
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'EV Charging Receipt',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Issued $issuedLabel',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFFE8F5EC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailsCard({
    required String bookingRef,
    required String stationName,
    required String slotLabel,
    String? paymentLabel,
  }) {
    // The Payment Method row is optional — omitted when no method is known
    // (e.g. the booking-success screen), so the Date row becomes the last one.
    final hasPayment = paymentLabel != null && paymentLabel.isNotEmpty;
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: pw.Column(
        children: [
          _row('Booking Reference', bookingRef),
          _row('Station', stationName),
          _row('Date', slotLabel, isLast: !hasPayment),
          if (hasPayment)
            _row('Payment Method', paymentLabel, isLast: true),
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value, {bool isLast = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line)),
            ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: _muted)),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(String amountLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEAF6ED),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Amount Paid',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            amountLabel,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _brand,
            ),
          ),
        ],
      ),
    );
  }
}
