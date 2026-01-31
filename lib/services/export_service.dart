import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../models/pos_models.dart';

class ExportService {
  Future<String> exportInvoicesToCSV(List<Invoice> invoices) async {
    List<List<dynamic>> rows = [];
    rows.add(["Invoice Number", "Type", "Customer ID", "Subtotal", "Tax", "Discount", "Total", "Status", "Date"]);

    for (var i in invoices) {
      rows.add([
        i.invoiceNumber,
        i.type.name,
        i.customerId ?? "N/A",
        i.subTotal,
        i.taxAmount,
        i.discountAmount,
        i.totalAmount,
        i.status.name,
        i.createdAt.toIso8601String(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'automata_pos', 'exports', 'invoices_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsString(csvData);
    
    return path;
  }

  Future<String> exportInvoicesToExcel(List<Invoice> invoices) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Invoices'];
    
    sheetObject.appendRow([
      TextCellValue("Invoice Number"),
      TextCellValue("Type"),
      TextCellValue("Subtotal"),
      TextCellValue("Tax"),
      TextCellValue("Discount"),
      TextCellValue("Total"),
      TextCellValue("Status"),
      TextCellValue("Date")
    ]);

    for (var i in invoices) {
      sheetObject.appendRow([
        TextCellValue(i.invoiceNumber),
        TextCellValue(i.type.name),
        DoubleCellValue(i.subTotal),
        DoubleCellValue(i.taxAmount),
        DoubleCellValue(i.discountAmount),
        DoubleCellValue(i.totalAmount),
        TextCellValue(i.status.name),
        TextCellValue(i.createdAt.toIso8601String()),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'automata_pos', 'exports', 'invoices_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsBytes(excel.save()!);
    
    return path;
  }

  Future<String> generateInvoicePDF(Invoice invoice, {Branch? branch, String? cashierName, String printerType = 'THERMAL_80'}) async {
    final pdf = pw.Document(
      title: 'Invoice_${invoice.invoiceNumber}',
      author: branch?.name ?? 'Automata POS',
      creator: 'Automata POS',
      subject: 'Invoice #${invoice.invoiceNumber}',
    );

    // Determine Page Format
    PdfPageFormat pageFormat;
    bool isThermal = true;
    
    switch (printerType) {
      case 'THERMAL_58':
        pageFormat = const PdfPageFormat(164, double.infinity, marginAll: 5); // 58mm ~ 164 points
        break;
      case 'A4':
        pageFormat = PdfPageFormat.a4;
        isThermal = false;
        break;
      case 'THERMAL_80':
      default:
        pageFormat = const PdfPageFormat(226, double.infinity, marginAll: 10); // 80mm ~ 226 points
        break;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          if (!isThermal) {
             // A4 Layout (Standard Invoice)
             return _buildA4Layout(invoice, branch, cashierName);
          }
          
          // Thermal Layout (Receipt)
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Name (Centered, Bold)
              pw.Text(
                branch?.name ?? 'MY STORE NAME',
                style: pw.TextStyle(
                  fontSize: printerType == 'THERMAL_58' ? 12 : 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              
              // Address, Phone, GSTIN (Centered, Small)
              if (branch != null) ...[
                pw.Text(
                  branch.address,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Phone: ${branch.phone}${branch.gstin != null ? ' | GSTIN: ${branch.gstin}' : ''}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 6),
              
              // Separator
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 4),
              
              // Invoice Number
              pw.Text(
                'Invoice: ${invoice.invoiceNumber}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              
              // Date and Cashier
              pw.Text(
                'Date: ${DateFormat('dd-MM-yyyy HH:mm').format(invoice.createdAt)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (cashierName != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Cashier: $cashierName',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              pw.SizedBox(height: 4),
              
              // Separator
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 4),
              
              // Items
              ...invoice.items.map((item) {
                final itemTotal = (item.rate * item.quantity) - item.discount;
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item.name}  x${item.quantity.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Text(
                          itemTotal.toStringAsFixed(2),
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                  ],
                );
              }).toList(),
              
              pw.SizedBox(height: 4),
              
              // Separator
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 4),
              
              // Subtotal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    invoice.subTotal.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              
              // GST (only if applicable)
              if (invoice.taxAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GST',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      invoice.taxAmount.toStringAsFixed(2),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],
              
              // Discount (only if applicable)
              if (invoice.discountAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      '-${invoice.discountAmount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],
              
              pw.SizedBox(height: 4),
              
              // Separator
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 4),
              
              // TOTAL (Bold, Larger)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    invoice.totalAmount.toStringAsFixed(2),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              
              if (invoice.balanceAmount > 0) ...[
                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      invoice.paidAmount.toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Balance Due', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      invoice.balanceAmount.toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              
              // Separator
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 4),
              
              // Payment Mode
              if (invoice.paymentMode == 'SPLIT' && invoice.payments.isNotEmpty) ...[
                 pw.Text('Payment Breakdown', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                 ...invoice.payments.map((p) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                       pw.Text(p.mode, style: const pw.TextStyle(fontSize: 9)),
                       pw.Text(p.amount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
                    ],
                 )),
                 pw.SizedBox(height: 4),
              ] else if (invoice.paymentMode != null) ...[
                pw.Text(
                  'Payment: ${invoice.paymentMode}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
              ],
              
              // Separator
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 6),
              
              // Thank You Message
              pw.Text(
                'Thank You! Visit Again',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'automata_pos', 'invoices', '${invoice.invoiceNumber}.pdf');
    
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  pw.Widget _buildPdfTaxAnalysis(Invoice invoice) {
     Map<String, HsnTaxBreakdown> breakdownMap = {};
     bool hasIgst = false;
     bool hasCgst = false;

    for (var item in invoice.items) {
      double rate = item.rate;
      double quantity = item.quantity;
      double discount = item.discount;
      double gstPercent = item.gstRate;

      double lineAmount = (rate * quantity) - discount;
      if (lineAmount < 0) lineAmount = 0;
      
      double cgst = item.cgst;
      double sgst = item.sgst;
      double igst = item.igst;
      double itemTax = cgst + sgst + igst;
      
      // Determine base (taxable) amount
      // If inclusive, we subtract tax. If exclusive, it's just lineAmount.
      // NOTE: The previous code did: itemBase = item.total - itemTax.
      // That works if item.total is correct (Base + Tax).
      // Let's stick to that as it's consistent for display.
      double itemBase = item.total - itemTax; 

      if (igst > 0) hasIgst = true;
      if (cgst > 0) hasCgst = true;

      String key;
      String label;
      
      if (invoice.type == InvoiceType.product) {
        key = gstPercent.toString();
        label = 'GST ${gstPercent.toInt()}%';
      } else {
        key = item.hsnCode ?? 'Others';
        label = item.hsnCode ?? 'Others';
      }

      if (!breakdownMap.containsKey(key)) {
        breakdownMap[key] = HsnTaxBreakdown(
          hsnCode: label,
          baseAmount: 0,
          gstRate: gstPercent,
          cgst: 0,
          sgst: 0,
          igst: 0,
          totalTax: 0,
        );
      }
      
      final existing = breakdownMap[key]!;
      breakdownMap[key] = HsnTaxBreakdown(
        hsnCode: existing.hsnCode,
        baseAmount: existing.baseAmount + itemBase,
        gstRate: existing.gstRate,
        cgst: existing.cgst + cgst,
        sgst: existing.sgst + sgst,
        igst: existing.igst + igst,
        totalTax: existing.totalTax + itemTax,
      );
    }
    
    final sortedBreakdown = breakdownMap.values.toList()..sort((a, b) => a.hsnCode.compareTo(b.hsnCode));

    if (sortedBreakdown.isEmpty || invoice.taxAmount == 0) return pw.SizedBox();
    
    // Dynamic Columns
    List<String> headers = ['HSN / Rate', 'Taxable Val'];
    if (hasCgst) {
      headers.addAll(['CGST', 'SGST']);
    }
    if (hasIgst) {
      headers.add('IGST');
    }
    headers.add('Total Tax');
    
    // Cell Alignments (Auto-generate based on length)
    Map<int, pw.Alignment> alignments = {0: pw.Alignment.centerLeft};
    for(int i=1; i<headers.length; i++) {
        alignments[i] = pw.Alignment.centerRight;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Tax Analysis', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey800),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignments: alignments,
          headers: headers,
          data: sortedBreakdown.map((bd) {
            List<String> row = [
               bd.hsnCode,
               bd.baseAmount.toStringAsFixed(2),
            ];
            
            if (hasCgst) {
               row.add(bd.cgst.toStringAsFixed(2));
               row.add(bd.sgst.toStringAsFixed(2));
            }
            if (hasIgst) {
               row.add(bd.igst.toStringAsFixed(2));
            }
            
            row.add(bd.totalTax.toStringAsFixed(2));
            return row;
          }).toList(),
        )
      ]
    );
  }

  pw.Widget _pdfSummaryRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('Rs. ${value.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  pw.Widget _buildA4Layout(Invoice invoice, Branch? branch, String? cashierName) {
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center, // Center everything by default
      children: [
        // Centered Header
        pw.Text(branch?.name ?? 'Business Name', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text((branch?.address ?? '').replaceAll('\r', '').replaceAll('\n', ', '), style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Phone: ${branch?.phone ?? ''}', style: const pw.TextStyle(fontSize: 10)),
        if (branch?.gstin != null) pw.Text('GSTIN: ${branch?.gstin}', style: const pw.TextStyle(fontSize: 10)),
        
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.SizedBox(height: 8),

        // Invoice Details Helper (Left/Right split for details)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
             pw.Column(
               crossAxisAlignment: pw.CrossAxisAlignment.start,
               children: [
                 pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                 // Placeholder for Customer Name as we don't have it in the invoice object directly here without fetching
                 // But we can show invoice type or notes
                 pw.Text('Invoice Type: ${invoice.type.name.toUpperCase()}'),
               ]
             ),
             pw.Column(
               crossAxisAlignment: pw.CrossAxisAlignment.end,
               children: [
                 pw.Text(
                   invoice.balanceAmount > 0 ? 'ADVANCE INVOICE' : 'TAX INVOICE', 
                   style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)
                 ),
                 pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                 pw.Text('Date: ${DateFormat('dd-MMM-yyyy').format(invoice.createdAt)}'),
               ]
             )
          ]
        ),
        
        pw.SizedBox(height: 20),
        
        // Item Table
         pw.Table.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          data: <List<String>>[
            <String>['Item', 'Qty', 'Rate', 'Dis.', 'Total'],
             ...invoice.items.map((item) {
               return [
                 item.name,
                 item.quantity.toStringAsFixed(0),
                 item.rate.toStringAsFixed(2),
                 item.discount.toStringAsFixed(2),
                 item.total.toStringAsFixed(2),
               ];
             })
          ],
        ),
        
        pw.SizedBox(height: 12),
        
        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
               pw.Container(
                 width: 200,
                 child: pw.Column(
                   children: [
                     _pdfSummaryRow('Subtotal', invoice.subTotal),
                     _pdfSummaryRow('Tax', invoice.taxAmount),
                   _pdfSummaryRow('Discount', invoice.discountAmount),
                   pw.Divider(),
                   _pdfSummaryRow('Total', invoice.totalAmount, isBold: true),
                   
                   // Conditional Display for Partial Invoices
                   if (invoice.balanceAmount > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Divider(borderStyle: pw.BorderStyle.dashed),
                      _pdfSummaryRow('Paid Amount', invoice.paidAmount, isBold: true),
                      _pdfSummaryRow('Balance Due', invoice.balanceAmount, isBold: true),
                      pw.SizedBox(height: 4),
                   ],
                   
                   // Payment Mode
                   if (invoice.paymentMode == 'SPLIT' && invoice.payments.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text('Payment Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ...invoice.payments.map((p) => pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(p.mode, style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Rs. ${p.amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      )),
                   ] else ...[
                      pw.SizedBox(height: 8),
                      // Just append to column
                      pw.Row(
                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                         children: [
                            pw.Text('Paid Via', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(invoice.paymentMode ?? 'CASH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                         ]
                      )
                   ]
                 ],
               ),
             ),
          ],
        ),
         
        pw.SizedBox(height: 20),
        _buildPdfTaxAnalysis(invoice),
      ],
    );
  }
}
