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
  final String? qrImage;
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
    this.qrImage,
    required this.status,
    this.expiresAt,
    this.paidAt,
  });

  static String crc16Ccitt(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) & 0xFF) << 8;
      for (int b = 0; b < 8; b++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Ensures any dynamic EMVCo KHQR string ('000201010212...6304XXXX') includes
  /// NBC Bakong Tag 99 (Creation & Expiration Timestamp in milliseconds) and
  /// compliant Individual Account Tag 29 ('29200016sonar_seang@bkrt').
  /// If the server already included Tag 99, returns [rawPayload] unchanged.
  static String? ensureDynamicKhqrExpiration(
    String? rawPayload, {
    DateTime? expiresAt,
  }) {
    if (rawPayload == null || rawPayload.isEmpty) return rawPayload;
    final trimmed = rawPayload.trim();
    if (!trimmed.startsWith('000201010212') || trimmed.length < 30) {
      return rawPayload;
    }
    final crcSuffixPattern = RegExp(r'6304[0-9A-Fa-f]{4}$');
    if (!crcSuffixPattern.hasMatch(trimmed)) {
      return rawPayload;
    }
    final validTag99Pattern = RegExp(
      r'99340013\d{13}0113\d{13}6304[0-9A-Fa-f]{4}$',
    );
    if (validTag99Pattern.hasMatch(trimmed) &&
        !trimmed.contains('0011bakong@khqr')) {
      return trimmed;
    }

    // Strip trailing '6304XXXX'
    String body = trimmed.substring(0, trimmed.length - 8);
    // Remove any existing Tag 99 right before 6304 if present
    body = body.replaceFirst(RegExp(r'99340013\d{13}0113\d{13}$'), '');

    // Upgrade legacy Tag 29 (at offset 12 right after '000201010212') using its exact TLV length
    if (body.length > 16 && body.substring(12, 14) == '29') {
      final int? tag29Len = int.tryParse(body.substring(14, 16));
      if (tag29Len != null && body.length >= 16 + tag29Len) {
        final String tag29Val = body.substring(16, 16 + tag29Len);
        if (tag29Val.startsWith('0011bakong@khqr') ||
            tag29Val.startsWith('0016abaakhppxxx@abaa') ||
            tag29Val.startsWith('0020acledakhppxxx@acleda')) {
          String targetAcct = 'sonar_seang@bkrt';
          // Extract sub-tag 01 if it has an @-qualified Bakong account ID
          final int sub00Len = int.tryParse(tag29Val.substring(2, 4)) ?? 0;
          final int sub01Start = 4 + sub00Len;
          if (tag29Val.length >= sub01Start + 4 &&
              tag29Val.substring(sub01Start, sub01Start + 2) == '01') {
            final int sub01Len =
                int.tryParse(
                  tag29Val.substring(sub01Start + 2, sub01Start + 4),
                ) ??
                0;
            if (tag29Val.length >= sub01Start + 4 + sub01Len) {
              final String candidate = tag29Val.substring(
                sub01Start + 4,
                sub01Start + 4 + sub01Len,
              );
              if (candidate.contains('@')) {
                targetAcct = candidate;
              }
            }
          }
          final String sub00 =
              '00${targetAcct.length.toString().padLeft(2, '0')}$targetAcct';
          final String newTag29 =
              '29${sub00.length.toString().padLeft(2, '0')}$sub00';
          body =
              body.substring(0, 12) + newTag29 + body.substring(16 + tag29Len);
        }
      }
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int expMs =
        (expiresAt != null &&
            expiresAt.millisecondsSinceEpoch > nowMs + 60 * 1000)
        ? expiresAt.millisecondsSinceEpoch
        : nowMs + 30 * 60 * 1000;
    final String nowStr = nowMs.toString();
    final String expStr = expMs.toString();
    final String tag99Val =
        '00${nowStr.length.toString().padLeft(2, '0')}$nowStr'
        '01${expStr.length.toString().padLeft(2, '0')}$expStr';
    final String tag99 =
        '99${tag99Val.length.toString().padLeft(2, '0')}$tag99Val';

    final String withoutCrc = '$body${tag99}6304';
    final String crc = crc16Ccitt(withoutCrc);
    return '$withoutCrc$crc';
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final parsedExpiresAt = json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'])
        : null;
    final rawQrPayload =
        (json['qr_payload'] ??
                json['qr_string'] ??
                (json['provider_response'] is Map
                    ? json['provider_response']['qr_string'] ??
                          json['provider_response']['qr_payload']
                    : null))
            ?.toString();
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
      qrPayload: ensureDynamicKhqrExpiration(
        rawQrPayload,
        expiresAt: parsedExpiresAt,
      ),
      qrImage:
          json['qr_image'] ??
          (json['provider_response'] is Map
              ? json['provider_response']['qr_image']
              : null),
      status: json['status'] ?? 'PENDING',
      expiresAt: parsedExpiresAt,
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
    String? qrImage,
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
      qrImage: qrImage ?? this.qrImage,
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

/// Metadata describing an available payment method returned from the backend.
class PaymentMethodConfig {
  final String code;
  final String name;
  final String khmerName;
  final String method;
  final bool isEnabled;
  final bool isConfigured;
  final List<String> currencies;
  final String icon;
  final String description;

  const PaymentMethodConfig({
    required this.code,
    required this.name,
    required this.khmerName,
    required this.method,
    required this.isEnabled,
    required this.isConfigured,
    required this.currencies,
    required this.icon,
    required this.description,
  });

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) {
    return PaymentMethodConfig(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      khmerName: json['khmer_name']?.toString() ?? '',
      method: json['method']?.toString() ?? 'KHQR',
      isEnabled: json['is_enabled'] == true,
      isConfigured: json['is_configured'] != false,
      currencies:
          (json['currencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['USD'],
      icon: json['icon']?.toString() ?? 'khqr_logo',
      description: json['description']?.toString() ?? '',
    );
  }
}
