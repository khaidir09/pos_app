import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_pos_app/core/extensions/int_ext.dart';
import 'package:flutter_pos_app/core/extensions/string_ext.dart';
import 'package:flutter_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

import '../../../../../data/models/response/product_sales_report.dart';
import '../../../../../data/models/response/summary_response_model.dart';
import 'helper_pdf_service.dart';

class Invoice {
  static late Font ttf;

  static Future<pw.Widget> buildPdfLogo(String logoPath) async {
    try {
      if (logoPath.startsWith('http')) {
        // Load dari URL
        final response = await http.get(Uri.parse(logoPath));
        if (response.statusCode == 200) {
          final image = pw.MemoryImage(response.bodyBytes);
          return pw.Image(image,
              width: 80.0, height: 80.0, fit: pw.BoxFit.contain);
        } else {
          throw Exception('Failed to load logo from network');
        }
      } else {
        // Load dari assets lokal
        final ByteData bytes = await rootBundle.load(logoPath);
        final image = pw.MemoryImage(bytes.buffer.asUint8List());
        return pw.Image(image,
            width: 80.0, height: 80.0, fit: pw.BoxFit.contain);
      }
    } catch (e) {
      return pw.Text('Logo tidak tersedia');
    }
  }

  static Future<File> generate(List<ProductSales> itemSales, Summary summary,
      {required String shopName,
      required String shopAddress} // Tambahkan named parameters
      ) async {
    final pdf = Document();
    // var data = await rootBundle.load("assets/fonts/noto-sans.ttf");
    // ttf = Font.ttf(data);

    final logoPath = await AuthLocalDatasource().getShopLogoUrl();
    print('Logo Path: $logoPath');

    final logoWidget = await buildPdfLogo(logoPath);

    pdf.addPage(
      MultiPage(
        build: (context) => [
          buildHeader(logoWidget, shopName),
          SizedBox(height: 1 * PdfPageFormat.cm),
          Text('Ringkasan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: 0.15 * PdfPageFormat.cm),
          buildSummary(summary),
          SizedBox(height: 4 * PdfPageFormat.cm),
          Text('Daftar Produk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: 0.25 * PdfPageFormat.cm),
          buildInvoice(itemSales),
          Divider(),
          SizedBox(height: 0.25 * PdfPageFormat.cm),
        ],
        footer: (context) => buildFooter(shopAddress),
      ),
    );

    return HelperPdfService.saveDocument(
        name:
            '$shopName | Laporan | ${DateTime.now().millisecondsSinceEpoch}.pdf',
        pdf: pdf);
  }

  static Widget buildHeader(
    pw.Widget logoWidget,
    String shopName, // Terima nama toko sebagai parameter
  ) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1 * PdfPageFormat.cm),
            Text('$shopName | Laporan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 0.2 * PdfPageFormat.cm),
            Text(
              'Dicetak pada: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            ),
          ],
        ),
        logoWidget
      ]);

  static Widget buildSummary(Summary summary) {
    return Column(children: [
      buildTextPrice(
        title: 'Pendapatan',
        value: summary.totalRevenue.currencyFormatRp,
        unite: true,
      ),
      buildTextPrice(
        title: 'Barang Terjual',
        value: summary.totalSoldQuantity.toString(),
        unite: true,
      ),
      Divider(),
    ]);
  }

  static Widget buildInvoice(List<ProductSales> itemSales) {
    final headers = ['No', 'Produk', 'Harga', 'Banyaknya', 'Total'];
    final data = itemSales.map((item) {
      int index = itemSales.indexOf(item) + 1;

      return [
        index.toString(),
        item.productName,
        item.productPrice.currencyFormatRp,
        item.totalQuantity,
        (item.totalQuantity.toInt * item.productPrice).currencyFormatRp
      ];
    }).toList();

    return Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(
          fontWeight: FontWeight.bold, color: PdfColor.fromHex('FFFFFF')),
      headerDecoration: const BoxDecoration(color: PdfColors.blue),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.center,
        1: Alignment.centerLeft,
        2: Alignment.centerLeft,
        3: Alignment.center,
        4: Alignment.centerLeft,
      },
    );
  }

  static Widget buildFooter(String shopAddress) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          buildSimpleText(title: 'Alamat', value: shopAddress),
          SizedBox(height: 1 * PdfPageFormat.mm),
        ],
      );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(value),
      ],
    );
  }

  static buildTextPrice({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: unite ? style : null),
        ],
      ),
    );
  }
}
