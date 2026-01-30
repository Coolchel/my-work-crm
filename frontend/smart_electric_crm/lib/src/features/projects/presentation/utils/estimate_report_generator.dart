import '../../data/models/estimate_item_model.dart';

class EstimateReportGenerator {
  static String formatStageTitle(String rawTitle) {
    const titles = {
      'precalc': 'Предпросчет',
      'stage_1': 'Этап 1 (Черновой)',
      'stage_1_2': 'Этап 1+2 (Черновой)',
      'stage_2': 'Этап 2 (Черновой)',
      'stage_3': 'Этап 3 (Чистовой)',
      'extra': 'Доп. работы',
      'other': 'Другое',
    };
    return titles[rawTitle] ?? rawTitle;
  }

  static String generateReportText(
      List<EstimateItemModel> items, String fullTitle,
      {bool showPrices = true,
      double markup = 0.0,
      String quantityType = 'total', // 'total', 'employer', 'our'
      String? note}) {
    final buffer = StringBuffer();
    buffer.writeln(fullTitle);
    buffer.writeln("----------------------------------------");

    // DETECT REPORT TYPE (Work vs Material)
    // We assume the list is homogeneous. Check the first item.
    bool isWorkReport = false;
    if (items.isNotEmpty) {
      isWorkReport = items.first.itemType == 'work';
    }

    // FORMATTERS
    // 1. Quantity: Always remove trailing zeros, up to 3 decimals (or as string)
    String fmtQty(double v) =>
        v.toStringAsFixed(3).replaceAll(RegExp(r"\.?0+$"), "");

    // 2. Money:
    //    - Works: Integer (Round)
    //    - Materials: 2 decimals, remove trailing zeros
    String fmtMoney(double v) {
      // Unified formatting: 2 decimals, remove trailing zeros.
      // Works Totals are already rounded to integer before this call, so they will appear as integers.
      return v.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "");
    }

    // 1. Process items (Filter & Markup)
    double totalUsd = 0;
    double totalByn = 0;

    // For formulae and "Ours" calculation
    final List<double> usdParts = [];
    final List<double> bynParts = [];
    double totalClientUsd = 0;
    double totalClientByn = 0;

    // Pre-calculate Total Client Amount (Whole Stage) for "Ours" calc
    // This allows "Ours" = "Total Stage" - "Contractor Share"
    // even if some items are not assigned to contractor at all.
    for (var item in items) {
      double p = item.pricePerUnit ?? 0;
      if (markup > 0) p = p * (1 + (markup / 100));

      // Accumulate for all items that have > 0 total quantity
      if (item.totalQuantity > 0.001) {
        if (item.currency == 'USD') {
          totalClientUsd += item.totalQuantity * p;
        } else {
          totalClientByn += item.totalQuantity * p;
        }
      }
    }

    // We want a flat list, no categories.
    // Just filter and process.
    List<EstimateItemModel> finalItems = [];

    for (var item in items) {
      double quantity = 0;
      if (quantityType == 'total') {
        quantity = item.totalQuantity;
      } else if (quantityType == 'employer') {
        quantity = item.employerQuantity;
      } else if (quantityType == 'our') {
        quantity = item.totalQuantity - item.employerQuantity;
      }

      // Skip empty
      if (quantity <= 0.001) continue;

      double price = item.pricePerUnit ?? 0;
      // Apply markup
      if (markup > 0) {
        price = price * (1 + (markup / 100));
      }

      final processedItem =
          item.copyWith(totalQuantity: quantity, pricePerUnit: price);
      finalItems.add(processedItem);

      final sum = quantity * price;

      // Calculate displayed totals
      if (item.currency == 'USD') {
        totalUsd += sum;
        usdParts.add(sum);
      } else {
        totalByn += sum;
        bynParts.add(sum);
      }
    }

    if (finalItems.isEmpty) {
      buffer.writeln("(Список пуст)");
      return buffer.toString();
    }

    // 2. Output Flat List
    // Split into groups
    final usdItems = finalItems.where((i) => i.currency == 'USD').toList();
    final otherItems = finalItems.where((i) => i.currency != 'USD').toList();

    int globalIndex = 0;

    void writeItems(List<EstimateItemModel> groupItems) {
      for (var item in groupItems) {
        globalIndex++;
        final q = item.totalQuantity;
        final p = item.pricePerUnit ?? 0;
        final sum = q * p;
        final currencySymbol = item.currency == 'USD' ? '\$' : 'р';

        buffer.write("$globalIndex. ${item.name}: ${fmtQty(q)} ${item.unit}");

        if (showPrices) {
          buffer.write(
              " x ${fmtMoney(p)}$currencySymbol = ${fmtMoney(sum)}$currencySymbol");
        }

        if (!item.name.trim().endsWith('.')) {
          buffer.write(";");
        }
        buffer.writeln("");
      }
    }

    // Write USD items
    if (usdItems.isNotEmpty) {
      writeItems(usdItems);
    }

    // Separator if needed
    if (usdItems.isNotEmpty && otherItems.isNotEmpty) {
      buffer.writeln(""); // Empty line
    }

