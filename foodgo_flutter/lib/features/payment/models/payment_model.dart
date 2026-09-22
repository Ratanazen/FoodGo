class PaymentModel {
  final int id;
  final int orderId;
  final String provider;
  final String method;
  final String? transactionId;
  final String? merchantReference;
  final double amount;
  final String currency;
  final String? qrPayload;
  final String status;
  final DateTime? expiresAt;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.method,
    this.transactionId,
    this.merchantReference,
    required this.amount,
    required this.currency,
    this.qrPayload,
    required this.status,
    this.expiresAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      orderId: json['order'],
      provider: json['provider'] ?? 'ABA',
      method: json['method'] ?? 'KHQR',
      transactionId: json['transaction_id'],
      merchantReference: json['merchant_reference'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      qrPayload: json['qr_payload'],
      status: json['status'] ?? 'PENDING',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
    );
  }

  bool get isPaid => status == 'PAID';
  bool get isExpired => status == 'EXPIRED';
  bool get isPending => status == 'PENDING';
  bool get isCancelled => status == 'CANCELLED';
}
