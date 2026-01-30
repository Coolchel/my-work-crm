import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/estimate_item_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  /// Generates a PDF for the given items and returns the bytes.
  /// [title] - Title of the document
  /// [items] - List of items to include
  /// [showPrices] - Whether to show price columns
  /// [isWork] - If true, round prices/amounts to integers (Works logic)
  /// [remarks] - Optional remarks to display at the bottom
  /// [markupPercent] - Markup percentage (optional, for materials)
  /// [quantityType] - 'total', 'employer', 'our'
  Future<Uint8List> generateEstimatePdf({
    required String title,
    required List<EstimateItemModel> items,
    required bool showPrices,
    required bool isWork,
    String? remarks,
    double markupPercent = 0.0,
    String quantityType = 'total',
  }) async {
    // 1. Load Fonts
    // Using OpenSans for clean look and Cyrillic support
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // 2. Prepare Data

    // Helper to resolve quantity based on type
    double getQty(EstimateItemModel item) {
      if (quantityType == 'employer') return item.employerQuantity;
      if (quantityType == 'our') {
        return item.totalQuantity - item.employerQuantity;
      }
      return item.totalQuantity;
    }

    // Filter out zero quantities
    final displayedItems = items.where((i) => getQty(i) > 0.001).toList();

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

    // Create the PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.only(
              left: 60,
              top: 40,
              right: 30,
              bottom: 40), // Increased left margin
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

            // Tables by Category
            ...sortedCats.map((cat) {
              final catItems = grouped[cat]!;
              return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border(
                            left: pw.BorderSide(
                                color: PdfColors.blueGrey800, width: 2)),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 1, horizontal: 6), // Reduced padding
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(cat,
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 9, // Smaller font
                              color: PdfColors.blueGrey800)),
                    ),
                    _buildTable(catItems, showPrices, markupPercent, font,
                        fontBold, isWork, getQty),
                    pw.SizedBox(height: 20),
                  ]);
            }),

            // Grand Total
            if (showPrices)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 15),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("ИТОГО: ",
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.grey700)), // Less flashy
                    pw.SizedBox(width: 8),
                    pw.Text(
                        _calculateTotal(
                            displayedItems, markupPercent, isWork, getQty),
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10, // Smaller font
                            color: PdfColors.grey700)),
                  ],
                ),
              ),

            // Remarks
            if (remarks != null && remarks.trim().isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text("* Примечание:",
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: PdfColors.grey600)), // Smaller, grey
              pw.SizedBox(height: 2),
              pw.Text(remarks,
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600)),
            ],

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Center(
                child: pw.Text("Электромонтажные работы", // Changed footer
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey))),
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
            pw.Container(
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          color: PdfColors.blueGrey800, width: 1))),
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text("Электромонтаж",
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 14, color: PdfColors.black)),
            ),
            pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now()),
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Center(
            child: pw.Text(title,
                style: pw.TextStyle(font: fontBold, fontSize: 13),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildTable(
      List<EstimateItemModel> items,
      bool showPrices,
      double markup,
      pw.Font font,
      pw.Font fontBold,
      bool isWork,
      double Function(EstimateItemModel) getQty) {
    return pw.Table(
        border: pw.TableBorder.symmetric(
            inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            outside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        columnWidths: {
          0: const pw.FlexColumnWidth(4), // Name
          1: const pw.FixedColumnWidth(40), // Qty (Reduced)
          2: const pw.FixedColumnWidth(30), // Unit (Reduced)
          if (showPrices) 3: const pw.FixedColumnWidth(60), // Price (Reduced)
          if (showPrices) 4: const pw.FixedColumnWidth(70), // Sum (Reduced)
        },
        children: [
          // Header Row
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _cell("Наименование", fontBold,
                    align: pw.TextAlign.left, isHeader: true),
                _cell("Кол-во", fontBold, isHeader: true),
                _cell("Ед.", fontBold, isHeader: true),
                if (showPrices) _cell("Цена", fontBold, isHeader: true),
                if (showPrices)
                  _cell("Сумма", fontBold,
                      isHeader: true), // Changed from "Сумма"
              ]),
          // Data Rows with Zebra Striping
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            double price = item.pricePerUnit ?? 0;
            if (markup > 0) price *= (1 + markup / 100);

            final qty = getQty(item);
            final sum = qty * price;

            return pw.TableRow(
                decoration: index % 2 == 1
                    ? const pw.BoxDecoration(color: PdfColors.grey50)
                    : null,
                children: [
                  _cell(item.name, font, align: pw.TextAlign.left),
                  _cell(_fmtQty(qty), font),
                  _cell(item.unit, font),
                  if (showPrices)
                    _cell(_fmtMoney(price, item.currency, isWork), font),
                  if (showPrices)
                    _cell(_fmtMoney(sum, item.currency, isWork), font),
                ]);
          }),
        ]);
  }

  pw.Widget _cell(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.center, bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font,
              fontSize: 8, // Reduced font size
              color: isHeader ? PdfColors.black : PdfColors.black),
          textAlign: align),
    );
  }

  String _fmtQty(double v) =>
      v.toStringAsFixed(3).replaceAll(RegExp(r"\.?0+$"), "");

  String _fmtMoney(double v, String currency, bool isWork) {
    String s;
    if (isWork) {
      s = v.round().toString(); // Works: Integer rounding
    } else {
      s = v.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "");
    }

    final sym = currency == 'USD' ? '\$' : 'р';
    return "$s$sym";
  }

  String _calculateTotal(List<EstimateItemModel> items, double markup,
      bool isWork, double Function(EstimateItemModel) getQty) {
    double totalUsd = 0;
    double totalByn = 0;

    for (var item in items) {
      double qty = getQty(item);
      if (qty <= 0.001) continue;

      double price = item.pricePerUnit ?? 0;
      if (markup > 0) price *= (1 + markup / 100);

      final sum = qty * price;

      if (item.currency == 'USD') {
        totalUsd += sum;
      } else {
        totalByn += sum;
      }
    }

    // Rounding logic for Total
    // Works: Round to nearest whole number
    // Materials: Round to 2 decimals

    final parts = <String>[];

    if (totalUsd > 0.001 || (totalUsd.abs() > 0.001 && isWork)) {
      // Logic: if almost zero, skip. But check rounding.
      // For straightforward display:
      String val;
      if (isWork) {
        val = totalUsd.round().toString();
      } else {
        val = totalUsd.toStringAsFixed(2);
      }
      if (double.parse(val) > 0) parts.add("$val\$");
    }

    if (totalByn > 0.001 || (totalByn.abs() > 0.001 && isWork)) {
      String val;
      if (isWork) {
        val = totalByn.round().toString();
      } else {
        val = totalByn.toStringAsFixed(2);
      }
      if (double.parse(val) > 0) parts.add("$valр");
    }

    return parts.isEmpty ? "0" : parts.join(" + ");
  }
}
