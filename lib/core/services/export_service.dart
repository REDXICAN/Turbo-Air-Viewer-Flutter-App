// lib/core/services/export_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<Uint8List> generateQuotePDF(String quoteId) async {
    final _firestore = FirebaseFirestore.instance;

    // Get quote details
    final quoteResponse = await supabase
        .collection('quotes')
        .select('*, clients(*), quote_items(*, products(*))')
        .where('id', isEqualTo: quoteId)
        .single();

    // Create PDF document
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#20429C'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TURBO AIR EQUIPMENT',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Professional Refrigeration Solutions',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Quote Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'QUOTE #${quoteResponse['quote_number']}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${dateFormat.format(DateTime.parse(quoteResponse['created_at']))}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Valid Until: ${dateFormat.format(DateTime.parse(quoteResponse['created_at']).add(const Duration(days: 30)))}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  quoteResponse['status'].toString().toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Client Info
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  quoteResponse['clients']['company'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (quoteResponse['clients']['contact_name'] != null)
                  pw.Text(quoteResponse['clients']['contact_name']),
                if (quoteResponse['clients']['contact_email'] != null)
                  pw.Text(quoteResponse['clients']['contact_email']),
                if (quoteResponse['clients']['contact_number'] != null)
                  pw.Text(quoteResponse['clients']['contact_number']),
                if (quoteResponse['clients']['address'] != null)
                  pw.Text(quoteResponse['clients']['address']),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                children: [
                  _buildTableCell('SKU', isHeader: true),
                  _buildTableCell('Description', isHeader: true),
                  _buildTableCell('Qty',
                      isHeader: true, align: pw.Alignment.center),
                  _buildTableCell('Unit Price',
                      isHeader: true, align: pw.Alignment.centerRight),
                  _buildTableCell('Total',
                      isHeader: true, align: pw.Alignment.centerRight),
                ],
              ),
              // Item rows
              ...(quoteResponse['quote_items'] as List).map((item) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(item['products']['sku']),
                    _buildTableCell(item['products']['product_type'] ?? ''),
                    _buildTableCell(item['quantity'].toString(),
                        align: pw.Alignment.center),
                    _buildTableCell(currencyFormat.format(item['unit_price']),
                        align: pw.Alignment.centerRight),
                    _buildTableCell(currencyFormat.format(item['total_price']),
                        align: pw.Alignment.centerRight),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _buildTotalRow('Subtotal',
                        currencyFormat.format(quoteResponse['subtotal'])),
                    _buildTotalRow('Tax (${quoteResponse['tax_rate']}%)',
                        currencyFormat.format(quoteResponse['tax_amount'])),
                    pw.Divider(),
                    _buildTotalRow('TOTAL',
                        currencyFormat.format(quoteResponse['total_amount']),
                        isBold: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '• This quote is valid for 30 days from the date of issue',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '• Prices are subject to change without notice',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '• Delivery times are estimates and not guaranteed',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '• Payment terms: Net 30 days',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List> generateQuoteExcel(String quoteId) async {
    final _firestore = FirebaseFirestore.instance;

    // Get quote details
    final quoteResponse = await supabase
        .collection('quotes')
        .select('*, clients(*), quote_items(*, products(*))')
        .where('id', isEqualTo: quoteId)
        .single();

    // Create Excel workbook
    final excel = Excel.createExcel();
    final sheet = excel['Quote'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Title
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'TURBO AIR EQUIPMENT - QUOTE #${quoteResponse['quote_number']}');

    // Date
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Date:');
    sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
        DateFormat('MM/dd/yyyy')
            .format(DateTime.parse(quoteResponse['created_at'])));

    // Client info
    sheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('CLIENT INFORMATION');
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Company:');
    sheet.cell(CellIndex.indexByString('B6')).value =
        TextCellValue(quoteResponse['clients']['company'] ?? '');

    if (quoteResponse['clients']['contact_name'] != null) {
      sheet.cell(CellIndex.indexByString('A7')).value =
          TextCellValue('Contact:');
      sheet.cell(CellIndex.indexByString('B7')).value =
          TextCellValue(quoteResponse['clients']['contact_name']);
    }

    if (quoteResponse['clients']['contact_email'] != null) {
      sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Email:');
      sheet.cell(CellIndex.indexByString('B8')).value =
          TextCellValue(quoteResponse['clients']['contact_email']);
    }

    // Items header
    int currentRow = 11;
    sheet.cell(CellIndex.indexByString('A$currentRow')).value =
        TextCellValue('SKU');
    sheet.cell(CellIndex.indexByString('B$currentRow')).value =
        TextCellValue('Description');
    sheet.cell(CellIndex.indexByString('C$currentRow')).value =
        TextCellValue('Quantity');
    sheet.cell(CellIndex.indexByString('D$currentRow')).value =
        TextCellValue('Unit Price');
    sheet.cell(CellIndex.indexByString('E$currentRow')).value =
        TextCellValue('Total');

    // Items
    currentRow++;
    for (final item in quoteResponse['quote_items'] as List) {
      sheet.cell(CellIndex.indexByString('A$currentRow')).value =
          TextCellValue(item['products']['sku']);
      sheet.cell(CellIndex.indexByString('B$currentRow')).value =
          TextCellValue(item['products']['product_type'] ?? '');
      sheet.cell(CellIndex.indexByString('C$currentRow')).value =
          IntCellValue(item['quantity']);
      sheet.cell(CellIndex.indexByString('D$currentRow')).value =
          DoubleCellValue(item['unit_price'].toDouble());
      sheet.cell(CellIndex.indexByString('E$currentRow')).value =
          DoubleCellValue(item['total_price'].toDouble());
      currentRow++;
    }

    // Totals
    currentRow += 2;
    sheet.cell(CellIndex.indexByString('D$currentRow')).value =
        TextCellValue('Subtotal:');
    sheet.cell(CellIndex.indexByString('E$currentRow')).value =
        DoubleCellValue(quoteResponse['subtotal'].toDouble());

    currentRow++;
    sheet.cell(CellIndex.indexByString('D$currentRow')).value =
        TextCellValue('Tax (${quoteResponse['tax_rate']}%):');
    sheet.cell(CellIndex.indexByString('E$currentRow')).value =
        DoubleCellValue(quoteResponse['tax_amount'].toDouble());

    currentRow++;
    sheet.cell(CellIndex.indexByString('D$currentRow')).value =
        TextCellValue('TOTAL:');
    sheet.cell(CellIndex.indexByString('E$currentRow')).value =
        DoubleCellValue(quoteResponse['total_amount'].toDouble());

    // Auto-fit columns
    for (int i = 0; i < 5; i++) {
      sheet.setColumnWidth(i, 20);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<Uint8List> generateClientListExcel() async {
    final _firestore = FirebaseFirestore.instance;
    final user = _firestore.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await supabase
        .collection('clients')
        .get()
        .where('user_id', isEqualTo: user.id)
        .order('company');

    final excel = Excel.createExcel();
    final sheet = excel['Clients'];
    excel.delete('Sheet1');

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Company');
    sheet.cell(CellIndex.indexByString('B1')).value =
        TextCellValue('Contact Name');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Email');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Phone');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Address');
    sheet.cell(CellIndex.indexByString('F1')).value =
        TextCellValue('Created Date');

    // Data
    int row = 2;
    for (final client in response as List) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(client['company'] ?? '');
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(client['contact_name'] ?? '');
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(client['contact_email'] ?? '');
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(client['contact_number'] ?? '');
      sheet.cell(CellIndex.indexByString('E$row')).value =
          TextCellValue(client['address'] ?? '');
      sheet.cell(CellIndex.indexByString('F$row')).value = TextCellValue(
          DateFormat('MM/dd/yyyy')
              .format(DateTime.parse(client['created_at'])));
      row++;
    }

    return Uint8List.fromList(excel.encode()!);
  }
}

