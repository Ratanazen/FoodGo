import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AddressItem {
  final int id;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;
  final String label;
  final double? lat;
  final double? lng;

  AddressItem({
    required this.id,
    required this.street,
    required this.city,
    this.state = 'Phnom Penh',
    this.zipCode = '12000',
    this.isDefault = false,
    this.label = 'Home',
    this.lat,
    this.lng,
  });

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    return AddressItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      street: json['street']?.toString() ?? '123 Street',
      city: json['city']?.toString() ?? 'Phnom Penh',
      state: json['state']?.toString() ?? 'Phnom Penh',
      zipCode: json['zip_code']?.toString() ?? '12000',
      isDefault: json['is_default'] == true,
      label: json['label']?.toString() ?? 'Home',
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'is_default': isDefault,
      'label': label,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }

  String get fullAddress => '$street, $city';
}

class AddressProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<AddressItem> _addresses = [];
  AddressItem? _selectedAddress;
  bool _isLoading = false;

  List<AddressItem> get addresses => _addresses;
  bool get isLoading => _isLoading;

  AddressItem? get selectedAddress {
    if (_selectedAddress != null) {
      final exists = _addresses.any((a) => a.id == _selectedAddress!.id);
      if (exists) return _selectedAddress;
    }
    if (_addresses.isNotEmpty) {
      return _addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => _addresses.first,
      );
    }
    return null;
  }

  void selectAddress(AddressItem address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('addresses/');
      final List<dynamic> list = res is List
          ? res
          : (res['results'] as List<dynamic>? ?? []);
      _addresses = list
          .map((e) => AddressItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (_addresses.isEmpty) {
        _loadDefaultFallbackAddresses();
      }
    } catch (_) {
      if (_addresses.isEmpty) {
        _loadDefaultFallbackAddresses();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadDefaultFallbackAddresses() {
    _addresses = [
      AddressItem(
        id: 1,
        street: 'Street 240, Daun Penh',
        city: 'Phnom Penh',
        state: 'Phnom Penh',
        zipCode: '12207',
        isDefault: true,
        lat: 11.5564,
        lng: 104.9282,
      ),
      AddressItem(
        id: 2,
        street: 'Vattanac Capital Tower, Monivong Blvd',
        city: 'Phnom Penh',
        state: 'Phnom Penh',
        zipCode: '12202',
        isDefault: false,
        lat: 11.5721,
        lng: 104.9210,
      ),
    ];
  }

  Future<bool> addAddress({
    required String street,
    required String city,
    String state = 'Phnom Penh',
    String zipCode = '12000',
    bool isDefault = false,
  }) async {
    final payload = {
      'street': street.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'zip_code': zipCode.trim(),
      'is_default': isDefault,
    };

    try {
      final res = await _api.post('addresses/', payload);
      final newItem = AddressItem.fromJson(
        Map<String, dynamic>.from(res as Map),
      );

      if (isDefault) {
        _addresses = _addresses
            .map(
              (a) => AddressItem(
                id: a.id,
                street: a.street,
                city: a.city,
                state: a.state,
                zipCode: a.zipCode,
                isDefault: false,
                lat: a.lat,
                lng: a.lng,
              ),
            )
            .toList();
      }

      _addresses.insert(0, newItem);
      if (isDefault || _addresses.length == 1) {
        _selectedAddress = newItem;
      }
      notifyListeners();
      return true;
    } catch (_) {
      final localId = DateTime.now().millisecondsSinceEpoch % 100000;
      if (isDefault) {
        _addresses = _addresses
            .map(
              (a) => AddressItem(
                id: a.id,
                street: a.street,
                city: a.city,
                state: a.state,
                zipCode: a.zipCode,
                isDefault: false,
                lat: a.lat,
                lng: a.lng,
              ),
            )
            .toList();
      }

      final localItem = AddressItem(
        id: localId,
        street: street.trim(),
        city: city.trim(),
        state: state.trim(),
        zipCode: zipCode.trim(),
        isDefault: isDefault,
      );

      _addresses.insert(0, localItem);
      if (isDefault || _addresses.length == 1) {
        _selectedAddress = localItem;
      }
      notifyListeners();
      return true;
    }
  }

  Future<bool> setDefaultAddress(int id) async {
    try {
      await _api.post('addresses/$id/set_default/', {});
    } catch (_) {}

    _addresses = _addresses.map((a) {
      final isDef = a.id == id;
      final updated = AddressItem(
        id: a.id,
        street: a.street,
        city: a.city,
        state: a.state,
        zipCode: a.zipCode,
        isDefault: isDef,
        lat: a.lat,
        lng: a.lng,
      );
      if (isDef) _selectedAddress = updated;
      return updated;
    }).toList();

    notifyListeners();
    return true;
  }

  Future<bool> deleteAddress(int id) async {
    try {
      await _api.delete('addresses/$id/');
    } catch (_) {}

    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddress?.id == id) {
      _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
    }
    notifyListeners();
    return true;
  }
}