    // Write Other items
    if (otherItems.isNotEmpty) {
      writeItems(otherItems);
    }

    buffer.writeln("----------------------------------------");

    // 3. Totals
    if (showPrices) {
      if (quantityType == 'employer') {
        // --- CONTRACTOR REPORT FORMAT ---

        // I. YOURS (Contractor)
        final yoursParts = <String>[];

        double displayedTotalUsd = 0;
        double displayedTotalByn = 0;

        // USD Formula
        if (usdParts.isNotEmpty) {
          if (usdParts.length > 1) {
            final formula = usdParts.map((e) {
              double val;
              if (isWorkReport) {
                val = e.roundToDouble();
              } else {
                // Standard round to 2 decimals for summation
                val = (e * 100).round() / 100;
              }
              displayedTotalUsd += val;
              return "${fmtMoney(val)}\$";
            }).join(" + ");
            yoursParts.add("$formula = ${fmtMoney(displayedTotalUsd)}\$");
          } else {
            double val;
            if (isWorkReport) {
              val = usdParts.first.roundToDouble();
            } else {
              val = (usdParts.first * 100).round() / 100;
            }

            displayedTotalUsd = val;
            yoursParts.add("${fmtMoney(val)}\$");
          }
        }

        // BYN Formula
        if (bynParts.isNotEmpty) {
          if (bynParts.length > 1) {
            final formula = bynParts.map((e) {
              double val;
              if (isWorkReport) {
                val = e.roundToDouble();
              } else {
                val = (e * 100).round() / 100;
              }
              displayedTotalByn += val;
              return "${fmtMoney(val)}р";
            }).join(" + ");
            yoursParts.add("$formula = ${fmtMoney(displayedTotalByn)}р");
          } else {
            double val;
            if (isWorkReport) {
              val = bynParts.first.roundToDouble();
            } else {
              val = (bynParts.first * 100).round() / 100;
            }

            displayedTotalByn = val;
            yoursParts.add("${fmtMoney(val)}р");
          }
        }

        if (yoursParts.isNotEmpty) {
          // Logic: Join with " + " only if ONLY 1 position in second currency (BYN).
          String separator = "; ";
          if (usdParts.isNotEmpty && bynParts.length == 1) {
            separator = " + ";
          }
          buffer.writeln("Итого Твои: ${yoursParts.join(separator)}.");
        } else {
          buffer.writeln("Итого Твои: 0.");
        }

        // II. OURS
        final oursParts = <String>[];

        // Calculate Totals using SAME rounding logic for Client side
        double calcClientTotal(double rawSum) {
          if (isWorkReport) return rawSum.roundToDouble();
          return (rawSum * 100).round() / 100;
        }

        final dClientUsd = calcClientTotal(totalClientUsd);
        final dClientByn = calcClientTotal(totalClientByn);

        final dOursUsd = dClientUsd - displayedTotalUsd;
        final dOursByn = dClientByn - displayedTotalByn;

        // USD Calc
        if (dClientUsd > 0.001 || displayedTotalUsd > 0.001) {
          oursParts.add(
              "${fmtMoney(dClientUsd)}\$ - ${fmtMoney(displayedTotalUsd)}\$ = ${fmtMoney(dOursUsd)}\$");
        }

        // BYN Calc logic
        if (dOursByn.abs() > 0.001) {
          if (displayedTotalByn == 0) {
            oursParts.add("+ ${fmtMoney(dOursByn)}р");
          } else {
            oursParts.add(
                "${fmtMoney(dClientByn)}р - ${fmtMoney(displayedTotalByn)}р = ${fmtMoney(dOursByn)}р");
          }
        }

        if (oursParts.isNotEmpty) {
          // Smart join
          final bufferParts = StringBuffer();
          bufferParts.write(oursParts[0]);

          for (int i = 1; i < oursParts.length; i++) {
            final p = oursParts[i];
            if (p.trim().startsWith('+')) {
              bufferParts.write(" $p");
            } else {
              bufferParts.write("; $p");
            }
          }
          buffer.writeln("Итого Наши: ${bufferParts.toString()}.");
        }
      } else {
        // --- STANDARD FORMAT ---
        final parts = <String>[];

        // Use displayed rounding
        double finalUsd;
        double finalByn;

        if (isWorkReport) {
          finalUsd = totalUsd.roundToDouble();
          finalByn = totalByn.roundToDouble();
        } else {
          finalUsd = (totalUsd * 100).round() / 100;
          finalByn = (totalByn * 100).round() / 100;
        }

        if (finalUsd > 0.001) parts.add("${fmtMoney(finalUsd)}\$");
        if (finalByn > 0.001) parts.add("${fmtMoney(finalByn)}р");

        if (parts.isNotEmpty) {
          buffer.writeln("Итого: ${parts.join(" + ")}.");
        } else {
          buffer.writeln("Итого: 0.");
        }
      }
    }

    if (note != null && note.trim().isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("Примечание:");
      buffer.writeln(note.trim());
    }

    return buffer.toString();
  }
}
