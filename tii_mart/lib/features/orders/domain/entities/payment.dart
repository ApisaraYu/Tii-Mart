/// การชำระเงินของออเดอร์ (payments/{orderId} — 1 ออเดอร์ : 1 รายการชำระเงิน)
class Payment {
  const Payment({
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    this.slipUrl,
  });

  final String orderId;
  final String method; // promptpay
  final String status; // pending → paid (ร้านยืนยัน)
  final int amount;
  final String? slipUrl;

  bool get isPaid => status == 'paid';
}
