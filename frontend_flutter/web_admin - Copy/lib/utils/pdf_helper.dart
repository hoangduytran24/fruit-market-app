import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';

class PdfHelper {
  static Future<void> generateInvoice({
    required Order order,
    required String Function(double) formatCurrency,
    required String Function(DateTime) formatDate,
  }) async {
    final pdf = pw.Document();

    // Sử dụng font hỗ trợ tiếng Việt từ Google Fonts (Printing package)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            // Đã sửa: Sử dụng crossAxisAlignment thay vì crossSize
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    // Đã sửa: Mặc định là start, không dùng crossSize
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("GREENFRUIT MARKET",
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 24,
                              color: PdfColors.green900)),
                      pw.Text("Cửa hàng trái cây sạch hàng đầu",
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("HOÁ ĐƠN BÁN HÀNG",
                          style: pw.TextStyle(font: fontBold, fontSize: 18)),
                      pw.Text("Mã đơn: #${order.orderId.toUpperCase()}",
                          style: pw.TextStyle(font: font)),
                      pw.Text("Ngày: ${formatDate(order.createdAt)}",
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Thông tin khách hàng
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Thông tin khách hàng:",
                        style: pw.TextStyle(font: fontBold)),
                    pw.Text("Họ tên: ${order.customerName}",
                        style: pw.TextStyle(font: font)),
                    pw.Text("SĐT: ${order.customerPhone ?? 'N/A'}",
                        style: pw.TextStyle(font: font)),
                    pw.Text("Địa chỉ: ${order.deliveryAddress}",
                        style: pw.TextStyle(font: font)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Bảng sản phẩm
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green800),
                    children: [
                      _buildTableCell("Sản phẩm", fontBold,
                          color: PdfColors.white),
                      _buildTableCell("SL", fontBold,
                          color: PdfColors.white, align: pw.TextAlign.center),
                      _buildTableCell("Đơn giá", fontBold,
                          color: PdfColors.white, align: pw.TextAlign.right),
                      _buildTableCell("Thành tiền", fontBold,
                          color: PdfColors.white, align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...order.items.map((item) => pw.TableRow(
                        children: [
                          _buildTableCell(item.productName, font),
                          _buildTableCell(item.quantity.toString(), font,
                              align: pw.TextAlign.center),
                          _buildTableCell(formatCurrency(item.price), font,
                              align: pw.TextAlign.right),
                          _buildTableCell(formatCurrency(item.subtotal), font,
                              align: pw.TextAlign.right),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 20),

              // Tổng kết
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Tổng tiền: ${formatCurrency(order.totalAmount)}",
                          style: pw.TextStyle(font: font)),
                      if (order.discountAmount > 0)
                        pw.Text(
                            "Giảm giá: -${formatCurrency(order.discountAmount)}",
                            style: pw.TextStyle(
                                font: font, color: PdfColors.red)),
                      pw.Divider(color: PdfColors.grey400),
                      pw.Text("TỔNG THANH TOÁN:",
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: PdfColors.green900)),
                      pw.Text(formatCurrency(order.finalAmount),
                          style: pw.TextStyle(font: fontBold, fontSize: 18)),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Center(
                child: pw.Text("Cảm ơn quý khách đã tin tưởng GreenFruit Market!",
                    style: pw.TextStyle(
                        font: fontItalic, fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    // Hiển thị hộp thoại xem trước và in/tải về
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Hoa_don_${order.orderId}.pdf',
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.left,
      PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, color: color), textAlign: align),
    );
  }
}