import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/estimate_item_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  /// Generates a PDF for the given items and returns the bytes.
  /// [title] - Title of the document (e.g. "Смета: Этап 1")
  /// [items] - List of items to include
  /// [showPrices] - Whether to show price columns
  /// [remarks] - Optional remarks to display at the bottom
  /// [markupPercent] - Markup percentage (optional, for materials)
  Future<Uint8List> generateEstimatePdf({
    required String title,
    required List<EstimateItemModel> items,
    required bool showPrices,
    String? remarks,
    double markupPercent = 0.0,
  }) async {
    // 1. Load Fonts (Google Fonts for Cyrillic support)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // 2. Prepare Data
    // Filter out zero quantities
    final displayedItems = items.where((i) => i.totalQuantity > 0.001).toList();

    // Group by Category
    final Map<String, List<EstimateItemModel>> grouped = {};
    for (var item in displayedItems) {
      final cat = item.categoryName ?? 'Разное';
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(item);
    }
    final sortedCats = grouped.keys.toList()..sort();
    if (sortedCats.contains('Разное')) {
      sortedCats.remove('Разное');
      sortedCats.add('Разное');
    }

    // Calculate Totals
    double totalSum = 0;

    // Create the PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: font,
            bold: fontBold,
          ),
        ),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(title, fontBold),
            pw.SizedBox(height: 20),

            // Table
            ...sortedCats.map((cat) {
              final catItems = grouped[cat]!;
              return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
                      child: pw.Text(cat,
                          style: pw.TextStyle(font: fontBold, fontSize: 14)),
                    ),
                    _buildTable(
                        catItems, showPrices, markupPercent, font, fontBold),
                  ]);
            }),

            // Grand Total
            if (showPrices)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text("ИТОГО: ",
                        style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    pw.Text(_calculateTotal(displayedItems, markupPercent),
                        style: pw.TextStyle(font: fontBold, fontSize: 16)),
                  ],
                ),
              ),

            // Remarks
            if (remarks != null && remarks.trim().isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text("Примечание:",
                  style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.SizedBox(height: 5),
              pw.Text(remarks, style: pw.TextStyle(fontSize: 12)),
            ],

            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Center(
                child: pw.Text("Smart Electric System",
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey))),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String title, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Smart Electric",
                style: pw.TextStyle(
                    font: fontBold, fontSize: 24, color: PdfColors.blue900)),
            pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 18)),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildTable(List<EstimateItemModel> items, bool showPrices,
      double markup, pw.Font font, pw.Font fontBold) {
    return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(4), // Name
          1: const pw.FixedColumnWidth(50), // Qty
          2: const pw.FixedColumnWidth(40), // Unit
          if (showPrices) 3: const pw.FixedColumnWidth(70), // Price
          if (showPrices) 4: const pw.FixedColumnWidth(80), // Sum
        },
        children: [
          // Header Row
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell("Наименование", fontBold, align: pw.TextAlign.left),
                _cell("Кол-во", fontBold),
                _cell("Ед.", fontBold),
                if (showPrices) _cell("Цена", fontBold),
                if (showPrices) _cell("Сумма", fontBold),
              ]),
          // Data Rows
          ...items.map((item) {
            double price = item.pricePerUnit ?? 0;
            if (markup > 0) price *= (1 + markup / 100);
            final sum = item.totalQuantity * price;

            return pw.TableRow(children: [
              _cell(item.name, font, align: pw.TextAlign.left),
              _cell(_fmtQty(item.totalQuantity), font),
              _cell(item.unit, font),
              if (showPrices) _cell(_fmtMoney(price, item.currency), font),
              if (showPrices) _cell(_fmtMoney(sum, item.currency), font),
            ]);
          }).toList(),
        ]);
  }

  pw.Widget _cell(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 10), textAlign: align),
    );
  }

  String _fmtQty(double v) =>
      v.toStringAsFixed(3).replaceAll(RegExp(r"\.?0+$"), "");

  String _fmtMoney(double v, String currency) {
    final s = v.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "");
    final sym = currency == 'USD' ? '\$' : 'р';
    return "$s$sym";
  }

  String _calculateTotal(List<EstimateItemModel> items, double markup) {
    double totalUsd = 0;
    double totalByn = 0;

    for (var item in items) {
      double price = item.pricePerUnit ?? 0;
      if (markup > 0) price *= (1 + markup / 100);
      final sum = item.totalQuantity * price;

      if (item.currency == 'USD')
        totalUsd += sum;
      else
        totalByn += sum;
    }

    final parts = <String>[];
    if (totalUsd > 0.001) parts.add("${totalUsd.toStringAsFixed(2)}\$");
    if (totalByn > 0.001) parts.add("${totalByn.toStringAsFixed(2)}р");

    return parts.isEmpty ? "0" : parts.join(" + ");
  }
}
