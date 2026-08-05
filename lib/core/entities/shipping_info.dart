import 'package:equatable/equatable.dart';

/// Customer-provided shipping details for checkout. Also persisted as the
/// local customer profile so checkout can be pre-filled.
class ShippingInfo extends Equatable {
  const ShippingInfo({this.name = '', this.phone = '', this.address = ''});

  final String name;
  final String phone;
  final String address;

  bool get isEmpty => name.isEmpty && phone.isEmpty && address.isEmpty;

  ShippingInfo copyWith({String? name, String? phone, String? address}) {
    return ShippingInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [name, phone, address];
}
