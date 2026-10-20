class PaymentModel {
  final int id;
  final int orderId;
  final String provider;
  final String method;
  final String? transactionId;
  final String? merchantReference;
  final String? orderReference;
  final String? restaurantName;
  final Map<String, dynamic>? orderSummary;
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
    this.orderReference,
    this.restaurantName,
    this.orderSummary,
    required this.amount,
    required this.currency,
    this.qrPayload,
    required this.status,
    this.expiresAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderId: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '') ??
                (json['order_id'] is int
                    ? json['order_id']
                    : int.tryParse(json['order_id']?.toString() ?? '') ?? 0),
      provider: json['provider'] ?? 'BAKONG',
      method: json['method'] ?? 'KHQR',
      transactionId: json['transaction_id'],
      merchantReference: json['merchant_reference'],
      orderReference: json['order_reference'],
      restaurantName:
          json['restaurant_name'] ??
          (json['order_summary'] is Map
              ? json['order_summary']['restaurant']
              : null),
      orderSummary: json['order_summary'] is Map<String, dynamic>
          ? json['order_summary']
          : null,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      currency: json['currency'] ?? 'USD',
      qrPayload: json['qr_payload'] ?? json['qr_string'],
      status: json['status'] ?? 'PENDING',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'])
          : null,
    );
  }

  PaymentModel copyWith({
    int? id,
    int? orderId,
    String? provider,
    String? method,
    String? transactionId,
    String? merchantReference,
    String? orderReference,
    String? restaurantName,
    Map<String, dynamic>? orderSummary,
    double? amount,
    String? currency,
    String? qrPayload,
    String? status,
    DateTime? expiresAt,
    DateTime? paidAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      provider: provider ?? this.provider,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      merchantReference: merchantReference ?? this.merchantReference,
      orderReference: orderReference ?? this.orderReference,
      restaurantName: restaurantName ?? this.restaurantName,
      orderSummary: orderSummary ?? this.orderSummary,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      qrPayload: qrPayload ?? this.qrPayload,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  bool get isPaid => status == 'PAID';
  bool get isExpired => status == 'EXPIRED';
  bool get isPending => status == 'PENDING';
  bool get isCreating => status == 'CREATING';
  bool get isCancelled => status == 'CANCELLED';
  bool get isFailed => status == 'FAILED';
  bool get isProcessing => status == 'PROCESSING';
  bool get isRefunded => status == 'REFUNDED';
}
