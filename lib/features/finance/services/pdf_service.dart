import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../auth/models/user_model.dart';

class PdfService {
  static Future<File> generateHisabPdf({
    required String messName,
    required String messId,
    required Map<String, dynamic> hisabSummary,
    required List<Map<String, dynamic>> hisabList,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#6366F1');
    final secondaryColor = PdfColor.fromHex('#F8FAFC');
    final textDark = PdfColor.fromHex('#0F172A');
    final textGrey = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MessIQ', style: pw.TextStyle(color: primaryColor, fontSize: 28, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Smart Living OS', style: pw.TextStyle(color: textGrey, fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('MONTHLY HISAB STATEMENT', style: pw.TextStyle(color: textDark, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Workspace: $messName', style: pw.TextStyle(color: textGrey, fontSize: 14)),
                    pw.Text('ID: $messId', style: pw.TextStyle(color: textGrey, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Divider(color: primaryColor, thickness: 2, height: 32),

            // 2. Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: secondaryColor, borderRadius: pw.BorderRadius.circular(12)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Bazaar', 'Tk ${hisabSummary['totalBazaar'].toStringAsFixed(0)}'),
                  _buildSummaryItem('Total Utility', 'Tk ${hisabSummary['totalUtility'].toStringAsFixed(0)}'),
                  _buildSummaryItem('Total Meals', '${hisabSummary['totalMeals'].toStringAsFixed(1)}'),
                  _buildSummaryItem('Meal Rate', 'Tk ${hisabSummary['mealRate'].toStringAsFixed(2)}', isHighlight: true, color: primaryColor),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // 3. Ledger Data Table
            pw.Text('Member Balances', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textDark)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Member Name', 'Meals', 'Meal Cost', 'Utility', 'Paid', 'Balance'],
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: pw.TextStyle(color: textDark, fontSize: 11),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
              data: hisabList.map((hisab) {
                final UserModel member = hisab['member'];
                final double balance = hisab['balance'];
                final String status = balance < 0 ? '(DUE)' : '(ADV)';
                return [
                  member.name,
                  hisab['totalMeals'].toStringAsFixed(1),
                  hisab['mealCost'].toStringAsFixed(0),
                  hisab['utilityShare'].toStringAsFixed(0),
                  hisab['totalPaid'].toStringAsFixed(0),
                  '${balance.abs().toStringAsFixed(0)} $status',
                ];
              }).toList(),
            ),
          ];
        },
        // 4. Branding Footer
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by MessIQ - The Auto Finance Engine', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to temporary directory to be shared or downloaded
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/MessIQ_Hisab_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryItem(String label, String value, {bool isHighlight = false, PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(color: isHighlight ? color : PdfColor.fromHex('#0F172A'), fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
